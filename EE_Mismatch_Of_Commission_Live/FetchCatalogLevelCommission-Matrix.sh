#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=30
DB_NAME="priopassdb"
outputFile="$PWD/records/Catalog_level_mismatch.csv"
outputFile2="$PWD/records/Catalog_Missing_Entries.csv"
source ~/vault/vault_fetch_creds.sh

mkdir -p $PWD/records
# Fetch credentials for 20Server
fetch_db_credentials "PrioticketLivePriomaryroPipe"

echo "ticket_id,hotel_id,commission,reseller_id,cod_id,sub_catalog_id,channel_level_commission_id,ticketpriceschedule_id,resale_currency_level,currency,commission_on_sale_price,is_hotel_prepaid_commission_percentage,hotel_prepaid_commission_percentage,hgs_prepaid_commission_percentage,ticket_net_price,museum_net_commission,merchant_net_commission,hotel_commission_net_price,hgs_commission_net_price,hotel_commission_should_be,gap" > $outputFile


product_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN  -e "select distinct ticket_id from (with qr_codess as (select reseller_id,cod_id, sub_catalog_id from qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0'), channels as (select d.*, qc.* from distributors d left join qr_codess qc on d.hotel_id = qc.cod_id group by d.ticket_id, qc.sub_catalog_id), final as (select c.*, clc.channel_level_commission_id, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage,clc.hgs_prepaid_commission_percentage, clc.ticket_net_price, clc.museum_net_commission, clc.merchant_net_commission,clc.subtotal_net_amount, clc.hotel_commission_net_price, clc.hgs_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join channel_level_commission clc on c.sub_catalog_id = clc.catalog_id and c.ticket_id = clc.ticket_id and clc.deleted = '0' and (clc.is_adjust_pricing = '1' or clc.hotel_prepaid_commission_percentage+clc.hgs_prepaid_commission_percentage>'0.05')) select *, ABS(hotel_commission_net_price - hotel_commission_should_be) as gap from final where ticketpriceschedule_id is not NULL and (ABS(hotel_commission_net_price - hotel_commission_should_be) > '0.05' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(subtotal_net_amount-hgs_commission_net_price-hotel_commission_net_price) > '0.02')) as raja;") || exit 1

for product_id in ${product_ids}

do

    echo $product_id

    ## Command to Record Mismatch
    timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN  -e "with qr_codess as (select reseller_id,cod_id, sub_catalog_id from qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0'), channels as (select d.*, qc.* from distributors d left join qr_codess qc on d.hotel_id = qc.cod_id where d.ticket_id = '$product_id' group by d.ticket_id, qc.sub_catalog_id), final as (select c.*, clc.channel_level_commission_id, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage,clc.hgs_prepaid_commission_percentage, clc.ticket_net_price, clc.museum_net_commission, clc.merchant_net_commission,clc.subtotal_net_amount, clc.hotel_commission_net_price, clc.hgs_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join channel_level_commission clc on c.sub_catalog_id = clc.catalog_id and c.ticket_id = clc.ticket_id and clc.deleted = '0' and c.sub_catalog_id is not NULL and (clc.is_adjust_pricing = '1' or clc.hotel_prepaid_commission_percentage+clc.hgs_prepaid_commission_percentage>'0.05')) select *, ABS(hotel_commission_net_price - hotel_commission_should_be) as gap from final where ticketpriceschedule_id is not NULL and (ABS(hotel_commission_net_price - hotel_commission_should_be) > '0.05' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(subtotal_net_amount-hgs_commission_net_price-hotel_commission_net_price) > '0.02');" >> $outputFile || exit 1


    sleep 1
    # exit

done 

## Missing Entries Part

echo "Missing Entries Insertion stated"

echo "ticket_id	hotel_id,commission,reseller_id,cod_id,sub_catalog_id,mec_end_date,tps_id,currency_code,clcproduct_id,ticketpriceschedule_id,resale_currency_level" > $outputFile2

MissingProduct_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN  -e "select distinct(ticket_id) from (with qr_codess as (select reseller_id,cod_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0'), channels as (select d.*, qc.* from priopassdb.distributors d left join qr_codess qc on d.hotel_id = qc.cod_id group by d.ticket_id, qc.sub_catalog_id), catalogs as (select * from channels where sub_catalog_id is not NULL), products as (select c.*, date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) as mec_end_date, tps.id as tps_id, tps.currency_code from catalogs c left join modeventcontent mec on c.ticket_id = mec.mec_id left join ticketpriceschedule tps on mec.mec_id = tps.ticket_id where mec.deleted = '0' and  date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) > CURRENT_DATE and tps.deleted = '0' and date(from_unixtime(if(tps.end_date like '9999999', '1794812755', tps.end_date))) > CURRENT_DATE) select p.*, clc.ticket_id as clcproduct_id, clc.ticketpriceschedule_id, clc.resale_currency_level from products p left join channel_level_commission clc on p.sub_catalog_id = clc.catalog_id and clc.channel_id = '0' and clc.catalog_id > '0' and clc.deleted = '0' and p.ticket_id = clc.ticket_id and p.tps_id = clc.ticketpriceschedule_id and clc.is_adjust_pricing = '1') as final where clcproduct_id is NULL;") || exit 1

for Missing_product_id in ${MissingProduct_ids}

do 


    echo "$Missing_product_id"

    timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME"  -e "select * from (with qr_codess as (select reseller_id,cod_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0'), channels as (select d.*, qc.* from priopassdb.distributors d left join qr_codess qc on d.hotel_id = qc.cod_id where d.ticket_id = '$Missing_product_id' group by d.ticket_id, qc.sub_catalog_id), catalogs as (select * from channels where sub_catalog_id is not NULL), products as (select c.*, date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) as mec_end_date, tps.id as tps_id, tps.currency_code from catalogs c left join modeventcontent mec on c.ticket_id = mec.mec_id left join ticketpriceschedule tps on mec.mec_id = tps.ticket_id where mec.mec_id = '$Missing_product_id' and mec.deleted = '0' and  date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) > CURRENT_DATE and tps.deleted = '0' and date(from_unixtime(if(tps.end_date like '9999999', '1794812755', tps.end_date))) > CURRENT_DATE) select p.*, clc.ticket_id as clcproduct_id, clc.ticketpriceschedule_id, clc.resale_currency_level from products p left join channel_level_commission clc on p.sub_catalog_id = clc.catalog_id and clc.channel_id = '0' and clc.catalog_id > '0' and clc.deleted = '0' and p.ticket_id = clc.ticket_id and p.tps_id = clc.ticketpriceschedule_id and clc.is_adjust_pricing = '1') as final where clcproduct_id is NULL;" >> $outputFile2 || exit 1

    sleep 3

done




