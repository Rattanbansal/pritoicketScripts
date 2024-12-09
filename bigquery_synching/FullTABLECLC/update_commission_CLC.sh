#!/bin/bash

# Path to the JSON file
JSON_FILE="mismatch.json"
rm -f Updatequeryclc.sql
# Check if the file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: File '$JSON_FILE' not found."
    exit 1
fi

# Batch size
BATCH_SIZE=100

# Extract channel_level_commission_id values using jq
ids=$(jq -r '.[] | .channel_level_commission_id' "$JSON_FILE")

# Convert the ids to an array
ids_array=($ids)

# Total number of ids
total_ids=${#ids_array[@]}

# Exit if total_ids is blank or zero
if [ -z "$total_ids" ] || [ "$total_ids" -eq 0 ]; then
    echo "Error: No channel_level_commission_id values found in the JSON file."
    exit 1
fi

# Process ids in batches
for (( i=0; i<$total_ids; i+=$BATCH_SIZE )); do
    # Create a batch of ids
    batch=(${ids_array[@]:$i:$BATCH_SIZE})
    # Join ids with commas
    ids_joined=$(IFS=, ; echo "${batch[*]}")
    # Construct the MySQL update query
    query="UPDATE channel_level_commissions SET last_modified_at = CURRENT_TIMESTAMP WHERE channel_level_commission_id IN ($ids_joined);select ROW_COUNT();"

    echo "$query" >> Updatequeryclc.sql

    sleep 2
    # Execute the query
    # mysql -u "$DBUSER" -h "$DBHOST" --port=$PORT -p"$DBPWD" "$DBDATABASE" -e "$query"
done

echo "Started Inserting Missing Records"

# Execute the query

# bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
# "insert into prioticket-reporting.prio_olap.channel_level_commission (with tlc1 as (select *,row_number() over(partition by channel_level_commission_id order by last_modified_at desc ) as rn from prioticket-reporting.prio_test.channel_level_mismatch), tlc as (select * from tlc1 where rn=1 and last_modified_at > TIMESTAMP(CONCAT(CAST(DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL $noOfdays DAY)) AS STRING), ' 00:00:00')) AND last_modified_at <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 45 MINUTE)), clc1 as (select *,row_number() over(partition by channel_level_commission_id order by last_modified_at desc ) as rn from prioticket-reporting.prio_olap.channel_level_commission), clc as (select * from clc1 where rn=1 and last_modified_at > TIMESTAMP(CONCAT(CAST(DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL $noOfdays DAY)) AS STRING), ' 00:00:00')) AND last_modified_at <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 45 MINUTE)), base as (SELECT tlc.*, clc.channel_level_commission_id as id FROM tlc left join  clc on tlc.channel_level_commission_id = clc.channel_level_commission_id and tlc.ticket_id = clc.ticket_id and tlc.ticketpriceschedule_id = clc.ticketpriceschedule_id and (tlc.last_modified_at = clc.last_modified_at or tlc.last_modified_at <= clc.last_modified_at)) select channel_level_commission_id,created_at,channel_id,ticket_id,ticketpriceschedule_id,museum_name,ticket_title,ticket_type,ticket_scan_price,ticket_list_price,ticket_new_price,ticket_discount,is_discount_in_percent,ticket_gross_price,ticket_tax_value,ticket_tax_id,ticket_net_price,museum_commission_old,museum_gross_commission,museum_net_commission,museum_commission_tax_value,museum_commission_tax_id,subtotal_net_amount,subtotal_gross_amount,subtotal_tax_value,subtotal_tax_id,is_combi_ticket_allowed,is_combi_discount,tickets_for_combi_discount,combi_discount_gross_amount,combi_discount_net_amount,combi_discount_tax_value,combi_discount_tax_id,commission_updated_at,'224.11.26.133' as ip_address,hotel_prepaid_commission_percentage,hotel_postpaid_commission_percentage,hotel_commission_tax_id,hotel_commission_tax_value,hgs_prepaid_commission_percentage,hgs_postpaid_commission_percentage,hgs_commission_tax_id,hgs_commission_tax_value,merchant_gross_commission,is_adjust_pricing,is_custom_setting,apply_service_tax,external_product_id,account_number,chart_number,deleted,market_merchant_id,merchant_net_commission,merchant_admin_id,merchant_admin_name,is_cluster_ticket_added,default_listing,catalog_id,last_modified_at,resale_percentage,is_resale_percentage,merchant_fee_percentage,is_merchant_fee_percentage,is_hotel_prepaid_commission_percentage,commission_on_sale_price,hotel_commission_gross_price,hotel_commission_net_price,hgs_commission_gross_price,hgs_commission_net_price,product_type,currency,resale_currency_level,resale_commission,affected_date,is_active,publish_level,channel_level,reseller_id,own_merchant_id,hostname,affected_before_date,discount_label,discount_setting_type,market_merchant_name,custom_setting_moved from base where id is NULL)" || exit 1
