#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=150

### Database Credentials For 19 DB
DB_HOST="10.10.10.19"
DB_USER="pip"
DB_PASS="pip2024##"
DB_NAME="priopassdb"
AccountLEVELTABLE=ticket_level_commission # Define Variable which database table we are going to work
ChannelLEVELTABLE=channel_level_commission
BackupFILETLC="/home/intersoft-admin/rattan/backup/$AccountLEVELTABLE.sql"
BackupFILECLC="/home/intersoft-admin/rattan/backup/$AccountLEVELTABLE.sql"
TEMP_FILE="temp_query_result.csv"

### Database credentials for Local database so that can work without interuption
LOCAL_HOST="10.10.10.19"
LOCAL_USER="pip"
LOCAL_PASS="pip2024##"
LOCAL_NAME="priopassdb"
LOCAL_NAME_1="priopassdb"

## GEt Distinct Reseller_id from Pricelist table

echo "ticket_id,reseller_id,commission,channel_id,mec_end_date,tps_id,currency_code,clcproduct_id,ticketpriceschedule_id,resale_currency_level" > reseller-Matrix_Missing_Entries.csv

reseller_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN  -e "select distinct reseller_id from "$LOCAL_NAME_1".pricelist where reseller_id not in (541,671)") || exit 1

for reseller_id in ${reseller_ids}

do

    echo "Fetching Data for reseller_id :: $reseller_id"
    
    channel_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "select distinct channel_id from priopassdb.qr_codes where cashier_type = '1' and channel_id > '0' and channel_id is not NULL and reseller_id = '$reseller_id'")

    for channel_id in ${channel_ids}

    do 

        timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "select * from (with qr_codess as (select reseller_id,channel_id from priopassdb.qr_codes where channel_id = '$channel_id' and cashier_type = '1' and channel_id is not NULL and channel_id > '0'), channels as (select d.*, qc.channel_id from priopassdb.pricelist d join qr_codess qc on d.reseller_id = qc.reseller_id group by d.ticket_id, qc.channel_id), catalogs as (select * from channels where channel_id is not NULL), products as (select c.*, date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) as mec_end_date, tps.id as tps_id, tps.currency_code from catalogs c left join modeventcontent mec on c.ticket_id = mec.mec_id left join ticketpriceschedule tps on mec.mec_id = tps.ticket_id where mec.deleted = '0' and  date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) > CURRENT_DATE and tps.deleted = '0' and date(from_unixtime(if(tps.end_date like '9999999', '1794812755', tps.end_date))) > CURRENT_DATE) select p.*, clc.ticket_id as clcproduct_id, clc.ticketpriceschedule_id, clc.resale_currency_level from products p left join channel_level_commission clc on p.channel_id = clc.channel_id and clc.catalog_id = '0' and clc.channel_id > '0' and clc.deleted = '0' and p.ticket_id = clc.ticket_id and p.tps_id = clc.ticketpriceschedule_id and clc.is_adjust_pricing = '1') as final where clcproduct_id is NULL" > "$TEMP_FILE"

        # Check if the temporary file contains data
        if [[ -s $TEMP_FILE ]]; then
            echo "Mismatch found for Reseller_ID=$reseller_id. Appending to CSV."

            # Append the result to the main CSV file
            cat "$TEMP_FILE" >> reseller-Matrix_Missing_Entries.csv

            # timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "update "$LOCAL_NAME".channel_level_commission tlcu join (with qr_codess as (select reseller_id, channel_id from priopassdb.qr_codes where cashier_type = '1' and channel_id = '$channel_id' and channel_id is not NULL group by reseller_id, channel_id), channels as (select d.*, qc.reseller_id as qc_reseller_id, qc.channel_id from rattan.pricelist d join qr_codess qc on d.reseller_id = qc.reseller_id), final as (select tlc.channel_level_commission_id,d.ticket_id as product_id, d.reseller_id as admin_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hgs_prepaid_commission_percentage, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price, tlc.resale_currency_level, tlc.currency from channels d left join priopassdb.channel_level_commission tlc on d.channel_id = tlc.channel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') select * from final where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-museum_net_commission-hotel_commission_net_price) > '0.02')) as diff on tlcu.channel_level_commission_id = diff.channel_level_commission_id set tlcu.hotel_prepaid_commission_percentage = ROUND(diff.commission, 2), tlcu.resale_percentage = ROUND(100-diff.commission,2), tlcu.commission_on_sale_price = '1', tlcu.is_hotel_prepaid_commission_percentage = '1', tlcu.hotel_commission_net_price = ROUND(tlcu.ticket_net_price*diff.commission/100,2), tlcu.hotel_commission_gross_price = ROUND((tlcu.ticket_net_price*diff.commission/100)*(100+tlcu.hotel_commission_tax_value)/100,2), tlcu.museum_net_commission = ROUND(tlcu.ticket_net_price-(tlcu.ticket_net_price*diff.commission/100),2), tlcu.museum_gross_commission = ROUND((tlcu.ticket_net_price-(tlcu.ticket_net_price*diff.commission/100))*(100+tlcu.museum_commission_tax_value)/100,2), tlcu.merchant_net_commission = '0.00', tlcu.merchant_gross_commission = '0.00', tlcu.subtotal_net_amount = ROUND((tlcu.ticket_net_price*diff.commission/100),2), tlcu.subtotal_gross_amount = ROUND(((tlcu.ticket_net_price*diff.commission/100))*(100+tlcu.museum_commission_tax_value)/100,2), tlcu.hgs_commission_net_price = '0.00', tlcu.hgs_commission_gross_price = '0.00', tlcu.ip_address = '192.168.1.16',tlcu.is_resale_percentage = '1' limit 5000;select ROW_COUNT();"

        else
            echo "No mismatch found for RESELLER_ID=$reseller_id. Skipping."
            cat "$TEMP_FILE" >> reseller-Matrix_Missing_Entries.csv
        fi

        sleep 1

        rm -f "$TEMP_FILE"


    done

    sleep 1

done




