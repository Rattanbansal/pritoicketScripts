#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=70

echo "-------------Script Starting So removing all Json Files-----------"
rm -rf *.json

gcloud config set project prioticket-reporting

UploadData=$1
DATABSETYPE=$2
LIMIT=5000
OFFSET=0

# Check if the required arguments are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: All arguments are required."
    echo "Usage: $0 UploadData datasetType"
    exit 1
fi

echo "condition Satisfy with Both Argument"

if [[ $DATABSETYPE == "PROD" ]]; then

    echo "Live Database Selected"

    DBHOST='production-primary-db-node-cluster.cluster-ck6w2al7sgpk.eu-west-1.rds.amazonaws.com'
    DBUSER='pipeuser'
    DBPWD='d4fb46eccNRAL'
    DBDATABASE='priopassdb'
    PORT="3306"

else

    echo "Staging Database Selected"

    DBHOST='163.47.214.30'
    DBUSER='datalook'
    DBPWD='datalook2024$$'
    DBDATABASE='priopassdb'
    PORT="3307"

fi

if [[ $UploadData == 2 ]]; then

  echo "-----------Started Deleting all records for bigquery--------"
  bq query --use_legacy_sql=False --format=prettyjson \
  "delete FROM prioticket-reporting.prio_test.modeventcontent_synch where 1=1"


  while :; do

    records=$( timeout $TIMEOUT_PERIOD time mysql -h $DBHOST --user=$DBUSER --port=$PORT --password=$DBPWD $DBDATABASE -N -e "select count(*) from (select * from modeventcontent where deleted = '0' limit $OFFSET, $LIMIT) as base;") || exit 1

    echo "$records"

    echo "limit $OFFSET, $LIMIT"

    echo "select * from modeventcontent where deleted = '0' limit $OFFSET, $LIMIT" | timeout $TIMEOUT_PERIOD time mysqlsh --sql --json --uri $DBUSER@$DBHOST:$PORT -p$DBPWD --database=$DBDATABASE >> modeventcontent.json || exit 1

    jq 'select(.warning | not)' modeventcontent.json >> modeventcontent1.json

    rm modeventcontent.json

    jq 'walk(if type == "number" then (. * 100 | round / 100) else . end)' modeventcontent1.json > modeventcontent2.json

    rm modeventcontent1.json

    jq .rows[] modeventcontent2.json  >> modeventcontentrows.json

    rm modeventcontent2.json

    cat modeventcontentrows.json | jq -c '.' >> modeventcontent_ndnewjson.json

    rm modeventcontentrows.json


    bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.modeventcontent_synch modeventcontent_ndnewjson.json || exit 1

    # exit

    rm modeventcontent_ndnewjson.json


    OFFSET=$(($OFFSET + $LIMIT))

    if [[ $records < $LIMIT ]]; then
      echo "No more records to fetch. Exiting loop."
      break
    fi
  done

fi

bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
"with mect as (select *,row_number() over(partition by mec_id order by last_modified_at desc ) as rn from prio_test.modeventcontent_synch), mecl as (select *,row_number() over(partition by mec_id order by last_modified_at desc ) as rn from prio_olap.modeventcontent), mectrn as (select * from mect where rn = 1), meclrn as (select * from mecl where rn = 1), final as (select mectrn.*, meclrn.mec_id as ids from mectrn left join meclrn on mectrn.mec_id = meclrn.mec_id and (mectrn.last_modified_at = meclrn.last_modified_at or mectrn.last_modified_at < meclrn.last_modified_at)) select mec_id, last_modified_at from final where ids is NULL" > mismatch.json

source update_commission_MEC.sh