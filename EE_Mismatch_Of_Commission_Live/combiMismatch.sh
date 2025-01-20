#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=15
DB_NAME="priopassdb"
outputFile="$PWD/records/combimismatch.csv"
source ~/vault/vault_fetch_creds.sh

mkdir -p $PWD/records
# Fetch credentials for 20Server
fetch_db_credentials "PrioticketLivePriomaryroPipe"

## GEt Distinct Reseller_id from Pricelist table



timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "select * from  (select p.*, ctd.cluster_row_id,ctd.hotel_id as old_cluster_hotel_id, ctd.main_ticket_id as cluster_product_id, ctd.main_ticket_price_schedule_id as cluster_product_type_id, ctd.cluster_ticket_id as cluster_sub_ticket_id, ctd.ticket_price_schedule_id as cluster_sub_product_type_id, ctd.is_deleted, ctd.list_price, ctd.new_price, ctd.ticket_gross_price, ctd.ticket_net_price, ctd.last_modified_at from (SELECT qc.reseller_id, qc.cod_id as company_id, qc.company, mec.mec_id, mec.cod_id, mec.museum_name, mec.postingEventTitle, mec.is_combi, mec.deleted, mec.reseller_id as product_reseller_id FROM priopassdb.qr_codes qc left join modeventcontent mec on qc.cod_id = mec.cod_id where qc.cashier_type = '2' and qc.reseller_id = '541' and mec.deleted = '0' and mec.is_combi = '2') as p left join cluster_tickets_detail ctd on p.mec_id = ctd.main_ticket_id where ctd.is_deleted = '0') as base where list_price+new_price+ticket_gross_price+ticket_net_price > '0.02' # only with price total > 0;" > $outputFile




