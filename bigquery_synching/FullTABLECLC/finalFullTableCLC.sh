#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=40

echo "-------------Script Starting So removing all Json Files-----------"
rm -rf *.json

gcloud config set project prioticket-reporting

UploadData=$1
noofdays=$2
DATABSETYPE=$3
LIMIT=25000
OFFSET=0

# Check if the required arguments are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Error: All arguments are required."
    echo "Usage: $0 UploadData noofdays datasetType"
    exit 1
fi

previous_date=$(date -d "$noofdays days ago" +"%Y-%m-%d 00:00:01")
echo "$noofdays"
echo "$previous_date"
exit 1

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
  # bq query --use_legacy_sql=False --format=prettyjson \
  # "delete FROM prioticket-reporting.prio_test.channel_level_commission_synch where 1=1"



  while :; do

    records=$(mysql -h $DBHOST --user=$DBUSER --port=$PORT --password=$DBPWD $DBDATABASE -N -e "select count(*) from (select * from channel_level_commission where deleted = '0' and last_modified_at > '$previous_date' limit $OFFSET, $LIMIT) as base;") || exit 1

    echo "$records"

    echo "limit $OFFSET, $LIMIT"

    echo "select * from channel_level_commission where deleted = '0' and last_modified_at > '$previous_date' limit $OFFSET, $LIMIT" | time mysqlsh --sql --json --uri $DBUSER@$DBHOST:$PORT -p$DBPWD --database=$DBDATABASE >> channel_level_commission_primarypt.json || exit 1

    jq 'select(.warning | not)' channel_level_commission_primarypt.json >> channel_level_commission_primarypt1.json

    rm channel_level_commission_primarypt.json

    jq 'walk(if type == "number" then (. * 100 | round / 100) else . end)' channel_level_commission_primarypt1.json > channel_level_commission_primarypt2.json

    rm channel_level_commission_primarypt1.json

    jq .rows[] channel_level_commission_primarypt2.json  >> channel_level_commission_primaryptrows.json

    rm channel_level_commission_primarypt2.json

    cat channel_level_commission_primaryptrows.json | jq -c '.' >> channel_level_commission_ndnewjson.json

    rm channel_level_commission_primaryptrows.json


    bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.channel_level_commission_synch channel_level_commission_ndnewjson.json || exit 1

    # exit

    rm channel_level_commission_ndnewjson.json


    OFFSET=$(($OFFSET + $LIMIT))

    if [[ $records < $LIMIT ]]; then
      echo "No more records to fetch. Exiting loop."
      break
    fi
  done

fi

bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
"with tlc1 as (select *,row_number() over(partition by channel_level_commission_id order by last_modified_at desc ) as rn from prioticket-reporting.prio_test.channel_level_mismatch), tlc as (select * from tlc1 where rn=1 and last_modified_at > TIMESTAMP(CONCAT(CAST(DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL $noofdays DAY)) AS STRING), ' 00:00:00')) AND last_modified_at <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 45 MINUTE)), clc1 as (select *,row_number() over(partition by channel_level_commission_id order by last_modified_at desc ) as rn from prioticket-reporting.prio_olap.channel_level_commission), clc as (select * from clc1 where rn=1 and last_modified_at > TIMESTAMP(CONCAT(CAST(DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL $noofdays DAY)) AS STRING), ' 00:00:00')) AND last_modified_at <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 45 MINUTE)), base as (SELECT tlc.*, clc.channel_level_commission_id as id FROM tlc left join  clc on tlc.channel_level_commission_id = clc.channel_level_commission_id and tlc.ticket_id = clc.ticket_id and tlc.ticketpriceschedule_id = clc.ticketpriceschedule_id and (tlc.last_modified_at = clc.last_modified_at or tlc.last_modified_at <= clc.last_modified_at)) select * from base where id is NULL" > mismatch.json || exit 1