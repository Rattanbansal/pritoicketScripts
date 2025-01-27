#!/bin/bash


# ./foundCLCDataMismatch.sh <upload> <bqtablename> <mysqltable> <primarykey> <nosofdays>

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
bqtablename=$2
mysqltablename=$3
primarykey=$4
nosofdays=$5

rm -rf *.json


maxLoopLimit=5000
limit=250000
offset=0
i=1
DBHOST="10.10.10.19"
DBUSER="pip"
DBPWD="pip2024##"
DBDATABASE="priopassdb"
Uploaddata=$1

if [[ "$Uploaddata" == "upload" ]]; then

    gcloud config set project prioticket-reporting
    bq query --use_legacy_sql=False --format=prettyjson \
    "delete FROM prioticket-reporting.prio_test.$bqtablename where 1=1"

    echo "<<<<<<<<<<<<-------------Loop for Hotel ID: Started----------------->>>>>>>"

    while [ $i -le $maxLoopLimit ]

    do

    data=$(mysql -h $DBHOST --user=$DBUSER --password=$DBPWD $DBDATABASE -N -e "select count(*) from (select * from $mysqltablename where deleted = '0' limit $offset, $limit) as base;")
    
    
    echo $data
            
       if [ $data -le 0 ];
           
        then
        echo "No record found from database using user id: $user and offset : $offset and limit : $limit" #>> backeup.txt

        break

        fi
    
    echo "Record from database Found using user id: $user and offset : $offset and limit : $limit" #>> inserted_data.txt


    echo "select $primarykey, ticket_id, ticketpriceschedule_id, last_modified_at from $mysqltablename where deleted = '0' limit $offset, $limit" | time mysqlsh --sql --json --uri $DBUSER@$DBHOST -p$DBPWD --database=$DBDATABASE >> "$offset"_primarypt.json

    jq 'select(.warning | not)' "$offset"_primarypt.json >> "$offset"_primarypt1.json

    jq 'walk(if type == "number" then (. * 100 | round / 100) else . end)' "$offset"_primarypt1.json > "$offset"_primarypt2.json

    jq .rows[] "$offset"_primarypt2.json  >> "$offset"_primaryptrows.json

    cat "$offset"_primaryptrows.json | jq -c '.' >> "$offset"_ndnewjson.json


    sleep 1;
    offset=$((offset+$limit))
    i=$((i+1))


    done

    files=$(ls *_ndnewjson.json)
    commandVar="'echo command started'";
    for FILE in ${files}; 
    do 
    echo $FILE; 

    bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.$bqtablename $FILE


    done
    sleep 15;
fi

# gcloud config set project prioticket-reporting-test
bigquerycount=$(bq query --use_legacy_sql=False --format=prettyjson \
"select count(*) as pcs FROM prioticket-reporting.prio_test.$bqtablename" | jq -r '.[] | .pcs')

mysqlcount=$(mysql -h 10.10.10.19 -u pip -p'pip2024##' priopassdb -sN -e "select count(*) as pcs from $mysqltablename where deleted = '0'")

if [[ "$bigquerycount" == "$mysqlcount" ]]; then

    echo "bigquery Count:$bigquerycount"
    echo "Mysql Count:$mysqlcount"

    echo "Count Matched Proceed with next step"

    bq query --use_legacy_sql=False --max_rows=10000000 --format=prettyjson \
    "select count(distinct($primarykey)) as ids from prio_olap.$mysqltablename where $primarykey not in (select distinct $primarykey from prio_test.$bqtablename) and last_modified_at < TIMESTAMP(CONCAT(CAST(DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL $nosofdays DAY)) AS STRING), ' 00:00:00'))" > final_mismatch.csv

    bq query --use_legacy_sql=False --max_rows=10000000 --format=prettyjson \
    "update prio_olap.$mysqltablename set hgs_postpaid_commission_percentage = 44.44 where $primarykey in (select distinct($primarykey) from prio_olap.$mysqltablename where $primarykey not in (select distinct $primarykey from prio_test.$bqtablename) and last_modified_at < TIMESTAMP(CONCAT(CAST(DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL $nosofdays DAY)) AS STRING), ' 00:00:00')))"

    bq query --use_legacy_sql=False --max_rows=10000000 --format=prettyjson \
    "select distinct($primarykey) from prio_olap.$mysqltablename where $primarykey not in (select distinct $primarykey from prio_test.$bqtablename) and hgs_postpaid_commission_percentage != 44.44 and last_modified_at < TIMESTAMP(CONCAT(CAST(DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL $nosofdays DAY)) AS STRING), ' 00:00:00'))" > final_mismatch.json
else
    echo "Count not matched"
    echo "bigquery Count:$bigquerycount"
    echo "Mysql Count:$mysqlcount"
    exit 1
fi

rm -f *.json