#!/bin/bash

# this script we make difference because some account commission are overlapping on catalog level so where we have overlap that we put in the distributors_standalone table and rest where we have not any overlap that we keep in the distributors table

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=30
DB_NAME="priopassdb"
outputFile="$PWD/records/tlc_level_mismatch_withoutOverlapAccount.csv"
source ~/vault/vault_fetch_creds.sh
outputfolder="$PWD/processedProducts"
BATCH_SIZE=4

# Create necessary files if they don't exist
mkdir -p "$outputfolder"
touch "$outputfolder/processed_products1.log"

mkdir -p $PWD/records
# Fetch credentials for 20Server
fetch_db_credentials "PrioticketLivePriomaryroPipe"



product_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "select distinct product_id from (SELECT d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission,tlc.ticket_id, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price FROM distributors d left join ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') as base where ticket_id is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-hgs_commission_net_price-hotel_commission_net_price) > '0.02');")

echo "ticket_level_commission_id,product_id,distributor_id,commission,hotel_prepaid_commission_percentage,is_hotel_prepaid_commission_percentage,commission_on_sale_price,hgs_prepaid_commission_percentage,ticket_net_price,museum_net_commission,merchant_net_commission,hotel_commission_net_price,hgs_commission_net_price" > $outputFile

echo "$product_ids"

# Convert the vt_group_numbers into an array
product_ids_array=($product_ids)
echo $product_ids_array
total_product_ids=${#product_ids_array[@]}

# Read already processed hotel_ids
processed_products=$(cat "$outputfolder/processed_products1.log")
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

    ## Command to Record Mismatch
    timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "select * from (SELECT tlc.ticket_level_commission_id,d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hgs_prepaid_commission_percentage, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price FROM distributors d left join ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1' where d.ticket_id in ($batch_str)) as base where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-hgs_commission_net_price-hotel_commission_net_price) > '0.02')" >> $outputFile

    # Mark each hotel_id in the batch as processed
    for hotel_id in "${batch[@]}"; do
        echo "$hotel_id" >> "$outputfolder/processed_products1.log"
    done

    sleep 5
    # exit

done 

