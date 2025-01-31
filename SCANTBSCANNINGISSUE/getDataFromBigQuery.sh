#!/bin/bash

# Start time
start_time=$(date +%s)
set -e  # Exit immediately if any command exits with a non-zero status


source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"
DB_NAME='rattan'
BATCH_SIZE=10
from_date=$1
to_date=$2
TIMEOUT_PERIOD=450
TIMEOUT_PERIODLIVE=25

BQ_QUERY_FILE="bq_query.sql"
OUTPUT_FILE="bq_output.csv"
MYSQL_TABLE="scanning"
startDate="$from_date 00:00:01"
endDate="$to_date 23:59:59"
uploadData=$3
echo $startDate
echo $endDate

if [[ "$uploadData" == "upload" ]]; then 

  rm -f $OUTPUT_FILE

  BQ_QUERY_FILE="WITH
  pt1 AS (
      SELECT *, 
            ROW_NUMBER() OVER (PARTITION BY prepaid_ticket_id ORDER BY last_modified_at DESC, IFNULL(version, '1') DESC) AS rn 
      FROM prio_olap.scan_report
  ),
  pt AS (
      SELECT * 
      FROM pt1 
      WHERE rn=1 AND deleted=0
  ),vt1 AS (
      SELECT *, 
            ROW_NUMBER() OVER (PARTITION BY id ORDER BY last_modified_at DESC, IFNULL(version, '1') DESC) AS rn 
      FROM prio_olap.financial_transactions
  ),
  vt AS (
      SELECT * 
      FROM vt1 
      WHERE rn=1 AND deleted='0'
  ), scantborders as (select distinct visitor_group_no from pt where action_performed like '%SCAN_TB%' and order_confirm_date > '$startDate'), ptfinal as (select pt.visitor_group_no,pt.order_confirm_date,pt.ticket_id,pt.tps_id,pt.is_refunded,pt.prepaid_ticket_id,pt.ticket_type,pt.used,pt.action_performed,pt.activated,pt.redeem_date_time,pt.redemption_notified_at ,pt.version from pt where pt.visitor_group_no in (select visitor_group_no from scantborders) and pt.is_addon_ticket != '2'), vtfinal as (select vt.vt_group_no, vt.order_confirm_date, vt.transaction_id, vt.tickettype_name,vt.ticketId,vt.ticketpriceschedule_id, vt.used, vt.action_performed, vt.visit_date_time, vt.version,vt.is_refunded, vt.row_type from vt where vt.vt_group_no in (select visitor_group_no from scantborders) and vt.col2!= 2 and row_type =1), finalData as (select ptfinal.visitor_group_no as pt_order_id, vtfinal.vt_group_no as vt_order_id, ptfinal.prepaid_ticket_id as pt_transactionId, vtfinal.transaction_id as vt_transactionId, ptfinal.version as pt_version, vtfinal.version as vt_version, ptfinal.ticket_id as ptticketId, vtfinal.ticketId as vt_ticketId, ptfinal.tps_id as pt_tpsId, vtfinal.ticketpriceschedule_id as vt_tpsId, ptfinal.action_performed as pt_actionPerformed, vtfinal.action_performed as vt_actionPeformed, ptfinal.used as pt_used, vtfinal.used as vt_used, ptfinal.redeem_date_time as pt_redeemDate, vtfinal.visit_date_time as vt_redeemDate, ptfinal.is_refunded as pt_refunded, vtfinal.is_refunded as vt_refunded, 0 as status from ptfinal left join vtfinal on ptfinal.visitor_group_no = vtfinal.vt_group_no and ptfinal.prepaid_ticket_id = vtfinal.transaction_id) select * from finalData where (pt_version != vt_version or pt_used != vt_used or ABS(TIMESTAMP_DIFF(pt_redeemDate, vt_redeemDate, SECOND)) > 10800) and pt_used = '1'"

  # Step 2: Run BigQuery Command
  echo "Running BigQuery Query..."

  gcloud config set project prioticket-reporting


  bq query --use_legacy_sql=False --max_rows=10000000 --format=csv \
  "$BQ_QUERY_FILE" > $OUTPUT_FILE || exit 1

  if [ $? -ne 0 ]; then
      echo "BigQuery query failed. Exiting."
      exit 1
  fi

  echo "BigQuery query successful. Data saved to $OUTPUT_FILE."

  # Step 3: Insert Data into MySQL
  echo "Inserting data into MySQL table..."



  timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "DROP TABLE IF EXISTS $MYSQL_TABLE" || exit 1

  # Create the table if it does not exist
  create_table_query="CREATE TABLE IF NOT EXISTS $MYSQL_TABLE (
      pt_order_id VARCHAR(255),
      vt_order_id VARCHAR(255),
      pt_transactionId VARCHAR(255),
      vt_transactionId VARCHAR(255),
      pt_version VARCHAR(255),
      vt_version VARCHAR(255),
      ptticketId VARCHAR(255),
      vtticketId VARCHAR(255),
      pt_tpsId VARCHAR(255),
      vt_tpsId VARCHAR(255),
      pt_actionPerformed VARCHAR(255),
      vt_actionPerformed VARCHAR(255),
      pt_used VARCHAR(255),
      vt_used VARCHAR(255),
      pt_redeemDate VARCHAR(255),
      vt_redeemDate VARCHAR(255),
      pt_refunded VARCHAR(255),
      vt_refunded VARCHAR(255),
      status VARCHAR(255)
  );"

  # Execute the query to create the table
  timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "$create_table_query" || exit 1

  mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "SET GLOBAL local_infile = 1;"

  echo "status of query to alter table"

  # Load the CSV data into the table
  mysql --local-infile=1 -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" <<EOF
  LOAD DATA LOCAL INFILE '$OUTPUT_FILE'
  INTO TABLE $MYSQL_TABLE
  FIELDS TERMINATED BY ',' 
  ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 ROWS
  (pt_order_id, vt_order_id,pt_transactionId, vt_transactionId, pt_version, vt_version, ptticketId, vtticketId, pt_tpsId, vt_tpsId, pt_actionPerformed,vt_actionPerformed,pt_used,vt_used,pt_redeemDate,vt_redeemDate,pt_refunded,vt_refunded,status);
