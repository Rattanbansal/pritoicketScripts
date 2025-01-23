#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=25


# DB_HOST='10.10.10.19'
# DB_USER='pip'
# DB_PASS='pip2024##'
source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"
DB_NAME='rattan'
BATCH_SIZE=100

# DB_HOST='localhost'
# DB_USER='admin'
# DB_PASS='redhat'
# DB_NAME='dummy'
# BATCH_SIZE=100
tableName=$1

mysqlHost="prodrds.prioticket.com"
mysqlUser=pipeuser
mysqlPassword=d4fb46eccNRAL
mysqlDatabase="prioprodrds"

rm -f ZeroSumissue.csv

echo "vt_group_no,transaction_id,salePrice,otherPrice,hotel_id,ticketId,ticketpriceschedule_id,channel_id,reseller_id, status" > ZeroSumissue.csv


# timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "update $tableName set channel_id = '0';select ROW_COUNT();" || exit 1  # channel_id used as status because not needed this column

# Get all unique ticket_ids
ticket_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "SELECT DISTINCT(ticketId) FROM $tableName where status = '0'") || exit 1   # channel_id used in place of status

# Loop through each ticket_id
for ticket_id in $ticket_ids; do
    # Get all vt_group_no for the current ticket_id
    vt_group_numbers=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "SELECT distinct vt_group_no FROM $tableName WHERE ticketId = '$ticket_id' and status = '0'") || exit 1

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
        
                    
        MISMATCHFInal="select * from (SELECT vt.vt_group_no, CONCAT(vt.transaction_id, 'R') AS transaction_id, sum(case when vt.row_type = '1' then vt.partner_net_price else 0 end) as salePrice, sum(case when vt.row_type in ('2','3','4','17') then vt.partner_net_price else 0 end) as otherPrice, hotel_id, ticketId, ticketpriceschedule_id, channel_id, reseller_id, '0' as status FROM visitor_tickets vt JOIN( SELECT vt_group_no, transaction_id, row_type, max(case when row_type = '1' then partner_net_price else 0 end) as salePrice, MAX(VERSION) AS VERSION FROM visitor_tickets WHERE ticketId = '$ticket_id' and vt_group_no IN($batch_str) AND col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%' and action_performed like '%EECommission_Jan' and row_type in ('1','2','3','4','17') GROUP BY vt_group_no, transaction_id ) AS maxversion ON vt.vt_group_no = maxversion.vt_group_no AND vt.transaction_id = maxversion.transaction_id and vt.col2 != '2' AND ABS(vt.version - maxversion.version) = '0' group by vt.vt_group_no,vt.transaction_id) as final where ABS(salePrice-otherPrice)>0.03;"


        # sleep 3
        timeout $TIMEOUT_PERIOD time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -sN -e "$MISMATCHFInal" >> ZeroSumissue.csv || exit 1

        timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "update $tableName set status = '4' where vt_group_no in ($batch_str)" || exit 1  # channel_id used as status because not needed this column

        
        echo "Sleep Started to Run next VGNS"
        echo "------$(date '+%Y-%m-%d %H:%M:%S.%3N')--------"

        sleep 10


    done
done


# Define the table name for the output data
output_table="ZeroSumIssue"
OUTPUT_FILE="ZeroSumissue.csv"

timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "DROP TABLE $output_table" || exit 1

# Create the table if it does not exist
create_table_query="CREATE TABLE IF NOT EXISTS $output_table (
    vt_group_no VARCHAR(255),
    transaction_id VARCHAR(255),
    salePrice DECIMAL(10,2),
    otherPrice DECIMAL(10,2),
    hotel_id INT,
    ticketId VARCHAR(255),
    ticketpriceschedule_id VARCHAR(255),
    channel_id INT,
    reseller_id INT,
    status INT
);"

# Execute the query to create the table
timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "$create_table_query" || exit 1
echo "status of query to alter table"

# Load the CSV data into the table
mysql --local-infile=1 -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" <<EOF
LOAD DATA LOCAL INFILE '$OUTPUT_FILE'
INTO TABLE $output_table
FIELDS TERMINATED BY '\t' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(vt_group_no, transaction_id, salePrice, otherPrice, hotel_id, ticketId, ticketpriceschedule_id, channel_id, reseller_id, status);
EOF


echo "status of query to insert data"
echo "Data successfully loaded into table: $output_table"


updaterecordsforwhichnoseting="update rattan.ZeroSumIssue ro join (select * from (select *,(case when qr_reseller_id = '541' and dt_hotel_id is null then 'No Setting' when qr_reseller_id != '541' and p_reseller_id is null then 'No Setting' else '' end) as settingtype  from (SELECT ev.*,dt.ticket_id as dt_ticket_id, dt.hotel_id as dt_hotel_id, dt.commission as dt_commission,dt.cod_id as dt_cod_id,dt.sub_catalog_id as dt_sub_catalog_id,qr.reseller_id as qr_reseller_id,p.ticket_id as p_ticket_id,p.reseller_id as p_reseller_id,p.commission as p_commission FROM rattan.ZeroSumIssue ev left join (select * from priopassdb.distributors UNION all select * from priopassdb.distributors1) as dt on ev.hotel_id = dt.hotel_id and ev.ticketId = dt.ticket_id left join priopassdb.qr_codes qr on qr.cod_id = ev.hotel_id left join priopassdb.pricelist p on p.reseller_id = qr.reseller_id and p.ticket_id = ev.ticketId) as main)  as orders where settingtype ='No Setting') as base on base.vt_group_no = ro.vt_group_no and ro.ticketid = base.ticketid and ro.ticketpriceschedule_id = base.ticketpriceschedule_id set ro.status ='10';select row_count();"

timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "$updaterecordsforwhichnoseting" || exit 1

echo "Update order successfully for which no setting provided by client"