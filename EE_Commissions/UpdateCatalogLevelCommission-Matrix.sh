#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=15

### Database Credentials For 19 DB
DB_HOST="10.10.10.19"
DB_USER="pip"
DB_PASS="pip2024##"
DB_NAME="priopassdb"
AccountLEVELTABLE=ticket_level_commission # Define Variable which database table we are going to work
ChannelLEVELTABLE=channel_level_commission
BackupFILETLC="/home/intersoft-admin/rattan/backup/$AccountLEVELTABLE.sql"
BackupFILECLC="/home/intersoft-admin/rattan/backup/$AccountLEVELTABLE.sql"

### Database credentials for Local database so that can work without interuption
LOCAL_HOST="localhost"
LOCAL_USER="admin"
LOCAL_PASS="redhat"
LOCAL_NAME="priopassdb"
LOCAL_NAME_1="priopassdb"

echo "ticket_id,hotel_id,commission,reseller_id,cod_id,sub_catalog_id,channel_level_commission_id,ticketpriceschedule_id,resale_currency_level,currency,commission_on_sale_price,is_hotel_prepaid_commission_percentage,hotel_prepaid_commission_percentage,hgs_prepaid_commission_percentage,ticket_net_price,museum_net_commission,merchant_net_commission,hotel_commission_net_price,hgs_commission_net_price,hotel_commission_should_be,gap" > Catalog_level_mismatch.csv


product_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN  -e "select distinct ticket_id from (with qr_codess as (select reseller_id,cod_id, sub_catalog_id from "$LOCAL_NAME".qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0'), channels as (select d.*, qc.* from "$LOCAL_NAME_1".distributors d left join qr_codess qc on d.hotel_id = qc.cod_id group by d.ticket_id, qc.sub_catalog_id), final as (select c.*, clc.channel_level_commission_id, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage,clc.hgs_prepaid_commission_percentage, clc.ticket_net_price, clc.museum_net_commission, clc.merchant_net_commission, clc.hotel_commission_net_price, clc.hgs_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join "$LOCAL_NAME".channel_level_commission clc on c.sub_catalog_id = clc.catalog_id and c.ticket_id = clc.ticket_id and clc.deleted = '0' and (clc.is_adjust_pricing = '1' or clc.hotel_prepaid_commission_percentage+clc.hgs_prepaid_commission_percentage>'0.05')) select *, ABS(hotel_commission_net_price - hotel_commission_should_be) as gap from final where ticketpriceschedule_id is not NULL and (ABS(hotel_commission_net_price - hotel_commission_should_be) > '0.05' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-museum_net_commission-hotel_commission_net_price) > '0.02')) as raja;")

for product_id in ${product_ids}

