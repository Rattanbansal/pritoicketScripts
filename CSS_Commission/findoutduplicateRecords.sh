#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=25


DB_HOST='localhost'
DB_USER='admin'
DB_PASS='redhat'
DB_NAME='dummy'
BATCH_SIZE=100

mysqlHost="prodrds.prioticket.com"
mysqlUser=pipeuser
mysqlPassword=d4fb46eccNRAL
mysqlDatabase="prioprodrds"

SECDATABASE='priopassdb'
SECHOST='production-secondary-db-node.cluster-ck6w2al7sgpk.eu-west-1.rds.amazonaws.com'
SECUSER='pipeuser'
SECPASSWORD='d4fb46eccNRAL'

# Get all unique ticket_ids
ticket_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "SELECT DISTINCT(ticketid) FROM orders where status = '0'") || exit 1

# Loop through each ticket_id
for ticket_id in $ticket_ids; do
    # Get all vt_group_no for the current ticket_id
    vt_group_numbers=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "SELECT vt_group_no FROM orders WHERE ticketid = '$ticket_id' and status = '0'") || exit 1
    
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

        MISMATCH="select vt_group_no, concat(transaction_id,'R') as transaction_id, version, row_type, col2,action_performed, count(*) from visitor_tickets where vt_group_no in ($batch_str) and col2 != '2' group by vt_group_no, transaction_id, version, row_type, col2, action_performed having count(*) > '1'"

        echo "Found MIsmatch Query"

        echo "$MISMATCH" >> rattan.sql

        timeout $TIMEOUT_PERIOD time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -sN -e "$MISMATCH" >> duplicaterds.csv

        # timeout $TIMEOUT_PERIOD time mysql -h"$SECHOST" -u"$SECUSER" -p"$SECPASSWORD" -D"$SECDATABASE" -sN -e "$MISMATCH" >> duplicatevt.csv
        

        timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "update orders set status = '1' where vt_group_no in ($batch_str);SELECT ROW_COUNT()" || exit 1

        sleep 2

    done
done