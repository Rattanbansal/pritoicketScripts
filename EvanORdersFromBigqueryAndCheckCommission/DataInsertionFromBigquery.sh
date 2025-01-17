#!/bin/bash

set -e

# Source the shared credential fetcher
source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"

DB_NAME="priopassdb"
from_date=$1
to_date=$2
OUTPUT_FILE="bq_output.csv"
MYSQL_TABLE="evanevansorders"

startDate="$from_date 00:00:01"
endDate="$to_date 23:59:59"

echo $startDate
echo $endDate

read rattan

rm -f $OUTPUT_FILE

tableexist=$(time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "describe $MYSQL_TABLE" 1>/dev/null || echo "TableNotFound")

echo "table value as following: $tableexist"

# Conditional check for table existence
if [ "$tableexist" == "TableNotFound" ]; then

    echo "Table '$MYSQL_TABLE' does not exist or is empty. So Creating Table"

    CreateTABLE="CREATE TABLE IF NOT EXISTS evanevansorders (
    vt_group_no bigint NOT NULL COMMENT 'same as visitor_group_no, but saved for all the four tables',
    transaction_id bigint NOT NULL DEFAULT '0',
    hotel_id int DEFAULT NULL,
    ticket_id int NOT NULL,
    ticketpriceschedule_id int DEFAULT NULL COMMENT 'id from ticketpriceschedule table',
    channel_id int DEFAULT NULL COMMENT 'Channel id of selected channel',
    reseller_id int DEFAULT '0',
    sale_price decimal(10,2) DEFAULT '0.00',
    Distributor_price decimal(10,2) NOT NULL DEFAULT '0.00',
    commission decimal(10,2) NOT NULL DEFAULT '0.00'
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;"

    AddIndex="ALTER TABLE evanevansorders ADD INDEX(vt_group_no);ALTER TABLE evanevansorders ADD INDEX(transaction_id);ALTER TABLE evanevansorders ADD INDEX(hotel_id);ALTER TABLE evanevansorders ADD INDEX(ticket_id);ALTER TABLE evanevansorders ADD INDEX(ticketpriceschedule_id);ALTER TABLE evanevansorders ADD INDEX(reseller_id);"

    time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "$CreateTABLE" || exit 1

    time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "$AddIndex" || exit 1

fi

time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "Truncate table $MYSQL_TABLE" || exit 1

# Step 2: Run BigQuery Command
echo "Running BigQuery Query..."
gcloud config set project prioticket-reporting

BQ_QUERY_FILE="with 
vt1 as (select *,row_number() over(partition by id order by last_modified_at desc, ifnull(version,'1') desc ) as rn from prio_olap.financial_transactions where vt_group_no in( select 
 distinct vt_group_no from prio_olap.financial_transactions where last_modified_at between '$startDate' and '$endDate')),

modeventcontent as (select *,row_number() over(partition by mec_id order by last_modified_at desc) as rn from prio_olap.modeventcontent),

mec as (select mec_id from  modeventcontent where reseller_id =541 and rn=1 and deleted ='0'),

vt as (select * from vt1 where rn=1 and ticketid in(select mec_id from mec) and row_type in(1,3) and partner_net_price >0 and (ticket_title not like '%Discount%' or ticket_title not like '%Extra%' or transaction_type_name not like '%Reprice%') ),

 main as (select vt_group_no,transaction_id,max(hotel_id) as hotel_id,max(ticketid) as ticket_id,max(ticketpriceschedule_id) as ticketpriceschedule_id,max(channel_id) as channel_id, max(reseller_id) as reseller_id,
sum(case when row_type =1 then partner_net_price else 0 end) as sale_price,sum(case when row_type =3 then partner_net_price else 0 end) as Distributor_price from vt group by vt_group_no,transaction_id)

select *,round((Distributor_price/sale_price)*100,2) as commission from main"

bq query --use_legacy_sql=False --max_rows=1000000 --format=csv \
"$BQ_QUERY_FILE" > $OUTPUT_FILE || exit 1

echo "BigQuery query successful. Data saved to $OUTPUT_FILE."

# Step 3: Insert Data into MySQL
echo "Inserting data into MySQL table..."

time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "Truncate Table $MYSQL_TABLE;" || exit 1

time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "SET GLOBAL local_infile = 1;" || exit 1


# Read CSV and insert into MySQL
mysql --local-infile=1 -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" <<EOF
LOAD DATA LOCAL INFILE '$OUTPUT_FILE'
INTO TABLE $MYSQL_TABLE
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(vt_group_no, transaction_id, hotel_id, ticket_id, ticketpriceschedule_id, channel_id, reseller_id, sale_price,Distributor_price, commission);
EOF

if [ $? -ne 0 ]; then
    echo "MySQL data insertion failed. Exiting."
    exit 1
fi

echo "Data successfully inserted into MySQL table: $MYSQL_TABLE"

echo "Process completed successfully."

