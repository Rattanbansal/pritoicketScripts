#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status


MYSQL_HOST="10.10.10.19"
MYSQL_USER="pip"
MYSQL_PASSWORD="pip2024##"
MYSQL_DB="priopassdb"
BQ_QUERY_FILE="bq_query.sql"
OUTPUT_FILE="bq_output.csv"
MYSQL_TABLE="bigqueryData"

rm -f $OUTPUT_FILE

BQ_QUERY_FILE="with 
vt1 as (select *,row_number() over(partition by id order by last_modified_at desc, ifnull(version,'1') desc ) as rn from prio_olap.financial_transactions where vt_group_no in( select 
 distinct vt_group_no from prio_olap.financial_transactions where last_modified_at between '2025-01-01 00:00:00' and '2025-01-16 00:00:00')),

modeventcontent as (select *,row_number() over(partition by mec_id order by last_modified_at desc) as rn from prio_olap.modeventcontent),

mec as (select mec_id from  modeventcontent where reseller_id =541 and rn=1 and deleted ='0'),

vt as (select * from vt1 where rn=1 and ticketid in(select mec_id from mec) and row_type in(1,3) and partner_net_price >0 and (ticket_title not like '%Discount%' or ticket_title not like '%Extra%' or transaction_type_name not like '%Reprice%') ),

 main as (select vt_group_no,concat(transaction_id,',') as transaction_id,max(hotel_id) as hotel_id,max(ticketid) as ticket_id,max(ticketpriceschedule_id) as ticketpriceschedule_id,max(channel_id) as channel_id, max(reseller_id) as reseller_id,
sum(case when row_type =1 then partner_net_price else 0 end) as sale_price,sum(case when row_type =3 then partner_net_price else 0 end) as Distributor_price from vt group by vt_group_no,transaction_id)

select *,round((Distributor_price/sale_price)*100,2) as commission from main"

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

mysql -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" -e "Truncate Table bigqueryData;"

mysql -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" -e "SET GLOBAL local_infile = 1;"

# Read CSV and insert into MySQL
mysql --local-infile=1 -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" <<EOF
LOAD DATA LOCAL INFILE '$OUTPUT_FILE'
INTO TABLE $MYSQL_TABLE
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(ticket_id, tps_id, hotel_id, channel_id, reseller_id);
EOF

if [ $? -ne 0 ]; then
    echo "MySQL data insertion failed. Exiting."
    exit 1
fi

echo "Data successfully inserted into MySQL table: $MYSQL_TABLE"


echo "Process completed successfully."



# CREATE TABLE bigqueryData (
#     ticket_id INT(11),
#     tps_id INT(11),
#     hotel_id INT(11),
#     channel_id INT(11),
#     reseller_id INT(11)
# );