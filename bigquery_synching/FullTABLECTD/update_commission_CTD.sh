#!/bin/bash

# Path to the JSON file
JSON_FILE="mismatch.json"
rm -f Updatequeryctd.sql
# Check if the file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: File '$JSON_FILE' not found."
    exit 1
fi

# Batch size
BATCH_SIZE=100

# Extract channel_level_commission_id values using jq
ids=$(jq -r '.[] | .cluster_row_id' "$JSON_FILE")

# Convert the ids to an array
ids_array=($ids)

# Total number of ids
total_ids=${#ids_array[@]}

# Exit if total_ids is blank or zero
if [ -z "$total_ids" ] || [ "$total_ids" -eq 0 ]; then
    echo "Error: No cluster_row_id values found in the JSON file."
    exit 1
fi

# Process ids in batches
for (( i=0; i<$total_ids; i+=$BATCH_SIZE )); do
    # Create a batch of ids
    batch=(${ids_array[@]:$i:$BATCH_SIZE})
    # Join ids with commas
    ids_joined=$(IFS=, ; echo "${batch[*]}")
    # Construct the MySQL update query
    query="UPDATE cluster_tickets_detail SET last_modified_at = CURRENT_TIMESTAMP WHERE cluster_row_id IN ($ids_joined);select ROW_COUNT();"

    echo "$query" >> Updatequeryctd.sql

    sleep 2
    # Execute the query
    # mysql -u "$DBUSER" -h "$DBHOST" --port=$PORT -p"$DBPWD" "$DBDATABASE" -e "$query"
done

# bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
# "insert into prioticket-reporting.prio_olap.cluster_tickets_detail (with cluster_tickets_detailt as (select *,row_number() over(partition by cluster_row_id order by last_modified_at desc ) as rn from prio_test.cluster_tickets_detail_synch), cluster_tickets_detaill as (select *,row_number() over(partition by cluster_row_id order by last_modified_at desc ) as rn from prio_olap.cluster_tickets_detail), cluster_tickets_detailtrn as (select * from cluster_tickets_detailt where rn = 1), cluster_tickets_detaillrn as (select * from cluster_tickets_detaill where rn = 1), final as (select cluster_tickets_detailtrn.*, cluster_tickets_detaillrn.cluster_row_id as ids from cluster_tickets_detailtrn left join cluster_tickets_detaillrn on cluster_tickets_detailtrn.cluster_row_id = cluster_tickets_detaillrn.cluster_row_id and (cluster_tickets_detailtrn.last_modified_at = cluster_tickets_detaillrn.last_modified_at or cluster_tickets_detailtrn.last_modified_at < cluster_tickets_detaillrn.last_modified_at)) select cluster_row_id,created_at,hotel_id,combi_museum_id,main_ticket_id,main_ticket_price_schedule_id,cluster_ticket_id,cluster_ticket_title,ticket_museum_id,ticket_museum_name,museum_id,age_group,ticket_type,age_from,age_to,pax,adjust_capacity,ticket_price_schedule_id,is_reservation,scan_price,discountType,discount,saveamount,reseller_margin,list_price,new_price,ticket_gross_price,ticket_tax_id,ticket_tax_value,ticket_net_price,is_deleted,updated_at,product_type,dependency,merchant_admin_id,merchant_admin_name,barcode_type,third_party_id,third_party_ticket_type_id,third_party_parameters,last_modified_at,hostname,resale_gross_price,resale_net_price,is_combi,currency,base_price from final where ids is NULL)" || exit 1