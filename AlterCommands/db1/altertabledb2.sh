#!/bin/bash

DB_NAME='test_secondary'

set -e

# Source the shared credential fetcher
source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "PrioticketTest"

# Test credentials by connecting to the database
echo "Connecting to the Primary Database..."
mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "SHOW TABLES;"

# Define the ALTER TABLE queries
queries=(
"ALTER TABLE prepaid_tickets MODIFY COLUMN additional_information varchar(255);"
"ALTER TABLE prepaid_tickets MODIFY COLUMN batch_id varchar(255);"
"ALTER TABLE prepaid_tickets MODIFY COLUMN chart_number varchar(255);"
"ALTER TABLE prepaid_tickets MODIFY COLUMN currency_rate float;"
"ALTER TABLE prepaid_tickets MODIFY COLUMN discount_code_amount float;"
"ALTER TABLE prepaid_tickets MODIFY COLUMN hotel_ticket_overview_id decimal(10,2);"
"ALTER TABLE prepaid_tickets MODIFY COLUMN is_data_moved int;"
"ALTER TABLE prepaid_tickets MODIFY COLUMN last_imported_date varchar(255);"
"ALTER TABLE prepaid_tickets MODIFY COLUMN order_cancellation_date varchar(255);"
"ALTER TABLE prepaid_tickets MODIFY COLUMN refunded_by int;"
"ALTER TABLE prepaid_tickets MODIFY COLUMN voucher_creation_date varchar(255);"
"ALTER TABLE visitor_tickets MODIFY COLUMN order_cancellation_date varchar(255);"
)

# Execute each query
for query in "${queries[@]}"; do
  echo "Executing: $query"
  if ! time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "$query"; then
    echo "Error executing query: $query" >&2
    echo "Error executing query: $query" >> errorqueries2.txt
  else
    echo "Successfully executed: $query" >> successfullqueries2.txt
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
