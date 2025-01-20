#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=15
DB_NAME="priopassdb"
outputFile="$PWD/records/StandaloneMissingEntries.csv"
source ~/vault/vault_fetch_creds.sh
outputfolder="$PWD/processedProducts"
BATCH_SIZE=10

# Create necessary files if they don't exist
mkdir -p "$outputfolder"
touch "$outputfolder/processed_hotelsMissingEntries.log"

mkdir -p $PWD/records
# Fetch credentials for 20Server
fetch_db_credentials "PrioticketLivePriomaryroPipe"

## GEt Distinct Reseller_id from Pricelist table



echo "Fetching Data for reseller_id :: $reseller_id"

cod_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "select distinct hotel_id from distributors_standalone;")

echo $cod_ids

# Convert the vt_group_numbers into an array
hotel_ids_array=($cod_ids)
echo $hotel_ids_array
total_hotel_ids=${#hotel_ids_array[@]}

# Read already processed hotel_ids
processed_hotels=$(cat "$outputfolder/processed_hotelsMissingEntries.log")
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

    timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "select CURRENT_TIMESTAMP as created_at,hotel_id,ticket_id,tps_id as ticketpriceschedule_id, museum_name,ticket_title,LEFT(ticket_type, 10) AS ticket_type,ticket_scan_price,ticket_list_price, ticket_new_price, '0' as ticket_discount,'0' as is_discount_in_percent, ticket_gross_price,'0.00' as ticket_tax_value, '227' as ticket_tax_id,ticket_gross_price as ticket_net_price,'0' as museum_commission_old,'0.00' as museum_gross_commission,'0.00' as museum_net_commission,'0.00' as museum_commission_tax_value, '227' as museum_commission_tax_id,ticket_gross_price as subtotal_net_amount, ticket_gross_price as subtotal_gross_amount,'0.00' as subtotal_tax_value, '227' as subtotal_tax_id,'0' as is_combi_ticket_allowed,'0' as is_combi_discount, '0' as tickets_for_combi_discount,'0' as combi_discount_gross_amount,'0' as combi_discount_net_amount, '0.00' as combi_discount_tax_value,'227' as combi_discount_tax_id,CURRENT_TIMESTAMP as commission_updated_at,'192.168.1.18' as ip_address,commission as hotel_prepaid_commission_percentage,'0.00' as hotel_postpaid_commission_percentage, '2' as hotel_commission_tax_id,'21.00' as hotel_commission_tax_value,'0.00' as hgs_prepaid_commission_percentage,'0.00' as hgs_postpaid_commission_percentage, '227' as hgs_commission_tax_id,'0.00' as hgs_commission_tax_value,'0.00' as merchant_gross_commission, '1' as is_adjust_pricing,'0' as is_custom_setting,'0' as apply_service_tax,'0' as external_product_id, '1' as account_number,'1' as chart_number,'0' as deleted,'4' as market_merchant_id, '0.00' as merchant_net_commission,'49758' as merchant_admin_id,'Evan Evans' as merchant_admin_name,(case when is_combi in ('2', '3') then '1' else '0' end) as is_cluster_ticket_added,'0' default_listing,'0' as catalog_id,CURRENT_TIMESTAMP as last_modified_at,'0.00' as resale_percentage,'1' as is_resale_percentage, '0.00' as merchant_fee_percentage,'0' as is_merchant_fee_percentage,'1' as is_hotel_prepaid_commission_percentage,'1' as commission_on_sale_price, ((ticket_gross_price*commission/100)*(121/100)) as hotel_commission_gross_price, (ticket_gross_price*commission/100) as hotel_commission_net_price,ticket_gross_price*(100-commission)/100 as hgs_commission_gross_price,ticket_gross_price*(100-commission)/100 as hgs_commission_net_price,is_combi as product_type,currency_code as currency,'1' as resale_currency_level,'0' as resale_commission,CURRENT_TIMESTAMP as affected_before_date,'0' as own_merchant_id,'0' as discount_label,'0' as discount_setting_type from (with qr_codess as (select cod_id from priopassdb.qr_codes where cod_id in ($batch_str) and cashier_type = '1'), channels as (select d.*, qc.cod_id from priopassdb.distributors_standalone d join qr_codess qc on d.hotel_id = qc.cod_id group by d.ticket_id, qc.cod_id), catalogs as (select * from channels where cod_id is not NULL), products as (select c.*, date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) as mec_end_date,mec.museum_name,mec.postingEventTitle as ticket_title,tps.ticket_type_label as ticket_type,tps.newPrice as ticket_scan_price, tps.newPrice as ticket_list_price, tps.newPrice as ticket_new_price,tps.newPrice as ticket_gross_price, tps.id as tps_id, tps.currency_code, mec.is_combi from catalogs c left join modeventcontent mec on c.ticket_id = mec.mec_id left join ticketpriceschedule tps on mec.mec_id = tps.ticket_id where mec.deleted = '0' and date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) > CURRENT_DATE and tps.deleted = '0' and date(from_unixtime(if(tps.end_date like '9999999', '1794812755', tps.end_date))) > CURRENT_DATE) select p.*, clc.ticket_id as clcproduct_id, clc.ticketpriceschedule_id, clc.resale_currency_level from products p left join ticket_level_commission clc on p.hotel_id = clc.hotel_id and clc.deleted = '0' and p.ticket_id = clc.ticket_id and p.tps_id = clc.ticketpriceschedule_id and clc.is_adjust_pricing = '1') as final where clcproduct_id is NULL;" >> $outputFile

    # Mark each hotel_id in the batch as processed
    for hotel_id in "${batch[@]}"; do
        echo "$hotel_id" >> "$outputfolder/processed_hotelsMissingEntries.log"
    done

    

    sleep 5


done

sleep 1




