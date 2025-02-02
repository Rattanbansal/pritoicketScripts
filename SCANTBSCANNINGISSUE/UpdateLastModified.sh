#!/bin/bash

# Start time
start_time=$(date +%s)
set -e  # Exit immediately if any command exits with a non-zero status
set -o pipefail  # Catch errors in piped commands
set -u  # Treat unset variables as an error


# rm -f mismatch.csv

source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "OfficeLocalMachineIP5"
DB_NAME='rattan'
BATCH_SIZE=100
TIMEOUT_PERIOD=450
TIMEOUT_PERIODLIVE=25
MYSQL_TABLE="scanning"


vt_group_numbers=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "select distinct(pt_order_id) from $MYSQL_TABLE where status = '0' limit 30000;") || exit 1


source ~/vault/vault_fetch_credsLive.sh

# Fetch credentials for LIVERDSServer
fetch_db_credentials "PrioticketLiveSecondaryPipe"
DB_NAMELIVE='priopassdb'

# Convert the vt_group_numbers into an array
vt_group_array=($vt_group_numbers)
total_vt_groups=${#vt_group_array[@]}

# Print the total count of vt_group_no for the current ticket_id
echo "Processing $total_vt_groups vt_group_no values"

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
    echo "Processing batch of size $batch_size ($current_progress / $total_vt_groups processed)" >> log.txt

    echo "$batch_str"

    echo "-----Started Update Last Modified query PT----------"
    timeout $TIMEOUT_PERIODLIVE time mysql -h"$DB_HOSTLIVE" -u"$DB_USERLIVE" --port=$DB_PORTLIVE -p"$DB_PASSWORDLIVE" -D"$DB_NAMELIVE" -sN -e "update prepaid_tickets set last_modified_at = CURRENT_TIMESTAMP where visitor_group_no in ($batch_str) and action_performed like '%SCANOPTMIZE';select ROW_COUNT();" || exit 1
    echo "<<<<<<<<<<<Insert Query To Visitor Tickets Ended>>>>>>>>>"

    sleep 5

    
    timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "update $MYSQL_TABLE set status = '1' where pt_order_id in ($batch_str);select ROW_COUNT();"
done

time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "select count(*) as activestatus from $MYSQL_TABLE where status = '0';select count(*) as inactivestatus from $MYSQL_TABLE where status = '1'"

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

# Play completion sound
paplay /usr/share/sounds/freedesktop/stereo/complete.oga


# 19Server_db-creds
# 20Server_db-creds
# 20ServerNoVPN_db-creds
# 19ServerNoVPN_db-creds
# OfficeLocalMachineIP5
# PrioticketLivePriomaryroPipe
# PrioticketLivePriomaryWritePipe
# PrioticketLiveRDSPipe
# PrioticketLiveSecondaryPipe
# PrioticketTest
# PrioticketShadow
# PrioticketLiveRDSCRITICAL
# PrioticketLiveSecondaryCRITICAL