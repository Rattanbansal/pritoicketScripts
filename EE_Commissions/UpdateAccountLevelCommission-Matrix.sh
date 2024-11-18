#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=300

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
GETBACKUP=$1
IMPORTDATATOHOST=$2

if [[ $GETBACKUP == 2 ]]; then

    echo "Condition 2 Satisfied"

    echo "Started Instering Data from Scratch"

    mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D rattan -e "TRUNCATE TABLE pricelist; TRUNCATE TABLE distributors"

    python pricelist.py pricelist.csv

    python distributors.py distributors.csv
    # rm -f "$BackupFILETLC"
    # rm -f "$BackupFILECLC"

    # echo "1"

    # time mysqldump --single-transaction -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$AccountLEVELTABLE" >> "$BackupFILETLC" || exit 1

    # echo "2"
    # time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" < "$BackupFILETLC"

    # time mysqldump --single-transaction -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$ChannelLEVELTABLE" >> "$BackupFILECLC" || exit 1

    # time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" < "$BackupFILECLC"

elif [[ $GETBACKUP == 1 ]]; then

    echo "Condition 1 Satisfied"

    # time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" < "$BackupFILETLC"

    # time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" < "$BackupFILECLC"

else 

    echo "Continue without Backup"


fi

if [[ $IMPORTDATATOHOST == 2 ]]; then


    echo "IMPORT DATA TO HOST"

    timeout $TIMEOUT_PERIOD time mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" rattan -e "delete from distributors where hotel_id = '0';delete from distributors where ticket_id = '0'; delete from pricelist where reseller_id = '0';delete from pricelist where ticket_id = '0';" || exit 1

    echo "TRUNCATE TABLE Started"
    timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -e "TRUNCATE TABLE "$LOCAL_NAME_1".distributors;TRUNCATE TABLE "$LOCAL_NAME_1".pricelist;" || exit 1
    echo "TRUNCATE TABLE Ended"


    echo "Distributor Dump Strated"
    time mysqldump --single-transaction --skip-lock-tables  --no-create-info -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" rattan distributors > distributors.sql || exit 1
    echo "Distributor Dump Ended"

    echo "Distributor DUMP restore started"
    timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" < distributors.sql || exit 1
    echo "Distributor DUMP restore ended"

    echo "Pricelist dump started"
    time mysqldump --single-transaction --skip-lock-tables  --no-create-info -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" rattan pricelist > pricelist.sql || exit 1
    echo "Pricelist dump ended"

    echo "Pricelist Dump restore started"
    timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" < pricelist.sql || exit 1
    echo "Pricelist Dump restore ended"

    rm -f pricelist.sql
    rm -f distributors.sql

else

    echo "NO IMPORT NEEDED"

fi


product_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "select distinct product_id from (SELECT d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission,tlc.ticket_id, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price FROM "$LOCAL_NAME_1".distributors d left join "$LOCAL_NAME".ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') as base where ticket_id is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-museum_net_commission-hotel_commission_net_price) > '0.02')")

echo "ticket_level_commission_id,product_id,distributor_id,commission,hotel_prepaid_commission_percentage,is_hotel_prepaid_commission_percentage,commission_on_sale_price,hgs_prepaid_commission_percentage,ticket_net_price,museum_net_commission,merchant_net_commission,hotel_commission_net_price,hgs_commission_net_price" > tlc_level_mismatch.csv

for product_id in ${product_ids}

do

    echo $product_id

    ## Command to Record Mismatch
    timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "select * from (SELECT tlc.ticket_level_commission_id,d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hgs_prepaid_commission_percentage, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price FROM "$LOCAL_NAME_1".distributors d left join "$LOCAL_NAME".ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1' where d.ticket_id = '$product_id') as base where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-museum_net_commission-hotel_commission_net_price) > '0.02')" >> tlc_level_mismatch.csv

    ## Command to Update Mismatch
    timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "update "$LOCAL_NAME".ticket_level_commission tlcu join (select * from (SELECT tlc.ticket_level_commission_id,d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hgs_prepaid_commission_percentage, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price FROM "$LOCAL_NAME_1".distributors d left join "$LOCAL_NAME".ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1' where d.ticket_id = '$product_id') as base where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-museum_net_commission-hotel_commission_net_price) > '0.02')) as diff on tlcu.ticket_level_commission_id = diff.ticket_level_commission_id set tlcu.hotel_prepaid_commission_percentage = ROUND(diff.commission, 2), tlcu.resale_percentage = ROUND(100-diff.commission,2), tlcu.commission_on_sale_price = '1', tlcu.is_hotel_prepaid_commission_percentage = '1', tlcu.hotel_commission_net_price = ROUND(tlcu.ticket_net_price*diff.commission/100,2), tlcu.hotel_commission_gross_price = ROUND((tlcu.ticket_net_price*diff.commission/100)*(100+tlcu.hotel_commission_tax_value)/100,2), tlcu.museum_net_commission = ROUND(tlcu.ticket_net_price-(tlcu.ticket_net_price*diff.commission/100),2), tlcu.museum_gross_commission = ROUND((tlcu.ticket_net_price-(tlcu.ticket_net_price*diff.commission/100))*(100+tlcu.museum_commission_tax_value)/100,2), tlcu.merchant_net_commission = '0.00', tlcu.merchant_gross_commission = '0.00', tlcu.subtotal_net_amount = ROUND(tlcu.ticket_net_price-(tlcu.ticket_net_price*diff.commission/100),2), tlcu.subtotal_gross_amount = ROUND((tlcu.ticket_net_price-(tlcu.ticket_net_price*diff.commission/100))*(100+tlcu.museum_commission_tax_value)/100,2), tlcu.hgs_commission_net_price = '0.00', tlcu.hgs_commission_gross_price = '0.00', tlcu.ip_address = '192.168.1.10'; select ROW_COUNT();"

    sleep 1
    # exit

done 

