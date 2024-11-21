#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=25


DB_HOST='localhost'
DB_USER='admin'
DB_PASS='redhat'
DB_NAME='dummy'
BATCH_SIZE=100

mysqlHost="prodrds.prioticket.com"
mysqlUser=pipeuser
mysqlPassword=d4fb46eccNRAL
mysqlDatabase="prioprodrds"

SECDATABASE='priopassdb'
SECHOST='production-secondary-db-node.cluster-ck6w2al7sgpk.eu-west-1.rds.amazonaws.com'
SECUSER='pipeuser'
SECPASSWORD='d4fb46eccNRAL'

# Get all unique ticket_ids
ticket_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "SELECT DISTINCT(ticketid) FROM orders where status = '0'") || exit 1

# Loop through each ticket_id
for ticket_id in $ticket_ids; do
    # Get all vt_group_no for the current ticket_id
    vt_group_numbers=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "SELECT vt_group_no FROM orders WHERE ticketid = '$ticket_id' and status = '0'") || exit 1
    
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

        MISMATCH="select IFNULL(TRIM(TRAILING ',' FROM GROUP_CONCAT(DISTINCT(final.vt_group_no))), '') as order_id from (select *, (case when tlc_ticketpriceschedule_id is not NULL then tlc_commissions when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sucatalog_commissions when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pricelist_commissions else 'No_Setting_found' end) as should_be from (select scdata.*, '----Price List Level---' as type3,pl.ticketpriceschedule_id as clc_ticketpriceschedule_id,(case when scdata.row_type = '1' then pl.ticket_net_price when scdata.row_type = '2' then pl.museum_net_commission when scdata.row_type = '17' then pl.merchant_net_commission when scdata.row_type = '3' then pl.hotel_commission_net_price when scdata.row_type = '4' then pl.hgs_commission_net_price else 0 end) as pricelist_commissions  from (select tlcdata.*, '----Sub catalog Level---' as type2, sc.catalog_id,sc.ticketpriceschedule_id as sc_ticketpriceschedule_id, sc.resale_currency_level as sc_resale_currency_level, (case when tlcdata.row_type = '1' then sc.ticket_net_price when tlcdata.row_type = '2' then sc.museum_net_commission when tlcdata.row_type = '17' then sc.merchant_net_commission when tlcdata.row_type = '3' then sc.hotel_commission_net_price when tlcdata.row_type = '4' then sc.hgs_commission_net_price else 0 end) as sucatalog_commissions   from (select vt.vt_group_no, concat(vt.transaction_id, 'R') as transaction_id,vt.order_confirm_date, vt.created_date,vt.hotel_id, vt.channel_id, vt.ticketId, vt.ticketpriceschedule_id, vt.version, vt.row_type, vt.partner_gross_price, vt.partner_net_price, vt.order_currency_partner_gross_price, vt.order_currency_partner_net_price, vt.supplier_gross_price, vt.supplier_net_price, vt.col2, qc.cod_id as company_id, qc.channel_id as company_pricelist_id, qc.sub_catalog_id as company_sub_catalog, '---TLC LEVEL---' as Type, tlc.ticketpriceschedule_id as tlc_ticketpriceschedule_id, tlc.resale_currency_level, (case when vt.row_type = '1' then tlc.ticket_net_price when vt.row_type = '2' then tlc.museum_net_commission when vt.row_type = '17' then tlc.merchant_net_commission when vt.row_type = '3' then tlc.hotel_commission_net_price when vt.row_type = '4' then tlc.hgs_commission_net_price else 0 end) as tlc_commissions from visitor_tickets vt join (select vt_group_no, transaction_id,row_type, max(version) as version from visitor_tickets where ticketId in ($ticket_id) and vt_group_no in ($batch_str) and col2 != '2' group by vt_group_no, transaction_id, row_type) as maxversion on vt.vt_group_no = maxversion.vt_group_no and vt.transaction_id = maxversion.transaction_id and vt.row_type = maxversion.row_type and ABS(vt.version-maxversion.version) = '0' left join tmp.qr_codes qc on qc.cod_id = vt.hotel_id and qc.cashier_type = '1' left join tmp.ticket_level_commission tlc on tlc.hotel_id = vt.hotel_id and tlc.ticketpriceschedule_id = vt.ticketpriceschedule_id and tlc.ticket_id = vt.ticketId and tlc.deleted = '0' and tlc.is_adjust_pricing = '1' where vt.col2 != '2') as tlcdata left join tmp.channel_level_commission sc on tlcdata.ticketpriceschedule_id = sc.ticketpriceschedule_id and tlcdata.ticketId = sc.ticket_id and if(tlcdata.company_sub_catalog = '0', 122222, tlcdata.company_sub_catalog) = sc.catalog_id and sc.is_adjust_pricing = '1' and sc.deleted = '0') as scdata left join tmp.channel_level_commission pl on scdata.ticketpriceschedule_id = pl.ticketpriceschedule_id and scdata.ticketId = pl.ticket_id and scdata.channel_id = pl.channel_id and pl.catalog_id = '0' and pl.is_adjust_pricing = '1' and pl.deleted = '0') as shouldbe) as final where final.partner_net_price != final.should_be and final.should_be != 'No_Setting_found' and final.row_type != '1'"

        echo "Found MIsmatch Query"

        echo "$MISMATCH" >> rattan.sql

        mismatchvgn=$(timeout $TIMEOUT_PERIOD time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -sN -e "$MISMATCH")

        echo "$mismatchvgn"

        if [ -z "$mismatchvgn" ]; then

            echo "No results found. Proceeding with further steps. for ($batch_str)" >> no_mismatch.txt
            # Add your further steps here
            timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "update orders set status = '1' where vt_group_no in ($batch_str)" || exit 1

        else 

            echo "------$(date '+%Y-%m-%d %H:%M:%S.%3N')--------" >> found_mismatch.txt 
            echo "$batch_str" >> found_mismatch.txt
             echo "Mismatch Out of above" >> found_mismatch.txt
            echo "Query returned results:"
            echo "$mismatchvgn" >> found_mismatchfinal.txt

            timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "update orders set status = '2' where vt_group_no in ($mismatchvgn)" || exit 1

            
            echo "Sleep Started to Run next VGNS"
            echo "------$(date '+%Y-%m-%d %H:%M:%S.%3N')--------"
            sleep 3

        fi

    done
