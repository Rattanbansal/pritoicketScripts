#!/bin/bash

# Start time
start_time=$(date +%s)
set -e  # Exit immediately if any command exits with a non-zero status
rm -f RecordsFinalDiff.csv
rm -f RecordsFinalDiff1.csv

# echo "vt_group_no,channel_level_commission_id,channel_id,catalog_id,ticket_id,ticketpriceschedule_id,last_modified_at,type" > primarycommissionsetting.csv

rm -f primarycommissionsetting.csv

# MYSQL_HOST="10.10.10.19"
# MYSQL_USER="pip"
# MYSQL_PASSWORD="pip2024##"
# MYSQL_DB="rattan"

mysqlHost="prodrds.prioticket.com"
mysqlUser=pipeuser
mysqlPassword=d4fb46eccNRAL
mysqlDatabase="prioprodrds"

source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"
DB_NAME='rattan'
from_date=$1
to_date=$2
TIMEOUT_PERIOD=450
TIMEOUT_PERIODLIVE=45

BQ_QUERY_FILE="bq_query.sql"
OUTPUT_FILE="bq_output.csv"
MYSQL_TABLE="EEBigqueryMismatch"
startDate="$from_date 00:00:01"
endDate="$to_date 23:59:59"

echo $startDate
echo $endDate

read rattan



rm -f $OUTPUT_FILE

