#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status

echo "Script Stated at $(date)"
startdate=$(date +"%Y-%m-%d %H:%M:%S")

DB_HOST='production-secondary-db-node.cluster-ck6w2al7sgpk.eu-west-1.rds.amazonaws.com'
DB_USER=prt_dbadmin
DB_PASSWORD='YI7g3zXYLaRLf06HTX2s'
DB_NAME=priopassdb
table_name=visitor_tickets
column_name=vt_group_no
table_name2=prepaid_tickets
column_name2=visitor_group_no
PORT=3306
BATCH_SIZE=25


DB2_HOST='prodrds.prioticket.com'
DB2_USER=prodrdsmaster
DB2_PASSWORD='FQ2b2RRCmehZi9gn'
DB2_NAME=prioprodrds
timeout_duration=60 # Timeout duration to kill queries if any queries taking time


vt_group_numbers="167248376982761"

# vt_group_numbers="171334036366002"

# Convert the vt_group_numbers into an array
vt_group_array=($vt_group_numbers)
total_vt_groups=${#vt_group_array[@]}

# Loop through vt_group_no array in batches
for ((i=0; i<$total_vt_groups; i+=BATCH_SIZE)); do
    # Create a batch of vt_group_no values
    batch=("${vt_group_array[@]:$i:$BATCH_SIZE}")
    batch_size=${#batch[@]}

    # Calculate the current progress level for this ticket_id
    current_progress=$((i + batch_size))
    
    # Join the batch into a comma-separated list
    batch_str=$(IFS=,; echo "${batch[*]}")

    echo "$batch_str"

    time timeout "$timeout_duration" mysqldump --single-transaction --skip-lock-tables --skip-add-locks --no-tablespaces -h $DB_HOST --set-gtid-purged=OFF -u $DB_USER --port=$PORT -p"$DB_PASSWORD"  --skip-add-drop-table --no-create-info $DB_NAME $table_name --where="$column_name in ($batch_str)" | gzip > $table_name.sql.gz

    echo "restore started"

    gunzip <  $table_name.sql.gz | time mysql -h $DB2_HOST -u $DB2_USER -p"$DB2_PASSWORD" $DB2_NAME || exit 1

    echo "restore ended"

    echo "---------Update started---------"

    time mysql -h $DB2_HOST -u $DB2_USER -p"$DB2_PASSWORD" $DB2_NAME -e "update visitor_tickets set last_modified_at = CURRENT_TIMESTAMP where vt_group_no in ($batch_str) " || exit 1

    time mysql -h $DB_HOST -u $DB_USER -p"$DB_PASSWORD" $DB_NAME -e "update visitor_tickets set last_modified_at = CURRENT_TIMESTAMP where vt_group_no in ($batch_str) " || exit 1

    echo "---------Update ended---------"

    rm -f $table_name.sql.gz


    echo "-------------Prepaid_tickets----------"

    time timeout "$timeout_duration" mysqldump --single-transaction --skip-lock-tables --skip-add-locks --no-tablespaces -h $DB_HOST --set-gtid-purged=OFF -u $DB_USER --port=$PORT -p"$DB_PASSWORD"  --skip-add-drop-table --no-create-info $DB_NAME $table_name2 --where="$column_name2 in ($batch_str)" | gzip > $table_name2.sql.gz

    echo "restore started"

    gunzip <  $table_name2.sql.gz | time mysql -h $DB2_HOST -u $DB2_USER -p"$DB2_PASSWORD" $DB2_NAME || exit 1

    echo "restore ended"

    echo "---------Update started---------"

    time mysql -h $DB2_HOST -u $DB2_USER -p"$DB2_PASSWORD" $DB2_NAME -e "update prepaid_tickets set last_modified_at = CURRENT_TIMESTAMP where visitor_group_no in ($batch_str) " || exit 1

    time mysql -h $DB_HOST -u $DB_USER -p"$DB_PASSWORD" $DB_NAME -e "update prepaid_tickets set last_modified_at = CURRENT_TIMESTAMP where visitor_group_no in ($batch_str) " || exit 1

    echo "---------Update ended---------"

    rm -f $table_name2.sql.gz

    sleep 10
    # exit 1

done