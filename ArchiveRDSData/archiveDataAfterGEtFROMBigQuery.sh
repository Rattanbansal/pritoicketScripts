#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status

source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"
DB_NAME='rattan'
tilldate=$1
BQ_QUERY_FILE="bq_query.sql"
TEMP_QUERY_FILE="bq_temp_query.sql"
OUTPUT_FILE="bq_output.csv"
MYSQL_TABLE="EEBigqueryMismatch"
ArchiveDate="$tilldate 00:00:01"

echo $ArchiveDate


rm -f $OUTPUT_FILE

# Step 1: Replace the placeholder with the dynamic date in SQL file
echo "Preparing query..."
sed "s/{{DATE_PLACEHOLDER}}/'$ArchiveDate'/g" $BQ_QUERY_FILE > $TEMP_QUERY_FILE

# Step 2: Run BigQuery Command
echo "Running BigQuery Query..."

gcloud config set project prioticket-reporting


bq query --use_legacy_sql=False --max_rows=100 --format=csv \
--parameter=archive_date::TIMESTAMP="$ArchiveDate" < "$BQ_QUERY_FILE" > "$OUTPUT_FILE" || exit 1


if [ $? -ne 0 ]; then
    echo "BigQuery query failed. Exiting."
    exit 1
fi

# Clean up temporary query file
rm -f $TEMP_QUERY_FILE

echo "BigQuery query successful. Data saved to $OUTPUT_FILE."

# Step 3: Insert Data into MySQL
echo "Inserting data into MySQL table..."


exit 1
timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "DROP TABLE IF EXISTS $MYSQL_TABLE" || exit 1

# Create the table if it does not exist
create_table_query="CREATE TABLE IF NOT EXISTS $MYSQL_TABLE (
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
(vt_group_no, transaction_id, salePrice, otherPrice, hotel_id, ticketId, ticketpriceschedule_id, channel_id, reseller_id, status);
EOF


echo "status of query to insert data"
echo "Data successfully loaded into table: $MYSQL_TABLE"


updaterecordsforwhichnoseting="update rattan.$MYSQL_TABLE ro join (select * from (select *,(case when qr_reseller_id = '541' and dt_hotel_id is null then 'No Setting' when qr_reseller_id != '541' and p_reseller_id is null then 'No Setting' else '' end) as settingtype  from (SELECT ev.*,dt.ticket_id as dt_ticket_id, dt.hotel_id as dt_hotel_id, dt.commission as dt_commission,dt.cod_id as dt_cod_id,dt.sub_catalog_id as dt_sub_catalog_id,qr.reseller_id as qr_reseller_id,p.ticket_id as p_ticket_id,p.reseller_id as p_reseller_id,p.commission as p_commission FROM rattan.$MYSQL_TABLE ev left join (select * from priopassdb.distributors UNION all select * from priopassdb.distributors1) as dt on ev.hotel_id = dt.hotel_id and ev.ticketId = dt.ticket_id left join priopassdb.qr_codes qr on qr.cod_id = ev.hotel_id left join priopassdb.pricelist p on p.reseller_id = qr.reseller_id and p.ticket_id = ev.ticketId) as main)  as orders where settingtype ='No Setting') as base on base.vt_group_no = ro.vt_group_no and ro.ticketid = base.ticketid and ro.ticketpriceschedule_id = base.ticketpriceschedule_id set ro.status ='10';select row_count();"

echo "$updaterecordsforwhichnoseting"

timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "$updaterecordsforwhichnoseting" || exit 1

echo "Update order successfully for which no setting provided by client"

RESULT=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "SELECT distinct vt_group_no, ticketId FROM EEBigqueryMismatch where status = '0' and ticketpriceschedule_id != '0';") || exit 1

# Check if the query was successful
if [ $? -ne 0 ]; then
  echo "Query failed or timed out."
  exit 1
fi


