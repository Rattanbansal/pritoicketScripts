#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=25


DB_HOST='10.10.10.19'
DB_USER='pip'
DB_PASS='pip2024##'
DB_NAME='rattan'
BATCH_SIZE=50

vt_group_numbers=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "SELECT visitor_group_no FROM elastic WHERE status = '0'") || exit 1

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


    echo "https://report.prioticket.com/Insert_api_data_nested/api_results_v2/$batch_str"
    curl https://report.prioticket.com/Insert_api_data_nested/api_results_v2/$batch_str
    

    timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "update elastic  set status = '1' where visitor_group_no in ($batch_str)" || exit 1


    echo "Sleep Started to Run next VGNS"
    echo "------$(date '+%Y-%m-%d %H:%M:%S.%3N')--------"
    sleep 10

done
