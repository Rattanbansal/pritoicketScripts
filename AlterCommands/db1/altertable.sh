#!/bin/bash

DB_NAME='staging_primary'

set -e

# Source the shared credential fetcher
source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "PrioticketShadow"

# Test credentials by connecting to the database
echo "Connecting to the Primary Database..."
mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "SHOW TABLES;"

# Define the ALTER TABLE queries
queries=(
  "ALTER TABLE block_order_details MODIFY COLUMN extra_options_details mediumtext;"
  "ALTER TABLE block_order_details MODIFY COLUMN person_details mediumtext;"
  "ALTER TABLE cashier_register MODIFY COLUMN last_modified_at timestamp;"
  "ALTER TABLE channel_level_commission MODIFY COLUMN combi_discount_tax_value decimal(10,2);"
  "ALTER TABLE channel_level_commission MODIFY COLUMN hgs_commission_tax_value decimal(10,2);"
  "ALTER TABLE channel_level_commission MODIFY COLUMN hotel_commission_tax_value decimal(10,2);"
  "ALTER TABLE channel_level_commission MODIFY COLUMN hgs_commission_tax_value decimal(10,2);"
  "ALTER TABLE channel_level_commission MODIFY COLUMN is_cluster_ticket_added tinyint;"
  "ALTER TABLE channel_level_commission MODIFY COLUMN market_merchant_id smallint;"
  "ALTER TABLE channel_level_commission MODIFY COLUMN ticket_tax_value decimal(10,2);"
  "ALTER TABLE credit_limit_details MODIFY COLUMN used_limit decimal(10,2);"
  "ALTER TABLE expedia_prepaid_tickets MODIFY COLUMN hotel_ticket_overview_id decimal(10,2);"
  "ALTER TABLE merchant_details MODIFY COLUMN postal_code varchar(244);"
  "ALTER TABLE merchant_details MODIFY COLUMN registration_no varchar(244);"
  "ALTER TABLE merchant_details MODIFY COLUMN vat_no varchar(244);"
  "ALTER TABLE modeventcontent MODIFY COLUMN banner_image text;"
  "ALTER TABLE modeventcontent MODIFY COLUMN barcode_specification tinyint;"
  "ALTER TABLE modeventcontent MODIFY COLUMN combi_ticket_ids text;"
  "ALTER TABLE modeventcontent MODIFY COLUMN content_description_setting text;"
  "ALTER TABLE modeventcontent MODIFY COLUMN contract_source_id tinyint;"
  "ALTER TABLE modeventcontent MODIFY COLUMN datetime_records text;"
  "ALTER TABLE modeventcontent MODIFY COLUMN grace_time_after text;"
  "ALTER TABLE modeventcontent MODIFY COLUMN grace_time_after_type text;"
  "ALTER TABLE modeventcontent MODIFY COLUMN grace_time_before text;"
  "ALTER TABLE modeventcontent MODIFY COLUMN grace_time_before_type text;"
  "ALTER TABLE modeventcontent MODIFY COLUMN last_modified_at timestamp;"
  "ALTER TABLE modeventcontent MODIFY COLUMN linked_combi_json text;"
  "ALTER TABLE modeventcontent MODIFY COLUMN modified_at datetime;"
  "ALTER TABLE modeventcontent MODIFY COLUMN notification text;"
  "ALTER TABLE modeventcontent MODIFY COLUMN notify_email varchar(244);"
  "ALTER TABLE modeventcontent MODIFY COLUMN second_party_id tinyint;"
  "ALTER TABLE modeventcontent MODIFY COLUMN third_party_id tinyint;"
  "ALTER TABLE modeventcontent MODIFY COLUMN third_party_parameters text;"
  "ALTER TABLE modeventcontent MODIFY COLUMN ticket_feature_id text;"
  "ALTER TABLE modeventcontent MODIFY COLUMN ticket_tags_id text;"
  "ALTER TABLE modeventcontent MODIFY COLUMN updated_by text;"
  "ALTER TABLE modeventcontent MODIFY COLUMN upsell_ticket_ids text;"
  "ALTER TABLE modeventcontent MODIFY COLUMN whats_included text;"
  "ALTER TABLE nav_customers MODIFY COLUMN credit_limit decimal(10,2);"
  "ALTER TABLE nav_customers MODIFY COLUMN name text;"
  "ALTER TABLE own_account_commissions MODIFY COLUMN hgs_commission_tax_value decimal(10,2);"
  "ALTER TABLE own_account_commissions MODIFY COLUMN hotel_commission_tax_value decimal(10,2);"
  "ALTER TABLE pos_tickets MODIFY COLUMN second_party_id tinyint;"
  "ALTER TABLE pos_tickets MODIFY COLUMN third_party_id tinyint;"
  "ALTER TABLE pos_tickets MODIFY COLUMN third_party_parameters text;"
  "ALTER TABLE pos_tickets MODIFY COLUMN ticket_short_desc varchar(244);"
  "ALTER TABLE prepaid_tickets MODIFY COLUMN hotel_ticket_overview_id decimal(10,2);"
  "ALTER TABLE qr_codes MODIFY COLUMN allow_reprint smallint;"
  "ALTER TABLE qr_codes MODIFY COLUMN credit_limit decimal(10,2);"
  "ALTER TABLE qr_codes MODIFY COLUMN credit_notification_settings varchar(244);"
  "ALTER TABLE qr_codes MODIFY COLUMN genericComDesc varchar(244);"
  "ALTER TABLE qr_codes MODIFY COLUMN last_modified_at timestamp;"
  "ALTER TABLE qr_codes MODIFY COLUMN manifest_version tinyint;"
  "ALTER TABLE qr_codes MODIFY COLUMN third_party_api_key varchar(244);"
  "ALTER TABLE qr_codes MODIFY COLUMN third_party_secret_key varchar(244);"
  "ALTER TABLE qr_codes MODIFY COLUMN trigger_amount decimal(10,2);"
  "ALTER TABLE resellers MODIFY COLUMN sub_catalog_id bigint;"
  "ALTER TABLE ticket_level_commission MODIFY COLUMN hotel_commission_tax_value decimal(10,2);"
  "ALTER TABLE ticket_level_commission MODIFY COLUMN hgs_commission_tax_value decimal(10,2);"
  "ALTER TABLE ticket_level_commission MODIFY COLUMN market_merchant_id smallint;"
  "ALTER TABLE ticketpriceschedule MODIFY COLUMN pricetext double;"
  "ALTER TABLE ticketpriceschedule MODIFY COLUMN updated_by varchar(244);"
  "ALTER TABLE users MODIFY COLUMN assign_tours text;"
  "ALTER TABLE users MODIFY COLUMN password text;"
  "ALTER TABLE prepaid_tickets MODIFY COLUMN refunded_by int(64)"
  "ALTER TABLE prepaid_tickets MODIFY COLUMN batch_id varchar(100)"
)

# Execute each query
for query in "${queries[@]}"; do
  echo "Executing: $query"
  if ! time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "$query"; then
    echo "Error executing query: $query" >&2
    echo "Error executing query: $query" >> errorqueries.txt
  else
    echo "Successfully executed: $query" >> successfullqueries.txt
  fi
  sleep 2
done



# 19Server_db-creds
# 20Server_db-creds
# 20ServerNoVPN_db-creds
# 19ServerNoVPN_db-creds
# OfficeLocalMachineIP5
# PrioticketLivePriomaryroPipe
# PrioticketLivePriomaryWritePipe
# PrioticketLiveRDSPipe
# PrioticketLiveSecondaryPipe
# PrioticketTest
# PrioticketShadow
# PrioticketLiveRDSCRITICAL
# PrioticketLiveSecondaryCRITICAL
