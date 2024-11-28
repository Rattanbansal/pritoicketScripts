#!/bin/bash

# Path to the JSON file
JSON_FILE="/home/intersoft-admin/rattan/pritoicketScripts/bigquery_synching/LiveMismatch/final_mismatch_TLC.json"

# Batch size
BATCH_SIZE=50

# Extract channel_level_commission_id values using jq
ids=$(jq -r '.[] | .channel_level_commission_id' "$JSON_FILE")

# Convert the ids to an array
ids_array=($ids)

# Total number of ids
total_ids=${#ids_array[@]}

# MySQL credentials
DBHOST='163.47.214.30'
DBUSER='datalook'
DBPWD='datalook2024$$'
DBDATABASE='priopassdb'
PORT="3307"

# Process ids in batches
for (( i=0; i<$total_ids; i+=$BATCH_SIZE )); do
    # Create a batch of ids
    batch=(${ids_array[@]:$i:$BATCH_SIZE})
    # Join ids with commas
    ids_joined=$(IFS=, ; echo "${batch[*]}")
    # Construct the MySQL update query
    query="UPDATE ticket_level_commission SET last_modified_at = CURRENT_TIMESTAMP WHERE ticket_level_commission_id IN ($ids_joined);"

    echo "$query" 
    # Execute the query
    # mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "$query"
done
