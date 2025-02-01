#!/bin/bash

# Start time
start_time=$(date +%s)
set -e  # Exit immediately if any command exits with a non-zero status
set -o pipefail  # Catch errors in piped commands
set -u  # Treat unset variables as an error

# Function to handle errors
handle_error() {
    echo "❌ Error occurred! Exiting..."
    paplay /usr/share/sounds/freedesktop/stereo/dialog-error.oga  # Error sound
    exit 1
}

# Trap errors and call handle_error
trap 'handle_error' ERR

# rm -f mismatch.csv

source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"
DB_NAME='rattan'
BATCH_SIZE=100
from_date=$1
to_date=$2
TIMEOUT_PERIOD=450
TIMEOUT_PERIODLIVE=25

BQ_QUERY_FILE="bq_query.sql"
OUTPUT_FILE="bq_output.csv"
MYSQL_TABLE="scanning"
startDate="$from_date 00:00:01"
endDate="$to_date 23:59:59"
uploadData=$3
echo $startDate
echo $endDate

# ./getDataFromBigQuery.sh <startdate> <enddate> <upload: upload to bigquery>

if [[ "$uploadData" == "upload" ]]; then 

  rm -f $OUTPUT_FILE

  BQ_QUERY_FILE="WITH
  pt1 AS (
      SELECT *, 
            ROW_NUMBER() OVER (PARTITION BY prepaid_ticket_id ORDER BY last_modified_at DESC, IFNULL(version, '1') DESC) AS rn 
      FROM prio_olap.scan_report
  ),
  pt AS (
      SELECT * 
      FROM pt1 
      WHERE rn=1 AND deleted=0
  ),vt1 AS (
      SELECT *, 
            ROW_NUMBER() OVER (PARTITION BY id ORDER BY last_modified_at DESC, IFNULL(version, '1') DESC) AS rn 
      FROM prio_olap.financial_transactions
  ),
  vt AS (
      SELECT * 
      FROM vt1 
      WHERE rn=1 AND deleted='0'
  ), scantborders as (select distinct visitor_group_no from pt where action_performed like '%SCAN_TB%' and order_confirm_date > '$startDate'), ptfinal as (select pt.visitor_group_no,pt.order_confirm_date,pt.ticket_id,pt.tps_id,pt.is_refunded,pt.prepaid_ticket_id,pt.ticket_type,pt.used,pt.action_performed,pt.activated,pt.redeem_date_time,pt.redemption_notified_at ,pt.version from pt where pt.visitor_group_no in (select visitor_group_no from scantborders) and pt.is_addon_ticket != '2'), vtfinal as (select vt.vt_group_no, vt.order_confirm_date, vt.transaction_id, vt.tickettype_name,vt.ticketId,vt.ticketpriceschedule_id, vt.used, vt.action_performed, vt.visit_date_time, vt.version,vt.is_refunded, vt.row_type from vt where vt.vt_group_no in (select visitor_group_no from scantborders) and vt.col2!= 2 and row_type =1), finalData as (select ptfinal.visitor_group_no as pt_order_id, vtfinal.vt_group_no as vt_order_id, ptfinal.prepaid_ticket_id as pt_transactionId, vtfinal.transaction_id as vt_transactionId, ptfinal.version as pt_version, vtfinal.version as vt_version, ptfinal.ticket_id as ptticketId, vtfinal.ticketId as vt_ticketId, ptfinal.tps_id as pt_tpsId, vtfinal.ticketpriceschedule_id as vt_tpsId, ptfinal.action_performed as pt_actionPerformed, vtfinal.action_performed as vt_actionPeformed, ptfinal.used as pt_used, vtfinal.used as vt_used, ptfinal.redeem_date_time as pt_redeemDate, vtfinal.visit_date_time as vt_redeemDate, ptfinal.is_refunded as pt_refunded, vtfinal.is_refunded as vt_refunded, 0 as status from ptfinal left join vtfinal on ptfinal.visitor_group_no = vtfinal.vt_group_no and ptfinal.prepaid_ticket_id = vtfinal.transaction_id) select * from finalData where (pt_version != vt_version or pt_used != vt_used or ABS(TIMESTAMP_DIFF(pt_redeemDate, vt_redeemDate, SECOND)) > 10800) and pt_used = '1'"

  # Step 2: Run BigQuery Command
  echo "Running BigQuery Query..."

  gcloud config set project prioticket-reporting


  bq query --use_legacy_sql=False --max_rows=10000000 --format=csv \
  "$BQ_QUERY_FILE" > $OUTPUT_FILE || exit 1

  if [ $? -ne 0 ]; then
      echo "BigQuery query failed. Exiting."
      exit 1
  fi

  echo "BigQuery query successful. Data saved to $OUTPUT_FILE."

  # Step 3: Insert Data into MySQL
  echo "Inserting data into MySQL table..."



  timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "DROP TABLE IF EXISTS $MYSQL_TABLE" || exit 1

  # Create the table if it does not exist
  create_table_query="CREATE TABLE IF NOT EXISTS $MYSQL_TABLE (
      pt_order_id VARCHAR(255),
      vt_order_id VARCHAR(255),
      pt_transactionId VARCHAR(255),
      vt_transactionId VARCHAR(255),
      pt_version VARCHAR(255),
      vt_version VARCHAR(255),
      ptticketId VARCHAR(255),
      vtticketId VARCHAR(255),
      pt_tpsId VARCHAR(255),
      vt_tpsId VARCHAR(255),
      pt_actionPerformed VARCHAR(255),
      vt_actionPerformed VARCHAR(255),
      pt_used VARCHAR(255),
      vt_used VARCHAR(255),
      pt_redeemDate VARCHAR(255),
      vt_redeemDate VARCHAR(255),
      pt_refunded VARCHAR(255),
      vt_refunded VARCHAR(255),
      status VARCHAR(255)
  );"

  # Execute the query to create the table
  timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "$create_table_query" || exit 1

  mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "SET GLOBAL local_infile = 1;"

  echo "status of query to alter table"

  # Load the CSV data into the table
  mysql --local-infile=1 -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" <<EOF
  LOAD DATA LOCAL INFILE '$OUTPUT_FILE'
  INTO TABLE $MYSQL_TABLE
  FIELDS TERMINATED BY ',' 
  ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 ROWS
  (pt_order_id, vt_order_id,pt_transactionId, vt_transactionId, pt_version, vt_version, ptticketId, vtticketId, pt_tpsId, vt_tpsId, pt_actionPerformed,vt_actionPerformed,pt_used,vt_used,pt_redeemDate,vt_redeemDate,pt_refunded,vt_refunded,status);
