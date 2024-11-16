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

timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN  -e "with qr_codess as (select reseller_id,cod_id, sub_catalog_id from "$LOCAL_NAME".qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0'), channels as (select d.*, qc.* from "$LOCAL_NAME_1".distributors d left join qr_codess qc on d.hotel_id = qc.cod_id group by d.ticket_id, qc.sub_catalog_id), final as (select c.*, clc.channel_level_commission_id, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage,clc.hgs_prepaid_commission_percentage, clc.ticket_net_price, clc.museum_net_commission, clc.merchant_net_commission, clc.hotel_commission_net_price, clc.hgs_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join "$LOCAL_NAME".channel_level_commission clc on c.sub_catalog_id = clc.catalog_id and c.ticket_id = clc.ticket_id and clc.deleted = '0' and (clc.is_adjust_pricing = '1' or clc.hotel_prepaid_commission_percentage+clc.hgs_prepaid_commission_percentage>'0.05')) select *, ABS(hotel_commission_net_price - hotel_commission_should_be) as gap from final where ABS(hotel_commission_net_price - hotel_commission_should_be) > '0.05' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ticketpriceschedule_id is NULL or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-museum_net_commission-hotel_commission_net_price) > '0.02';" >> Catalog_level_mismatch.csv

# echo "ticket_level_commission_id,product_id,distributor_id,commission,hotel_prepaid_commission_percentage,is_hotel_prepaid_commission_percentage,commission_on_sale_price,hgs_prepaid_commission_percentage,ticket_net_price,museum_net_commission,merchant_net_commission,hotel_commission_net_price,hgs_commission_net_price" > tlc_level_mismatch.csv

# for product_id in ${product_ids}

# do

#     echo $product_id

#     ## Command to Record Mismatch
#     timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "select * from (SELECT tlc.ticket_level_commission_id,d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hgs_prepaid_commission_percentage, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price FROM "$LOCAL_NAME_1".distributors d left join "$LOCAL_NAME".ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and (tlc.is_adjust_pricing = '1' or tlc.hotel_prepaid_commission_percentage+hgs_prepaid_commission_percentage > '0') where d.ticket_id = '$product_id') as base where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-museum_net_commission-hotel_commission_net_price) > '0.02')" >> tlc_level_mismatch.csv

#     ## Command to Update Mismatch
#     timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "update "$LOCAL_NAME".ticket_level_commission tlcu join (select * from (SELECT tlc.ticket_level_commission_id,d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hgs_prepaid_commission_percentage, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price FROM "$LOCAL_NAME_1".distributors d left join "$LOCAL_NAME".ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and (tlc.is_adjust_pricing = '1' or tlc.hotel_prepaid_commission_percentage+hgs_prepaid_commission_percentage > '0') where d.ticket_id = '$product_id') as base where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-museum_net_commission-hotel_commission_net_price) > '0.02')) as diff on tlcu.ticket_level_commission_id = diff.ticket_level_commission_id set tlcu.hotel_prepaid_commission_percentage = ROUND(diff.commission, 2), tlcu.resale_percentage = ROUND(100-diff.commission,2), tlcu.commission_on_sale_price = '1', tlcu.is_hotel_prepaid_commission_percentage = '1', tlcu.hotel_commission_net_price = ROUND(tlcu.ticket_net_price*diff.commission/100,2), tlcu.hotel_commission_gross_price = ROUND((tlcu.ticket_net_price*diff.commission/100)*(100+tlcu.hotel_commission_tax_value)/100,2), tlcu.museum_net_commission = ROUND(tlcu.ticket_net_price-(tlcu.ticket_net_price*diff.commission/100),2), tlcu.museum_gross_commission = ROUND((tlcu.ticket_net_price-(tlcu.ticket_net_price*diff.commission/100))*(100+tlcu.museum_commission_tax_value)/100,2), tlcu.merchant_net_commission = '0.00', tlcu.merchant_gross_commission = '0.00', tlcu.subtotal_net_amount = ROUND(tlcu.ticket_net_price-(tlcu.ticket_net_price*diff.commission/100),2), tlcu.subtotal_gross_amount = ROUND((tlcu.ticket_net_price-(tlcu.ticket_net_price*diff.commission/100))*(100+tlcu.museum_commission_tax_value)/100,2), tlcu.hgs_commission_net_price = '0.00', tlcu.hgs_commission_gross_price = '0.00'; select ROW_COUNT();"

#     sleep 1
#     # exit

# done 




