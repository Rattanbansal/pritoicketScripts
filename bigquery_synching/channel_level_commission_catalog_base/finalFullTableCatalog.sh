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

catalog_id_bq=$(bq query --use_legacy_sql=False --max_rows=100000 --format=csv \
"select distinct catalog_id FROM prioticket-reporting.prio_test.channel_level_commission_synch where 1=1 and channel_level_commission_id != 2 and catalog_id > 0 and channel_id = 0" | tail -n +2) || exit 1


echo "Entered Under Conditional Statement"
# Check if catalog_id_bq is empty
if [ -z "$catalog_id_bq" ]; then
  echo "No catalog_ids retrieved from BigQuery. Proceeding without exclusions."
  catalog_exclude_clause=""
else
  # Convert BigQuery output to a comma-separated string
  catalog_exclude_ids=$(echo "$catalog_id_bq" | tr '\n' ',' | sed 's/,$//')
  echo "Excluding channel_ids: $catalog_exclude_ids"
  catalog_exclude_clause="AND channel_id NOT IN ($catalog_exclude_ids)"
fi

echo "--------Started Mysql Query-----------"

DBHOST="10.10.10.19"
DBUSER="pip"
DBPWD="pip2024##"
DBDATABASE="priopassdb"


echo "select distinct catalog_id from channel_level_commission where deleted = '0' and catalog_id > '0' and channel_id = '0' $catalog_exclude_clause;"

echo "--------------Started Running Mysql Query----------------"
catalog_ticket_ids=$(mysql -h $DBHOST --user=$DBUSER --password=$DBPWD $DBDATABASE -N -e "select distinct catalog_id from channel_level_commission where last_modified_at > '2024-11-14 00:00:01' and deleted = '0' and catalog_id > '0' and channel_id = '0' $catalog_exclude_clause;") || exit 1

echo $catalog_ticket_ids

echo "------------Loop on channed If going to start----------"
for catalog_ticket_id in ${catalog_ticket_ids}

do

 
    echo $catalog_ticket_id
       
    echo "Record from database Found using ticket_id id: $catalog_ticket_id" #>> inserted_data.txt


    echo "select * from channel_level_commission where last_modified_at > '2024-11-14 00:00:01' and deleted = '0' and catalog_id = '$catalog_ticket_id'" | time mysqlsh --sql --json --uri $DBUSER@$DBHOST -p$DBPWD --database=$DBDATABASE >> "$catalog_ticket_id"_primarypt.json || exit 1

    jq 'select(.warning | not)' "$catalog_ticket_id"_primarypt.json >> "$catalog_ticket_id"_primarypt1.json

    rm "$catalog_ticket_id"_primarypt.json

    jq 'walk(if type == "number" then (. * 100 | round / 100) else . end)' "$catalog_ticket_id"_primarypt1.json > "$catalog_ticket_id"_primarypt2.json

    rm "$catalog_ticket_id"_primarypt1.json

    jq .rows[] "$catalog_ticket_id"_primarypt2.json  >> "$catalog_ticket_id"_primaryptrows.json

    rm "$catalog_ticket_id"_primarypt2.json

    cat "$catalog_ticket_id"_primaryptrows.json | jq -c '.' >> "$catalog_ticket_id"_ndnewjson.json

    rm "$catalog_ticket_id"_primaryptrows.json


    bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.channel_level_commission_synch "$catalog_ticket_id"_ndnewjson.json || exit 1

    # exit

    rm "$catalog_ticket_id"_ndnewjson.json

    sleep $((RANDOM % 21 + 40))

    done

    # # exit
    # sleep 15;

    # # gcloud config set project prioticket-reporting-test
    # bq query --use_legacy_sql=False --format=prettyjson \
    # "select count(*) FROM prioticket-reporting.prio_test.channel_level_commission_synch"

    # bq query --use_legacy_sql=False --format=prettyjson \
    # "with base as (SELECT tlc.*, clc.channel_level_commission_id as id FROM prioticket-reporting.prio_test.channel_level_commission_synch tlc left join prioticket-reporting.prio_olap.channel_level_commission clc on tlc.channel_level_commission_id = clc.channel_level_commission_id and tlc.ticket_id = clc.ticket_id and tlc.ticketpriceschedule_id = clc.ticketpriceschedule_id and (tlc.last_modified_at = clc.last_modified_at or tlc.last_modified_at <= clc.last_modified_at)) select * from base where id is NULL" > final_mismatch.csv

    # mysql -h 10.10.10.19 -u pip -p'pip2024##' priopassdb -e "select count(*) from channel_level_commission"

    # rm -rf *.json

    # SELECT catalog_id,count(*) FROM `channel_level_commission` where last_modified_at > '2024-11-14 00:00:01' and channel_id = '0' and catalog_id > '0' and catalog_id = 140267947063130 and deleted = '0' group by catalog_id order by count(*) desc;

#     SELECT
#   catalog_id,
#   COUNT(*)
# FROM
#   `prioticket-reporting.prio_test.channel_level_commission_synch`
# WHERE
#   last_modified_at > '2024-11-14 00:00:01'
#   AND channel_id = 0
#   AND catalog_id > 0
#   AND deleted = 0
# GROUP BY
#   catalog_id
# ORDER BY
#   COUNT(*) DESC;

# 2669879