BQ_QUERY_FILE="WITH modeventcontent AS( SELECT *, ROW_NUMBER() OVER(PARTITION BY mec_id ORDER BY last_modified_at DESC) AS rn FROM prioticket-reporting.prio_olap.modeventcontent), mec AS ( SELECT mec_id FROM modeventcontent WHERE reseller_id =541 AND rn=1 AND deleted ='0'), channellevelcommission AS ( SELECT *, ROW_NUMBER() OVER(PARTITION BY channel_id, catalog_id, ticket_id, ticketpriceschedule_id ORDER BY resale_currency_level DESC, last_modified_at DESC) AS rn FROM prio_olap.channel_level_commission WHERE deleted = 0 and hgs_postpaid_commission_percentage != 44.44), finalclc AS ( SELECT * FROM channellevelcommission WHERE rn = 1 AND is_adjust_pricing = 1), qrcodes AS ( SELECT *, ROW_NUMBER() OVER(PARTITION BY cod_id ORDER BY last_modified_at DESC) AS rn FROM prio_olap.qr_codes WHERE cashier_type = '1'), finalqc AS ( SELECT * FROM qrcodes WHERE rn = 1), ticketlevelcommission AS ( SELECT *, ROW_NUMBER() OVER(PARTITION BY hotel_id, ticket_id, ticketpriceschedule_id ORDER BY resale_currency_level DESC, last_modified_at DESC) AS rn FROM prio_olap.ticket_level_commission WHERE deleted = 0 and hgs_postpaid_commission_percentage != 44.44), finaltlc AS ( SELECT * FROM ticketlevelcommission WHERE rn = 1 AND is_adjust_pricing = 1), visitorTickets AS ( SELECT *, ROW_NUMBER() OVER(PARTITION BY id ORDER BY last_modified_at DESC, IFNULL(version,'1') DESC) AS rn FROM prio_olap.financial_transactions), orderId AS ( SELECT DISTINCT vt_group_no FROM visitorTickets WHERE last_modified_at BETWEEN '$startDate' AND '$endDate' and order_confirm_date BETWEEN '$startDate' AND '$endDate' AND ticketId IN ( SELECT DISTINCT mec_id FROM mec)), finalRecords AS ( SELECT * FROM visitorTickets WHERE vt_group_no IN ( SELECT vt_group_no FROM orderId) AND rn = 1 AND col2 != 2), prepaidTickets AS ( SELECT *, ROW_NUMBER() OVER(PARTITION BY prepaid_ticket_id ORDER BY last_modified_at DESC, IFNULL(version,'1') DESC ) AS rn FROM prio_olap.scan_report), orderIdPT AS ( SELECT DISTINCT visitor_group_no FROM prepaidTickets WHERE last_modified_at BETWEEN '$startDate' AND '$endDate' and order_confirm_date BETWEEN '$startDate' AND '$endDate'), finalRecordsPT AS ( SELECT * FROM prepaidTickets WHERE visitor_group_no IN ( SELECT visitor_group_no FROM orderIdPT) AND rn = 1), vtFinalData AS ( SELECT vt_group_no, CONCAT(transaction_id, 'R') AS transaction_id, MAX(hotel_id) AS hotel_id, MAX(hotel_name) AS hotel_name, MAX(reseller_id) AS reseller_id, max(channel_id) as channel_id_vt, MAX(reseller_name) AS reseller_name, MAX(ticketId) AS ticket_id, MAX(ticketpriceschedule_id) AS ticketpriceschedule_id, version, SUM(CASE WHEN row_type = 1 THEN partner_net_price ELSE 0 END ) AS saleprice, SUM(CASE WHEN row_type = 2 THEN partner_net_price ELSE 0 END ) AS purchaseprice, SUM(CASE WHEN row_type = 3 THEN partner_net_price ELSE 0 END ) AS distributorcommission, SUM(CASE WHEN row_type = 4 THEN partner_net_price ELSE 0 END ) AS hgscommission, SUM(CASE WHEN row_type = 17 THEN partner_net_price ELSE 0 END ) AS merchantcommission, MAX(order_confirm_date) AS order_confirm_date FROM finalRecords WHERE row_type IN (1, 2, 3, 4, 17) GROUP BY vt_group_no, transaction_id, version), getpricestting AS ( SELECT vt.*, qc.cod_id, qc.channel_id, qc.sub_catalog_id, tlc.ticket_net_price AS tlcsaleprice, tlc.museum_net_commission AS tlcmuseumfee, tlc.merchant_net_commission AS tlcmerhantfee, tlc.hotel_commission_net_price AS tlchotelfee, tlc.hgs_commission_net_price AS tlchgsfee, tlc.last_modified_at AS tlcmodified, tlc.commission_on_sale_price AS tlc_commission_on_sale, tlc.is_resale_percentage AS tlc_is_resale_percentage, tlc.hotel_prepaid_commission_percentage AS tlc_hotel_per, tlc.resale_percentage AS tlc_resale_per, catalog.ticket_net_price AS catalogsaleprice, catalog.museum_net_commission AS catalogmuseumfee, catalog.merchant_net_commission AS catalogmerchantfee, catalog.hotel_commission_net_price AS cataloghotelfee, catalog.hgs_commission_net_price AS cataloghgsfee, catalog.last_modified_at AS catalog_modified, catalog.commission_on_sale_price AS catalog_commission_on_sale, catalog.is_resale_percentage AS catalog_is_resale_percentage, catalog.hotel_prepaid_commission_percentage AS catalog_hotel_per, catalog.resale_percentage AS catalog_resale_per, clc.ticket_net_price AS clcsaleprice, clc.museum_net_commission AS clcmuseumfee, clc.merchant_net_commission AS clcmerchantfee, clc.hotel_commission_net_price AS clchotelfee, clc.hgs_commission_net_price AS clchgsfee, clc.last_modified_at AS clcmodified, clc.commission_on_sale_price AS clc_commission_on_sale, clc.is_resale_percentage AS clc_is_resale_percentage, clc.hotel_prepaid_commission_percentage AS clc_hotel_per, clc.resale_percentage AS clc_resale_per FROM vtFinalData vt LEFT JOIN finalqc qc ON vt.hotel_id = qc.cod_id LEFT JOIN finaltlc tlc ON vt.hotel_id = tlc.hotel_id AND vt.ticket_id = tlc.ticket_id AND vt.ticketpriceschedule_id = tlc.ticketpriceschedule_id LEFT JOIN finalclc catalog ON catalog.catalog_id = IF (qc.sub_catalog_id > 111, qc.sub_catalog_id, 111) AND catalog.ticket_id = vt.ticket_id AND catalog.ticketpriceschedule_id = vt.ticketpriceschedule_id LEFT JOIN finalclc clc ON clc.channel_id = qc.channel_id AND clc.ticket_id = vt.ticket_id AND clc.ticketpriceschedule_id = vt.ticketpriceschedule_id), mismatchescalculate AS ( SELECT vt_group_no, transaction_id, hotel_id, hotel_name, reseller_id, channel_id_vt, reseller_name, ticket_id, ticketpriceschedule_id, version, order_confirm_date, saleprice, purchaseprice, merchantcommission, distributorcommission, hgscommission, CASE WHEN tlcsaleprice IS NOT NULL THEN tlcsaleprice WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NOT NULL THEN catalogsaleprice WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NULL AND clcsaleprice IS NOT NULL THEN clcsaleprice ELSE 111 END AS salepricesetting, CASE WHEN tlcsaleprice IS NOT NULL THEN tlcmuseumfee WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NOT NULL THEN catalogmuseumfee WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NULL AND clcsaleprice IS NOT NULL THEN clcmuseumfee ELSE 111 END AS museumfeesetting, CASE WHEN tlcsaleprice IS NOT NULL THEN tlcmerhantfee WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NOT NULL THEN catalogmerchantfee WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NULL AND clcsaleprice IS NOT NULL THEN clcmerchantfee ELSE 111 END AS merchantfeesetting, CASE WHEN tlcsaleprice IS NOT NULL THEN tlchotelfee WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NOT NULL THEN cataloghotelfee WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NULL AND clcsaleprice IS NOT NULL THEN clchotelfee ELSE 111 END AS hotelfeesetting, CASE WHEN tlcsaleprice IS NOT NULL THEN tlchgsfee WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NOT NULL THEN cataloghgsfee WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NULL AND clcsaleprice IS NOT NULL THEN clchgsfee ELSE 111 END AS hgsfeesetting, CASE WHEN tlcsaleprice IS NOT NULL THEN tlcmodified WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NOT NULL THEN catalog_modified WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NULL AND clcsaleprice IS NOT NULL THEN clcmodified ELSE '2022-02-22 22:22:22' END AS modifiedshouldbe, CASE WHEN tlcsaleprice IS NOT NULL THEN tlc_commission_on_sale WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NOT NULL THEN catalog_commission_on_sale WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NULL AND clcsaleprice IS NOT NULL THEN clc_commission_on_sale ELSE 111 END AS commission_on_sale, CASE WHEN tlcsaleprice IS NOT NULL THEN tlc_is_resale_percentage WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NOT NULL THEN catalog_is_resale_percentage WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NULL AND clcsaleprice IS NOT NULL THEN clc_is_resale_percentage ELSE 111 END AS is_resale_percentage, CASE WHEN tlcsaleprice IS NOT NULL THEN tlc_hotel_per WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NOT NULL THEN catalog_hotel_per WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NULL AND clcsaleprice IS NOT NULL THEN clc_hotel_per ELSE 111 END AS hotel_percentage, CASE WHEN tlcsaleprice IS NOT NULL THEN tlc_resale_per WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NOT NULL THEN catalog_resale_per WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NULL AND clcsaleprice IS NOT NULL THEN clc_resale_per ELSE 111 END AS resale_percentage, CASE WHEN tlcsaleprice IS NOT NULL THEN 'tlcsetting' WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NOT NULL THEN 'catalogsetting' WHEN tlcsaleprice IS NULL AND catalogsaleprice IS NULL AND clcsaleprice IS NOT NULL THEN 'clcsetting' ELSE 'Nosetting' END AS pricinglevel FROM getpricestting), mismatches AS ( SELECT vt_group_no, transaction_id, hotel_id, hotel_name, reseller_id, channel_id_vt, reseller_name, ticket_id, ticketpriceschedule_id, version, order_confirm_date, saleprice, salepricesetting as salepriceshouldbe, purchaseprice, case when is_resale_percentage = 1 then saleprice*resale_percentage/100 else museumfeesetting end as museumfeeshouldbe, merchantcommission, merchantfeesetting as merchantfeeshouldbe, distributorcommission, case when commission_on_sale = 1 then saleprice*hotel_percentage/100 else hotelfeesetting end as hotelfeeshouldbe, hgscommission, hgsfeesetting as hgsfeeshouldbe, pricinglevel, modifiedshouldbe, commission_on_sale, is_resale_percentage, hotel_percentage, resale_percentage FROM mismatchescalculate) SELECT vt_group_no, transaction_id,order_confirm_date,distributorcommission, hotelfeeshouldbe,hotel_id, ticket_id,ticketpriceschedule_id,channel_id_vt as channel_id, reseller_id, 0 as status FROM mismatches WHERE pricinglevel = 'Nosetting' OR ABS(CAST(distributorcommission AS float64)-(hotelfeeshouldbe)) > 0.03"

