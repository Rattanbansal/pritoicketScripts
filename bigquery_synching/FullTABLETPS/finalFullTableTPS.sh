#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

echo "-------------Script Starting So removing all Json Files-----------"
rm -rf *.json

gcloud config set project prioticket-reporting

# DBHOST='163.47.214.30'
# DBUSER='datalook'
# DBPWD='datalook2024$$'
# DBDATABASE='priopassdb'
# PORT="3307"
DBHOST='production-primary-db-node-cluster.cluster-ck6w2al7sgpk.eu-west-1.rds.amazonaws.com'
DBUSER='pipeuser'
DBPWD='d4fb46eccNRAL'
DBDATABASE='priopassdb'
PORT="3306"
UploadData=$1

LIMIT=25000
OFFSET=0

if [[ $UploadData == 2 ]]; then

  echo "-----------Started Deleting all records for bigquery--------"
  bq query --use_legacy_sql=False --format=prettyjson \
  "delete FROM prioticket-reporting.prio_test.ticketpriceschedule_synch where 1=1"


  while :; do

    records=$(mysql -h $DBHOST --user=$DBUSER --port=$PORT --password=$DBPWD $DBDATABASE -N -e "select count(*) from (select * from ticketpriceschedule where deleted = '0' limit $OFFSET, $LIMIT) as base;") || exit 1

    echo "$records"

    echo "limit $OFFSET, $LIMIT"

    echo "select * from ticketpriceschedule where deleted = '0' limit $OFFSET, $LIMIT" | time mysqlsh --sql --json --uri $DBUSER@$DBHOST:$PORT -p$DBPWD --database=$DBDATABASE >> ticketpriceschedule.json || exit 1

    jq 'select(.warning | not)' ticketpriceschedule.json >> ticketpriceschedule1.json

    rm ticketpriceschedule.json

    jq 'walk(if type == "number" then (. * 100 | round / 100) else . end)' ticketpriceschedule1.json > ticketpriceschedule2.json

    rm ticketpriceschedule1.json

    jq .rows[] ticketpriceschedule2.json  >> ticketpriceschedulerows.json

    rm ticketpriceschedule2.json

    cat ticketpriceschedulerows.json | jq -c '.' >> ticketpriceschedule_ndnewjson.json

    rm ticketpriceschedulerows.json


    bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.ticketpriceschedule_synch ticketpriceschedule_ndnewjson.json || exit 1

    # exit

    rm ticketpriceschedule_ndnewjson.json


    OFFSET=$(($OFFSET + $LIMIT))

    if [[ $records < $LIMIT ]]; then
      echo "No more records to fetch. Exiting loop."
      break
    fi
  done

else

  bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
  "with tpst as (select *,row_number() over(partition by id order by last_modified_at desc ) as rn from prio_test.ticketpriceschedule_synch), tpsl as (select *,row_number() over(partition by id order by last_modified_at desc ) as rn from prio_olap.ticketpriceschedule), tpstrn as (select * from tpst where rn = 1), tpslrn as (select * from tpsl where rn = 1), final as (select tpstrn.*, tpslrn.id as ids from tpstrn left join tpslrn on tpstrn.id = tpslrn.id and (tpstrn.last_modified_at = tpslrn.last_modified_at or tpstrn.last_modified_at < tpslrn.last_modified_at)) select *except(rn, ids) from final where ids is NULL" > mismatch.json

fi