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
"delete FROM prioticket-reporting.prio_test.ticket_level_commission_synch where 1=1"


DBHOST='163.47.214.30'
DBUSER='datalook'
DBPWD='datalook2024$$'
DBDATABASE='priopassdb'
PORT="3307"

LIMIT=150000
OFFSET=0


while :; do

  records=$(mysql -h $DBHOST --user=$DBUSER --port=$PORT --password=$DBPWD $DBDATABASE -N -e "select count(*) from (select * from ticket_level_commission where deleted = '0' limit $OFFSET, $LIMIT) as base;") || exit 1

  echo "$records"

  echo "select * from ticket_level_commission where deleted = '0' limit $OFFSET, $LIMIT" | time mysqlsh --sql --json --uri $DBUSER@$DBHOST:$PORT -p$DBPWD --database=$DBDATABASE >> ticket_level_commission_primarypt.json || exit 1

  jq 'select(.warning | not)' ticket_level_commission_primarypt.json >> ticket_level_commission_primarypt1.json

  rm ticket_level_commission_primarypt.json

  jq 'walk(if type == "number" then (. * 100 | round / 100) else . end)' ticket_level_commission_primarypt1.json > ticket_level_commission_primarypt2.json

  rm ticket_level_commission_primarypt1.json

  jq .rows[] ticket_level_commission_primarypt2.json  >> ticket_level_commission_primaryptrows.json

  rm ticket_level_commission_primarypt2.json

  cat ticket_level_commission_primaryptrows.json | jq -c '.' >> ticket_level_commission_ndnewjson.json

  rm ticket_level_commission_primaryptrows.json


  bq load --source_format=NEWLINE_DELIMITED_JSON  prio_test.ticket_level_commission_synch ticket_level_commission_ndnewjson.json || exit 1

  # exit

  rm ticket_level_commission_ndnewjson.json


  OFFSET=$(($OFFSET + $LIMIT))

  if [[ $records < $LIMIT ]]; then
    echo "No more records to fetch. Exiting loop."
    break
  fi

done