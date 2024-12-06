#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

echo "-------------Script Starting So removing all Json Files-----------"
rm -rf *.json

echo "-----------Started Deleting all records for bigquery--------"
gcloud config set project prioticket-reporting
bq query --use_legacy_sql=False --format=prettyjson \
"delete FROM prioticket-reporting.prio_test.own_account_commissions_synch where 1=1"


DBHOST='163.47.214.30'
DBUSER='datalook'
DBPWD='datalook2024$$'
DBDATABASE='priopassdb'
PORT="3307"
# DBHOST='production-primary-db-node-cluster.cluster-ck6w2al7sgpk.eu-west-1.rds.amazonaws.com'
# DBUSER='pipeuser'
# DBPWD='d4fb46eccNRAL'
# DBDATABASE='priopassdb'
# PORT="3306"
UploadData=$1

LIMIT=100000
OFFSET=0

if [[ $UploadData == 2 ]]; then

  while :; do

    records=$(mysql -h $DBHOST --user=$DBUSER --port=$PORT --password=$DBPWD $DBDATABASE -N -e "select count(*) from (select * from own_account_commissions where deleted = '0' limit $OFFSET, $LIMIT) as base;") || exit 1

    echo "$records"

    echo "limit $OFFSET, $LIMIT"

    echo "select * from own_account_commissions where deleted = '0' limit $OFFSET, $LIMIT" | time mysqlsh --sql --json --uri $DBUSER@$DBHOST:$PORT -p$DBPWD --database=$DBDATABASE >> own_account_commissions.json || exit 1

    jq 'select(.warning | not)' own_account_commissions.json >> own_account_commissions1.json

    rm own_account_commissions.json

    jq 'walk(if type == "number" then (. * 100 | round / 100) else . end)' own_account_commissions1.json > own_account_commissions2.json

    rm own_account_commissions1.json

    jq .rows[] own_account_commissions2.json  >> own_account_commissionsrows.json

    rm own_account_commissions2.json

    cat own_account_commissionsrows.json | jq -c '.' >> own_account_commissions_ndnewjson.json

    rm own_account_commissionsrows.json


    bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.own_account_commissions_synch own_account_commissions_ndnewjson.json || exit 1

    # exit

    rm own_account_commissions_ndnewjson.json


    OFFSET=$(($OFFSET + $LIMIT))

    if [[ $records < $LIMIT ]]; then
      echo "No more records to fetch. Exiting loop."
      break
    fi
  done

fi

  echo "Rattan"

  bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
  "with oact as (select *,row_number() over(partition by id order by last_modified_at desc ) as rn from prio_test.own_account_commissions), oacl as (select *,row_number() over(partition by id order by last_modified_at desc ) as rn from prio_olap.own_account_commissions), oactrn as (select * from oact where rn = 1), oaclrn as (select * from oacl where rn = 1), final as (select oactrn.*, oaclrn.id as ids from oactrn left join oaclrn on oactrn.id = oaclrn.id and (oactrn.last_modified_at = oaclrn.last_modified_at or oactrn.last_modified_at < oaclrn.last_modified_at)) select *except(rn,ids) from final where ids is NULL" > mismatch.json