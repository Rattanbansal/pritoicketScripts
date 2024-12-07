#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

echo "-------------Script Starting So removing all Json Files-----------"
rm -rf *.json

gcloud config set project prioticket-reporting

DBHOST='163.47.214.30'
DBUSER='datalook'
DBPWD='datalook2024$$'
DBDATABASE='priopassdb'
PORT="3307"
# DBHOST='production-primary-db-node-cluster.cluster-ck6w2al7sgpk.eu-west-1.rds.amazonaws.com'
# DBUSER='pipeuser'
# DBPWD='d4fb46eccNRAL'
# DBDATABASE='priopassdb'
# PORT="3306"
UploadData=$1

LIMIT=25000
OFFSET=0

if [[ $UploadData == 2 ]]; then

  echo "-----------Started Deleting all records for bigquery--------"
  bq query --use_legacy_sql=False --format=prettyjson \
  "delete FROM prioticket-reporting.prio_test.ticket_destinations_synch where 1=1"


  while :; do

    records=$(mysql -h $DBHOST --user=$DBUSER --port=$PORT --password=$DBPWD $DBDATABASE -N -e "select count(*) from (select * from ticket_destinations where deleted = '0' limit $OFFSET, $LIMIT) as base;") || exit 1

    echo "$records"

    echo "limit $OFFSET, $LIMIT"

    echo "select * from ticket_destinations where deleted = '0' limit $OFFSET, $LIMIT" | time mysqlsh --sql --json --uri $DBUSER@$DBHOST:$PORT -p$DBPWD --database=$DBDATABASE >> ticket_destinations.json || exit 1

    jq 'select(.warning | not)' ticket_destinations.json >> ticket_destinations1.json

    rm ticket_destinations.json

    jq 'walk(if type == "number" then (. * 100 | round / 100) else . end)' ticket_destinations1.json > ticket_destinations2.json

    rm ticket_destinations1.json

    jq .rows[] ticket_destinations2.json  >> ticket_destinationsrows.json

    rm ticket_destinations2.json

    cat ticket_destinationsrows.json | jq -c '.' >> ticket_destinations_ndnewjson.json

    rm ticket_destinationsrows.json


    bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.ticket_destinations_synch ticket_destinations_ndnewjson.json || exit 1

    # exit

    rm ticket_destinations_ndnewjson.json


    OFFSET=$(($OFFSET + $LIMIT))

    if [[ $records < $LIMIT ]]; then
      echo "No more records to fetch. Exiting loop."
      break
    fi
  done

else

  bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
  "with tdt as (select *,row_number() over(partition by destination_id order by last_modified_at desc ) as rn from prio_test.ticket_destinations_synch), tdl as (select *,row_number() over(partition by destination_id order by last_modified_at desc ) as rn from prio_olap.ticket_destinations), tdtrn as (select * from tdt where rn = 1), tdlrn as (select * from tdl where rn = 1), final as (select tdtrn.*, tdlrn.destination_id as ids from tdtrn left join tdlrn on tdtrn.destination_id = tdlrn.destination_id and (tdtrn.last_modified_at = tdlrn.last_modified_at or tdtrn.last_modified_at < tdlrn.last_modified_at)) select *except(rn, ids) from final where ids is NULL" > mismatch.json

fi