#!/bin/bash

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8


rm -rf *.json

gcloud config set project prioticket-reporting
bq query --use_legacy_sql=False --format=prettyjson \
"delete FROM prioticket-reporting.prio_test.channel_level_mismatch where 1=1"

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

    echo "<<<<<<<<<<<<-------------Loop for Hotel ID: Started----------------->>>>>>>"

    while [ $i -le $maxLoopLimit ]

    do

    data=$(mysql -h $DBHOST --user=$DBUSER --password=$DBPWD $DBDATABASE -N -e "select count(*) from (select * from channel_level_commission where deleted = '0' limit $offset, $limit) as base;")
    
    
    echo $data
            
       if [ $data -le 0 ];
           
        then
        echo "No record found from database using user id: $user and offset : $offset and limit : $limit" #>> backeup.txt

        break

        fi
    
    echo "Record from database Found using user id: $user and offset : $offset and limit : $limit" #>> inserted_data.txt


    echo "select channel_level_commission_id, ticket_id, ticketpriceschedule_id, last_modified_at from channel_level_commission where deleted = '0' limit $offset, $limit" | time mysqlsh --sql --json --uri $DBUSER@$DBHOST -p$DBPWD --database=$DBDATABASE >> "$offset"_primarypt.json

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

    bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.channel_level_mismatch $FILE


    done


    sleep 15;

fi

# gcloud config set project prioticket-reporting-test
bq query --use_legacy_sql=False --format=prettyjson \
"select count(*) FROM prioticket-reporting.prio_test.channel_level_mismatch"

bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
"with base as (SELECT tlc.*, clc.channel_level_commission_id as id FROM prioticket-reporting.prio_test.channel_level_mismatch tlc left join prioticket-reporting.prio_olap.channel_level_commission clc on tlc.channel_level_commission_id = clc.channel_level_commission_id and tlc.ticket_id = clc.ticket_id and tlc.ticketpriceschedule_id = clc.ticketpriceschedule_id and tlc.last_modified_at = clc.last_modified_at) select * from base where id is NULL" > final_mismatch.csv

mysql -h 10.10.10.19 -u pip -p'pip2024##' priopassdb -e "select count(*) from channel_level_commission where deleted = '0'"

rm -rf *.json