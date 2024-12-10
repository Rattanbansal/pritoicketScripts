#!/bin/bash

# Path to the JSON file
JSON_FILE="mismatch.json"
rm -f UpdatequeryDestination.sql
# Check if the file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: File '$JSON_FILE' not found."
    exit 1
fi

# Batch size
BATCH_SIZE=100

# Extract channel_level_commission_id values using jq
ids=$(jq -r '.[] | .destination_id' "$JSON_FILE")

# Convert the ids to an array
ids_array=($ids)

# Total number of ids
total_ids=${#ids_array[@]}

# Exit if total_ids is blank or zero
if [ -z "$total_ids" ] || [ "$total_ids" -eq 0 ]; then
    echo "Error: No destination_id values found in the JSON file."
    exit 1
fi

# Process ids in batches
for (( i=0; i<$total_ids; i+=$BATCH_SIZE )); do
    # Create a batch of ids
    batch=(${ids_array[@]:$i:$BATCH_SIZE})
    # Join ids with commas
    ids_joined=$(IFS=, ; echo "${batch[*]}")
    # Construct the MySQL update query
    query="UPDATE ticket_destinations SET last_modified_at = CURRENT_TIMESTAMP WHERE destination_id IN ($ids_joined);select ROW_COUNT();"

    echo "$query" >> UpdatequeryDestination.sql

    sleep 2
    # Execute the query
    # mysql -u "$DBUSER" -h "$DBHOST" --port=$PORT -p"$DBPWD" "$DBDATABASE" -e "$query"
done

bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
"insert into prioticket-reporting.prio_olap.ticket_destinations (with tdt as (select *,row_number() over(partition by destination_id order by last_modified_at desc ) as rn from prio_test.ticket_destinations_synch), tdl as (select *,row_number() over(partition by destination_id order by last_modified_at desc ) as rn from prio_olap.ticket_destinations), tdtrn as (select * from tdt where rn = 1), tdlrn as (select * from tdl where rn = 1), final as (select tdtrn.*, tdlrn.destination_id as ids from tdtrn left join tdlrn on tdtrn.destination_id = tdlrn.destination_id and (tdtrn.last_modified_at = tdlrn.last_modified_at or tdtrn.last_modified_at < tdlrn.last_modified_at)) select destination_id,slug,name,destination_logo,is_checked,cod_id,is_global_destination,description,position,reseller_destination_logo,created_by,updated_by,updated_at,created_at,last_modified_at,thumbnails,destination_type,parent_destination_id,hostname,is_deleted from final where ids is NULL)" || exit 1