#!/bin/bash

set -e

# Source the shared credential fetcher
source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"

DB_NAME="priopassdb"
from_date=$1
to_date=$2
OUTPUT_FILE="bigqueryReport.csv"
MYSQL_TABLE="evanevansorders"

startDate="$from_date 00:00:01"
endDate="$to_date 23:59:59"

echo $startDate
echo $endDate

read rattan


echo "Running BigQuery Query..."
gcloud config set project prioticket-reporting

BQ_QUERY_FILE="with modeventcontent as (select *,row_number() over(partition by mec_id order by last_modified_at desc) as rn from prioticket-reporting.prio_olap.modeventcontent),mec as (select mec_id from  modeventcontent where reseller_id =541 and rn=1 and deleted ='0'), channellevelcommission as (select *,row_number() over(partition by channel_id, catalog_id,ticket_id,ticketpriceschedule_id order by resale_currency_level desc, last_modified_at desc) as rn from prio_olap.channel_level_commission where deleted = 0),finalclc as (select * from channellevelcommission where rn = 1 and is_adjust_pricing = 1), qrcodes as (select *,row_number() over(partition by cod_id order by last_modified_at desc) as rn from prio_olap.qr_codes where cashier_type = '1'),finalqc as (select * from qrcodes where rn = 1),ticketlevelcommission as (select *,row_number() over(partition by hotel_id,ticket_id,ticketpriceschedule_id order by resale_currency_level desc, last_modified_at desc) as rn from prio_olap.ticket_level_commission where deleted = 0),finaltlc as (select * from ticketlevelcommission where rn = 1 and is_adjust_pricing = 1), visitorTickets as (select *,row_number() over(partition by id order by last_modified_at desc, ifnull(version,'1') desc ) as rn from prio_olap.financial_transactions), orderId as (select distinct vt_group_no from visitorTickets where last_modified_at between '$startDate' and '$endDate' and ticketId in (select distinct mec_id from mec)), finalRecords as (select * from visitorTickets where vt_group_no in (select vt_group_no from orderId) and rn = 1 and col2 != 2), prepaidTickets as (select *,row_number() over(partition by prepaid_ticket_id order by last_modified_at desc, ifnull(version,'1') desc ) as rn from prio_olap.scan_report), orderIdPT as (select distinct visitor_group_no from prepaidTickets where last_modified_at between '$startDate' and '$endDate'), finalRecordsPT as (select * from prepaidTickets where visitor_group_no in (select visitor_group_no from orderIdPT) and rn = 1), vtFinalData as  (select vt_group_no, concat(transaction_id, 'R') as transaction_id,max(hotel_id) as hotel_id, max(hotel_name) as hotel_name, max(reseller_id) as reseller_id, max(reseller_name) as reseller_name,max(ticketId) as ticket_id, max(ticketpriceschedule_id) as ticketpriceschedule_id,version, sum(case when row_type = 1 then partner_net_price else 0 end) as saleprice, sum(case when row_type = 2 then partner_net_price else 0 end) as purchaseprice,sum(case when row_type = 3 then partner_net_price else 0 end) as distributorcommission,sum(case when row_type = 4 then partner_net_price else 0 end) as hgscommission,sum(case when row_type = 17 then partner_net_price else 0 end) as merchantcommission, max(order_confirm_date) as order_confirm_date from finalRecords where row_type in (1,2,3,4,17) group by vt_group_no, transaction_id,version), getpricestting as (select vt.*, qc.cod_id, qc.channel_id, qc.sub_catalog_id, tlc.ticket_net_price as tlcsaleprice, tlc.museum_net_commission as tlcmuseumfee, tlc.merchant_net_commission as tlcmerhantfee, tlc.hotel_commission_net_price as tlchotelfee,tlc.hgs_commission_net_price as tlchgsfee, tlc.last_modified_at as tlcmodified,catalog.ticket_net_price as catalogsaleprice, catalog.museum_net_commission as catalogmuseumfee, catalog.merchant_net_commission as catalogmerchantfee, catalog.hotel_commission_net_price as cataloghotelfee, catalog.hgs_commission_net_price as cataloghgsfee, catalog.last_modified_at as catalog_modified,clc.ticket_net_price as clcsaleprice, clc.museum_net_commission as clcmuseumfee, clc.merchant_net_commission as clcmerchantfee, clc.hotel_commission_net_price as clchotelfee, clc.hgs_commission_net_price as clchgsfee, clc.last_modified_at as clcmodified from vtFinalData vt left join finalqc qc on vt.hotel_id = qc.cod_id left join finaltlc tlc on vt.hotel_id = tlc.hotel_id and vt.ticket_id = tlc.ticket_id and vt.ticketpriceschedule_id = tlc.ticketpriceschedule_id left join finalclc catalog on catalog.catalog_id = if(qc.sub_catalog_id > 111, qc.sub_catalog_id, 111) and catalog.ticket_id = vt.ticket_id and catalog.ticketpriceschedule_id = vt.ticketpriceschedule_id left join finalclc clc on clc.channel_id = qc.channel_id and clc.ticket_id = vt.ticket_id and clc.ticketpriceschedule_id = vt.ticketpriceschedule_id), mismatches as (select vt_group_no, transaction_id,hotel_id,hotel_name, reseller_id, reseller_name, ticket_id, ticketpriceschedule_id, version, order_confirm_date, saleprice, purchaseprice, merchantcommission, distributorcommission, hgscommission, case when tlcsaleprice is not null then tlcsaleprice when tlcsaleprice is null and catalogsaleprice is not null then catalogsaleprice when tlcsaleprice is null and catalogsaleprice is null and clcsaleprice is not null then clcsaleprice else 111 end as salepriceshouldbe, 
case when tlcsaleprice is not null then tlcmuseumfee when tlcsaleprice is null and catalogsaleprice is not null then catalogmuseumfee when tlcsaleprice is null and catalogsaleprice is null and clcsaleprice is not null then clcmuseumfee else 111 end as museumfeeshouldbe,
case when tlcsaleprice is not null then tlcmerhantfee when tlcsaleprice is null and catalogsaleprice is not null then catalogmerchantfee when tlcsaleprice is null and catalogsaleprice is null and clcsaleprice is not null then clcmerchantfee else 111 end as merchantfeeshouldbe,
case when tlcsaleprice is not null then tlchotelfee when tlcsaleprice is null and catalogsaleprice is not null then cataloghotelfee when tlcsaleprice is null and catalogsaleprice is null and clcsaleprice is not null then clchotelfee else 111 end as hotelfeeshouldbe,
case when tlcsaleprice is not null then tlchgsfee when tlcsaleprice is null and catalogsaleprice is not null then cataloghgsfee when tlcsaleprice is null and catalogsaleprice is null and clcsaleprice is not null then clchgsfee else 111 end as hgsfeeshouldbe,
case when tlcsaleprice is not null then tlcmodified when tlcsaleprice is null and catalogsaleprice is not null then catalog_modified when tlcsaleprice is null and catalogsaleprice is null and clcsaleprice is not null then clcmodified else '2022-02-22 22:22:22' end as modifiedshouldbe,
case when tlcsaleprice is not null then 'tlcsetting' when tlcsaleprice is null and catalogsaleprice is not null then 'catalogsetting' when tlcsaleprice is null and catalogsaleprice is null and clcsaleprice is not null then 'clcsetting' else 'Nosetting' end as pricinglevel from getpricestting) select * from mismatches where pricinglevel = 'Nosetting' or ABS(cast(saleprice as float64)-(salepriceshouldbe)) > 0.03 or ABS(cast(purchaseprice as float64)-(museumfeeshouldbe)) > 0.03 or ABS(cast(merchantcommission as float64)-(merchantfeeshouldbe)) > 0.03 or ABS(cast(distributorcommission as float64)-(hotelfeeshouldbe)) > 0.03 or ABS(cast(hgscommission as float64)-(hgsfeeshouldbe)) > 0.03"

bq query --use_legacy_sql=False --max_rows=1000000 --format=csv \
"$BQ_QUERY_FILE" > $OUTPUT_FILE || exit 1

echo "BigQuery query successful. Data saved to $OUTPUT_FILE."

