#!/bin/bash

# Path to the JSON file
JSON_FILE="mismatch.json"
rm -f UpdatequeryQRCODES.sql
# Check if the file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: File '$JSON_FILE' not found."
    exit 1
fi

# Batch size
BATCH_SIZE=100

# Extract cod_id values using jq
ids=$(jq -r '.[] | .cod_id' "$JSON_FILE")

# Convert the ids to an array
ids_array=($ids)

# Total number of ids
total_ids=${#ids_array[@]}

# Exit if total_ids is blank or zero
if [ -z "$total_ids" ] || [ "$total_ids" -eq 0 ]; then
    echo "Error: No cod_id values found in the JSON file."
    exit 1
fi

# Process ids in batches
for (( i=0; i<$total_ids; i+=$BATCH_SIZE )); do
    # Create a batch of ids
    batch=(${ids_array[@]:$i:$BATCH_SIZE})
    # Join ids with commas
    ids_joined=$(IFS=, ; echo "${batch[*]}")
    # Construct the MySQL update query
    query="UPDATE qr_codes SET last_modified_at = CURRENT_TIMESTAMP WHERE cod_id IN ($ids_joined);select ROW_COUNT();"

    echo "$query" >> UpdatequeryQRCODES.sql

    sleep 2
    # Execute the query
    # mysql -u "$DBUSER" -h "$DBHOST" --port=$PORT -p"$DBPWD" "$DBDATABASE" -e "$query"
done

bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
"insert into prioticket-reporting.prio_olap.qr_codes (with qr_codest as (select *,row_number() over(partition by cod_id order by last_modified_at desc ) as rn from prio_test.qr_codes_synch), qr_codesl as (select *,row_number() over(partition by cod_id order by last_modified_at desc ) as rn from prio_olap.qr_codes), qr_codestrn as (select * from qr_codest where rn = 1), qr_codeslrn as (select * from qr_codesl where rn = 1), final as (select qr_codestrn.*, qr_codeslrn.cod_id as ids from qr_codestrn left join qr_codeslrn on qr_codestrn.cod_id = qr_codeslrn.cod_id and (qr_codestrn.last_modified_at = qr_codeslrn.last_modified_at or qr_codestrn.last_modified_at < qr_codeslrn.last_modified_at)) select cod_id,cod_creation_date,cod_title,company,financial_company_type,native_id,native_name,platform_id,platform_name,saledesk_user_email,genericComDesc,genericComPhoto,company_image,city,city_code,address,genericEmail,postalCode,country,mobileNo,genericCategory,scan_date,scan_machineId,star,IsActive,genericComCode,latitude,longitude,bankregisterationnumber,bankaccount,taxnumber,language,numberformat,currency,timeZone,hex_code,corporateAddress,currency_position,currency_code,mpos_admin_device_setting,mpos_settings,mpos_receipt_text,scan_report_settings,details_on_scan,supplier_email_address,third_party_api_key,third_party_secret_key,promotion_package,commerce_number,vat_number,modified_at,activation_method,upfront_text,invoice_text,invoice_after_redeem_text,pay_at_cashier_text,isPremiumAccount,state,company_type,postit,service_fee,clicks,adyen_api_key,cancreateticket,add_guest_information,add_room_no,add_booking_name,add_email,primary_host_name,own_supplier_id,group_booking_hotel_account,cashier_type,distributor_type,distributor_id,account_type,paymentMethodType,invoice_type,invoice_variant,pos_payment_option,google_api_map_type,google_translation_service,is_pos_payment_only_prepaid,prepaid_commission_percentage,postpaid_commission_percentage,commission_tax_id,commission_tax_value,hgs_prepaid_commission_percentage,hgs_postpaid_commission_percentage,hgs_commission_tax_id,hgs_commission_tax_value,is_service_cost_checked,service_cost,service_cost_type,is_pos_url_checked,pos_url,upfront_payment,invoice,invoice_after_redeem,pay_at_cashier,activation_type,pos_type,order_correction,mpos_booking_detail_popup,multi_user_login,printer_settings,overbooking_allowed,welcomeBulletinBoard,merchantAdminstativeInstruction,merchantAdminstativeInstructionIsMandatory,isEmployeeInstruction,city_maps,passes,invoice_period,authentication_amount_per_person,payment_types,records_per_page,transaction_report,show_distributor_partner_section,voucher_activation_type,upsell_card_by_card,report_daily_overview_email,booking_report,booking_report_email,selected_payment_type,selected_time_based_payment_method,warning_text,service_name,optional_text,creditcard_cost_option,is_send_receipt_email,is_confirm_checkout_page_on,checkout_overview_type,is_guest_image,is_inc_tax,is_checkout_report_email_sent,check_out_email_to_admin,is_display_night,display_detail_on_checkout_overview,display_booking_overview_tab,is_report_overview_daily_email,is_credit_card_fee_charged_to_guest,is_time_based_on,is_time_based_checkbox_on,multiuser_access,can_add_label,bank_name,iban,btw_code,kvk_code,daily_email_show_per_user,phone,email,rezgo_id,tourcms_channel_id,is_show_fee_on_report_on,partner_name,is_email_sent,not_sent_email,sent_emails,check_in_option,online_web_check_in,initial_payment_charged_to_guest,self_activation_guest_via_url,self_activation_guest_via_web,is_autocheckout,name_on_activation,online_scan_pass,is_combi_ticket_allowed,is_booking_combi_ticket_allowed,is_group_check_in_allowed,is_group_entry_allowed,instant_ticket_charge,invoice_without_tax,headercolor,template,company_code,template_logo,report_layout,colorcode,email_template,export_format,template_country,headertextcolor,templatecolor,digital_payment,token,print_cashier_name,is_printing,is_shop_search_focus_active,service_cost_tax,is_hotel_museum,intermediate_type,pos_points,exclude_from_financial,gvb_mode,test_gvb_web_service_url,test_gvb_cash_register_id,test_gvb_reader_number,test_gvb_merchant_id,live_gvb_web_service_url,live_gvb_cash_register_id,live_gvb_reader_number,live_gvb_merchant_id,gvb_reader_cookie,is_nav_on,nav_mode,test_nav_web_service_url,test_nav_company_name,test_nav_webservice_username,test_nav_webservice_password,live_nav_web_service_url,live_nav_company_name,live_nav_webservice_username,live_nav_webservice_password,adyen_merchant_account,entity_type,gender,date_of_birth,iban_no,bic,merchant_bank_name,adyen_sdk_username,adyen_sdk_password,country_code,owner_name,automatic_payout,announcement,rezgo_key,is_mobileapp_active,mobile_app_payment_type,nav_customer_modified_date,post_payment_note,pre_payment_note,cancelation_hours,cancelation_minutes,cancelation_charge,show_guest_manifest,show_guide_manager,discount_labels,guide_option,other_guide_option,instant_ticket_charge_copy,guide_details,mpos_theme_colors,cashier_login,is_venue_app_active,allow_reprint,dashboard_type,cashier_password,financial_id,financial_name,viator_supplier_id,channel_id,template_id,channel_name,approved_company,reseller_id,saledesk_name,saledesk_id,reseller_name,reseller_invoice_type,default_reference_number,add_to_pass,twinfield_setting,third_party_supplier_id,third_party_parameters,margin_if_ota,margin_if_csw,updated_at,updated_by,manifest_version,hop_on_hop_off_activation,booking_type,last_modified_at,sell_prioticket,market_merchant_id,hostname,customize_default_content,add_currency,keyboard_type,credit_notification_settings,credit_type,suspend_account,business_type,catalog_id,sub_catalog_id,credit_limit,trigger_amount,adyen_payment_via_api,invoice_template_id,third_party_source_id,capacity_setting,allocate_voucher_period,place_id,is_markup,show_add_room_no from final where ids is NULL)" || exit 1