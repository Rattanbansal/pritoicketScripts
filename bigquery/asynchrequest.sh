#!/bin/bash

rm -rf *.json

# gcloud config set project prioticket-reporting-test
# bq query --use_legacy_sql=False --format=prettyjson \
# "delete FROM prioticket-reporting-test.prio_test.pri_prepaid_extra_options where 1=1"


maxLoopLimit=2000
limit=50000
offset=0
i=1

echo "<<<<<<<<<<<<-------------Loop for Hotel ID: Started----------------->>>>>>>"

    while [ $i -le $maxLoopLimit ]

    do

    data=$(mysql -h 10.10.10.19 --user=pip --password='pip2024##' priopassdb -N -e "select count(*) from (select * from channel_level_commission limit $offset, $limit) as base;")
    
    
    echo $data
            
       if [ $data -le 0 ];
           
        then
        echo "No record found from database using user id: $user and offset : $offset and limit : $limit" #>> backeup.txt

        break

        fi
    
        echo "Record from database Found using user id: $user and offset : $offset and limit : $limit" #>> inserted_data.txt


        echo "select * from channel_level_commission limit $offset, $limit" | time mysqlsh --sql --json --uri pip@10.10.10.19 -p'pip2024##' --database=priopassdb >> "$offset"_primarypt.json

        jq .rows[] "$offset"_primarypt.json  >> "$offset"_primaryptrows.json

        cat "$offset"_primaryptrows.json | jq -c '.' >> "$offset"_ndnewjson.json


        sleep 1;
        offset=$((offset+$limit))
        i=$((i+1))

    

    done


    # files=$(ls *_ndnewjson.json)
    # commandVar="'echo command started'";
    # for FILE in ${files}; 
    # do 
    # echo $FILE; 
    # commandVar=$commandVar" 'bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.pri_prepaid_extra_options $FILE'"
    # done
    # echo $commandVar

    # #commandtorun=$(echo "parallel -j echo "'command started';"$commandVar" | sed 's/.$//') #sometime first command not run in parallel so added extra command in it

    # commandtorun=$(echo "parallel ::: $commandVar")  # another method to run parallel commands

    # gcloud config set project prioticket-reporting-test
    # eval $commandtorun

    # sleep 15;

    # gcloud config set project prioticket-reporting-test
    # bq query --use_legacy_sql=False --format=prettyjson \
    # "select count(*) FROM prioticket-reporting-test.prio_test.pri_prepaid_extra_options"

    # mysql -h 10.10.10.19 -u admin -p'petscan@123!' dbtestpri -e "select count(*) from prepaid_extra_options"

    # rm -rf *.json
