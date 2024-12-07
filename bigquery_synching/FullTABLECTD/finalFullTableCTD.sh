#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=40

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

  echo "-----------Started Deleting all records for bigquery--------"
  bq query --use_legacy_sql=False --format=prettyjson \
  "delete FROM prioticket-reporting.prio_test.cluster_tickets_detail_synch where 1=1"


  while :; do

    records=$(timeout $TIMEOUT_PERIOD time mysql -h $DBHOST --user=$DBUSER --port=$PORT --password=$DBPWD $DBDATABASE -N -e "select count(*) from (select * from cluster_tickets_detail limit $OFFSET, $LIMIT) as base;") || exit 1

    echo "$records"

    echo "limit $OFFSET, $LIMIT"

    echo "select * from cluster_tickets_detail limit $OFFSET, $LIMIT" | timeout $TIMEOUT_PERIOD time mysqlsh --sql --json --uri $DBUSER@$DBHOST:$PORT -p$DBPWD --database=$DBDATABASE >> cluster_tickets_detail.json || exit 1

    jq 'select(.warning | not)' cluster_tickets_detail.json >> cluster_tickets_detail1.json

    rm cluster_tickets_detail.json

    jq 'walk(if type == "number" then (. * 100 | round / 100) else . end)' cluster_tickets_detail1.json > cluster_tickets_detail2.json

    rm cluster_tickets_detail1.json

    jq .rows[] cluster_tickets_detail2.json  >> cluster_tickets_detailrows.json

    rm cluster_tickets_detail2.json

    cat cluster_tickets_detailrows.json | jq -c '.' >> cluster_tickets_detail_ndnewjson.json

    rm cluster_tickets_detailrows.json


    bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.cluster_tickets_detail_synch cluster_tickets_detail_ndnewjson.json || exit 1

    # exit

    rm cluster_tickets_detail_ndnewjson.json


    OFFSET=$(($OFFSET + $LIMIT))

    if [[ $records < $LIMIT ]]; then
      echo "No more records to fetch. Exiting loop."
      break
    fi
  done

fi

bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
"with cluster_tickets_detailt as (select *,row_number() over(partition by cluster_row_id order by last_modified_at desc ) as rn from prio_test.cluster_tickets_detail_synch), cluster_tickets_detaill as (select *,row_number() over(partition by cluster_row_id order by last_modified_at desc ) as rn from prio_olap.cluster_tickets_detail), cluster_tickets_detailtrn as (select * from cluster_tickets_detailt where rn = 1), cluster_tickets_detaillrn as (select * from cluster_tickets_detaill where rn = 1), final as (select cluster_tickets_detailtrn.*, cluster_tickets_detaillrn.cluster_row_id as ids from cluster_tickets_detailtrn left join cluster_tickets_detaillrn on cluster_tickets_detailtrn.cluster_row_id = cluster_tickets_detaillrn.cluster_row_id and (cluster_tickets_detailtrn.last_modified_at = cluster_tickets_detaillrn.last_modified_at or cluster_tickets_detailtrn.last_modified_at < cluster_tickets_detaillrn.last_modified_at)) select cluster_row_id, last_modified_at from final where ids is NULL" > mismatch.json

source update_commission_CTD.sh