# Step 2: Run BigQuery Command
echo "Running BigQuery Query..."

gcloud config set project prioticket-reporting


bq query --use_legacy_sql=False --max_rows=1000000 --format=csv \
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
    vt_group_no VARCHAR(255),
    transaction_id VARCHAR(255),
    order_confirm_date VARCHAR(255),
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
(vt_group_no, transaction_id,order_confirm_date, salePrice, otherPrice, hotel_id, ticketId, ticketpriceschedule_id, channel_id, reseller_id, status);
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

  if [[ $VT_GROUP_NO == "" ]]; then
    break
  fi

  getData="SELECT vt_group_no, transaction_id, hotel_id, channel_id, ticketId, ticketpriceschedule_id, version, row_type, partner_net_price,salePrice, (case when row_type = '2' and tlc_ticketpriceschedule_id is not NULL then tlc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_res_per when row_type = '3' and tlc_ticketpriceschedule_id is not NULL then tlc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_dist_per when row_type = '4' and tlc_ticketpriceschedule_id is not NULL then tlc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_hgs_per when row_type = '1' then '100.00' else 'No_Setting_found' end) as percentage_commission, (case when row_type = '2' and tlc_ticketpriceschedule_id is not NULL then tlc_museum_net_commission when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_museum_net_commission when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_museum_net_commission when row_type = '3' and tlc_ticketpriceschedule_id is not NULL then tlc_hotel_commission_net_price when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_hotel_commission_net_price when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_hotel_commission_net_price when row_type = '4' and tlc_ticketpriceschedule_id is not NULL then tlc_hgs_commission_net_price when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_hgs_commission_net_price when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_hgs_commission_net_price when row_type = '17' and tlc_ticketpriceschedule_id is not NULL then tlc_merchant_net_commission when row_type = '17' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_merchant_net_commission when row_type = '17' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_merchant_net_commission else 'No_Setting_found' end) as commission_price, case when tlc_ticketpriceschedule_id is not NULL then tlc_comm_on_sale when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_comm_on_sale when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_comm_on_sale else 'NO SETTING_FOUND' end as commission_on_sale, case when tlc_ticketpriceschedule_id is not NULL then tlc_is_resale_percentage when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_is_resale_percentage when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_is_resale_percentage else 'NO SETTING_FOUND' end as resale_percentage FROM ( SELECT scdata.*, '----Price List Level---' AS type3, pl.ticketpriceschedule_id AS clc_ticketpriceschedule_id, pl.hotel_prepaid_commission_percentage as pl_dist_per, pl.hgs_prepaid_commission_percentage as pl_hgs_per, pl.merchant_fee_percentage as pl_mer_per, pl.resale_percentage as pl_res_per, pl.commission_on_sale_price as pl_comm_on_sale, pl.is_resale_percentage as pl_is_resale_percentage, pl.museum_net_commission as pl_museum_net_commission, pl.merchant_net_commission as pl_merchant_net_commission, pl.hotel_commission_net_price as pl_hotel_commission_net_price, pl.hgs_commission_net_price as pl_hgs_commission_net_price FROM ( SELECT tlcdata.*, '----Sub catalog Level---' AS type2, sc.catalog_id, sc.ticketpriceschedule_id AS sc_ticketpriceschedule_id, sc.resale_currency_level AS sc_resale_currency_level, sc.hotel_prepaid_commission_percentage as sc_dist_per, sc.hgs_prepaid_commission_percentage as sc_hgs_per, sc.merchant_fee_percentage as sc_mer_per, sc.resale_percentage as sc_res_per, sc.commission_on_sale_price as sc_comm_on_sale , sc.is_resale_percentage as sc_is_resale_percentage, sc.museum_net_commission as sc_museum_net_commission, sc.merchant_net_commission as sc_merchant_net_commission, sc.hotel_commission_net_price as sc_hotel_commission_net_price, sc.hgs_commission_net_price as sc_hgs_commission_net_price FROM ( SELECT vt.vt_group_no, CONCAT(vt.transaction_id, 'R') AS transaction_id, vt.order_confirm_date, vt.created_date, vt.hotel_id, vt.channel_id, vt.ticketId, vt.ticketpriceschedule_id, vt.version, vt.row_type, vt.partner_gross_price, vt.partner_net_price, maxversion.salePrice, vt.order_currency_partner_gross_price, vt.order_currency_partner_net_price, vt.supplier_gross_price, vt.supplier_net_price, vt.col2, qc.cod_id AS company_id, qc.channel_id AS company_pricelist_id, qc.sub_catalog_id AS company_sub_catalog, '---TLC LEVEL---' AS TYPE, tlc.ticketpriceschedule_id AS tlc_ticketpriceschedule_id, tlc.resale_currency_level, tlc.hotel_prepaid_commission_percentage as tlc_dist_per, tlc.hgs_prepaid_commission_percentage as tlc_hgs_per, tlc.merchant_fee_percentage as tlc_mer_per, tlc.resale_percentage as tlc_res_per, tlc.commission_on_sale_price as tlc_comm_on_sale, tlc.is_resale_percentage as tlc_is_resale_percentage, tlc.museum_net_commission as tlc_museum_net_commission, tlc.merchant_net_commission as tlc_merchant_net_commission, tlc.hotel_commission_net_price as tlc_hotel_commission_net_price, tlc.hgs_commission_net_price as tlc_hgs_commission_net_price FROM visitor_tickets vt JOIN( SELECT vt_group_no, transaction_id, row_type, max(case when row_type = '1' then partner_net_price else 0 end) as salePrice, MAX(VERSION) AS VERSION FROM visitor_tickets WHERE ticketId = '$TICKET_ID' and vt_group_no IN($VT_GROUP_NO) AND col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%' GROUP BY vt_group_no, transaction_id ) AS maxversion ON vt.vt_group_no = maxversion.vt_group_no AND vt.transaction_id = maxversion.transaction_id AND ABS(vt.version - maxversion.version) = '0' LEFT JOIN tmp.qr_codes qc ON qc.cod_id = vt.hotel_id AND qc.cashier_type = '1' LEFT JOIN tmp.ticket_level_commission tlc ON tlc.hotel_id = vt.hotel_id AND tlc.ticketpriceschedule_id = vt.ticketpriceschedule_id AND tlc.ticket_id = vt.ticketId AND tlc.deleted = '0' AND tlc.is_adjust_pricing = '1' WHERE vt.col2 != '2' ) AS tlcdata LEFT JOIN tmp.channel_level_commission sc ON tlcdata.ticketpriceschedule_id = sc.ticketpriceschedule_id AND tlcdata.ticketId = sc.ticket_id AND IF( tlcdata.company_sub_catalog = '0', 122222, tlcdata.company_sub_catalog ) = sc.catalog_id AND sc.is_adjust_pricing = '1' AND sc.deleted = '0' ) AS scdata LEFT JOIN tmp.channel_level_commission pl ON scdata.ticketpriceschedule_id = pl.ticketpriceschedule_id AND scdata.ticketId = pl.ticket_id AND scdata.channel_id = pl.channel_id AND pl.catalog_id = '0' AND pl.is_adjust_pricing = '1' AND pl.deleted = '0' ) AS shouldbe;"


  # sleep 3
  timeout $TIMEOUT_PERIODLIVE time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -e "$getData" >> RecordsFinalDiff.csv || exit 1

  timeout $TIMEOUT_PERIODLIVE time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -e "SELECT scdata.*, '----Price List Level---' AS type3, pl.ticketpriceschedule_id AS clc_ticketpriceschedule_id, pl.hotel_prepaid_commission_percentage as pl_dist_per, pl.hgs_prepaid_commission_percentage as pl_hgs_per, pl.merchant_fee_percentage as pl_mer_per, pl.resale_percentage as pl_res_per, pl.commission_on_sale_price as pl_comm_on_sale, pl.is_resale_percentage as pl_is_resale_percentage, pl.museum_net_commission as pl_museum_net_commission, pl.merchant_net_commission as pl_merchant_net_commission, pl.hotel_commission_net_price as pl_hotel_commission_net_price, pl.hgs_commission_net_price as pl_hgs_commission_net_price FROM ( SELECT tlcdata.*, '----Sub catalog Level---' AS type2, sc.catalog_id, sc.ticketpriceschedule_id AS sc_ticketpriceschedule_id, sc.resale_currency_level AS sc_resale_currency_level, sc.hotel_prepaid_commission_percentage as sc_dist_per, sc.hgs_prepaid_commission_percentage as sc_hgs_per, sc.merchant_fee_percentage as sc_mer_per, sc.resale_percentage as sc_res_per, sc.commission_on_sale_price as sc_comm_on_sale , sc.is_resale_percentage as sc_is_resale_percentage, sc.museum_net_commission as sc_museum_net_commission, sc.merchant_net_commission as sc_merchant_net_commission, sc.hotel_commission_net_price as sc_hotel_commission_net_price, sc.hgs_commission_net_price as sc_hgs_commission_net_price FROM ( SELECT vt.vt_group_no, CONCAT(vt.transaction_id, 'R') AS transaction_id, vt.order_confirm_date, vt.created_date, vt.hotel_id, vt.channel_id, vt.ticketId, vt.ticketpriceschedule_id, vt.version, vt.row_type, vt.partner_gross_price, vt.partner_net_price, maxversion.salePrice, vt.order_currency_partner_gross_price, vt.order_currency_partner_net_price, vt.supplier_gross_price, vt.supplier_net_price, vt.col2, qc.cod_id AS company_id, qc.channel_id AS company_pricelist_id, qc.sub_catalog_id AS company_sub_catalog, '---TLC LEVEL---' AS TYPE, tlc.ticketpriceschedule_id AS tlc_ticketpriceschedule_id, tlc.resale_currency_level, tlc.hotel_prepaid_commission_percentage as tlc_dist_per, tlc.hgs_prepaid_commission_percentage as tlc_hgs_per, tlc.merchant_fee_percentage as tlc_mer_per, tlc.resale_percentage as tlc_res_per, tlc.commission_on_sale_price as tlc_comm_on_sale, tlc.is_resale_percentage as tlc_is_resale_percentage, tlc.museum_net_commission as tlc_museum_net_commission, tlc.merchant_net_commission as tlc_merchant_net_commission, tlc.hotel_commission_net_price as tlc_hotel_commission_net_price, tlc.hgs_commission_net_price as tlc_hgs_commission_net_price FROM visitor_tickets vt JOIN( SELECT vt_group_no, transaction_id, row_type, max(case when row_type = '1' then partner_net_price else 0 end) as salePrice, MAX(VERSION) AS VERSION FROM visitor_tickets WHERE ticketId = '$TICKET_ID' and vt_group_no IN($VT_GROUP_NO) AND col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%' GROUP BY vt_group_no, transaction_id ) AS maxversion ON vt.vt_group_no = maxversion.vt_group_no AND vt.transaction_id = maxversion.transaction_id AND ABS(vt.version - maxversion.version) = '0' LEFT JOIN tmp.qr_codes qc ON qc.cod_id = vt.hotel_id AND qc.cashier_type = '1' LEFT JOIN tmp.ticket_level_commission tlc ON tlc.hotel_id = vt.hotel_id AND tlc.ticketpriceschedule_id = vt.ticketpriceschedule_id AND tlc.ticket_id = vt.ticketId AND tlc.deleted = '0' AND tlc.is_adjust_pricing = '1' WHERE vt.col2 != '2' ) AS tlcdata LEFT JOIN tmp.channel_level_commission sc ON tlcdata.ticketpriceschedule_id = sc.ticketpriceschedule_id AND tlcdata.ticketId = sc.ticket_id AND IF( tlcdata.company_sub_catalog = '0', 122222, tlcdata.company_sub_catalog ) = sc.catalog_id AND sc.is_adjust_pricing = '1' AND sc.deleted = '0' ) AS scdata LEFT JOIN tmp.channel_level_commission pl ON scdata.ticketpriceschedule_id = pl.ticketpriceschedule_id AND scdata.ticketId = pl.ticket_id AND scdata.channel_id = pl.channel_id AND pl.catalog_id = '0' AND pl.is_adjust_pricing = '1' AND pl.deleted = '0'" >> RecordsFinalDiff1.csv || exit 1


    # Add your logic here
  # Example: Call another script or function
  # ./process_ticket.sh "$VT_GROUP_NO" "$TICKET_ID"
  sleep 2

