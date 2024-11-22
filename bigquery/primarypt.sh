#!/bin/bash

# rm -rf *.json

gcloud config set project prioticket-reporting-test
bq query --use_legacy_sql=False --format=prettyjson \
"delete FROM prioticket-reporting-test.prio_test.pri_prepaid_extra_options where 1=1"

# echo "select * from prepaid_tickets" | time mysqlsh --sql --json --uri admin@10.10.10.19 -p'petscan@123!' --database=dbtestpri >> primarypt.json

# jq .rows[] primarypt.json  >> primaryptrows.json

# cat primaryptrows.json | jq -c '.' >> ndnewjson.json

# gcloud config set project prioticket-reporting-test
# bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.test22_prepaid ndnewjson.json


# gcloud config set project prioticket-reporting-test
# bq query --use_legacy_sql=False --format=prettyjson \
# "select count(*) FROM prioticket-reporting-test.prio_test.test22_prepaid"

# mysql -h 10.10.10.19 -u admin -p'petscan@123!' dbtestpri -e "select count(*) from prepaid_tickets"

maxLoopLimit=1000
limit=100000
offset=0
i=1

echo "<<<<<<<<<<<<-------------Loop for Hotel ID: Started----------------->>>>>>>"

    while [ $i -le $maxLoopLimit ]

    do

    data=$(mysql -h 10.10.10.19 --user=admin --password=petscan@123! dbtestpri -N -e "select count(*) from (select * from prepaid_extra_options limit $offset, $limit) as base;")
    
    
    echo $data
            
       if [ $data -le 0 ];
           
        then
        echo "No record found from database using user id: $user and offset : $offset and limit : $limit" #>> backeup.txt

        break

        fi
    
    echo "Record from database Found using user id: $user and offset : $offset and limit : $limit" #>> inserted_data.txt


    rm -rf *.json

    echo "select * from prepaid_extra_options limit $offset, $limit" | time mysqlsh --sql --json --uri admin@10.10.10.19 -p'petscan@123!' --database=dbtestpri >> primarypt.json

    jq .rows[] primarypt.json  >> primaryptrows.json

    cat primaryptrows.json | jq -c '.' >> ndnewjson.json

    gcloud config set project prioticket-reporting-test
    bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.pri_prepaid_extra_options ndnewjson.json

    sleep 1;
    offset=$((offset+$limit))
    i=$((i+1))

    

    done

gcloud config set project prioticket-reporting-test
bq query --use_legacy_sql=False --format=prettyjson \
"select count(*) FROM prioticket-reporting-test.prio_test.pri_prepaid_extra_options"

mysql -h 10.10.10.19 -u admin -p'petscan@123!' dbtestpri -e "select count(*) from prepaid_extra_options"