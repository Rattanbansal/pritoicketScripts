#!/bin/bash

# Path to the JSON file
JSON_FILE="mismatch.json"
rm -f UpdatequeryTLT.sql
# Check if the file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: File '$JSON_FILE' not found."
    exit 1
fi

# Batch size
BATCH_SIZE=100

# Extract template_level_tickets_id values using jq
ids=$(jq -r '.[] | .template_level_tickets_id' "$JSON_FILE")

# Convert the ids to an array
ids_array=($ids)

# Total number of ids
total_ids=${#ids_array[@]}

# Exit if total_ids is blank or zero
if [ -z "$total_ids" ] || [ "$total_ids" -eq 0 ]; then
    echo "Error: No reseller_id values found in the JSON file."
    exit 1
fi

# Process ids in batches
for (( i=0; i<$total_ids; i+=$BATCH_SIZE )); do
    # Create a batch of ids
    batch=(${ids_array[@]:$i:$BATCH_SIZE})
    # Join ids with commas
    ids_joined=$(IFS=, ; echo "${batch[*]}")
    # Construct the MySQL update query
    query="UPDATE template_level_tickets SET last_modified_at = CURRENT_TIMESTAMP WHERE template_level_tickets_id IN ($ids_joined);select ROW_COUNT();"

    echo "$query" >> UpdatequeryTLT.sql

    sleep 2
    # Execute the query
    # mysql -u "$DBUSER" -h "$DBHOST" --port=$PORT -p"$DBPWD" "$DBDATABASE" -e "$query"
done

# bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
# "insert into prioticket-reporting.prio_olap.template_level_tickets (with tltt as (select *,row_number() over(partition by template_level_tickets_id order by last_modified_at desc ) as rn from prio_test.template_level_tickets), tltl as (select *,row_number() over(partition by template_level_tickets_id order by last_modified_at desc ) as rn from prio_olap.template_level_tickets), tlttrn as (select * from tltt where rn = 1), tltlrn as (select * from tltl where rn = 1), final as (select tlttrn.*, tltlrn.template_level_tickets_id as ids from tlttrn left join tltlrn on tlttrn.template_level_tickets_id = tltlrn.template_level_tickets_id and (tlttrn.last_modified_at = tltlrn.last_modified_at or tlttrn.last_modified_at < tltlrn.last_modified_at)) select template_level_tickets_id,template_id,ticket_id,is_pos_list,created_at,market_merchant_id,content_description_setting,last_modified_at,catalog_id,merchant_admin_id,publish_catalog,deleted,hostname,is_suspended,product_verify_status from final where ids is NULL)" || exit 1