#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=30
DB_NAME="priopassdb"
outputFile="$PWD/records/reseller-Matrix_account_level_mismatch.csv"
source ~/vault/vault_fetch_creds.sh
outputfolder="$PWD/processedProducts"
BATCH_SIZE=10

# Create necessary files if they don't exist
mkdir -p "$outputfolder"
touch "$outputfolder/processed_hotels.log"

mkdir -p $PWD/records
# Fetch credentials for 20Server
fetch_db_credentials "PrioticketLivePriomaryroPipe"



## GEt Distinct Reseller_id from Pricelist table

echo "ticket_level_commission_id,product_id,admin_id,commission,hotel_prepaid_commission_percentage,is_hotel_prepaid_commission_percentage,commission_on_sale_price,hgs_prepaid_commission_percentage,ticket_net_price,museum_net_commission,merchant_net_commission,hotel_commission_net_price,hgs_commission_net_price" >> $outputFile

reseller_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN  -e "select distinct reseller_id from pricelist") || exit 1

for reseller_id in ${reseller_ids}

do

    echo "Fetching Data for reseller_id :: $reseller_id"
    distributor_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN  -e "select distinct cod_id from qr_codes where reseller_id = '$reseller_id' and cashier_type = '1' and cod_id > '0';") || exit 1

    # Convert the vt_group_numbers into an array
    hotel_ids_array=($distributor_ids)
    echo $hotel_ids_array
    total_hotel_ids=${#hotel_ids_array[@]}

    # Read already processed hotel_ids
    processed_hotels=$(cat "$outputfolder/processed_hotels.log")
    processed_hotels_array=($processed_hotels)

    # Filter out already processed hotel_ids
    unprocessed_hotels=()
    for id in "${hotel_ids_array[@]}"; do
        if [[ ! " ${processed_hotels_array[@]} " =~ " $id " ]]; then
            unprocessed_hotels+=("$id")
        fi
    done

    # Update total hotel_ids after filtering
    total_unprocessed_hotels=${#unprocessed_hotels[@]}
    echo "Total unprocessed hotel_ids: $total_unprocessed_hotels"

    # Print the total count of vt_group_no for the current ticket_id
    echo "Processing: $total_hotel_ids hotel_ids values"

    # Initialize the progress tracking for the current ticket_id
    current_progress=0

    # Loop through vt_group_no array in batches
    for ((i=0; i<$total_unprocessed_hotels; i+=BATCH_SIZE)); do

        # Create a batch of vt_group_no values
        batch=("${unprocessed_hotels[@]:$i:$BATCH_SIZE}")
        batch_size=${#batch[@]}

        # Calculate the current progress level for this ticket_id
        current_progress=$((i + batch_size))
        
        # Join the batch into a comma-separated list
        batch_str=$(IFS=,; echo "${batch[*]}")

        echo "$batch_str"

        # Print progress information for the current ticket_id
        echo "Processing batch of size $batch_size : $ticket_id ($current_progress / $total_unprocessed_hotels processed)" >> $outputfolder/log.txt

        echo "Fetching Data for Distributor_id:: $batch_str-ResellerID-$reseller_id"

        timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "with qr_codess as (select cod_id, reseller_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1' and cod_id in ($batch_str)), distributor as (select p.*, qc.cod_id, qc.sub_catalog_id from priopassdb.pricelist p join qr_codess qc on p.reseller_id = qc.reseller_id), final as (select tlc.ticket_level_commission_id,d.ticket_id as product_id, d.reseller_id as admin_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hgs_prepaid_commission_percentage, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price from distributor d left join priopassdb.ticket_level_commission tlc on d.cod_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') select * from final where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-museum_net_commission-hotel_commission_net_price) > '0.02')" >> $outputFile

        # Mark each hotel_id in the batch as processed
        for hotel_id in "${batch[@]}"; do
            echo "$hotel_id" >> "$outputfolder/processed_hotels.log"
        done

        sleep 3
    done

sleep 3

done




