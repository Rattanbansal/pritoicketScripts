#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=25


DB_HOST='10.10.10.19'
DB_USER='pip'
DB_PASS='pip2024##'
DB_NAME='rattan'
BATCH_SIZE=30

mysqlHost="prodrds.prioticket.com"
mysqlUser=pipeuser
mysqlPassword=d4fb46eccNRAL
mysqlDatabase="prioprodrds"

# Get all vt_group_no for the current ticket_id
vt_group_numbers=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "SELECT distinct visitor_group_no FROM matrix WHERE status = '0'") || exit 1

# Convert the vt_group_numbers into an array
vt_group_array=($vt_group_numbers)
total_vt_groups=${#vt_group_array[@]}

# Print the total count of vt_group_no for the current ticket_id
echo "Processing Ticket ID: $ticket_id with $total_vt_groups vt_group_no values"

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
    echo "Processing batch of size $batch_size for Ticket ID: $ticket_id ($current_progress / $total_vt_groups processed)" >> log.txt
    
    # Construct and execute the UPDATE query
    # update_query="UPDATE your_table SET your_column = 'your_value' WHERE ticket_id = $ticket_id AND vt_group_no IN ($batch_str)"

    MISMATCH="select vt_group_no, ticketId, ticketpriceschedule_id, channel_id, hotel_id from visitor_tickets where vt_group_no in ($batch_str) and col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%' group by vt_group_no, ticketId, ticketpriceschedule_id, channel_id, hotel_id"

    echo "Found MIsmatch Query"

    echo "$MISMATCH" >> rattan.sql

    timeout $TIMEOUT_PERIOD time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -sN -e "$MISMATCH" >> records.csv

    

    timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "update matrix set status = '1' where visitor_group_no in ($batch_str);SELECT ROW_COUNT()" || exit 1

    echo "Sleep Started to Run next VGNS"
    echo "------$(date '+%Y-%m-%d %H:%M:%S.%3N')--------"
    sleep 3

done