done <<< "$RESULT"


timeout $TIMEOUT_PERIODLIVE time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "select cod_id, company, channel_id, sub_catalog_id, cashier_type from priopassdb.qr_codes where cod_id in (SELECT DISTINCT(hotel_id) FROM rattan.EEBigqueryMismatch where status = '10' and reseller_id = '541') and sub_catalog_id > '0';" || exit 1 # list of distributors which are linked to catalog

timeout $TIMEOUT_PERIODLIVE time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "select cod_id, company, channel_id, sub_catalog_id, cashier_type from priopassdb.qr_codes where cod_id in (SELECT DISTINCT(hotel_id) FROM rattan.EEBigqueryMismatch where status = '10' and reseller_id = '541') and sub_catalog_id < '2';" || exit 1 # list of distributors which are not linked to catalog

timeout $TIMEOUT_PERIODLIVE time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "select * from rattan.EEBigqueryMismatch where hotel_id in (select distinct cod_id from priopassdb.qr_codes where cod_id in (SELECT DISTINCT(hotel_id) FROM rattan.EEBigqueryMismatch where status = '10' and reseller_id = '541') and sub_catalog_id > '0') and ticketId > '0' and status = '10' and ticketpriceschedule_id > '0';" || exit 1 #list of products which linked to sub catalog having status = 10 but need to check why commission goes wrong and not updated by us

