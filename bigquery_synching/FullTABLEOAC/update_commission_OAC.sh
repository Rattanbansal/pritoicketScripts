#!/bin/bash

# Path to the JSON file
JSON_FILE="mismatch.json"
rm -f UpdatequeryOAC.sql
# Check if the file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: File '$JSON_FILE' not found."
    exit 1
fi

# Batch size
BATCH_SIZE=100

# Extract channel_level_commission_id values using jq
ids=$(jq -r '.[] | .id' "$JSON_FILE")

# Convert the ids to an array
ids_array=($ids)

# Total number of ids
total_ids=${#ids_array[@]}

# Exit if total_ids is blank or zero
if [ -z "$total_ids" ] || [ "$total_ids" -eq 0 ]; then
    echo "Error: No id values found in the JSON file."
    exit 1
fi

# Process ids in batches
for (( i=0; i<$total_ids; i+=$BATCH_SIZE )); do
    # Create a batch of ids
    batch=(${ids_array[@]:$i:$BATCH_SIZE})
    # Join ids with commas
    ids_joined=$(IFS=, ; echo "${batch[*]}")
    # Construct the MySQL update query
    query="UPDATE own_account_commissions SET last_modified_at = CURRENT_TIMESTAMP WHERE id IN ($ids_joined);select ROW_COUNT();"

    echo "$query" >> UpdatequeryOAC.sql

    sleep 2
    # Execute the query
    mysql -u "$DBUSER" -h "$DBHOST" --port=$PORT -p"$DBPWD" "$DBDATABASE" -e "$query"
done