EOF


  echo "status of query to insert data"
  echo "Data successfully loaded into table: $MYSQL_TABLE"

fi

timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "select count(*) from $MYSQL_TABLE;select count(distinct(pt_order_id)) from $MYSQL_TABLE;"

vt_group_numbers=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "select distinct(pt_order_id) from $MYSQL_TABLE where status = '0' limit 200;") || exit 1


source ~/vault/vault_fetch_credsLive.sh

# Fetch credentials for LIVERDSServer
fetch_db_credentials "PrioticketLiveSecondaryPipe"
DB_NAMELIVE='priopassdb'

# Convert the vt_group_numbers into an array
vt_group_array=($vt_group_numbers)
total_vt_groups=${#vt_group_array[@]}

# Print the total count of vt_group_no for the current ticket_id
echo "Processing $total_vt_groups vt_group_no values"

# Initialize the progress tracking for the current ticket_id
current_progress=0

# Loop through vt_group_no array in batches
for ((i=0; i<$total_vt_groups; i+=BATCH_SIZE)); do
    # Create a batch of vt_group_no values
    batch=("${vt_group_array[@]:$i:$BATCH_SIZE}")
    batch_size=${#batch[@]}

    # Calculate the current progress level for this ticket_id
    current_progress=$((i + batch_size))
    
    # Join the batch into a comma-separated list
    batch_str=$(IFS=,; echo "${batch[*]}")

    # Print progress information for the current ticket_id
    echo "Processing batch of size $batch_size ($current_progress / $total_vt_groups processed)" >> log.txt

    echo "$batch_str"

    echo "-----Started Running Insert query VT----------"
    timeout $TIMEOUT_PERIODLIVE time mysql -h"$DB_HOSTLIVE" -u"$DB_USERLIVE" --port=$DB_PORTLIVE -p"$DB_PASSWORDLIVE" -D"$DB_NAMELIVE" -sN -e "insert into visitor_tickets (id, created_date, transaction_id, invoice_id, channel_id, channel_name, reseller_id, reseller_name, saledesk_id, saledesk_name, financial_id, financial_name, transaction_type_name, transaction_type_id, ticketId, shared_capacity_id, ticket_booking_id, related_order_id, related_booking_id, ticket_title, ticketwithdifferentpricing, ticketpriceschedule_id, ticket_extra_option_id, group_type_ticket, group_price, group_quantity, group_linked_with, selected_date, booking_selected_date, from_time, to_time, slot_type, amount_before_extra_discount, discount_before_extra_discount, hto_id, visitor_group_no, roomNo, nights, user_age, gender, user_image, visitor_country, merchantAccountCode, merchantReference, original_pspReference, shopperReference, partner_id, relational_partner_id, partner_name, museum_name, museum_id, hotel_name, hotel_id, pos_point_id, pos_point_name, shift_id, passNo, pass_type, ticketAmt, visit_date, visit_date_time, ticketType, tickettype_name, discount_applied_on_how_many_tickets, paid, payment_method, isBillToHotel, card_name, pspReference, card_type, captured, age_group, discount, isDiscountInPercent, updated_discount_type, without_elo_reference_no, debitor, creditor, split_cash_amount, split_card_amount, split_voucher_amount, split_direct_payment_amount, total_gross_commission, total_net_commission, commission_type, partner_gross_price, order_currency_partner_gross_price, partner_gross_price_without_combi_discount, partner_net_price, order_currency_partner_net_price, partner_net_price_without_combi_discount, isCommissionInPercent, tax_id, tax_value, tax_name, timezone, invoice_status, row_type, updated_by_id, updated_by_username, voucher_updated_by, voucher_updated_by_name, redeem_method, redeem_by_ticket_id, redeem_by_ticket_title, cashier_id, cashier_name, cashier_register_id, targetlocation, paymentMethodType, targetcity, service_name, adjustment_row_type, description, distributor_status, adyen_status, adjustment_method, all_ticket_ids, time_based_done, visitor_invoice_id, ticketPrice, deleted, is_refunded, is_block, is_edited, vt_group_no, user_name, issuer_country_code, distributor_commission_invoice, activation_method, is_prioticket, is_shop_product, shop_category_name, external_account_number, used, ticket_status, is_prepaid, is_purchased_with_postpaid, invoice_type, supplier_currency_symbol, order_currency_code, order_currency_symbol, currency_rate, invoice_variant, service_cost, service_cost_net_amount, service_cost_type, scanned_pass, groupTransactionId, booking_status, channel_type, is_voucher, extra_text_field_answer, distributor_type, distributor_partner_id, distributor_partner_name, issuer_country_name, chart_number, extra_discount, manual_payment_note, account_number, is_custom_setting, external_product_id, supplier_currency_code, col1, col2, partner_category_id, col4, partner_category_name, col6, col7, col8, is_data_moved, action_performed, updated_at, tp_payment_method, order_confirm_date, payment_date, order_cancellation_date, voucher_creation_date, primary_host_name,supplier_gross_price, supplier_discount, supplier_ticket_amt, supplier_tax_value,supplier_net_price, last_modified_at, market_merchant_id, merchant_admin_id, order_updated_cashier_id, order_updated_cashier_name, version, supplier_tax_id, merchant_currency_code, merchant_price, merchant_net_price, merchant_tax_id, admin_currency_code) select vtf.id, vtf.created_date, vtf.transaction_id, vtf.invoice_id, vtf.channel_id, vtf.channel_name, vtf.reseller_id, vtf.reseller_name, vtf.saledesk_id, vtf.saledesk_name, vtf.financial_id, vtf.financial_name, vtf.transaction_type_name, vtf.transaction_type_id, vtf.ticketId, vtf.shared_capacity_id, vtf.ticket_booking_id, vtf.related_order_id, vtf.related_booking_id, vtf.ticket_title, vtf.ticketwithdifferentpricing, vtf.ticketpriceschedule_id, vtf.ticket_extra_option_id, vtf.group_type_ticket, vtf.group_price, vtf.group_quantity, vtf.group_linked_with, vtf.selected_date, vtf.booking_selected_date, vtf.from_time, vtf.to_time, vtf.slot_type, vtf.amount_before_extra_discount, vtf.discount_before_extra_discount, vtf.hto_id, vtf.visitor_group_no, vtf.roomNo, vtf.nights, vtf.user_age, vtf.gender, vtf.user_image, vtf.visitor_country, vtf.merchantAccountCode, vtf.merchantReference, vtf.original_pspReference, vtf.shopperReference, vtf.partner_id, vtf.relational_partner_id, vtf.partner_name, vtf.museum_name, vtf.museum_id, vtf.hotel_name, vtf.hotel_id, vtf.pos_point_id, vtf.pos_point_name, vtf.shift_id, vtf.passNo, vtf.pass_type, vtf.ticketAmt, DATE(mm.pt_redeemDate) as visit_date, mm.pt_redeemDate as visit_date_time, vtf.ticketType, vtf.tickettype_name, vtf.discount_applied_on_how_many_tickets, vtf.paid, vtf.payment_method, vtf.isBillToHotel, vtf.card_name, vtf.pspReference, vtf.card_type, vtf.captured, vtf.age_group, vtf.discount, vtf.isDiscountInPercent, vtf.updated_discount_type, vtf.without_elo_reference_no, vtf.debitor, vtf.creditor, vtf.split_cash_amount, vtf.split_card_amount, vtf.split_voucher_amount, vtf.split_direct_payment_amount, vtf.total_gross_commission, vtf.total_net_commission, vtf.commission_type, vtf.partner_gross_price, vtf.order_currency_partner_gross_price, vtf.partner_gross_price_without_combi_discount, vtf.partner_net_price, vtf.order_currency_partner_net_price, vtf.partner_net_price_without_combi_discount, vtf.isCommissionInPercent, vtf.tax_id, vtf.tax_value, vtf.tax_name, vtf.timezone, vtf.invoice_status, vtf.row_type, vtf.updated_by_id, vtf.updated_by_username, vtf.voucher_updated_by, vtf.voucher_updated_by_name, vtf.redeem_method, vtf.redeem_by_ticket_id, vtf.redeem_by_ticket_title, vtf.cashier_id, vtf.cashier_name, vtf.cashier_register_id, vtf.targetlocation, vtf.paymentMethodType, vtf.targetcity, vtf.service_name, vtf.adjustment_row_type, vtf.description, vtf.distributor_status, vtf.adyen_status, vtf.adjustment_method, vtf.all_ticket_ids, vtf.time_based_done, vtf.visitor_invoice_id, vtf.ticketPrice, vtf.deleted, vtf.is_refunded, vtf.is_block, vtf.is_edited, vtf.vt_group_no, vtf.user_name, vtf.issuer_country_code, vtf.distributor_commission_invoice, vtf.activation_method, vtf.is_prioticket, vtf.is_shop_product, vtf.shop_category_name, vtf.external_account_number, mm.pt_used as used, vtf.ticket_status, vtf.is_prepaid, vtf.is_purchased_with_postpaid, vtf.invoice_type, vtf.supplier_currency_symbol, vtf.order_currency_code, vtf.order_currency_symbol, vtf.currency_rate, vtf.invoice_variant, vtf.service_cost, vtf.service_cost_net_amount, vtf.service_cost_type, vtf.scanned_pass, vtf.groupTransactionId, vtf.booking_status, vtf.channel_type, vtf.is_voucher, vtf.extra_text_field_answer, vtf.distributor_type, vtf.distributor_partner_id, vtf.distributor_partner_name, vtf.issuer_country_name, vtf.chart_number, vtf.extra_discount, vtf.manual_payment_note, vtf.account_number, vtf.is_custom_setting, vtf.external_product_id, vtf.supplier_currency_code, vtf.col1, vtf.col2, vtf.partner_category_id, vtf.col4, vtf.partner_category_name, vtf.col6, vtf.col7, vtf.col8, vtf.is_data_moved, concat(mm.pt_actionPerformed, ', SCANOPTMIZE') as action_performed, vtf.updated_at, vtf.tp_payment_method, vtf.order_confirm_date, vtf.payment_date, vtf.order_cancellation_date, vtf.voucher_creation_date, vtf.primary_host_name,vtf.supplier_gross_price, vtf.supplier_discount, vtf.supplier_ticket_amt, vtf.supplier_tax_value,vtf.supplier_net_price,CURRENT_TIMESTAMP as last_modified_at, vtf.market_merchant_id, vtf.merchant_admin_id, vtf.order_updated_cashier_id, vtf.order_updated_cashier_name, case when mm.pt_version-mm.vt_version > '0' then ROUND(mm.pt_version,1) else ROUND((vtf.version+1),1) end as version, vtf.supplier_tax_id, vtf.merchant_currency_code, vtf.merchant_price, vtf.merchant_net_price, vtf.merchant_tax_id, vtf.admin_currency_code from visitor_tickets vtf join (select ptt.visitor_group_no as pt_orderId, vt.vt_group_no as vt_orderId, ptt.prepaid_ticket_id as pt_transactionId, vt.transaction_id as vt_transactionId, ptt.version as pt_version, vt.version as vt_version, ptt.used as pt_used, vt.used as vt_used, ptt.redeem_date_time as pt_redeemDate, vt.visit_date_time as vt_redeemDate, ptt.action_performed as pt_actionPerformed, vt.action_performed as vt_actionPerformed from (select pt.visitor_group_no, pt.prepaid_ticket_id, pt.version, pt.used, pt.redeem_date_time, pt.action_performed from prepaid_tickets pt join (SELECT visitor_group_no, prepaid_ticket_id, max(version) as version FROM prepaid_tickets where visitor_group_no in ($batch_str) and is_addon_ticket != '2' group by prepaid_ticket_id, visitor_group_no) as base on pt.visitor_group_no = base.visitor_group_no and ABS(pt.version-base.version) = '0' and pt.prepaid_ticket_id = base.prepaid_ticket_id and pt.used = '1') as ptt left join (select vtt.vt_group_no, vtt.version, vtt.transaction_id, vtt.used, vtt.visit_date_time, vtt.action_performed from visitor_tickets vtt join (SELECT vt_group_no,transaction_id, row_type,max(version) as version FROM visitor_tickets where vt_group_no in ($batch_str) and col2 != '2' and row_type = '1' group by transaction_id, vt_group_no,row_type) as base1 on vtt.vt_group_no = base1.vt_group_no and ABS(vtt.version-base1.version) = '0' and vtt.transaction_id = base1.transaction_id and vtt.row_type = base1.row_type where vtt.col2 != '2') vt on ptt.visitor_group_no = vt.vt_group_no and ptt.prepaid_ticket_id = vt.transaction_id where ROUND(ABS(ptt.used-vt.used)) != '0' or ABS(TIMESTAMPDIFF(MINUTE, ptt.redeem_date_time, vt.visit_date_time)) > 180 or ABS(ptt.version-vt.version) != '0') as mm on vtf.vt_group_no = mm.vt_orderId and vtf.transaction_id = mm.vt_transactionId and ABS(vtf.version-mm.vt_version) = '0' and vtf.col2 != '2' where vtf.vt_group_no in ($batch_str);select ROW_COUNT();" || exit 1
    echo "<<<<<<<<<<<Insert Query To Visitor Tickets Ended>>>>>>>>>"

    sleep 5

    echo "-----Started Running Insert Query Prepaid Tickets----------"
    timeout $TIMEOUT_PERIODLIVE time mysql -h"$DB_HOSTLIVE" -u"$DB_USERLIVE" --port=$DB_PORTLIVE -p"$DB_PASSWORDLIVE" -D"$DB_NAMELIVE" -sN -e "insert into prepaid_tickets (prepaid_ticket_id, is_combi_ticket, visitor_group_no, ticket_id, shared_capacity_id, ticket_booking_id, related_order_id, related_booking_id, hotel_ticket_overview_id, hotel_id, own_supplier_id, distributor_partner_id, distributor_partner_name, hotel_name, shift_id, cashier_register_id, pos_point_id, pos_point_name, channel_id, channel_name, reseller_id, reseller_name, saledesk_id, saledesk_name, title, age_group, museum_id, museum_name, additional_information, location, highlights, image, oroginal_price, order_currency_oroginal_price, discount, order_currency_discount, is_discount_in_percent, price, order_currency_price, ticket_scan_price, cc_rows_value, tax, distributor_type, tax_name, net_price, order_currency_net_price, ticket_amount_before_extra_discount, extra_discount, extra_fee, order_currency_extra_discount, is_combi_discount, combi_discount_gross_amount, order_currency_combi_discount_gross_amount, is_discount_code, discount_code_value, discount_code_amount, order_currency_discount_code_amount, discount_code_promotion_title, service_cost_type, service_cost, net_service_cost, ticket_type, ticket_type_additional_info, discount_applied_on_how_many_tickets, quantity, refund_quantity, timeslot, from_time, to_time, selected_date, booking_selected_date, valid_till, created_date_time, created_at, scanned_at, redemption_notified_at,action_performed, redeem_date_time, is_prioticket, product_type, shop_category_name, rezgo_id, rezgo_ticket_id, rezgo_ticket_price, tps_id, group_type_ticket, group_price, group_quantity, group_linked_with, group_id, supplier_currency_code, supplier_currency_symbol, order_currency_code, order_currency_symbol, currency_rate, selected_quantity, min_qty, max_qty, passNo, bleep_pass_no, pass_type, used, activated, visitor_tickets_id, activation_method, invoice_method_label, booking_type, split_payment_detail, timezone, is_pre_selected_ticket, is_prepaid, is_cancelled, deleted, time_based_done, booking_status, order_status, is_refunded, refunded_by, without_elo_reference_no, is_voucher, is_iticket_product, reference_id, is_addon_ticket, cluster_group_id, clustering_id, related_product_id, parent_product_id, related_product_title, pos_point_id_on_redeem, pos_point_name_on_redeem, distributor_id_on_redeem, distributor_cashier_id_on_redeem, third_party_type, third_party_booking_reference, third_party_response_data, supplier_original_price, supplier_discount, supplier_price, supplier_tax, supplier_net_price,museum_net_fee, distributor_net_fee,hgs_net_fee,museum_gross_fee, distributor_gross_fee,hgs_gross_fee, second_party_type, second_party_booking_reference, second_party_passNo, batch_id, batch_reference, cashier_id, cashier_name, redeem_users, cashier_code, location_code, voucher_updated_by, voucher_updated_by_name, redeem_method, tp_payment_method, order_confirm_date, payment_date, museum_cashier_id, museum_cashier_name, extra_text_field_answer, pick_up_location, refund_note, manual_payment_note, channel_type, financial_id, financial_name, is_custom_setting, external_product_id, account_number, chart_number, is_invoice, split_card_amount, split_cash_amount, split_voucher_amount, split_direct_payment_amount, is_data_moved, last_imported_date, redeem_by_ticket_id, redeem_by_ticket_title, updated_at, commission_type, barcode_type, guest_names, guest_emails, secondary_guest_email, secondary_guest_name, passport_number, order_status_hto, pspReference, merchantReference, merchantAccountCode, reserved_1, reserved_2, reserved_3, authcode, payment_gateway, payment_conditions, payment_term_category, order_cancellation_date, voucher_creation_date, partner_category_id, partner_category_name,last_modified_at, order_updated_cashier_id, order_updated_cashier_name, primary_host_name, is_order_confirmed, booking_information, extra_booking_information, contact_details, contact_information, phone_number, booking_details, market_merchant_id, merchant_admin_id, pax, capacity, commission_json, supplier_cost, partner_cost, tax_id, tax_exception_applied, version, supplier_tax_id, merchant_currency_code, merchant_price, merchant_net_price, merchant_tax_id, admin_currency_code, expiry_date, validity_date, \`unlock\`, checkin_uid, checkin_date, voucher_release_date) select ptf.prepaid_ticket_id, ptf.is_combi_ticket, ptf.visitor_group_no, ptf.ticket_id, ptf.shared_capacity_id, ptf.ticket_booking_id, ptf.related_order_id, ptf.related_booking_id, ptf.hotel_ticket_overview_id, ptf.hotel_id, ptf.own_supplier_id, ptf.distributor_partner_id, ptf.distributor_partner_name, ptf.hotel_name, ptf.shift_id, ptf.cashier_register_id, ptf.pos_point_id, ptf.pos_point_name, ptf.channel_id, ptf.channel_name, ptf.reseller_id, ptf.reseller_name, ptf.saledesk_id, ptf.saledesk_name, ptf.title, ptf.age_group, ptf.museum_id, ptf.museum_name, ptf.additional_information, ptf.location, ptf.highlights, ptf.image, ptf.oroginal_price, ptf.order_currency_oroginal_price, ptf.discount, ptf.order_currency_discount, ptf.is_discount_in_percent, ptf.price, ptf.order_currency_price, ptf.ticket_scan_price, ptf.cc_rows_value, ptf.tax, ptf.distributor_type, ptf.tax_name, ptf.net_price, ptf.order_currency_net_price, ptf.ticket_amount_before_extra_discount, ptf.extra_discount, ptf.extra_fee, ptf.order_currency_extra_discount, ptf.is_combi_discount, ptf.combi_discount_gross_amount, ptf.order_currency_combi_discount_gross_amount, ptf.is_discount_code, ptf.discount_code_value, ptf.discount_code_amount, ptf.order_currency_discount_code_amount, ptf.discount_code_promotion_title, ptf.service_cost_type, ptf.service_cost, ptf.net_service_cost, ptf.ticket_type, ptf.ticket_type_additional_info, ptf.discount_applied_on_how_many_tickets, ptf.quantity, ptf.refund_quantity, ptf.timeslot, ptf.from_time, ptf.to_time, ptf.selected_date, ptf.booking_selected_date, ptf.valid_till, ptf.created_date_time, ptf.created_at, ptf.scanned_at, ptf.redemption_notified_at,mm.vt_actionPerformed as action_performed, ptf.redeem_date_time, ptf.is_prioticket, ptf.product_type, ptf.shop_category_name, ptf.rezgo_id, ptf.rezgo_ticket_id, ptf.rezgo_ticket_price, ptf.tps_id, ptf.group_type_ticket, ptf.group_price, ptf.group_quantity, ptf.group_linked_with, ptf.group_id, ptf.supplier_currency_code, ptf.supplier_currency_symbol, ptf.order_currency_code, ptf.order_currency_symbol, ptf.currency_rate, ptf.selected_quantity, ptf.min_qty, ptf.max_qty, ptf.passNo, ptf.bleep_pass_no, ptf.pass_type, ptf.used, ptf.activated, ptf.visitor_tickets_id, ptf.activation_method, ptf.invoice_method_label, ptf.booking_type, ptf.split_payment_detail, ptf.timezone, ptf.is_pre_selected_ticket, ptf.is_prepaid, ptf.is_cancelled, ptf.deleted, ptf.time_based_done, ptf.booking_status, ptf.order_status, ptf.is_refunded, ptf.refunded_by, ptf.without_elo_reference_no, ptf.is_voucher, ptf.is_iticket_product, ptf.reference_id, ptf.is_addon_ticket, ptf.cluster_group_id, ptf.clustering_id, ptf.related_product_id, ptf.parent_product_id, ptf.related_product_title, ptf.pos_point_id_on_redeem, ptf.pos_point_name_on_redeem, ptf.distributor_id_on_redeem, ptf.distributor_cashier_id_on_redeem, ptf.third_party_type, ptf.third_party_booking_reference, ptf.third_party_response_data, ptf.supplier_original_price, ptf.supplier_discount, ptf.supplier_price, ptf.supplier_tax, ptf.supplier_net_price,ptf.museum_net_fee, ptf.distributor_net_fee,ptf.hgs_net_fee,ptf.museum_gross_fee, ptf.distributor_gross_fee,ptf.hgs_gross_fee, ptf.second_party_type, ptf.second_party_booking_reference, ptf.second_party_passNo, ptf.batch_id, ptf.batch_reference, ptf.cashier_id, ptf.cashier_name, ptf.redeem_users, ptf.cashier_code, ptf.location_code, ptf.voucher_updated_by, ptf.voucher_updated_by_name, ptf.redeem_method, ptf.tp_payment_method, ptf.order_confirm_date, ptf.payment_date, ptf.museum_cashier_id, ptf.museum_cashier_name, ptf.extra_text_field_answer, ptf.pick_up_location, ptf.refund_note, ptf.manual_payment_note, ptf.channel_type, ptf.financial_id, ptf.financial_name, ptf.is_custom_setting, ptf.external_product_id, ptf.account_number, ptf.chart_number, ptf.is_invoice, ptf.split_card_amount, ptf.split_cash_amount, ptf.split_voucher_amount, ptf.split_direct_payment_amount, ptf.is_data_moved, ptf.last_imported_date, ptf.redeem_by_ticket_id, ptf.redeem_by_ticket_title, ptf.updated_at, ptf.commission_type, ptf.barcode_type, ptf.guest_names, ptf.guest_emails, ptf.secondary_guest_email, ptf.secondary_guest_name, ptf.passport_number, ptf.order_status_hto, ptf.pspReference, ptf.merchantReference, ptf.merchantAccountCode, ptf.reserved_1, ptf.reserved_2, ptf.reserved_3, ptf.authcode, ptf.payment_gateway, ptf.payment_conditions, ptf.payment_term_category, ptf.order_cancellation_date, ptf.voucher_creation_date, ptf.partner_category_id, ptf.partner_category_name,ptf.last_modified_at, ptf.order_updated_cashier_id, ptf.order_updated_cashier_name, ptf.primary_host_name, ptf.is_order_confirmed, ptf.booking_information, ptf.extra_booking_information, ptf.contact_details, ptf.contact_information, ptf.phone_number, ptf.booking_details, ptf.market_merchant_id, ptf.merchant_admin_id, ptf.pax, ptf.capacity, ptf.commission_json, ptf.supplier_cost, ptf.partner_cost, ptf.tax_id, ptf.tax_exception_applied,mm.vt_version as version, ptf.supplier_tax_id, ptf.merchant_currency_code, ptf.merchant_price, ptf.merchant_net_price, ptf.merchant_tax_id, ptf.admin_currency_code, ptf.expiry_date, ptf.validity_date, ptf.unlock, ptf.checkin_uid, ptf.checkin_date, ptf.voucher_release_date from prepaid_tickets ptf join (select ptt.visitor_group_no as pt_orderId, vt.vt_group_no as vt_orderId, ptt.prepaid_ticket_id as pt_transactionId, vt.transaction_id as vt_transactionId, ptt.version as pt_version, vt.version as vt_version, ptt.used as pt_used, vt.used as vt_used, ptt.redeem_date_time as pt_redeemDate, vt.visit_date_time as vt_redeemDate, ptt.action_performed as pt_actionPerformed, vt.action_performed as vt_actionPerformed from (select pt.visitor_group_no, pt.prepaid_ticket_id, pt.version, pt.used, pt.redeem_date_time, pt.action_performed from prepaid_tickets pt join (SELECT visitor_group_no, prepaid_ticket_id, max(version) as version FROM prepaid_tickets where visitor_group_no in ($batch_str) and is_addon_ticket != '2' group by prepaid_ticket_id, visitor_group_no) as base on pt.visitor_group_no = base.visitor_group_no and ABS(pt.version-base.version) = '0' and pt.prepaid_ticket_id = base.prepaid_ticket_id and pt.used = '1') as ptt right join (select vtt.vt_group_no, vtt.version, vtt.transaction_id, vtt.used, vtt.visit_date_time, vtt.action_performed from visitor_tickets vtt join (SELECT vt_group_no,transaction_id, row_type,max(version) as version FROM visitor_tickets where vt_group_no in ($batch_str) and col2 != '2' and row_type = '1' and action_performed like '%SCANOPTMIZE' group by transaction_id, vt_group_no,row_type) as base1 on vtt.vt_group_no = base1.vt_group_no and ABS(vtt.version-base1.version) = '0' and vtt.transaction_id = base1.transaction_id and vtt.row_type = base1.row_type where vtt.col2 != '2' and vtt.action_performed like '%SCANOPTMIZE') vt on ptt.visitor_group_no = vt.vt_group_no and ptt.prepaid_ticket_id = vt.transaction_id where ROUND(ABS(ptt.used-vt.used)) != '0' or ABS(TIMESTAMPDIFF(MINUTE, ptt.redeem_date_time, vt.visit_date_time)) > 180 or ABS(ptt.version-vt.version) != '0') as mm on ptf.visitor_group_no = mm.pt_orderId and ptf.prepaid_ticket_id = mm.pt_transactionId and ABS(ptf.version-mm.pt_version) = '0' and ptf.is_addon_ticket != '2' where ptf.visitor_group_no in ($batch_str);select ROW_COUNT();" || exit 1
    echo "<<<<<<<<<<<Insert Query To Prepaid Tickets Ended>>>>>>>>>"

    sleep 5

    echo "-----Started Running Mismatch----------"
    timeout $TIMEOUT_PERIODLIVE time mysql -h"$DB_HOSTLIVE" -u"$DB_USERLIVE" --port=$DB_PORTLIVE -p"$DB_PASSWORDLIVE" -D"$DB_NAMELIVE" -sN -e "select ptt.visitor_group_no as pt_orderId, vt.vt_group_no as vt_orderId, ptt.prepaid_ticket_id as pt_transactionId, vt.transaction_id as vt_transactionId, ptt.version as pt_version, vt.version as vt_version, ptt.used as pt_used, vt.used as vt_used, ptt.redeem_date_time as pt_redeemDate, vt.visit_date_time as vt_redeemDate, ptt.action_performed as pt_actionPerformed, vt.action_performed as vt_actionPerformed from (select pt.visitor_group_no, pt.prepaid_ticket_id, pt.version, pt.used, pt.redeem_date_time, pt.action_performed from prepaid_tickets pt join (SELECT visitor_group_no, prepaid_ticket_id, max(version) as version FROM prepaid_tickets where visitor_group_no in ($batch_str) and is_addon_ticket != '2' group by prepaid_ticket_id, visitor_group_no) as base on pt.visitor_group_no = base.visitor_group_no and ABS(pt.version-base.version) = '0' and pt.prepaid_ticket_id = base.prepaid_ticket_id and pt.used = '1') as ptt left join (select vtt.vt_group_no, vtt.version, vtt.transaction_id, vtt.used, vtt.visit_date_time, vtt.action_performed from visitor_tickets vtt join (SELECT vt_group_no,transaction_id, row_type,max(version) as version FROM visitor_tickets where vt_group_no in ($batch_str) and col2 != '2' and row_type = '1' group by transaction_id, vt_group_no,row_type) as base1 on vtt.vt_group_no = base1.vt_group_no and ABS(vtt.version-base1.version) = '0' and vtt.transaction_id = base1.transaction_id and vtt.row_type = base1.row_type where vtt.col2 != '2') vt on ptt.visitor_group_no = vt.vt_group_no and ptt.prepaid_ticket_id = vt.transaction_id where ROUND(ABS(ptt.used-vt.used)) != '0' or ABS(TIMESTAMPDIFF(MINUTE, ptt.redeem_date_time, vt.visit_date_time)) > 180 or ABS(ptt.version-vt.version) != '0';" >> mismatch.csv || exit 1
    echo "<<<<<<<<<<<Mismatch Query Ended>>>>>>>>>"

    sleep 5

    timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "update $MYSQL_TABLE set status = '1' where pt_order_id in ($batch_str);select ROW_COUNT();"

done
time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "select count(*) as activestatus from $MYSQL_TABLE where status = '0';select count(*) as inactivestatus from $MYSQL_TABLE where status = '1'"
rm -f "$OUTPUT_FILE"
# End time
end_time=$(date +%s)

# Calculate elapsed time in seconds
execution_time=$((end_time - start_time))

# Calculate hours, minutes, and seconds
hours=$((execution_time / 3600))
minutes=$(( (execution_time % 3600) / 60 ))
seconds=$((execution_time % 60))

# Display execution time in HH:MM:SS
printf "Total Execution Time: %02d hours, %02d minutes, %02d seconds\n" $hours $minutes $seconds

# Play completion sound
paplay /usr/share/sounds/freedesktop/stereo/complete.oga