orderstatuschange=$(timeout $TIMEOUT_PERIODLIVE time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "select DISTINCT vt_group_no from rattan.EEBigqueryMismatch where hotel_id in (select distinct cod_id from priopassdb.qr_codes where cod_id in (SELECT DISTINCT(hotel_id) FROM rattan.EEBigqueryMismatch where status = '10' and reseller_id = '541') and sub_catalog_id > '0') and ticketId > '0' and status = '10' and ticketpriceschedule_id > '0';") || exit 1

for orderiid in ${orderstatuschange}
do

timeout $TIMEOUT_PERIODLIVE time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "update rattan.EEBigqueryMismatch set status = '0' where vt_group_no = '$orderiid';select ROW_COUNT();"

done


RESULTNEW=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "SELECT vt_group_no, hotel_id, ticketId, ticketpriceschedule_id FROM EEBigqueryMismatch where status = '0' and ticketpriceschedule_id != '0' group by vt_group_no, hotel_id, ticketId, ticketpriceschedule_id") || exit 1

# Ensure RESULTNEW is not empty
if [[ -z "$RESULTNEW" ]]; then
  echo "No results found. Exiting."
  exit 1
fi

source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "PrioticketLivePriomaryroPipe"
DB_NAME='priopassdb'
echo "Verify information and press enter to continue....................>>>>>>>>>>"
echo $DB_HOST
echo $DB_PORT
# read rattan