# Loop through the result
while read -r LINE; do
  VT_GROUP_NO=$(echo "$LINE" | awk '{print $1}')
  TICKET_ID=$(echo "$LINE" | awk '{print $2}')
  
  # Perform actions with VT_GROUP_NO and TICKET_ID
  echo "Processing vt_group_no: $VT_GROUP_NO, ticket_id: $TICKET_ID"

  getData="SELECT vt_group_no, transaction_id, hotel_id, channel_id, ticketId, ticketpriceschedule_id, version, row_type, partner_net_price,salePrice, (case when row_type = '2' and tlc_ticketpriceschedule_id is not NULL then tlc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_res_per when row_type = '3' and tlc_ticketpriceschedule_id is not NULL then tlc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_dist_per when row_type = '4' and tlc_ticketpriceschedule_id is not NULL then tlc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_hgs_per when row_type = '1' then '100.00' else 'No_Setting_found' end) as percentage_commission, (case when row_type = '2' and tlc_ticketpriceschedule_id is not NULL then tlc_museum_net_commission when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_museum_net_commission when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_museum_net_commission when row_type = '3' and tlc_ticketpriceschedule_id is not NULL then tlc_hotel_commission_net_price when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_hotel_commission_net_price when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_hotel_commission_net_price when row_type = '4' and tlc_ticketpriceschedule_id is not NULL then tlc_hgs_commission_net_price when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_hgs_commission_net_price when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_hgs_commission_net_price when row_type = '17' and tlc_ticketpriceschedule_id is not NULL then tlc_merchant_net_commission when row_type = '17' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_merchant_net_commission when row_type = '17' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_merchant_net_commission else 'No_Setting_found' end) as commission_price, case when tlc_ticketpriceschedule_id is not NULL then tlc_comm_on_sale when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_comm_on_sale when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_comm_on_sale else 'NO SETTING_FOUND' end as commission_on_sale, case when tlc_ticketpriceschedule_id is not NULL then tlc_is_resale_percentage when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_is_resale_percentage when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_is_resale_percentage else 'NO SETTING_FOUND' end as resale_percentage FROM ( SELECT scdata.*, '----Price List Level---' AS type3, pl.ticketpriceschedule_id AS clc_ticketpriceschedule_id, pl.hotel_prepaid_commission_percentage as pl_dist_per, pl.hgs_prepaid_commission_percentage as pl_hgs_per, pl.merchant_fee_percentage as pl_mer_per, pl.resale_percentage as pl_res_per, pl.commission_on_sale_price as pl_comm_on_sale, pl.is_resale_percentage as pl_is_resale_percentage, pl.museum_net_commission as pl_museum_net_commission, pl.merchant_net_commission as pl_merchant_net_commission, pl.hotel_commission_net_price as pl_hotel_commission_net_price, pl.hgs_commission_net_price as pl_hgs_commission_net_price FROM ( SELECT tlcdata.*, '----Sub catalog Level---' AS type2, sc.catalog_id, sc.ticketpriceschedule_id AS sc_ticketpriceschedule_id, sc.resale_currency_level AS sc_resale_currency_level, sc.hotel_prepaid_commission_percentage as sc_dist_per, sc.hgs_prepaid_commission_percentage as sc_hgs_per, sc.merchant_fee_percentage as sc_mer_per, sc.resale_percentage as sc_res_per, sc.commission_on_sale_price as sc_comm_on_sale , sc.is_resale_percentage as sc_is_resale_percentage, sc.museum_net_commission as sc_museum_net_commission, sc.merchant_net_commission as sc_merchant_net_commission, sc.hotel_commission_net_price as sc_hotel_commission_net_price, sc.hgs_commission_net_price as sc_hgs_commission_net_price FROM ( SELECT vt.vt_group_no, CONCAT(vt.transaction_id, 'R') AS transaction_id, vt.order_confirm_date, vt.created_date, vt.hotel_id, vt.channel_id, vt.ticketId, vt.ticketpriceschedule_id, vt.version, vt.row_type, vt.partner_gross_price, vt.partner_net_price, maxversion.salePrice, vt.order_currency_partner_gross_price, vt.order_currency_partner_net_price, vt.supplier_gross_price, vt.supplier_net_price, vt.col2, qc.cod_id AS company_id, qc.channel_id AS company_pricelist_id, qc.sub_catalog_id AS company_sub_catalog, '---TLC LEVEL---' AS TYPE, tlc.ticketpriceschedule_id AS tlc_ticketpriceschedule_id, tlc.resale_currency_level, tlc.hotel_prepaid_commission_percentage as tlc_dist_per, tlc.hgs_prepaid_commission_percentage as tlc_hgs_per, tlc.merchant_fee_percentage as tlc_mer_per, tlc.resale_percentage as tlc_res_per, tlc.commission_on_sale_price as tlc_comm_on_sale, tlc.is_resale_percentage as tlc_is_resale_percentage, tlc.museum_net_commission as tlc_museum_net_commission, tlc.merchant_net_commission as tlc_merchant_net_commission, tlc.hotel_commission_net_price as tlc_hotel_commission_net_price, tlc.hgs_commission_net_price as tlc_hgs_commission_net_price FROM visitor_tickets vt JOIN( SELECT vt_group_no, transaction_id, row_type, max(case when row_type = '1' then partner_net_price else 0 end) as salePrice, MAX(VERSION) AS VERSION FROM visitor_tickets WHERE ticketId = '$TICKET_ID' and vt_group_no IN($VT_GROUP_NO) AND col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%' GROUP BY vt_group_no, transaction_id ) AS maxversion ON vt.vt_group_no = maxversion.vt_group_no AND vt.transaction_id = maxversion.transaction_id AND ABS(vt.version - maxversion.version) = '0' LEFT JOIN tmp.qr_codes qc ON qc.cod_id = vt.hotel_id AND qc.cashier_type = '1' LEFT JOIN tmp.ticket_level_commission tlc ON tlc.hotel_id = vt.hotel_id AND tlc.ticketpriceschedule_id = vt.ticketpriceschedule_id AND tlc.ticket_id = vt.ticketId AND tlc.deleted = '0' AND tlc.is_adjust_pricing = '1' WHERE vt.col2 != '2' ) AS tlcdata LEFT JOIN tmp.channel_level_commission sc ON tlcdata.ticketpriceschedule_id = sc.ticketpriceschedule_id AND tlcdata.ticketId = sc.ticket_id AND IF( tlcdata.company_sub_catalog = '0', 122222, tlcdata.company_sub_catalog ) = sc.catalog_id AND sc.is_adjust_pricing = '1' AND sc.deleted = '0' ) AS scdata LEFT JOIN tmp.channel_level_commission pl ON scdata.ticketpriceschedule_id = pl.ticketpriceschedule_id AND scdata.ticketId = pl.ticket_id AND scdata.channel_id = pl.channel_id AND pl.catalog_id = '0' AND pl.is_adjust_pricing = '1' AND pl.deleted = '0' ) AS shouldbe;"


  # sleep 3
  timeout $TIMEOUT_PERIOD time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -e "$getData" >> RecordsFinalDiff.csv || exit 1

  timeout $TIMEOUT_PERIOD time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -e "SELECT scdata.*, '----Price List Level---' AS type3, pl.ticketpriceschedule_id AS clc_ticketpriceschedule_id, pl.hotel_prepaid_commission_percentage as pl_dist_per, pl.hgs_prepaid_commission_percentage as pl_hgs_per, pl.merchant_fee_percentage as pl_mer_per, pl.resale_percentage as pl_res_per, pl.commission_on_sale_price as pl_comm_on_sale, pl.is_resale_percentage as pl_is_resale_percentage, pl.museum_net_commission as pl_museum_net_commission, pl.merchant_net_commission as pl_merchant_net_commission, pl.hotel_commission_net_price as pl_hotel_commission_net_price, pl.hgs_commission_net_price as pl_hgs_commission_net_price FROM ( SELECT tlcdata.*, '----Sub catalog Level---' AS type2, sc.catalog_id, sc.ticketpriceschedule_id AS sc_ticketpriceschedule_id, sc.resale_currency_level AS sc_resale_currency_level, sc.hotel_prepaid_commission_percentage as sc_dist_per, sc.hgs_prepaid_commission_percentage as sc_hgs_per, sc.merchant_fee_percentage as sc_mer_per, sc.resale_percentage as sc_res_per, sc.commission_on_sale_price as sc_comm_on_sale , sc.is_resale_percentage as sc_is_resale_percentage, sc.museum_net_commission as sc_museum_net_commission, sc.merchant_net_commission as sc_merchant_net_commission, sc.hotel_commission_net_price as sc_hotel_commission_net_price, sc.hgs_commission_net_price as sc_hgs_commission_net_price FROM ( SELECT vt.vt_group_no, CONCAT(vt.transaction_id, 'R') AS transaction_id, vt.order_confirm_date, vt.created_date, vt.hotel_id, vt.channel_id, vt.ticketId, vt.ticketpriceschedule_id, vt.version, vt.row_type, vt.partner_gross_price, vt.partner_net_price, maxversion.salePrice, vt.order_currency_partner_gross_price, vt.order_currency_partner_net_price, vt.supplier_gross_price, vt.supplier_net_price, vt.col2, qc.cod_id AS company_id, qc.channel_id AS company_pricelist_id, qc.sub_catalog_id AS company_sub_catalog, '---TLC LEVEL---' AS TYPE, tlc.ticketpriceschedule_id AS tlc_ticketpriceschedule_id, tlc.resale_currency_level, tlc.hotel_prepaid_commission_percentage as tlc_dist_per, tlc.hgs_prepaid_commission_percentage as tlc_hgs_per, tlc.merchant_fee_percentage as tlc_mer_per, tlc.resale_percentage as tlc_res_per, tlc.commission_on_sale_price as tlc_comm_on_sale, tlc.is_resale_percentage as tlc_is_resale_percentage, tlc.museum_net_commission as tlc_museum_net_commission, tlc.merchant_net_commission as tlc_merchant_net_commission, tlc.hotel_commission_net_price as tlc_hotel_commission_net_price, tlc.hgs_commission_net_price as tlc_hgs_commission_net_price FROM visitor_tickets vt JOIN( SELECT vt_group_no, transaction_id, row_type, max(case when row_type = '1' then partner_net_price else 0 end) as salePrice, MAX(VERSION) AS VERSION FROM visitor_tickets WHERE ticketId = '$TICKET_ID' and vt_group_no IN($VT_GROUP_NO) AND col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%' GROUP BY vt_group_no, transaction_id ) AS maxversion ON vt.vt_group_no = maxversion.vt_group_no AND vt.transaction_id = maxversion.transaction_id AND ABS(vt.version - maxversion.version) = '0' LEFT JOIN tmp.qr_codes qc ON qc.cod_id = vt.hotel_id AND qc.cashier_type = '1' LEFT JOIN tmp.ticket_level_commission tlc ON tlc.hotel_id = vt.hotel_id AND tlc.ticketpriceschedule_id = vt.ticketpriceschedule_id AND tlc.ticket_id = vt.ticketId AND tlc.deleted = '0' AND tlc.is_adjust_pricing = '1' WHERE vt.col2 != '2' ) AS tlcdata LEFT JOIN tmp.channel_level_commission sc ON tlcdata.ticketpriceschedule_id = sc.ticketpriceschedule_id AND tlcdata.ticketId = sc.ticket_id AND IF( tlcdata.company_sub_catalog = '0', 122222, tlcdata.company_sub_catalog ) = sc.catalog_id AND sc.is_adjust_pricing = '1' AND sc.deleted = '0' ) AS scdata LEFT JOIN tmp.channel_level_commission pl ON scdata.ticketpriceschedule_id = pl.ticketpriceschedule_id AND scdata.ticketId = pl.ticket_id AND scdata.channel_id = pl.channel_id AND pl.catalog_id = '0' AND pl.is_adjust_pricing = '1' AND pl.deleted = '0'" >> RecordsFinalDiff1.csv || exit 1
    # Add your logic here
  # Example: Call another script or function
  # ./process_ticket.sh "$VT_GROUP_NO" "$TICKET_ID"
  sleep 2

done <<< "$RESULT"