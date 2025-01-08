#!/bin/bash

set -e

# Configuration
source ~/vault/vault_fetch_creds.sh
fetch_db_credentials "PrioticketLivePriomaryWritePipe"

DB_NAME="priopassdb"
outputfolder="$PWD/DATA"
TIMEOUT_PERIOD=10
BATCH_SIZE=500  # Number of IDs per batch

# Ensure output folder exists
mkdir -p "$outputfolder"
LOG_FILE="$outputfolder/delete_log.txt"
PROCESSED_FILE="$outputfolder/processed_ids.log"

# File paths
CSV_FILE="$outputfolder/pos_tickets_duplicate.csv"

# Validate if CSV exists
if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: CSV file not found at $CSV_FILE"
    exit 1
fi

# Read IDs from CSV, skipping header if present
ids=($(tail -n +2 "$CSV_FILE"))

# Total IDs to process
total_ids=${#ids[@]}
echo "Total IDs to process: $total_ids"

# Load already processed IDs
touch "$PROCESSED_FILE"
processed_ids=($(cat "$PROCESSED_FILE"))

# Filter unprocessed IDs
unprocessed_ids=()
for id in "${ids[@]}"; do
    if [[ ! " ${processed_ids[@]} " =~ " $id " ]]; then
        unprocessed_ids+=("$id")
    fi
done

total_unprocessed=${#unprocessed_ids[@]}
echo "Unprocessed IDs: $total_unprocessed"

# Process in batches
current_progress=0

for ((i = 0; i < total_unprocessed; i += BATCH_SIZE)); do
    batch=("${unprocessed_ids[@]:$i:$BATCH_SIZE}")
    batch_size=${#batch[@]}
    current_progress=$((i + batch_size))
    
    # Create a comma-separated list of IDs
    batch_str=$(IFS=,; echo "${batch[*]}")
    
    # Construct and execute DELETE query
    delete_query="DELETE FROM pos_tickets WHERE pos_ticket_id IN ($batch_str) and deleted = '1';select ROW_COUNT();"
    echo "$delete_query" >> "$LOG_FILE"
    
    timeout $TIMEOUT_PERIOD mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "$delete_query" || exit 1
    
    # Log processed IDs
    for id in "${batch[@]}"; do
        echo "$id" >> "$PROCESSED_FILE"
    done
    
    echo "Processed batch $current_progress / $total_unprocessed"
    
    # Sleep for safety if needed
    sleep 5
done

echo "All batches processed successfully."