EOF


  echo "status of query to insert data"
  echo "Data successfully loaded into table: $MYSQL_TABLE"

fi

timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "select count(*) from $MYSQL_TABLE;select count(distinct(pt_order_id)) from $MYSQL_TABLE;"

vt_group_numbers=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "select distinct(pt_order_id) from $MYSQL_TABLE where status = '0' limit 100;") || exit 1


source ~/vault/vault_fetch_credsLive.sh

# Fetch credentials for LIVERDSServer
fetch_db_credentials "PrioticketLiveRDSPipe"
DB_NAMELIVE='prioprodrds'

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

    timeout $TIMEOUT_PERIODLIVE time mysql -h"$DB_HOSTLIVE" -u"$DB_USERLIVE" --port=$DB_PORTLIVE -p"$DB_PASSWORDLIVE" -D"$DB_NAMELIVE" -sN -e "select ptt.visitor_group_no as pt_orderId, vt.vt_group_no as vt_orderId, ptt.prepaid_ticket_id as pt_transactionId, vt.transaction_id as vt_transactionId, ptt.version as pt_version, vt.version as vt_version, ptt.used as pt_used, vt.used as vt_used, ptt.redeem_date_time as pt_redeemDate, vt.visit_date_time as vt_redeemDate, ptt.action_performed as pt_actionPerformed, vt.action_performed as vt_actionPerformed from (select pt.visitor_group_no, pt.prepaid_ticket_id, pt.version, pt.used, pt.redeem_date_time, pt.action_performed from prepaid_tickets pt join (SELECT visitor_group_no, prepaid_ticket_id, max(version) as version FROM prepaid_tickets where visitor_group_no in ($batch_str) and is_addon_ticket != '2' group by prepaid_ticket_id, visitor_group_no) as base on pt.visitor_group_no = base.visitor_group_no and ABS(pt.version-base.version) = '0' and pt.prepaid_ticket_id = base.prepaid_ticket_id and pt.used = '1') as ptt left join (select vtt.vt_group_no, vtt.version, vtt.transaction_id, vtt.used, vtt.visit_date_time, vtt.action_performed from visitor_tickets vtt join (SELECT vt_group_no,transaction_id, row_type,max(version) as version FROM visitor_tickets where vt_group_no in ($batch_str) and col2 != '2' and row_type = '1' group by transaction_id, vt_group_no,row_type) as base1 on vtt.vt_group_no = base1.vt_group_no and ABS(vtt.version-base1.version) = '0' and vtt.transaction_id = base1.transaction_id and vtt.row_type = base1.row_type where vtt.col2 != '2') vt on ptt.visitor_group_no = vt.vt_group_no and ptt.prepaid_ticket_id = vt.transaction_id where ROUND(ABS(ptt.used-vt.used)) != '0' or ABS(TIMESTAMPDIFF(MINUTE, ptt.redeem_date_time, vt.visit_date_time)) > 180 or ABS(ptt.version-vt.version) != '0';" >> mismatch.csv || exit 1

    sleep 5

    timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "update $MYSQL_TABLE set status = '1' where pt_order_id in ($batch_str);select ROW_COUNT();"

done

timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "select count(*) as activestatus from $MYSQL_TABLE where status = '0';select count(*) as inactivestatus from $MYSQL_TABLE where status = '1'"


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