# Loop through the result
while IFS= read -r LINE; do
  VT_GROUP_NO=$(echo "$LINE" | awk '{print $1}')
  HOTEL_ID=$(echo "$LINE" | awk '{print $2}')
  TICKET_ID=$(echo "$LINE" | awk '{print $3}')
  TICKETPRICESCHEDULE_ID=$(echo "$LINE" | awk '{print $4}')
  
  # Perform actions with VT_GROUP_NO and TICKET_ID
  echo "Processing vt_group_no: $VT_GROUP_NO,hotel_id: $HOTEL_ID, ticket_id: $TICKET_ID, ticketpriceschedule_id: $TICKETPRICESCHEDULE_ID"

  if [[ $VT_GROUP_NO == "" ]]; then
    break
  fi

  getCatalogData="SELECT '$VT_GROUP_NO' as vt_group_no,channel_level_commission_id, channel_id, catalog_id, ticket_id, ticketpriceschedule_id, last_modified_at, '2' as type FROM channel_level_commission where catalog_id in (select sub_catalog_id from qr_codes where cod_id = '$HOTEL_ID' and sub_catalog_id > '2') and ticketpriceschedule_id = '$TICKETPRICESCHEDULE_ID' and deleted = '0' and is_adjust_pricing = '1';"

  getCLCData="SELECT '$VT_GROUP_NO' as vt_group_no,channel_level_commission_id, channel_id, catalog_id, ticket_id, ticketpriceschedule_id, last_modified_at, '3' as type FROM channel_level_commission where channel_id in (select channel_id from qr_codes where cod_id = '$HOTEL_ID') and ticketpriceschedule_id = '$TICKETPRICESCHEDULE_ID' and deleted = '0' and is_adjust_pricing = '1';"

  getTLCData="select '$VT_GROUP_NO' as vt_group_no,ticket_level_commission_id, hotel_id,'0' as catalog_id, ticket_id, ticketpriceschedule_id, last_modified_at, '1' as type from ticket_level_commission where ticketpriceschedule_id = '411331' and hotel_id = '44587' and deleted = '0' and is_adjust_pricing = '1'"

  echo "$getCatalogData"
  echo "$getCLCData"
  echo "$getTLCData"

  
  timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "$getCatalogData" >> primarycommissionsetting.csv
  sleep 1
  timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "$getCLCData" >> primarycommissionsetting.csv
  sleep 1
  timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "$getTLCData" >> primarycommissionsetting.csv
  
  sleep 2