done



# select transaction_id, count(*) from visitor_tickets where vt_group_no in (172045255276797,171025431591257,171727346539316,172053346499600,171141947172133,171574639920145,172704081562491,171163934037471,171536931080789,171986309649833,172100781072771,171351848854810,171433057167697,171242616086533,171741139833003,171185633076512,172156075664258,171472054427291,172547458139142,171994602778711,171930733511999,171011644400218,172578141163575,171563415795607,172409437657983,172685575287572,171738344350056,171915181827493,171297041994939,171694065980369,171372664507728,172359779009045,171009727210196,171328800669347,171913769909957,171233843827790,171695329843824,172302377028197,172712340166603,171614164484789,171680191898746,171542971521723,172314356772802,172667004798377,171261513579759,172493962896932,172489212878186,172227461759518,171820765792530,171967693251310) and action_performed like '%CSSCommission' group by transaction_id


# select transaction_id, row_type, version, partner_gross_price from visitor_tickets where vt_group_no in (172045255276797) and action_performed like '%CSSCommission' group by transaction_id


# select prepaid_ticket_id, version, museum_net_fee, distributor_net_fee,hgs_net_fee,museum_gross_fee, distributor_gross_fee,hgs_gross_fee from visitor_tickets where visitor_group_no in (172372552429548,172581021304387,171319842070743,172044725102381,172424987440319,171581197165690,172218824782823,171294830620865,171963335467192,172632428502457,171845059887457,171249535930396,171753352986167,171615494480590,172415206736420,172595013086763,172211262744573,171109848818468,172686371291316,171432563777550,172271791662673,171137599486683,172338975718524,171846823963922,172248768288914,171150416414760,171733260622365,172718747512263,172171190436226,172632333684048,171026681260426,171573650317812,171849895407657,171880775596472,172842214750400,172245315860611,171519070314444,171121424818909,171311329769765,171319400365877,171414246206059,172236811194455,172528341037576,172490619649031,171168096454202,172434321667956,172770507844065,171907540129772,171737520896895,171197228065742,172045255276797,171025431591257,171727346539316,172053346499600,171141947172133,171574639920145,172704081562491,171163934037471,171536931080789,171986309649833,172100781072771,171351848854810,171433057167697,171242616086533,171741139833003,171185633076512,172156075664258,171472054427291,172547458139142,171994602778711,171930733511999,171011644400218,172578141163575,171563415795607,172409437657983,172685575287572,171738344350056,171915181827493,171297041994939,171694065980369,171372664507728,172359779009045,171009727210196,171328800669347,171913769909957,171233843827790,171695329843824,172302377028197,172712340166603,171614164484789,171680191898746,171542971521723,172314356772802,172667004798377,171261513579759,172493962896932,172489212878186,172227461759518,171820765792530,171967693251310)