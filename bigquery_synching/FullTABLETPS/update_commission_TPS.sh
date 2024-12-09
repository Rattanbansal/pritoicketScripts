#!/bin/bash

# Path to the JSON file
JSON_FILE="mismatch.json"
rm -f UpdatequeryTPS.sql
# Check if the file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: File '$JSON_FILE' not found."
    exit 1
fi

# Batch size
BATCH_SIZE=100

# Extract id values using jq
ids=$(jq -r '.[] | .id' "$JSON_FILE")

# Convert the ids to an array
ids_array=($ids)

# Total number of ids
total_ids=${#ids_array[@]}

# Exit if total_ids is blank or zero
if [ -z "$total_ids" ] || [ "$total_ids" -eq 0 ]; then
    echo "Error: No id values found in the JSON file."
    exit 1
fi

# Process ids in batches
for (( i=0; i<$total_ids; i+=$BATCH_SIZE )); do
    # Create a batch of ids
    batch=(${ids_array[@]:$i:$BATCH_SIZE})
    # Join ids with commas
    ids_joined=$(IFS=, ; echo "${batch[*]}")
    # Construct the MySQL update query
    query="UPDATE ticketpriceschedule SET last_modified_at = CURRENT_TIMESTAMP WHERE id IN ($ids_joined);select ROW_COUNT();"

    echo "$query" >> UpdatequeryTPS.sql

    sleep 2
    # Execute the query
    # mysql -u "$DBUSER" -h "$DBHOST" --port=$PORT -p"$DBPWD" "$DBDATABASE" -e "$query"
done


bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
"insert into prioticket-reporting.prio_olap.ticketpriceschedule (with tpst as (select *,row_number() over(partition by id order by last_modified_at desc ) as rn from prio_test.ticketpriceschedule_synch), tpsl as (select *,row_number() over(partition by id order by last_modified_at desc ) as rn from prio_olap.ticketpriceschedule), tpstrn as (select * from tpst where rn = 1), tpslrn as (select * from tpsl where rn = 1), final as (select tpstrn.*, tpslrn.id as ids from tpstrn left join tpslrn on tpstrn.id = tpslrn.id and (tpstrn.last_modified_at = tpslrn.last_modified_at or tpstrn.last_modified_at < tpslrn.last_modified_at)) select id,ticket_id,parent_ticket_id,currency_code,gt_ticket_type_id,group_linked_with,group_type_ticket,agefrom,ageto,group_price,is_time_based_ticket,pricetext,museum_price,ticket_net_price,optionaldesc,ticketType,parent_ticket_type,ticket_type_label,gender,discountType,original_price,newPrice,discount,saveamount,deal_type_free,isStandardType,totalCommission,museumCommission,museumNetPrice,subtotal,hotelCommission,hotelNetPrice,calculated_hotel_commission,calculated_hgs_commission,hgsCommission,hgsnetprice,margin,isCommissionInPercent,museum_tax_id,hotel_tax_id,hgs_tax_id,ticket_tax_id,totalNetCommission,hgs_provider_id,hgs_provider_name,ticket_tax_value,hgs_tax_value,is_commission_assigned,standard_ticket_id,timeslot,pcs,is_pos_list,show_type_on_pos,apply_service_tax,is_extra_options,no_of_extra_options,alert_pass_count,alert_capacity_count,gvb_product_id,ticket_sku,third_party_ticket_type_id,timezone,nav_item_no,checkin_points_label,checkin_points_mandatory,checkin_points,min_qty,max_qty,pax,adjust_capacity,start_date,end_date,additional_information,created_by,created_at,updated_by,updated_at,market_merchant_id,day_specific_pricing,days,default_price,default_listing,deleted,last_modified_at,hostname,additional_info,info_type,season_name,version,smartbox_price,product_rules,uniqueActivityIdConnectivity,is_scheduled from final where ids is NULL)" || exit 1
