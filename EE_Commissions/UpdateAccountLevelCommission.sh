#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=25

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
GETBACKUP=$1
IMPORTDATATOHOST=$2

if [[ $GETBACKUP == 2 ]]; then

    echo "Condition 2 Satisfied"
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

    time mysqldump --single-transaction --skip-lock-tables  --no-create-info -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" rattan distributors >> distributors.sql || exit 1

    time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" < distributors.sql

    time mysqldump --single-transaction --skip-lock-tables  --no-create-info -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" rattan pricelist >> pricelist.sql || exit 1

    time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" < pricelist.sql

    rm -f pricelist.sql
    rm -f distributors.sql

else

    echo "NO IMPORT NEEDED"

fi


time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -e "select * from (SELECT d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hotel_commission_net_price, tlc.ticket_net_price FROM "$LOCAL_NAME".distributors d left join "$LOCAL_NAME".ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') as base where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1')" > tlc_level_mismatch.csv




