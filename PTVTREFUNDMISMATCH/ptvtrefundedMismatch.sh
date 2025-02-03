#!/bin/bash

# Start time
start_time=$(date +%s)
set -e  # Exit immediately if any command exits with a non-zero status
set -o pipefail  # Catch errors in piped commands
set -u  # Treat unset variables as an error

# Function to handle errors
handle_error() {
    echo "❌ Error occurred! Exiting..."
    paplay /usr/share/sounds/freedesktop/stereo/dialog-error.oga  # Error sound
    exit 1
}

# Trap errors and call handle_error
trap 'handle_error' ERR

# rm -f mismatch.csv

source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"
DB_NAME='rattan'
BATCH_SIZE=100
from_date=$1
to_date=$2
TIMEOUT_PERIOD=450
TIMEOUT_PERIODLIVE=25

BQ_QUERY_FILE="bq_query.sql"
OUTPUT_FILE="bq_output.csv"
MYSQL_TABLE="RefundMismatch"
startDate="$from_date 00:00:01"
endDate="$to_date 23:59:59"
uploadData=$3
echo $startDate
echo $endDate

# ./getDataFromBigQuery.sh <startdate> <enddate> <upload: upload to bigquery>

if [[ "$uploadData" == "upload" ]]; then 

  rm -f $OUTPUT_FILE

  BQ_QUERY_FILE="WITH
  pt1 AS (
      SELECT *, 
            ROW_NUMBER() OVER (PARTITION BY prepaid_ticket_id ORDER BY IFNULL(version, '1') DESC,last_modified_at DESC) AS rn 
      FROM prio_olap.scan_report
  ),
  pt AS (
      SELECT * 
      FROM pt1 
      WHERE rn=1 AND deleted=0
  ),vt1 AS (
      SELECT *, 
            ROW_NUMBER() OVER (PARTITION BY id ORDER BY IFNULL(version, '1') DESC,last_modified_at DESC) AS rn 
      FROM prio_olap.financial_transactions
  ),
  vt AS (
      SELECT * 
      FROM vt1 
      WHERE rn=1 AND deleted='0'
  ), scantborders as (select distinct visitor_group_no from pt where order_confirm_date > '$startDate'), ptfinal as (select pt.visitor_group_no,pt.order_confirm_date,pt.ticket_id,pt.tps_id,pt.is_refunded,pt.prepaid_ticket_id,pt.ticket_type,pt.used,pt.action_performed,pt.activated,pt.redeem_date_time,pt.redemption_notified_at ,pt.version from pt where pt.visitor_group_no in (select visitor_group_no from scantborders)), vtfinal as (select vt.vt_group_no, vt.order_confirm_date, vt.transaction_id, vt.tickettype_name,vt.ticketId,vt.ticketpriceschedule_id, vt.used, vt.action_performed, vt.visit_date_time, vt.version,vt.is_refunded, vt.row_type from vt where vt.vt_group_no in (select visitor_group_no from scantborders)), finalData as (select ptfinal.visitor_group_no as pt_order_id, vtfinal.vt_group_no as vt_order_id, concat(ptfinal.prepaid_ticket_id, 'R') as pt_transactionId, concat(vtfinal.transaction_id,'R') as vt_transactionId, ptfinal.version as pt_version, vtfinal.version as vt_version, ptfinal.ticket_id as ptticketId, vtfinal.ticketId as vt_ticketId, ptfinal.tps_id as pt_tpsId, vtfinal.ticketpriceschedule_id as vt_tpsId, ptfinal.action_performed as pt_actionPerformed, vtfinal.action_performed as vt_actionPeformed, ptfinal.used as pt_used, vtfinal.used as vt_used, ptfinal.redeem_date_time as pt_redeemDate, vtfinal.visit_date_time as vt_redeemDate, ptfinal.is_refunded as pt_refunded, vtfinal.is_refunded as vt_refunded,vtfinal.row_type as row_type, 0 as status from ptfinal left join vtfinal on ptfinal.visitor_group_no = vtfinal.vt_group_no and ptfinal.prepaid_ticket_id = vtfinal.transaction_id) select * from finalData where pt_refunded != vt_refunded"

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
      row_type VARCHAR(255),
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
  (pt_order_id, vt_order_id,pt_transactionId, vt_transactionId, pt_version, vt_version, ptticketId, vtticketId, pt_tpsId, vt_tpsId, pt_actionPerformed,vt_actionPerformed,pt_used,vt_used,pt_redeemDate,vt_redeemDate,pt_refunded,vt_refunded,row_type,status);
EOF


  echo "status of query to insert data"
  echo "Data successfully loaded into table: $MYSQL_TABLE"

fi

timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "select * from $MYSQL_TABLE;" > refundedmismatch.csv


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