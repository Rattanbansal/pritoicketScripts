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
LOCAL_HOST="10.10.10.19"
LOCAL_USER="pip"
LOCAL_PASS="pip2024##"
LOCAL_NAME="priopassdb"
LOCAL_NAME_1="priopassdb"

## GEt Distinct Reseller_id from Pricelist table

echo "ticket_level_commission_id,product_id,admin_id,commission,hotel_prepaid_commission_percentage,is_hotel_prepaid_commission_percentage,commission_on_sale_price,hgs_prepaid_commission_percentage,ticket_net_price,museum_net_commission,merchant_net_commission,hotel_commission_net_price,hgs_commission_net_price" > reseller-Matrix_account_level_mismatch.csv

reseller_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN  -e "select distinct reseller_id from "$LOCAL_NAME_1".pricelist where reseller_id not in ('541-671');") || exit 1

for reseller_id in ${reseller_ids}

do

    echo "Fetching Data for reseller_id :: $reseller_id"
    distributor_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN  -e "select distinct cod_id from "$LOCAL_NAME_1".qr_codes where reseller_id = '$reseller_id';") || exit 1

    for distributor_id in ${distributor_ids}

    do

        echo "Fetching Data for Distributor_id:: $distributor_id-ResellerID-$reseller_id"

        timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "with qr_codess as (select cod_id, reseller_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1' and cod_id = '$distributor_id'), distributor as (select p.*, qc.cod_id, qc.sub_catalog_id from rattan.pricelist p join qr_codess qc on p.reseller_id = qc.reseller_id), final as (select tlc.ticket_level_commission_id,d.ticket_id as product_id, d.reseller_id as admin_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hgs_prepaid_commission_percentage, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price from distributor d left join priopassdb.ticket_level_commission tlc on d.cod_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') select * from final where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-museum_net_commission-hotel_commission_net_price) > '0.02')" >> reseller-Matrix_account_level_mismatch.csv

        sleep 1

    done

    sleep 1

done




