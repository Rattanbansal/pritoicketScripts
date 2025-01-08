#!/bin/bash

set -e

# Start time
start_time=$(date +%s)

# Commands or Script Logic
echo "Script is running..."

source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "PrioticketLivePriomaryWritePipe"
outputfolder="$PWD/DATA"
DB_NAME="priopassdb"
outputFile="$outputfolder/pos_tickets_duplicate.csv"
TIMEOUT_PERIOD=20
BATCH_SIZE=50

# Create necessary files if they don't exist
mkdir -p "$outputfolder"
touch "$outputfolder/processed_hotels.log"

echo "pos_ticket_id" >> $outputFile

fetchHotelIdsQuery="SELECT DISTINCT hotel_id FROM pos_tickets"
hotel_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "$fetchHotelIdsQuery") || exit 1

# Convert the vt_group_numbers into an array
hotel_ids_array=($hotel_ids)
echo $hotel_ids_array
total_hotel_ids=${#hotel_ids_array[@]}

# Read already processed hotel_ids
processed_hotels=$(cat "$outputfolder/processed_hotels.log")
processed_hotels_array=($processed_hotels)

# Filter out already processed hotel_ids
unprocessed_hotels=()
for id in "${hotel_ids_array[@]}"; do
    if [[ ! " ${processed_hotels_array[@]} " =~ " $id " ]]; then
        unprocessed_hotels+=("$id")
    fi
done

# Update total hotel_ids after filtering
total_unprocessed_hotels=${#unprocessed_hotels[@]}
echo "Total unprocessed hotel_ids: $total_unprocessed_hotels"

# Print the total count of vt_group_no for the current ticket_id
echo "Processing: $total_hotel_ids hotel_ids values"

# Initialize the progress tracking for the current ticket_id
current_progress=0

# Loop through vt_group_no array in batches
for ((i=0; i<$total_unprocessed_hotels; i+=BATCH_SIZE)); do
    # Create a batch of vt_group_no values
    batch=("${unprocessed_hotels[@]:$i:$BATCH_SIZE}")
    batch_size=${#batch[@]}

    # Calculate the current progress level for this ticket_id
    current_progress=$((i + batch_size))
    
    # Join the batch into a comma-separated list
    batch_str=$(IFS=,; echo "${batch[*]}")

    echo "$batch_str"

    # Print progress information for the current ticket_id
    echo "Processing batch of size $batch_size : $ticket_id ($current_progress / $total_unprocessed_hotels processed)" >> $outputfolder/log.txt
    
    fetchduplicateentries="select distinct pos_ticket_id from (select pos.pos_ticket_id, pos.hotel_id, pos.mec_id, pos.is_pos_list, pos.deleted, pos.last_modified_at from pos_tickets pos join (SELECT max(pos_ticket_id) as pos_ticket_id, hotel_id,mec_id, count(*) as pcs from pos_tickets where hotel_id in ($batch_str) and deleted = '1' group by mec_id, hotel_id, deleted having pcs > '1' and deleted = '1') as base on pos.hotel_id = base.hotel_id and pos.mec_id = base.mec_id and pos.deleted = '1' and pos.pos_ticket_id != base.pos_ticket_id) as base1"
    echo "$fetchduplicateentries" >> queries.sql

    timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "$fetchduplicateentries" >> $outputFile || exit 1

    # Mark each hotel_id in the batch as processed
    for hotel_id in "${batch[@]}"; do
        echo "$hotel_id" >> "$outputfolder/processed_hotels.log"
    done

    echo "-----------Sleep Started----------"
    sleep 5
    echo "-----------Sleep Ended----------"

done


# End time
end_time=$(date +%s)

# Calculate elapsed time in seconds
execution_time=$((end_time - start_time))

# Calculate hours, minutes, and seconds
hours=$((execution_time / 3600))
minutes=$(( (execution_time % 3600) / 60 ))
seconds=$((execution_time % 60))

# Display execution time in HH:MM:SS
printf "Total Execution Time: %02d hours, %02d minutes, %02d seconds\n" $hours $minutes $seconds