do

    echo $product_id

    ## Command to Record Mismatch
    timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN  -e "with qr_codess as (select reseller_id,cod_id, sub_catalog_id from "$LOCAL_NAME".qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0'), channels as (select d.*, qc.* from "$LOCAL_NAME_1".distributors d left join qr_codess qc on d.hotel_id = qc.cod_id where d.ticket_id = '$product_id' group by d.ticket_id, qc.sub_catalog_id), final as (select c.*, clc.channel_level_commission_id, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage,clc.hgs_prepaid_commission_percentage, clc.ticket_net_price, clc.museum_net_commission, clc.merchant_net_commission, clc.hotel_commission_net_price, clc.hgs_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join "$LOCAL_NAME".channel_level_commission clc on c.sub_catalog_id = clc.catalog_id and c.ticket_id = clc.ticket_id and clc.deleted = '0' and c.sub_catalog_id is not NULL and (clc.is_adjust_pricing = '1' or clc.hotel_prepaid_commission_percentage+clc.hgs_prepaid_commission_percentage>'0.05')) select *, ABS(hotel_commission_net_price - hotel_commission_should_be) as gap from final where ticketpriceschedule_id is not NULL and (ABS(hotel_commission_net_price - hotel_commission_should_be) > '0.05' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-museum_net_commission-hotel_commission_net_price) > '0.02');" >> Catalog_level_mismatch.csv

    ## Command to Update Mismatch
    timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "update "$LOCAL_NAME".channel_level_commission tlcu join (with qr_codess as (select reseller_id,cod_id, sub_catalog_id from "$LOCAL_NAME".qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0'), channels as (select d.*, qc.* from "$LOCAL_NAME_1".distributors d left join qr_codess qc on d.hotel_id = qc.cod_id where d.ticket_id = '$product_id' group by d.ticket_id, qc.sub_catalog_id), final as (select c.*, clc.channel_level_commission_id, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage,clc.hgs_prepaid_commission_percentage, clc.ticket_net_price, clc.museum_net_commission, clc.merchant_net_commission, clc.hotel_commission_net_price, clc.hgs_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join "$LOCAL_NAME".channel_level_commission clc on c.sub_catalog_id = clc.catalog_id and c.ticket_id = clc.ticket_id and clc.deleted = '0' and (clc.is_adjust_pricing = '1' or clc.hotel_prepaid_commission_percentage+clc.hgs_prepaid_commission_percentage>'0.05')) select *, ABS(hotel_commission_net_price - hotel_commission_should_be) as gap from final where ticketpriceschedule_id is not NULL and (ABS(hotel_commission_net_price - hotel_commission_should_be) > '0.05' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-museum_net_commission-hotel_commission_net_price) > '0.02')) as diff on tlcu.channel_level_commission_id = diff.channel_level_commission_id set tlcu.hotel_prepaid_commission_percentage = ROUND(diff.commission, 2), tlcu.resale_percentage = ROUND(100-diff.commission,2), tlcu.commission_on_sale_price = '1', tlcu.is_hotel_prepaid_commission_percentage = '1', tlcu.hotel_commission_net_price = ROUND(tlcu.ticket_net_price*diff.commission/100,2), tlcu.hotel_commission_gross_price = ROUND((tlcu.ticket_net_price*diff.commission/100)*(100+tlcu.hotel_commission_tax_value)/100,2), tlcu.museum_net_commission = ROUND(tlcu.ticket_net_price-(tlcu.ticket_net_price*diff.commission/100),2), tlcu.museum_gross_commission = ROUND((tlcu.ticket_net_price-(tlcu.ticket_net_price*diff.commission/100))*(100+tlcu.museum_commission_tax_value)/100,2), tlcu.merchant_net_commission = '0.00', tlcu.merchant_gross_commission = '0.00', tlcu.subtotal_net_amount = ROUND(tlcu.ticket_net_price-(tlcu.ticket_net_price*diff.commission/100),2), tlcu.subtotal_gross_amount = ROUND((tlcu.ticket_net_price-(tlcu.ticket_net_price*diff.commission/100))*(100+tlcu.museum_commission_tax_value)/100,2), tlcu.hgs_commission_net_price = '0.00', tlcu.hgs_commission_gross_price = '0.00', tlcu.ip_address = '192.168.1.10'; select ROW_COUNT();"

    sleep 1
    # exit

done 

## Missing Entries Part

timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME"  -e "select * from (with qr_codess as (select reseller_id,cod_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0'), channels as (select d.*, qc.* from priopassdb.distributors d left join qr_codess qc on d.hotel_id = qc.cod_id group by d.ticket_id, qc.sub_catalog_id), catalogs as (select * from channels where sub_catalog_id is not NULL), products as (select c.*, date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) as mec_end_date, tps.id as tps_id, tps.currency_code from catalogs c left join modeventcontent mec on c.ticket_id = mec.mec_id left join ticketpriceschedule tps on mec.mec_id = tps.ticket_id where mec.deleted = '0' and  date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) > CURRENT_DATE and tps.deleted = '0' and date(from_unixtime(if(tps.end_date like '9999999', '1794812755', tps.end_date))) > CURRENT_DATE) select p.*, clc.ticket_id as clcproduct_id, clc.ticketpriceschedule_id, clc.resale_currency_level from products p left join channel_level_commission clc on p.sub_catalog_id = clc.catalog_id and clc.channel_id = '0' and clc.catalog_id > '0' and clc.deleted = '0' and p.ticket_id = clc.ticket_id and p.tps_id = clc.ticketpriceschedule_id and clc.is_adjust_pricing = '1') as final where clcproduct_id is NULL;" > Catalog_Missing_Entries.csv




