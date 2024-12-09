#!/bin/bash

# Path to the JSON file
JSON_FILE="mismatch.json"
rm -f UpdatequeryResellers.sql
# Check if the file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: File '$JSON_FILE' not found."
    exit 1
fi

# Batch size
BATCH_SIZE=100

# Extract reseller_id values using jq
ids=$(jq -r '.[] | .reseller_id' "$JSON_FILE")

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
    query="UPDATE resellers SET last_modified_at = CURRENT_TIMESTAMP WHERE reseller_id IN ($ids_joined);select ROW_COUNT();"

    echo "$query" >> UpdatequeryResellers.sql

    sleep 2
    # Execute the query
    # mysql -u "$DBUSER" -h "$DBHOST" --port=$PORT -p"$DBPWD" "$DBDATABASE" -e "$query"
done

# bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
# "insert into prioticket-reporting.prio_olap.resellers (with resellerst as (select *,row_number() over(partition by reseller_id order by last_modified_at desc ) as rn from prio_test.resellers_synch), reellersl as (select *,row_number() over(partition by reseller_id order by last_modified_at desc ) as rn from prio_olap.resellers), resellerstrn as (select * from resellerst where rn = 1), reellerslrn as (select * from reellersl where rn = 1), final as (select resellerstrn.*, reellerslrn.reseller_id as ids from resellerstrn left join reellerslrn on resellerstrn.reseller_id = reellerslrn.reseller_id and (resellerstrn.last_modified_at = reellerslrn.last_modified_at or resellerstrn.last_modified_at < reellerslrn.last_modified_at)) select reseller_id,created_date,modified_date,reseller_name,company_name,login_page_url,login_page_background_image,country_of_origin,country_code,state,state_code,currency_code,currency_hex,company_address,address2,zip_code,city,contact_person,contact_phone_number,contact_email,bus_reg_number,contact_info,reseller_invoice_type,payment_terms,invoice_terms,invoice_period,invoice_type,is_discount_show,tax_rate,is_different_tax_rate,commission_type,is_commission_fee_show,credit_limit,reseller_logo,add_tax_to_statement,bank_name,iban,bic,kvk_code,btw_code,status,template_id,template_name,channel_id,channel_name,public_product_color,private_product_color,combi_product_color,third_party_product_color,product_type_filter_settings,category,business_type,short_desc,long_desc,super_long_desc,reseller_profile_public_logo,company_profile,user_type,marketplace_settings,market_merchant_id,api_connection,marketplace_active_tab,target_market_type,target_country,target_region,target_city,standard_fee,basic_fee,basic_plus_fee,updated_at,last_modified_at,hostname,is_market_merchant,import_settings,related_reseller_id,date_format,time_format,timezone,currency_position,thousand_separator,decimal_separator,no_of_decimals,language,guest_currency,deleted,version_mapping,multi_currency,sub_catalog_id,third_party_parameters,place_id,notify_resellers,welcome_popup,related_products,cart_expiry_time from final where ids is NULL)" || exit 1