done <<< "$RESULTNEW"
echo "--------------Started with local------------"
sleep 5
source ~/vault/vault_fetch_creds.sh
# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"
DB_NAME='rattan'
MYSQLTABLENEW='primarypricesettings'
echo "Verify information and press enter to continue....................>>>>>>>>>>"
if [[ "$DB_HOST" == "163.47.214.30" ]]; then
  echo "Host Successfully changed"
  echo "$DB_HOST"
else
  echo "Host Not changed so exiting"
  echo "$DB_HOST"
  exit 1
fi

mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "DROP TABLE IF EXISTS $MYSQLTABLENEW;"

createtable="CREATE TABLE $MYSQLTABLENEW (
  vt_group_no varchar(255) NOT NULL,
  clctlcid varchar(255) NOT NULL,
  channel_id varchar(255) NOT NULL,
  catalog_id varchar(255) NOT NULL,
  ticket_id varchar(255) NOT NULL,
  ticketpriceschedule_id varchar(255) NOT NULL,
  las_modified_at timestamp NOT NULL,
  type varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;ALTER TABLE $MYSQLTABLENEW
  ADD KEY vt (vt_group_no),
  ADD KEY ticketid (ticket_id),
  ADD KEY tps (ticketpriceschedule_id),
  ADD KEY ci (channel_id),
  ADD KEY status (catalog_id),
  ADD KEY hi (clctlcid);