resellerCommissionMismatch="select * from (select vt_group_no, concat(transaction_id, 'R') as transaction_id,hotel_id, ticket_id, ticketpriceschedule_id,channel_id, reseller_id,sale_price,Distributor_price,commission,commission_should_be as client_provided_commission, case when tlc_percentage is not null then tlc_percentage when tlc_percentage is null and catalog_percentage is not null then catalog_percentage when tlc_percentage is null and catalog_percentage is null and clc_percentage is not null then clc_percentage else 111 end as percentage_from_level,case when tlc_percentage is not null then tlc_commission_on_sale when tlc_percentage is null and catalog_percentage is not null then catalog_commission_on_sale when tlc_percentage is null and catalog_percentage is null and clc_percentage is not null then clc_commission_on_sale else 11 end as commission_on_sale_from_level  from (select catalogdata.*, '---TLC DATA---' as tlc_data, tlc.hotel_prepaid_commission_percentage as tlc_percentage, tlc.commission_on_sale_price as tlc_commission_on_sale from (select clcdata.*, qc.sub_catalog_id, '---Catalog Data---' as catalog_data, catalog.hotel_prepaid_commission_percentage as catalog_percentage, catalog.commission_on_sale_price as catalog_commission_on_sale from (select base1.*,'---CLC Table--' as clc_data,clc.hotel_prepaid_commission_percentage as clc_percentage, clc.commission_on_sale_price as clc_commission_on_sale from (select * from (select r.*,'---Client Overview---' as clientsheet,p.commission as commission_should_be from evanevansorders r left join pricelist p on r.reseller_id = p.reseller_id and r.ticket_id = p.ticket_id where r.reseller_id !='541') as base) as base1 left join channel_level_commission clc on clc.channel_id = base1.channel_id and clc.ticketpriceschedule_id = base1.ticketpriceschedule_id and clc.ticket_id = base1.ticket_id and clc.is_adjust_pricing = '1' and clc.deleted = '0') as clcdata left join qr_codes qc on clcdata.hotel_id = qc.cod_id and qc.cashier_type = '1' and qc.sub_catalog_id > '111' left join channel_level_commission catalog on if(qc.sub_catalog_id > '111', qc.sub_catalog_id, '1252351') = catalog.catalog_id and clcdata.ticketpriceschedule_id = catalog.ticketpriceschedule_id and catalog.is_adjust_pricing = '1' and catalog.deleted = '0') as catalogdata left join ticket_level_commission tlc on tlc.hotel_id = catalogdata.hotel_id and tlc.ticketpriceschedule_id = catalogdata.ticketpriceschedule_id and tlc.is_adjust_pricing = '1' and tlc.deleted = '0') as final) as final1 where ABS(commission-client_provided_commission) > '0.02' or ABS(client_provided_commission-percentage_from_level) > '0.02';"

distributorCommissionMismatch="select * from (select vt_group_no, concat(transaction_id, 'R') as transaction_id,hotel_id, ticket_id, ticketpriceschedule_id,channel_id, reseller_id,sale_price,Distributor_price,commission,commission_should_be as client_provided_commission, case when tlc_percentage is not null then tlc_percentage when tlc_percentage is null and catalog_percentage is not null then catalog_percentage when tlc_percentage is null and catalog_percentage is null and clc_percentage is not null then clc_percentage else 111 end as percentage_from_level,case when tlc_percentage is not null then tlc_commission_on_sale when tlc_percentage is null and catalog_percentage is not null then catalog_commission_on_sale when tlc_percentage is null and catalog_percentage is null and clc_percentage is not null then clc_commission_on_sale else 11 end as commission_on_sale_from_level  from (select catalogdata.*, '---TLC DATA---' as tlc_data, tlc.hotel_prepaid_commission_percentage as tlc_percentage, tlc.commission_on_sale_price as tlc_commission_on_sale from (select clcdata.*, qc.sub_catalog_id, '---Catalog Data---' as catalog_data, catalog.hotel_prepaid_commission_percentage as catalog_percentage, catalog.commission_on_sale_price as catalog_commission_on_sale from (select base1.*,'---CLC Table--' as clc_data,clc.hotel_prepaid_commission_percentage as clc_percentage, clc.commission_on_sale_price as clc_commission_on_sale from (select * from (select r.*,'---Client Overview---' as clientsheet,p.commission as commission_should_be from evanevansorders r left join (select * from distributors union all select * from distributors1) p on r.hotel_id = p.hotel_id and r.ticket_id = p.ticket_id where r.reseller_id ='541') as base) as base1 left join channel_level_commission clc on clc.channel_id = base1.channel_id and clc.ticketpriceschedule_id = base1.ticketpriceschedule_id and clc.ticket_id = base1.ticket_id and clc.is_adjust_pricing = '1' and clc.deleted = '0') as clcdata left join qr_codes qc on clcdata.hotel_id = qc.cod_id and qc.cashier_type = '1' and qc.sub_catalog_id > '111' left join channel_level_commission catalog on if(qc.sub_catalog_id > '111', qc.sub_catalog_id, '1252351') = catalog.catalog_id and clcdata.ticketpriceschedule_id = catalog.ticketpriceschedule_id and catalog.is_adjust_pricing = '1' and catalog.deleted = '0') as catalogdata left join ticket_level_commission tlc on tlc.hotel_id = catalogdata.hotel_id and tlc.ticketpriceschedule_id = catalogdata.ticketpriceschedule_id and tlc.is_adjust_pricing = '1' and tlc.deleted = '0') as final) as final1 where ABS(commission-client_provided_commission) > '0.02' or ABS(client_provided_commission-percentage_from_level) > '0.02';"


time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "$resellerCommissionMismatch" > resellerMismatch.csv || exit 1

time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "$distributorCommissionMismatch" > distributorMismatch.csv || exit 1