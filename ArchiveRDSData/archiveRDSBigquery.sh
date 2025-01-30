#!/bin/bash

# Start time
start_time=$(date +%s)

set -e

LIMIT=5000
OFFSET=0
startDate=$1
endDate=$2
Archivedate=$3
BATCH_SIZE=50
TIMEOUT_PERIOD=40
LocalTable='rdsarchive'
outputfolder="$PWD/VT"

# Check if the required arguments are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Error: All arguments are required."
    echo "Usage: $0 startDate endDate Archivedate"
    exit 1
fi

#  Loop to get data in chunk of 5000 at once
while :; do

    source ~/vault/vault_fetch_creds.sh

    # Fetch credentials for 20Server
    fetch_db_credentials "19ServerNoVPN_db-creds"
    DB_NAME='rattan'

    if [[ "$DB_HOST" == "163.47.214.30" ]]; then
        echo "Host Successfully changed"
        echo "$DB_HOST"
    else
        echo "Host Not changed so exiting"
        echo "$DB_HOST"
        exit 1
    fi

    records=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "select count(*) from (select * from $LocalTable where status = '0' limit $OFFSET, $LIMIT) as base;") || exit 1

    echo "Records From DB: $records"
    echo "limit Passed: $OFFSET, $LIMIT"

    # Get VT GROUP NOs to Run loop and remove it from The RDS
    vt_group_numbers=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "SELECT distinct vt_group_no FROM $LocalTable where status = '0' limit $OFFSET, $LIMIT") || exit 1
    
    # Convert the vt_group_numbers into an array
    vt_group_array=($vt_group_numbers)
    echo $vt_group_array
    total_vt_groups=${#vt_group_array[@]}

    # Print the total count of vt_group_no for the current ticket_id
    echo "Processing: $total_vt_groups vt_group_no values"

    # Initialize the progress tracking for the current ticket_id
    current_progress=0

    source ~/vault/vault_fetch_creds.sh

    # Fetch credentials for 20Server
    fetch_db_credentials "PrioticketLiveRDSPipe"
    DB_NAME="prioprodrds"

    if [[ "$DB_HOST" == "prodrds.prioticket.com" ]]; then
        echo "Host Successfully changed"
        echo "$DB_HOST"
    else
        echo "Host Not changed so exiting"
        echo "$DB_HOST"
        exit 1
    fi

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

            echo "delete from visitor_tickets where vt_group_no in ($batch_str);select ROW_COUNT();delete from prepaid_tickets where visitor_group_no in ($batch_str);select ROW_COUNT();delete from hotel_ticket_overview where visitor_group_no in ($batch_str);select ROW_COUNT();"

            # timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "delete from visitor_tickets where vt_group_no in ($batch_str);select ROW_COUNT();" || exit 1
            # sleep 5
            # timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "delete from prepaid_tickets where visitor_group_no in ($batch_str);select ROW_COUNT();" || exit 1
            # sleep 5
            # timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "delete from hotel_ticket_overview where visitor_group_no in ($batch_str);select ROW_COUNT();" || exit 1
        fi

        sleep 5
    done

    OFFSET=$(($OFFSET + $LIMIT))
    if [[ $records < $LIMIT ]]; then
      echo "No more records to fetch. Exiting loop."
      break
    fi
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