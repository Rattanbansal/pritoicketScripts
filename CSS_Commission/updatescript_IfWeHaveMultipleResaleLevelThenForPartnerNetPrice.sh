#!/bin/bash

DB_HOST='10.10.10.19'
DB_USER='pip'
DB_PASS='pip2024##'
DB_NAME='rattan'
BATCH_SIZE=5

mysqlHost="prodrds.prioticket.com"
mysqlUser=pipeuser
mysqlPassword=d4fb46eccNRAL
mysqlDatabase="prioprodrds"

# Get all unique ticket_ids
ticket_ids=$(mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "SELECT DISTINCT(ticketid) FROM orders where ticketid = '3305'")

# Loop through each ticket_id
for ticket_id in $ticket_ids; do
    # Get all vt_group_no for the current ticket_id
    vt_group_numbers=$(mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "SELECT vt_group_no FROM orders WHERE ticketid = $ticket_id")
    
    # Convert the vt_group_numbers into an array
    vt_group_array=($vt_group_numbers)
    total_vt_groups=${#vt_group_array[@]}

    # Print the total count of vt_group_no for the current ticket_id
    echo "Processing Ticket ID: $ticket_id with $total_vt_groups vt_group_no values"

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
        echo "Processing batch of size $batch_size for Ticket ID: $ticket_id ($current_progress / $total_vt_groups processed)" >> log.txt
        
        # Construct and execute the UPDATE query
        # update_query="UPDATE your_table SET your_column = 'your_value' WHERE ticket_id = $ticket_id AND vt_group_no IN ($batch_str)"

        update_query_vt="update visitor_tickets vtt join (select *, (case when tlc_ticketpriceschedule_id is not NULL then tlc_commissions when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sucatalog_commissions when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pricelist_commissions else 'No_Setting_found' end) as should_be from (select scdata.*, '----Price List Level---' as type3,pl.ticketpriceschedule_id as clc_ticketpriceschedule_id,(case when scdata.row_type = '1' then pl.ticket_net_price when scdata.row_type = '2' then pl.museum_net_commission when scdata.row_type = '17' then pl.merchant_net_commission when scdata.row_type = '3' then pl.hotel_commission_net_price when scdata.row_type = '4' then pl.hgs_commission_net_price else 0 end) as pricelist_commissions  from (select tlcdata.*, '----Sub catalog Level---' as type2, sc.catalog_id,sc.ticketpriceschedule_id as sc_ticketpriceschedule_id, sc.resale_currency_level as sc_resale_currency_level, (case when tlcdata.row_type = '1' then sc.ticket_net_price when tlcdata.row_type = '2' then sc.museum_net_commission when tlcdata.row_type = '17' then sc.merchant_net_commission when tlcdata.row_type = '3' then sc.hotel_commission_net_price when tlcdata.row_type = '4' then sc.hgs_commission_net_price else 0 end) as sucatalog_commissions   from (select vt.vt_group_no, concat(vt.transaction_id, 'R') as transaction_id,vt.order_confirm_date, vt.created_date,vt.hotel_id, vt.channel_id, vt.ticketId, vt.ticketpriceschedule_id, vt.version, vt.row_type, vt.partner_gross_price, vt.partner_net_price, vt.order_currency_partner_gross_price, vt.order_currency_partner_net_price, vt.supplier_gross_price, vt.supplier_net_price, vt.col2, qc.cod_id as company_id, qc.channel_id as company_pricelist_id, qc.sub_catalog_id as company_sub_catalog, '---TLC LEVEL---' as Type, tlc.ticketpriceschedule_id as tlc_ticketpriceschedule_id, tlc.resale_currency_level, (case when vt.row_type = '1' then tlc.ticket_net_price when vt.row_type = '2' then tlc.museum_net_commission when vt.row_type = '17' then tlc.merchant_net_commission when vt.row_type = '3' then tlc.hotel_commission_net_price when vt.row_type = '4' then tlc.hgs_commission_net_price else 0 end) as tlc_commissions from visitor_tickets vt join (select vt_group_no, transaction_id,row_type, max(version) as version from visitor_tickets where created_date between '2024-03-10 00:00:01' and '2024-10-10 23:59:59' and ticketId = '$ticket_id' and vt_group_no in ($batch_str) group by vt_group_no, transaction_id, row_type) as maxversion on vt.vt_group_no = maxversion.vt_group_no and vt.transaction_id = maxversion.transaction_id and vt.row_type = maxversion.row_type and ABS(vt.version-maxversion.version) = '0' left join tmp.qr_codes qc on qc.cod_id = vt.hotel_id and qc.cashier_type = '1' left join tmp.ticket_level_commission tlc on tlc.hotel_id = vt.hotel_id and tlc.ticketpriceschedule_id = vt.ticketpriceschedule_id and tlc.ticket_id = vt.ticketId) as tlcdata left join tmp.channel_level_commission sc on tlcdata.ticketpriceschedule_id = sc.ticketpriceschedule_id and tlcdata.ticketId = sc.ticket_id and if(tlcdata.company_sub_catalog = '0', 122222, tlcdata.company_sub_catalog) = sc.catalog_id) as scdata left join tmp.channel_level_commission pl on scdata.ticketpriceschedule_id = pl.ticketpriceschedule_id and scdata.ticketId = pl.ticket_id and scdata.channel_id = pl.channel_id and pl.catalog_id = '0') as shouldbe) as final on vtt.vt_group_no = final.vt_group_no and ABS(vtt.version-final.version) = '0' and vtt.transaction_id = final.transaction_id and vtt.row_type = final.row_type set vtt.partner_net_price = final.should_be, vtt.partner_gross_price = final.should_be*(100+vtt.tax_value)/100, vtt.action_performed = concat(vtt.action_performed, ', CSSCommissionUpdate') where final.partner_net_price != final.should_be and final.should_be != 'No_Setting_found' and final.row_type != '1';select ROW_COUNT();"
        
        echo "------$(date '+%Y-%m-%d %H:%M:%S.%3N')--------" >> vt_update_query.sql

        echo "$update_query_vt" >> vt_update_query.sql

        mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -sN -e "$update_query_vt"
        

        update_query_pt="UPDATE prepaid_tickets pt join (SELECT transaction_id,vt_group_no,version,ticketId,MAX(CASE WHEN row_type = '1' THEN partner_net_price ELSE 0 END) AS sale_price,MAX(CASE WHEN row_type = '2' THEN partner_net_price ELSE 0 END) AS purchase_price,MAX(CASE WHEN row_type = '3' THEN partner_net_price ELSE 0 END) AS distributor_fee,MAX(CASE WHEN row_type = '4' THEN partner_net_price ELSE 0 END) AS hgs_fee,MAX(CASE WHEN row_type = '17' THEN partner_net_price ELSE 0 END) AS merchant_fee,MAX(CASE WHEN row_type = '1' THEN partner_gross_price ELSE 0 END) AS sale_priceg,MAX(CASE WHEN row_type = '2' THEN partner_gross_price ELSE 0 END) AS purchase_priceg,MAX(CASE WHEN row_type = '3' THEN partner_gross_price ELSE 0 END) AS distributor_feeg,MAX(CASE WHEN row_type = '4' THEN partner_gross_price ELSE 0 END) AS hgs_feeg FROM visitor_tickets WHERE vt_group_no in ($batch_str) and action_performed like '%CSSCommissionUpdate' GROUP BY vt_group_no,transaction_id,ticketpriceschedule_id) as aggt ON pt.visitor_group_no = aggt.vt_group_no AND pt.prepaid_ticket_id = aggt.transaction_id and ABS(pt.version-aggt.version) = '0' SET pt.museum_net_fee = aggt.purchase_price,pt.distributor_net_fee = aggt.distributor_fee,pt.hgs_net_fee = aggt.hgs_fee,pt.museum_gross_fee = aggt.purchase_priceg,pt.distributor_gross_fee = aggt.distributor_feeg,pt.hgs_gross_fee = aggt.hgs_feeg, pt.action_performed = concat(pt.action_performed, ', CSSCommissionUpdate');select ROW_COUNT();"

        echo "------$(date '+%Y-%m-%d %H:%M:%S.%3N')--------" >> pt_update_query.sql

        echo "$update_query_pt" >> pt_update_query.sql

        mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -sN -e "$update_query_pt"

        sleep 15

    done
done
