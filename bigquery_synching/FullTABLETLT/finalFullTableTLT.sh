#!/bin/bash

echo "Final Full Table TLT Script is Running..........."

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=70

echo "-------------Script Starting So removing all Json Files-----------"
rm -rf *.json

gcloud config set project prioticket-reporting

UploadData=$1
DATABSETYPE=$2
LIMIT=25000
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

  bq query --use_legacy_sql=False --format=prettyjson \
  "delete FROM prioticket-reporting.prio_test.template_level_tickets_synch where 1=1"


  while :; do

    records=$(timeout $TIMEOUT_PERIOD time mysql -h $DBHOST --user=$DBUSER --port=$PORT --password=$DBPWD $DBDATABASE -N -e "select count(*) from (select * from template_level_tickets where deleted = '0' limit $OFFSET, $LIMIT) as base;") || exit 1

    echo "$records"

    echo "limit $OFFSET, $LIMIT"

    echo "select * from template_level_tickets where deleted = '0' limit $OFFSET, $LIMIT" | timeout $TIMEOUT_PERIOD time mysqlsh --sql --json --uri $DBUSER@$DBHOST:$PORT -p$DBPWD --database=$DBDATABASE >> template_level_tickets.json || exit 1

    jq 'select(.warning | not)' template_level_tickets.json >> template_level_tickets1.json

    rm template_level_tickets.json

    jq 'walk(if type == "number" then (. * 100 | round / 100) else . end)' template_level_tickets1.json > template_level_tickets2.json

    rm template_level_tickets1.json

    jq .rows[] template_level_tickets2.json  >> template_level_ticketsrows.json

    rm template_level_tickets2.json

    cat template_level_ticketsrows.json | jq -c '.' >> template_level_tickets_ndnewjson.json

    rm template_level_ticketsrows.json


    bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.template_level_tickets_synch template_level_tickets_ndnewjson.json || exit 1

    # exit

    rm template_level_tickets_ndnewjson.json


    OFFSET=$(($OFFSET + $LIMIT))

    if [[ $records < $LIMIT ]]; then
      echo "No more records to fetch. Exiting loop."
      break
    fi
  done

fi

bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
"with tltt as (select *,row_number() over(partition by template_level_tickets_id order by last_modified_at desc ) as rn from prio_test.template_level_tickets), tltl as (select *,row_number() over(partition by template_level_tickets_id order by last_modified_at desc ) as rn from prio_olap.template_level_tickets), tlttrn as (select * from tltt where rn = 1), tltlrn as (select * from tltl where rn = 1), final as (select tlttrn.*, tltlrn.template_level_tickets_id as ids from tlttrn left join tltlrn on tlttrn.template_level_tickets_id = tltlrn.template_level_tickets_id and (tlttrn.last_modified_at = tltlrn.last_modified_at or tlttrn.last_modified_at < tltlrn.last_modified_at)) select template_level_tickets_id, template_id, ticket_id, is_pos_list, is_suspended, created_at, market_merchant_id, content_description_setting, last_modified_at, catalog_id, merchant_admin_id, publish_catalog, product_verify_status, deleted from final where ids is NULL" > mismatch.json


source update_commission_TLT.sh