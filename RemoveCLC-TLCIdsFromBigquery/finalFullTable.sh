#!/bin/bash


set -e  # Exit immediately if any command exits with a non-zero status

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

echo "-------------Script Starting So removing all Json Files-----------"
rm -rf *.json

echo "-----------Started Deleting all records for bigquery--------"
gcloud config set project prioticket-reporting
# bq query --use_legacy_sql=False --format=prettyjson \
# "delete FROM prioticket-reporting.prio_test.channel_level_commission_synch where 1=1"

echo "------Started Fetching Channel Id from Bigquery--------"

channel_id_bq=$(bq query --use_legacy_sql=False --max_rows=1000000 --format=csv \
"select distinct channel_id FROM prioticket-reporting.prio_test.channel_level_commission_synch where 1=1 and channel_level_commission_id != 2" | tail -n +2) || exit 1


echo "Entered Under Conditional Statement"
# Check if channel_id_bq is empty
if [ -z "$channel_id_bq" ]; then
  echo "No channel_ids retrieved from BigQuery. Proceeding without exclusions."
  exclude_clause=""
else
  # Convert BigQuery output to a comma-separated string
  exclude_ids=$(echo "$channel_id_bq" | tr '\n' ',' | sed 's/,$//')
  echo "Excluding channel_ids: $exclude_ids"
  exclude_clause="AND channel_id NOT IN ($exclude_ids)"
fi

echo "--------Started Mysql Query-----------"

DBHOST="10.10.10.19"
DBUSER="pip"
DBPWD="pip2024##"
DBDATABASE="priopassdb"


echo "select channel_id from channel_level_commission where last_modified_at > '2024-11-14 00:00:01' and deleted = '0' and channel_id > '0' "$exclude_clause" group by channel_id order by count(*) desc;"

echo "--------------Started Running Mysql Query----------------"
ticket_ids=$(mysql -h $DBHOST --user=$DBUSER --password=$DBPWD $DBDATABASE -N -e "select channel_id from channel_level_commission where last_modified_at > '2024-11-14 00:00:01' and deleted = '0' and channel_id > '0' $exclude_clause group by channel_id order by count(*) desc;") || exit 1

echo $ticket_ids

echo "------------Loop on channed If going to start----------"
for ticket_id in ${ticket_ids}

do

 
    echo $ticket_id
       
    echo "Record from database Found using ticket_id id: $ticket_id" #>> inserted_data.txt


    echo "select * from channel_level_commission where last_modified_at > '2024-11-14 00:00:01' and deleted = '0' and channel_id = '$ticket_id'" | time mysqlsh --sql --json --uri $DBUSER@$DBHOST -p$DBPWD --database=$DBDATABASE >> "$ticket_id"_primarypt.json || exit 1

    jq 'select(.warning | not)' "$ticket_id"_primarypt.json >> "$ticket_id"_primarypt1.json

    rm "$ticket_id"_primarypt.json

    jq 'walk(if type == "number" then (. * 100 | round / 100) else . end)' "$ticket_id"_primarypt1.json > "$ticket_id"_primarypt2.json

    rm "$ticket_id"_primarypt1.json

    jq .rows[] "$ticket_id"_primarypt2.json  >> "$ticket_id"_primaryptrows.json

    rm "$ticket_id"_primarypt2.json

    cat "$ticket_id"_primaryptrows.json | jq -c '.' >> "$ticket_id"_ndnewjson.json

    rm "$ticket_id"_primaryptrows.json


    bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.channel_level_commission_synch "$ticket_id"_ndnewjson.json || exit 1

    # exit

    rm "$ticket_id"_ndnewjson.json

    done

    # # exit
    # sleep 15;

    # # gcloud config set project prioticket-reporting-test
    # bq query --use_legacy_sql=False --format=prettyjson \
    # "select count(*) FROM prioticket-reporting.prio_test.channel_level_commission_synch"

    # bq query --use_legacy_sql=False --format=prettyjson \
    # "with base as (SELECT tlc.*, clc.channel_level_commission_id as id FROM prioticket-reporting.prio_test.channel_level_commission_synch tlc left join prioticket-reporting.prio_olap.channel_level_commission clc on tlc.channel_level_commission_id = clc.channel_level_commission_id and tlc.ticket_id = clc.ticket_id and tlc.ticketpriceschedule_id = clc.ticketpriceschedule_id and tlc.last_modified_at = clc.last_modified_at) select * from base where id is NULL" > final_mismatch.csv

    # (with tlc1 as (select *,row_number() over(partition by channel_level_commission_id order by last_modified_at desc ) as rn from prioticket-reporting.prio_test.channel_level_commission_synch),tlc as (select * from tlc1 where rn=1),clc1 as (select *,row_number() over(partition by channel_level_commission_id order by last_modified_at desc ) as rn from prioticket-reporting.prio_olap.channel_level_commission),clc as (select * from clc1 where rn=1),base as (SELECT tlc.*, clc.channel_level_commission_id as id FROM tlc left join  clc on tlc.channel_level_commission_id = clc.channel_level_commission_id and tlc.ticket_id = clc.ticket_id and tlc.ticketpriceschedule_id = clc.ticketpriceschedule_id) select *except(rn,id) from base where id is NULL and channel_level_commission_id =12053939)

    # mysql -h 10.10.10.19 -u pip -p'pip2024##' priopassdb -e "select count(*) from channel_level_commission"

    # rm -rf *.json