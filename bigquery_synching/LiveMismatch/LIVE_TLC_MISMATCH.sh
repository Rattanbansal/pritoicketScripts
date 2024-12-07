#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=40

rm -f final_mismatch_TLC.json

gcloud config set project prioticket-reporting
# bq query --use_legacy_sql=False --format=prettyjson \
# "delete FROM prioticket-reporting.prio_test.ticket_level_mismatch where 1=1"

maxLoopLimit=500
limit=50000
offset=0
i=1
noOfdays=$2

SELECTCOLUMNS="ticket_level_commission_id, ticket_id, ticketpriceschedule_id, last_modified_at"
previous_date=$(date -d "$noOfdays days ago" +"%Y-%m-%d 00:00:01")

echo "$previous_date" >> rattantlc.txt

# DBHOST="10.10.10.19"
# DBUSER="pip"
# DBPWD="pip2024##"
# DBDATABASE="priopassdb"
UploadData=$1
DATABSETYPE=$3

# Check if the required arguments are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Error: All arguments are required."
    echo "Usage: $0 UploadData NoOfDays datasetType"
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



    while [ $i -le $maxLoopLimit ]

    do

    RecordCount=$(timeout $TIMEOUT_PERIOD time mysql -h $DBHOST --user=$DBUSER --port=$PORT --password=$DBPWD $DBDATABASE -N -e "select count(*) from (select * from ticket_level_commission where deleted = '0' and last_modified_at > '$previous_date' limit $offset, $limit) as base;") || exit 1

    echo $RecordCount
            
        if [ $RecordCount -le 0 ];
            
        then
        echo "No record found from database offset : $offset and limit : $limit"

        break

        fi

    echo "Record from database Found offset : $offset and limit : $limit"


    echo "select $SELECTCOLUMNS from ticket_level_commission where deleted = '0' and last_modified_at > '$previous_date' limit $offset, $limit" | timeout $TIMEOUT_PERIOD time mysqlsh --sql --json --uri $DBUSER@$DBHOST:$PORT -p$DBPWD --database=$DBDATABASE >> "$offset"_primarypt.json || exit 1

    jq 'select(.warning | not)' "$offset"_primarypt.json >> "$offset"_primarypt1.json

    jq 'walk(if type == "number" then (. * 100 | round / 100) else . end)' "$offset"_primarypt1.json > "$offset"_primarypt2.json

    jq .rows[] "$offset"_primarypt2.json  >> "$offset"_primaryptrows.json

    cat "$offset"_primaryptrows.json | jq -c '.' >> "$offset"_ndnewjson.json

    bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.ticket_level_mismatch "$offset"_ndnewjson.json


    sleep 5;
    offset=$((offset+$limit))
    i=$((i+1))

    rm -rf *_primarypt.json  *_primarypt1.json *_primarypt2.json *_primaryptrows.json *_ndnewjson.json

    done

else


    bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
    "with tlc1 as (select *,row_number() over(partition by ticket_level_commission_id order by last_modified_at desc ) as rn from prioticket-reporting.prio_test.ticket_level_mismatch), tlc as (select * from tlc1 where rn=1 and last_modified_at > TIMESTAMP(CONCAT(CAST(DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL $noOfdays DAY)) AS STRING), ' 00:00:00')) AND last_modified_at <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 45 MINUTE)), clc1 as (select *,row_number() over(partition by ticket_level_commission_id order by last_modified_at desc ) as rn from prioticket-reporting.prio_olap.ticket_level_commission), clc as (select * from clc1 where rn=1 and last_modified_at > TIMESTAMP(CONCAT(CAST(DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL $noOfdays DAY)) AS STRING), ' 00:00:00')) AND last_modified_at <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 45 MINUTE)), base as (SELECT tlc.*, clc.ticket_level_commission_id as id FROM tlc left join  clc on tlc.ticket_level_commission_id = clc.ticket_level_commission_id and tlc.ticket_id = clc.ticket_id and tlc.ticketpriceschedule_id = clc.ticketpriceschedule_id and (tlc.last_modified_at = clc.last_modified_at or tlc.last_modified_at <= clc.last_modified_at)) select * from base where id is NULL" > final_mismatch_TLC.json || exit 1

fi


bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
"with tlc1 as (select *,row_number() over(partition by ticket_level_commission_id order by last_modified_at desc ) as rn from prioticket-reporting.prio_test.ticket_level_mismatch), tlc as (select * from tlc1 where rn=1 and last_modified_at > TIMESTAMP(CONCAT(CAST(DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL $noOfdays DAY)) AS STRING), ' 00:00:00')) AND last_modified_at <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 45 MINUTE)), clc1 as (select *,row_number() over(partition by ticket_level_commission_id order by last_modified_at desc ) as rn from prioticket-reporting.prio_olap.ticket_level_commission), clc as (select * from clc1 where rn=1 and last_modified_at > TIMESTAMP(CONCAT(CAST(DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL $noOfdays DAY)) AS STRING), ' 00:00:00')) AND last_modified_at <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 45 MINUTE)), base as (SELECT tlc.*, clc.ticket_level_commission_id as id FROM tlc left join  clc on tlc.ticket_level_commission_id = clc.ticket_level_commission_id and tlc.ticket_id = clc.ticket_id and tlc.ticketpriceschedule_id = clc.ticketpriceschedule_id and (tlc.last_modified_at = clc.last_modified_at or tlc.last_modified_at <= clc.last_modified_at)) select * from base where id is NULL" > final_mismatch_TLC.json || exit 1

source update_commission_TLC.sh