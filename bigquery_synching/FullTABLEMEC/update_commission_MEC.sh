#!/bin/bash

# Path to the JSON file
JSON_FILE="mismatch.json"
rm -f UpdatequeryMEC.sql
# Check if the file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: File '$JSON_FILE' not found."
    exit 1
fi

# Batch size
BATCH_SIZE=100

# Extract channel_level_commission_id values using jq
ids=$(jq -r '.[] | .mec_id' "$JSON_FILE")

# Convert the ids to an array
ids_array=($ids)

# Total number of ids
total_ids=${#ids_array[@]}

# Exit if total_ids is blank or zero
if [ -z "$total_ids" ] || [ "$total_ids" -eq 0 ]; then
    echo "Error: No mec_id values found in the JSON file."
    exit 1
fi

# Process ids in batches
for (( i=0; i<$total_ids; i+=$BATCH_SIZE )); do
    # Create a batch of ids
    batch=(${ids_array[@]:$i:$BATCH_SIZE})
    # Join ids with commas
    ids_joined=$(IFS=, ; echo "${batch[*]}")
    # Construct the MySQL update query
    query="UPDATE modeventcontent SET last_modified_at = CURRENT_TIMESTAMP WHERE mec_id IN ($ids_joined);select ROW_COUNT();"

    echo "$query" >> UpdatequeryMEC.sql

    sleep 2
    # Execute the query
    # mysql -u "$DBUSER" -h "$DBHOST" --port=$PORT -p"$DBPWD" "$DBDATABASE" -e "$query"
done

bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
"insert into prioticket-reporting.prio_olap.modeventcontent (with mect as (select *,row_number() over(partition by mec_id order by last_modified_at desc ) as rn from prio_test.modeventcontent_synch), mecl as (select *,row_number() over(partition by mec_id order by last_modified_at desc ) as rn from prio_olap.modeventcontent), mectrn as (select * from mect where rn = 1), meclrn as (select * from mecl where rn = 1), final as (select mectrn.*, meclrn.mec_id as ids from mectrn left join meclrn on mectrn.mec_id = meclrn.mec_id and (mectrn.last_modified_at = meclrn.last_modified_at or mectrn.last_modified_at < meclrn.last_modified_at)) select mec_id,parent_ticket_id,rezgo_ticket_id,rezgo_id,rezgo_key,is_gt_ticket,sku,is_own_capacity,shared_capacity_id,own_capacity_id,iticket_product_id,iticket_location_code,tourcms_tour_id,tourcms_channel_id,barcode_type,ticket_tax_value,cod_id,museum_name,reseller_id,reseller_name,created_at,usr_id,category,cat_id,sub_cat_id,sub_category,event_type,address,location,city,deal_type_free,targetAge,targetAgeMax,targetGender,targetValidCities,postingEventTitle,shortDesc,longDesc,super_desc,MoreDesc,scan_info,allow_city_card,alert_pass_count,alert_capacity_count,termsConditions,perDiscount,apply_service_tax,eventImage,banner_image,original_price,newPrice,discount,saveamount,voucherDesc,voucherValue,vchrMinSpend,vchrLimitedAvail,vouch_termsCond,limited_availPcs,startDate,startTime,endDate,endTime,is_default_location_checked,isBarcode,barcode_img,codsrc,isSmartPhon,isReservManual,deleted,mod_loc_id,rating,clicks,created_on,reservedatetime,reservepeople,confirmmanually,eventstartDate,eventendDate,discountCode,msgClaim,additional_notification_emails,notification_emails,is_default,online_additional_information,modified_at,originalimg,module_item_id,totalClaim,limitReachedDate,notify_email,notify_count,imageType,timezone,local_timezone_name,local_timezone,tab_id,merchantCatId,ticketPrice,ticketwithdifferentpricing,is_reservation,more_info_images,ticket_fee,ticketExtraInfo,museumCommission,museumNetPrice,subtotal,hotelCommission,hotelNetPrice,calculated_hotel_commission,hgsCommission,hgsnetprice,calculated_hgs_commission,isCommissionInPercent,museum_tax_id,hotel_tax_id,hgs_tax_id,ticket_tax_id,totalCommission,totalNetCommission,hgs_provider_id,hgs_provider_name,ticket_net_price,hgs_tax_value,is_commission_assigned,isreservation,reservation_amount,is_pos_list,is_limit_per_order,min_order_qty,max_order_qty,is_allow_pre_bookings,pre_booking_date,is_cut_off_time,cut_off_time,is_show_fee,show_fee,show_fee_type,valid_for_months,is_scan_countdown,countdown_interval,upsell_ticket_ids,booking_email_text,is_valid_for,is_over_booking,third_party_id,third_party_parameters,third_party_status,second_party_id,second_party_ticket_id,second_party_parameters,pos_image,more_images,highlights,whats_included,whats_not_included,additional_information,guest_notification,duration,languages,is_extra_options,no_of_extra_options,checkin_points_label,checkin_points_mandatory,checkin_point_ids,checkin_points,extra_text_field,nav_item_no,qc_company,is_cancel_allow,ticket_type,capacity_type,updated_by,updated_at,add_token_label,ticket_tags_id,ticket_feature_id,hop_on_hop_off,routes_ids,hoho_option,active,daily_cron_processed,weekly_cron_processed,cluster_ticket_details,cancellation_policy,currency_code,is_sell_via_ota,code_vs_voucher,combi_ticket_ids,created_by,notification,product_visibility,market_merchant_id,is_combi,merchant_admin_id,merchant_admin_name,content_description_setting,barcode_specification,main_product_id,product_type,voucher_type,link_product_type,last_modified_at,cancellation_time,hostname,linked_combi_json,datetime_records,third_party_ticket_id,contract_source_id,grace_time_enable,grace_time_before_type,grace_time_after_type,grace_time_before,grace_time_after,slug,google_categories,product_booking_url,landing_page_view_url,product_has_duration,product_duration,cancellation_time_label,cancellation_time_type,wheelchair_accessible,relation_type,product_free_sell,product_amount_type,product_amount,show_single_timeslot,review_rating_no,cart_expiry_time,version,owned_by_supplier,content_language,Calculate_timeslot_endtime,ticket_timeslot_type,targetPercent,iconType,icon_image,isUnlock,unlockCode,codimg,eventstartTime,eventendTime,days,isClaimOnce,campaigntype,discountwebpage,is_mobile_campatible,isSalesVoucher,module_id,extraexposure,facebooktwitterdiscount,twittertext,facebooktitle,facebooktext,placeevent,campaign_owner_type,toptenlisting,treatCity,treatId,isTreatInCombinationWithAnotherCampaign,isConfirmedByTreatCompany,iconImage,cityPoints,topic,topic_id,welcomecampaign,approvedByadmin,ticketStandardOpeningHoursInfo,isnotshowfee,is_pos,third_party_code,schedule,loop_time,frequency,no_of_stops,stops_info,description_json,prio_hostname,import_images,status,action,newTgs,targetType,extraDiscountType,isTreat,istargetvisitor,redeem_sub_products,product_barcode,stock_quantity,enable_price_variation,third_party_account,second_party_account,notify_expiry_days from final where ids is NULL)" || exit 1