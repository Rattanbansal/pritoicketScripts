#!/bin/bash

rm -rf *.json
DBHOST="10.10.10.19"
DBUSER="pip"
DBPWD="pip2024##"
DBDATABASE="priopassdb"

echo "select * from channel_level_commission where deleted = '0' and channel_level_commission_id = '6619' limit 0, 1" \
| time mysqlsh --sql --json --uri $DBUSER@$DBHOST -p$DBPWD --database=$DBDATABASE > "$offset"_primarypt.json

jq 'walk(if type == "number" then (. * 100 | round / 100) else . end)' "$offset"_primarypt.json > "$offset"_valid_primarypt.json
