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

if [ $GETBACKUP == 2 ]; then

    rm -f "$BackupFILETLC"
    rm -f "$BackupFILECLC"

    echo "1"

    time mysqldump --single-transaction -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$AccountLEVELTABLE" >> "$BackupFILETLC" || exit 1

    echo "2"
    time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" < "$BackupFILETLC"

    time mysqldump --single-transaction -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$ChannelLEVELTABLE" >> "$BackupFILECLC" || exit 1

    time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" < "$BackupFILECLC"

elif [ $GETBACKUP == 1 ]; then

    time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" < "$BackupFILETLC"

    time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" < "$BackupFILECLC"

else 

    echo "Continue with Backup"

fi