COMMIT;"

mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "$createtable"

mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "SET GLOBAL local_infile = 1;"

# Read CSV and insert into MySQL
mysql --local-infile=1 -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" <<EOF
LOAD DATA LOCAL INFILE 'primarycommissionsetting.csv'
INTO TABLE $MYSQLTABLENEW
FIELDS TERMINATED BY '\t' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(vt_group_no,clctlcid,channel_id,catalog_id,ticket_id, ticketpriceschedule_id, las_modified_at, type);
EOF

if [ $? -ne 0 ]; then
    echo "MySQL data insertion failed. Exiting."
    exit 1
fi

echo "Data successfully inserted into MySQL table: $MYSQL_TABLE"

clcids=$(mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sse "SELECT group_concat(distinct(clctlcid)) FROM primarypricesettings where type in (2,3);") || exit 1

tlcids=$(mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sse "SELECT group_concat(distinct(clctlcid)) FROM primarypricesettings where type in (1);") || exit 1

if [ -z "$clcids" ]; then
  echo "VARIABLE is empty"
else

  clcliveids=$(timeout $TIMEOUT_PERIODLIVE time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"tmp" -e "select distinct channel_level_commission_id from channel_level_commission where channel_level_commission_id in ($clcids)") || exit 1
  echo "$clcids"
  echo "$clcliveids"

  tlcliveids=$(timeout $TIMEOUT_PERIODLIVE time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"tmp" -e "select distinct channel_level_commission_id from channel_level_commission where channel_level_commission_id in ($tlcids)") || exit 1
  echo "$tlcids"
  echo "$tlcliveids"

  # Find missing values
  missingclc=$(comm -23 <(echo "$clcids" | tr ',' '\n' | sort) <(echo "$clcliveids" | sort))

  missingtlc=$(comm -23 <(echo "$tlcids" | tr ',' '\n' | sort) <(echo "$tlcliveids" | sort))

  # Output result CLC
  if [ -z "$missingclc" ]; then
    echo "No values are missing."
  else
    echo "Missing values CLC: $missingclc"
  fi

  # Output result TLC
  if [ -z "$missingtlc" ]; then
    echo "No values are missing."
  else
    echo "Missing values TLC: $missingtlc"
  fi
fi
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