#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status


# MYSQL_HOST="10.10.10.19"
# MYSQL_USER="pip"
# MYSQL_PASSWORD="pip2024##"
# MYSQL_DB="rattan"

source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"
DB_NAME='rattan'

BQ_QUERY_FILE="bq_query.sql"
OUTPUT_FILE="bq_output.csv"
MYSQL_TABLE="evanorders"
startdate=$1

startfrom="$startdate 00:00:01"

echo $startfrom

read rattan

rm -f $OUTPUT_FILE

BQ_QUERY_FILE="WITH
pt1 AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY prepaid_ticket_id ORDER BY last_modified_at DESC, IFNULL(version, '1') DESC) AS rn 
    FROM prioticket-reporting.prio_olap.scan_report
),
pt AS (
    SELECT * 
    FROM pt1 
    WHERE rn=1 AND deleted=0
),
mec1 AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY mec_id ORDER BY last_modified_at DESC) AS rn 
    FROM prioticket-reporting.prio_olap.modeventcontent
),
mec AS (
    SELECT * 
    FROM mec1 
    WHERE rn=1 AND deleted='0' AND reseller_id=541
)
SELECT DISTINCT visitor_group_no,ticket_id, tps_id, channel_id,hotel_id
FROM pt 
WHERE order_confirm_date >= '$startfrom' 
AND ticket_id IN (SELECT mec_id FROM mec)"

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

mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "Truncate Table evanorders;"

mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "SET GLOBAL local_infile = 1;"

# Read CSV and insert into MySQL
mysql --local-infile=1 -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" <<EOF
LOAD DATA LOCAL INFILE '$OUTPUT_FILE'
INTO TABLE $MYSQL_TABLE
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(vt_group_no,ticketId, ticketpriceschedule_id, channel_id, hotel_id);
EOF

if [ $? -ne 0 ]; then
    echo "MySQL data insertion failed. Exiting."
    exit 1
fi

echo "Data successfully inserted into MySQL table: $MYSQL_TABLE"


echo "Process completed successfully."

mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "update evanorders set channel_id = '0';"


# CREATE TABLE bigqueryData (
#     ticket_id INT(11),
#     tps_id INT(11),
#     hotel_id INT(11),
#     channel_id INT(11),
#     reseller_id INT(11)
# );

# select 

# select * from (select *,(case when qr_reseller_id = '541' and dt_hotel_id is null then 'No Setting' when qr_reseller_id != '541' and p_reseller_id is null then 'No Setting' else '' end) as status  from (SELECT ev.*,dt.ticket_id as dt_ticket_id, dt.hotel_id as dt_hotel_id, dt.commission as dt_commission,dt.cod_id as dt_cod_id,dt.sub_catalog_id as dt_sub_catalog_id,qr.reseller_id as qr_reseller_id,p.ticket_id as p_ticket_id,p.reseller_id as p_reseller_id,p.commission as p_commission FROM rattan.evanorders ev left join (select * from distributors UNION all select * from distributors1) as dt on ev.hotel_id = dt.hotel_id and ev.ticketId = dt.ticket_id left join priopassdb.qr_codes qr on qr.cod_id = ev.hotel_id left join pricelist p on p.reseller_id = qr.reseller_id and p.ticket_id = ev.ticketId) as main)  as orders where status ='No Setting'
 
# update
 
# explain update rattan.evanorders ro join (select * from (select *,(case when qr_reseller_id = '541' and dt_hotel_id is null then 'No Setting' when qr_reseller_id != '541' and p_reseller_id is null then 'No Setting' else '' end) as status  from (SELECT ev.*,dt.ticket_id as dt_ticket_id, dt.hotel_id as dt_hotel_id, dt.commission as dt_commission,dt.cod_id as dt_cod_id,dt.sub_catalog_id as dt_sub_catalog_id,qr.reseller_id as qr_reseller_id,p.ticket_id as p_ticket_id,p.reseller_id as p_reseller_id,p.commission as p_commission FROM rattan.evanorders ev left join (select * from distributors UNION all select * from distributors1) as dt on ev.hotel_id = dt.hotel_id and ev.ticketId = dt.ticket_id left join priopassdb.qr_codes qr on qr.cod_id = ev.hotel_id left join pricelist p on p.reseller_id = qr.reseller_id and p.ticket_id = ev.ticketId) as main)  as orders where status ='No Setting') as base on base.vt_group_no = ro.vt_group_no and ro.ticketid = base.ticketid and ro.ticketpriceschedule_id = base.ticketpriceschedule_id set ro.channel_id ='10';
 