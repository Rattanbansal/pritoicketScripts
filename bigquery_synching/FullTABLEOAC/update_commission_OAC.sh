#!/bin/bash

# Path to the JSON file
JSON_FILE="mismatch.json"
rm -f UpdatequeryOAC.sql
# Check if the file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: File '$JSON_FILE' not found."
    exit 1
fi

# Batch size
BATCH_SIZE=100

# Extract channel_level_commission_id values using jq
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
    query="UPDATE own_account_commissions SET last_modified_at = CURRENT_TIMESTAMP WHERE id IN ($ids_joined);select ROW_COUNT();"

    echo "$query" >> UpdatequeryOAC.sql

    sleep 2
    # Execute the query
    # mysql -u "$DBUSER" -h "$DBHOST" --port=$PORT -p"$DBPWD" "$DBDATABASE" -e "$query"
done

bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
"insert into prioticket-reporting.prio_olap.own_account_commissions (with oact as (select *,row_number() over(partition by id order by last_modified_at desc ) as rn from prio_test.own_account_commissions), oacl as (select *,row_number() over(partition by id order by last_modified_at desc ) as rn from prio_olap.own_account_commissions), oactrn as (select * from oact where rn = 1), oaclrn as (select * from oacl where rn = 1), final as (select oactrn.*, oaclrn.id as ids from oactrn left join oaclrn on oactrn.id = oaclrn.id and (oactrn.last_modified_at = oaclrn.last_modified_at or oactrn.last_modified_at < oaclrn.last_modified_at)) select id,channel_id,catalog_id,partner_id,price_setting_type,ticket_id,ticket_title,ticket_net_price,ticket_gross_price,currency,hotel_prepaid_commission_percentage,hgs_prepaid_commission_percentage,hotel_commission_tax_id,hotel_commission_tax_value,hgs_commission_tax_id,hgs_commission_tax_value,is_hotel_prepaid_commission_percentage,commission_on_sale_price,hotel_commission_gross_price,hotel_commission_net_price,hgs_commission_gross_price,hgs_commission_net_price,priority_over_ticket_type,deleted,pricing_level,last_modified_at,created_at,updated_by,hostname,ip_address from final where ids is NULL)" || exit 1