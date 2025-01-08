#!/bin/bash

set -e

# source ~/vault/startvalue.sh
# Source the shared credential fetcher
source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "PrioticketLiveRDSPipe"
outputfolder="$PWD/VT"
DB_NAME="prioprodrds"
outputFile="$outputfolder/recordshto.csv"
BATCH_SIZE=75
TIMEOUT_PERIOD=20

# Input Parameters
start_date=$1
end_date=$2
daystorun=$3  # Change to 1 or 2 as needed

# Check if the required arguments are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Error: All arguments are required."
    echo "Usage: $0 startdate enddate interval"
    exit 1
fi

# Convert start and end dates to seconds since epoch
current_start_date=$(date -d "$start_date" +%s)
end_date_epoch=$(date -d "$end_date" +%s)

# Loop through date ranges
while [ "$current_start_date" -le "$end_date_epoch" ]; do
    # Calculate the current end date
    current_end_date=$((current_start_date + (daystorun - 1) * 86400))
    
    # Ensure the current_end_date doesn't exceed global end_date
    if [ "$current_end_date" -gt "$end_date_epoch" ]; then
        current_end_date=$end_date_epoch
    fi
    
    start_date=$(date -d "@$current_start_date" '+%Y-%m-%d')' 00:00:01'
    end_date=$(date -d "@$current_end_date" '+%Y-%m-%d')' 23:59:59'

    # Print the current range in the desired format
    echo "$start_date"
    echo "$end_date"
    echo "--------------------------------------------------"

    vt_group_numbers=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "SELECT distinct vt_group_no FROM visitor_tickets where last_modified_at BETWEEN '$start_date' and '$end_date'") || exit 1
    
    # Convert the vt_group_numbers into an array
    vt_group_array=($vt_group_numbers)
    echo $vt_group_array
    total_vt_groups=${#vt_group_array[@]}

    # Print the total count of vt_group_no for the current ticket_id
    echo "Processing: $ticket_id with $total_vt_groups vt_group_no values"

    # Initialize the progress tracking for the current ticket_id
    current_progress=0

    # Loop through vt_group_no array in batches
    for ((i=0; i<$total_vt_groups; i+=BATCH_SIZE)); do
        # Create a batch of vt_group_no values
        batch=("${vt_group_array[@]:$i:$BATCH_SIZE}")
        batch_size=${#batch[@]}

        # Calculate the current progress level for this ticket_id
        current_progress=$((i + batch_size))
        
        # Join the batch into a comma-separated list
        batch_str=$(IFS=,; echo "${batch[*]}")

        # Print progress information for the current ticket_id
        echo "Processing batch of size $batch_size for Ticket ID from date: $start_date till end date $end_date: $ticket_id ($current_progress / $total_vt_groups processed)" >> $outputfolder/log.txt

        echo $batch_str

        if [ -z "$batch_str" ]; then

            echo "No results found. Proceeding with further steps. for ($batch_str)" >> $outputfolder/no_mismatch.txt
            
        else 

            querydata="select IFNULL(TRIM(TRAILING ',' FROM GROUP_CONCAT(DISTINCT(vt_group_no))), '') as order_id from (SELECT vt_group_no, max(last_modified_at) as mx_last_modified, min(last_modified_at) as mn_last_modified FROM visitor_tickets WHERE vt_group_no in ($batch_str) group by vt_group_no having mn_last_modified < '2024-01-01 00:00:01' and mx_last_modified < '2024-01-01 00:00:01') as base"


            ArchiveOrders=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "$querydata") || exit 1

            echo "$ArchiveOrders"

            if [ -z "$ArchiveOrders" ]; then

                echo "No results found. Proceeding with further steps. for ($ArchiveOrders)" >> $outputfolder/no_mismatch.txt

            else 

                echo "Results found. Proceeding with further steps. for ($ArchiveOrders)" >> $outputfolder/mismatch.txt

                reportdata="SELECT vt_group_no, max(last_modified_at) as mx_last_modified, min(last_modified_at) as mn_last_modified FROM visitor_tickets WHERE vt_group_no in ($ArchiveOrders) group by vt_group_no having mn_last_modified < '2024-01-01 00:00:01' and mx_last_modified < '2024-01-01 00:00:01'"
                sleep 1
                timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "$reportdata" >> $outputFile || exit 1
                sleep 1
                timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "delete from visitor_tickets where vt_group_no in ($ArchiveOrders);select ROW_COUNT();" || exit 1
                sleep 3
                timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "delete from prepaid_tickets where visitor_group_no in ($ArchiveOrders);select ROW_COUNT();" || exit 1
                sleep 2
                timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "delete from hotel_ticket_overview where visitor_group_no in ($ArchiveOrders);select ROW_COUNT();" || exit 1

            fi
        fi

        sleep 3

    done
    
    # Increment start date for the next iteration
    current_start_date=$((current_end_date + 86400))

    sleep 3

done


# SELECT distinct vt_group_no FROM visitor_tickets where last_modified_at BETWEEN '2024-01-01 00:00:01' and '2024-01-01 23:59:59'