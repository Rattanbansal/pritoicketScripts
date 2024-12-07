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
  "delete FROM prioticket-reporting.prio_test.resellers_synch where 1=1"


  while :; do

    records=$(mysql -h $DBHOST --user=$DBUSER --port=$PORT --password=$DBPWD $DBDATABASE -N -e "select count(*) from (select * from resellers where deleted = '0' limit $OFFSET, $LIMIT) as base;") || exit 1

    echo "$records"

    echo "limit $OFFSET, $LIMIT"

    echo "select * from resellers where deleted = '0' limit $OFFSET, $LIMIT" | time mysqlsh --sql --json --uri $DBUSER@$DBHOST:$PORT -p$DBPWD --database=$DBDATABASE >> resellers.json || exit 1

    jq 'select(.warning | not)' resellers.json >> resellers1.json

    rm resellers.json

    jq 'walk(if type == "number" then (. * 100 | round / 100) else . end)' resellers1.json > resellers2.json

    rm resellers1.json

    jq .rows[] resellers2.json  >> resellersrows.json

    rm resellers2.json

    cat resellersrows.json | jq -c '.' >> resellers_ndnewjson.json

    rm resellersrows.json


    bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.resellers_synch resellers_ndnewjson.json || exit 1

    # exit

    rm resellers_ndnewjson.json


    OFFSET=$(($OFFSET + $LIMIT))

    if [[ $records < $LIMIT ]]; then
      echo "No more records to fetch. Exiting loop."
      break
    fi
  done

else

  bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
  "with resellerst as (select *,row_number() over(partition by reseller_id order by last_modified_at desc ) as rn from prio_test.resellers_synch), reellersl as (select *,row_number() over(partition by reseller_id order by last_modified_at desc ) as rn from prio_olap.resellers), resellerstrn as (select * from resellerst where rn = 1), reellerslrn as (select * from reellersl where rn = 1), final as (select resellerstrn.*, reellerslrn.reseller_id as ids from resellerstrn left join reellerslrn on resellerstrn.reseller_id = reellerslrn.reseller_id and (resellerstrn.last_modified_at = reellerslrn.last_modified_at or resellerstrn.last_modified_at < reellerslrn.last_modified_at)) select *except(rn, ids) from final where ids is NULL" > mismatch.json

fi