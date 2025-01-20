#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=20

### Database Credentials For 19 DB
DB_HOST="10.10.10.19"
DB_USER="pip"
DB_PASS="pip2024##"
DB_NAME="priopassdb"
AccountLEVELTABLE=ticket_level_commission # Define Variable which database table we are going to work
ChannelLEVELTABLE=channel_level_commission
BackupFILETLC="/home/intersoft-admin/rattan/backup/$AccountLEVELTABLE.sql"
BackupFILECLC="/home/intersoft-admin/rattan/backup/$AccountLEVELTABLE.sql"
outputfolder="$PWD/processedProducts"
BATCH_SIZE=2

# Create necessary files if they don't exist
mkdir -p "$outputfolder"
touch "$outputfolder/processed_products.log"

## Database credentials for Local database so that can work without interuption
# LOCAL_HOST="10.10.10.19"
# LOCAL_USER="pip"
# LOCAL_PASS="pip2024##"
# LOCAL_NAME="priopassdb"
# LOCAL_NAME_1="priopassdb"
# GETBACKUP=$1
# IMPORTDATATOHOST=$2

LOCAL_HOST="production-primary-db-node-cluster.cluster-ck6w2al7sgpk.eu-west-1.rds.amazonaws.com"
LOCAL_USER="pipeuser"
LOCAL_PASS="d4fb46eccNRAL"
LOCAL_NAME="priopassdb"
LOCAL_NAME_1="priopassdb"
# GETBACKUP=$1
# IMPORTDATATOHOST=$2

if [[ $GETBACKUP == 2 ]]; then

    echo "Condition 2 Satisfied"

    echo "Started Instering Data from Scratch"

    mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D rattan -e "TRUNCATE TABLE pricelist; TRUNCATE TABLE distributors"

    sleep 5

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

    sleep 5

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



product_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "select distinct product_id from (SELECT d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission,tlc.ticket_id, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price FROM "$LOCAL_NAME_1".distributors_standalone d left join "$LOCAL_NAME".ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') as base where ticket_id is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-hgs_commission_net_price-hotel_commission_net_price) > '0.02');")

echo "ticket_level_commission_id,product_id,distributor_id,commission,hotel_prepaid_commission_percentage,is_hotel_prepaid_commission_percentage,commission_on_sale_price,hgs_prepaid_commission_percentage,ticket_net_price,museum_net_commission,merchant_net_commission,hotel_commission_net_price,hgs_commission_net_price" > tlc_level_mismatch.csv

echo "$product_ids"

# Convert the vt_group_numbers into an array
product_ids_array=($product_ids)
echo $product_ids_array
total_product_ids=${#product_ids_array[@]}

# Read already processed hotel_ids
processed_products=$(cat "$outputfolder/processed_products.log")
processed_products_array=($processed_products)

# Filter out already processed hotel_ids
unprocessed_products=()
for id in "${product_ids_array[@]}"; do
    if [[ ! " ${processed_products_array[@]} " =~ " $id " ]]; then
        unprocessed_products+=("$id")
    fi
done

# Update total hotel_ids after filtering
total_unprocessed_products=${#unprocessed_products[@]}
echo "Total unprocessed product_ids: $total_unprocessed_products"

# Print the total count of vt_group_no for the current ticket_id
echo "Processing: $total_product_ids product_ids values"

# Initialize the progress tracking for the current ticket_id
current_progress=0

# Loop through vt_group_no array in batches
for ((i=0; i<$total_unprocessed_products; i+=BATCH_SIZE)); do

    # Create a batch of vt_group_no values
    batch=("${unprocessed_products[@]:$i:$BATCH_SIZE}")
    batch_size=${#batch[@]}

    # Calculate the current progress level for this ticket_id
    current_progress=$((i + batch_size))
    
    # Join the batch into a comma-separated list
    batch_str=$(IFS=,; echo "${batch[*]}")

    echo "$batch_str"

    # Print progress information for the current ticket_id
    echo "Processing batch of size $batch_size : $ticket_id ($current_progress / $total_unprocessed_products processed)" >> $outputfolder/log.txt

    echo "select * from (SELECT tlc.ticket_level_commission_id,d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hgs_prepaid_commission_percentage, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price FROM "$LOCAL_NAME_1".distributors_standalone d left join "$LOCAL_NAME".ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1' where d.ticket_id in ($batch_str)) as base where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-hgs_commission_net_price-hotel_commission_net_price) > '0.02')"

    ## Command to Record Mismatch
    timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "select * from (SELECT tlc.ticket_level_commission_id,d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hgs_prepaid_commission_percentage, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price FROM "$LOCAL_NAME_1".distributors_standalone d left join "$LOCAL_NAME".ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1' where d.ticket_id in ($batch_str)) as base where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-hgs_commission_net_price-hotel_commission_net_price) > '0.02')" >> tlc_level_mismatch.csv


    sleep 2
    ## Command to Update Mismatch
    timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "update "$LOCAL_NAME".ticket_level_commission tlcu join (select * from (SELECT tlc.ticket_level_commission_id,d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hgs_prepaid_commission_percentage, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price FROM "$LOCAL_NAME_1".distributors_standalone d left join "$LOCAL_NAME".ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1' where d.ticket_id in ($batch_str)) as base where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-hgs_commission_net_price-hotel_commission_net_price) > '0.02')) as diff on tlcu.ticket_level_commission_id = diff.ticket_level_commission_id set tlcu.hotel_prepaid_commission_percentage = ROUND(diff.commission, 2), tlcu.resale_percentage = '0.00', tlcu.commission_on_sale_price = '1', tlcu.is_hotel_prepaid_commission_percentage = '1', tlcu.hotel_commission_net_price = ROUND(tlcu.ticket_net_price*diff.commission/100,2), tlcu.hotel_commission_gross_price = ROUND((tlcu.ticket_net_price*diff.commission/100)*(100+tlcu.hotel_commission_tax_value)/100,2), tlcu.museum_net_commission = '0.00', tlcu.hgs_commission_net_price = ROUND(tlcu.ticket_net_price-(tlcu.ticket_net_price*diff.commission/100),2), tlcu.museum_gross_commission = '0.00', tlcu.hgs_commission_gross_price = ROUND((tlcu.ticket_net_price-(tlcu.ticket_net_price*diff.commission/100))*(100+tlcu.hgs_commission_tax_value)/100,2), tlcu.merchant_net_commission = '0.00', tlcu.merchant_gross_commission = '0.00', tlcu.subtotal_net_amount = ROUND((tlcu.ticket_net_price),2), tlcu.subtotal_gross_amount = ROUND(((tlcu.ticket_net_price))*(100+tlcu.subtotal_tax_value)/100,2), tlcu.ip_address = '163.47.25.151',tlcu.is_resale_percentage = '1', tlcu.hgs_prepaid_commission_percentage = ROUND(100-diff.commission,2); select ROW_COUNT();"

    # Mark each hotel_id in the batch as processed
    for hotel_id in "${batch[@]}"; do
        echo "$hotel_id" >> "$outputfolder/processed_products.log"
    done

    sleep 5
    # exit

done 

