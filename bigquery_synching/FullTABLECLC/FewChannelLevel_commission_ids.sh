#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=40
noofdays=$1

previous_date=$(date -d "$noofdays days ago" +"%Y-%m-%d 00:00:01")
echo "$noofdays"
echo "$previous_date"

echo "-------------Script Starting So removing all Json Files-----------"
rm -rf *.json

gcloud config set project prioticket-reporting



DBHOST='163.47.214.30'
DBUSER='datalook'
DBPWD='datalook2024$$'
DBDATABASE='priopassdb'
PORT="3307"


echo "select * from channel_level_commission where deleted = '0' and last_modified_at > '$previous_date' limit $OFFSET, $LIMIT" | time mysqlsh --sql --json --uri $DBUSER@$DBHOST:$PORT -p$DBPWD --database=$DBDATABASE >> $PWD/channel_level_commission_primarypt.json || exit 1

jq 'select(.warning | not)' $PWD/channel_level_commission_primarypt.json >> $PWD/channel_level_commission_primarypt1.json

rm $PWD/channel_level_commission_primarypt.json

jq 'walk(if type == "number" then (. * 100 | round / 100) else . end)' $PWD/channel_level_commission_primarypt1.json > $PWD/channel_level_commission_primarypt2.json

rm $PWD/channel_level_commission_primarypt1.json

jq .rows[] $PWD/channel_level_commission_primarypt2.json  >> $PWD/channel_level_commission_primaryptrows.json

rm $PWD/channel_level_commission_primarypt2.json

cat $PWD/channel_level_commission_primaryptrows.json | jq -c '.' >> $PWD/channel_level_commission_ndnewjson.json

rm $PWD/channel_level_commission_primaryptrows.json


bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.channel_level_commission_synch $PWD/channel_level_commission_ndnewjson.json || exit 1

# exit

rm $PWD/channel_level_commission_ndnewjson.json




bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
"with tlc1 as (select *,row_number() over(partition by channel_level_commission_id order by last_modified_at desc ) as rn from prioticket-reporting.prio_test.channel_level_commission_synch), tlc as (select * from tlc1 where rn=1 and last_modified_at > TIMESTAMP(CONCAT(CAST(DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL $noofdays DAY)) AS STRING), ' 00:00:00')) AND last_modified_at <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 45 MINUTE)), clc1 as (select *,row_number() over(partition by channel_level_commission_id order by last_modified_at desc ) as rn from prioticket-reporting.prio_olap.channel_level_commission), clc as (select * from clc1 where rn=1 and last_modified_at > TIMESTAMP(CONCAT(CAST(DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL $noofdays DAY)) AS STRING), ' 00:00:00')) AND last_modified_at <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 45 MINUTE)), base as (SELECT tlc.*, clc.channel_level_commission_id as id FROM tlc left join  clc on tlc.channel_level_commission_id = clc.channel_level_commission_id and tlc.ticket_id = clc.ticket_id and tlc.ticketpriceschedule_id = clc.ticketpriceschedule_id and (tlc.last_modified_at = clc.last_modified_at or tlc.last_modified_at <= clc.last_modified_at)) select * from base where id is NULL" > mismatch.json || exit 1

source update_commission_CLC.sh