#!/bin/bash

echo "Final Full Table QR COdees Script is Running..........."

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
  "delete FROM prioticket-reporting.prio_test.qr_codes_synch where 1=1"


  while :; do

    records=$(timeout $TIMEOUT_PERIOD time mysql -h $DBHOST --user=$DBUSER --port=$PORT --password=$DBPWD $DBDATABASE -N -e "select count(*) from (select * from qr_codes limit $OFFSET, $LIMIT) as base;") || exit 1

    echo "$records"

    echo "limit $OFFSET, $LIMIT"

    echo "select * from qr_codes limit $OFFSET, $LIMIT" | timeout $TIMEOUT_PERIOD time mysqlsh --sql --json --uri $DBUSER@$DBHOST:$PORT -p$DBPWD --database=$DBDATABASE >> qr_codes.json || exit 1

    jq 'select(.warning | not)' qr_codes.json >> qr_codes1.json

    rm qr_codes.json

    jq 'walk(if type == "number" then (. * 100 | round / 100) else . end)' qr_codes1.json > qr_codes2.json

    rm qr_codes1.json

    jq .rows[] qr_codes2.json  >> qr_codesrows.json

    rm qr_codes2.json

    cat qr_codesrows.json | jq -c '.' >> qr_codes_ndnewjson.json

    rm qr_codesrows.json


    bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.qr_codes_synch qr_codes_ndnewjson.json || exit 1

    # exit

    rm qr_codes_ndnewjson.json


    OFFSET=$(($OFFSET + $LIMIT))

    if [[ $records < $LIMIT ]]; then
      echo "No more records to fetch. Exiting loop."
      break
    fi
  done

fi

bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
"with qr_codest as (select *,row_number() over(partition by cod_id order by last_modified_at desc ) as rn from prio_test.qr_codes_synch), qr_codesl as (select *,row_number() over(partition by cod_id order by last_modified_at desc ) as rn from prio_olap.qr_codes), qr_codestrn as (select * from qr_codest where rn = 1), qr_codeslrn as (select * from qr_codesl where rn = 1), final as (select qr_codestrn.*, qr_codeslrn.cod_id as ids from qr_codestrn left join qr_codeslrn on qr_codestrn.cod_id = qr_codeslrn.cod_id and (qr_codestrn.last_modified_at = qr_codeslrn.last_modified_at or qr_codestrn.last_modified_at < qr_codeslrn.last_modified_at)) select cod_id, last_modified_at from final where ids is NULL" > mismatch.json

source update_commission_QRCODES.sh

echo "<<<<<<<<<<<<<<Final Full Table QR Codes Script is Ended>>>>>>>>>>>>>>>>"