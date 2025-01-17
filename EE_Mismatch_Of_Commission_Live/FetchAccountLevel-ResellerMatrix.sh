#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=15
DB_NAME="priopassdb"
outputFile="$PWD/records/reseller-Matrix_account_level_mismatch.csv"
source ~/vault/vault_fetch_creds.sh

mkdir -p $PWD/records
# Fetch credentials for 20Server
fetch_db_credentials "PrioticketLivePriomaryroPipe"



## GEt Distinct Reseller_id from Pricelist table

echo "ticket_level_commission_id,product_id,admin_id,commission,hotel_prepaid_commission_percentage,is_hotel_prepaid_commission_percentage,commission_on_sale_price,hgs_prepaid_commission_percentage,ticket_net_price,museum_net_commission,merchant_net_commission,hotel_commission_net_price,hgs_commission_net_price" > $outputFile

reseller_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN  -e "select distinct reseller_id from pricelist where reseller_id in (4406);") || exit 1

for reseller_id in ${reseller_ids}

do

    echo "Fetching Data for reseller_id :: $reseller_id"
    distributor_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN  -e "select distinct cod_id from qr_codes where reseller_id = '$reseller_id' and cashier_type = '1' and cod_id > '0';") || exit 1

    for distributor_id in ${distributor_ids}

    do

        echo "Fetching Data for Distributor_id:: $distributor_id-ResellerID-$reseller_id"

        timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "with qr_codess as (select cod_id, reseller_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1' and cod_id = '$distributor_id'), distributor as (select p.*, qc.cod_id, qc.sub_catalog_id from priopassdb.pricelist p join qr_codess qc on p.reseller_id = qc.reseller_id), final as (select tlc.ticket_level_commission_id,d.ticket_id as product_id, d.reseller_id as admin_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hgs_prepaid_commission_percentage, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price from distributor d left join priopassdb.ticket_level_commission tlc on d.cod_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') select * from final where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-museum_net_commission-hotel_commission_net_price) > '0.02')" >> $outputFile

    
    done

sleep 3

done




