#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=25


# DB_HOST='10.10.10.19'
# DB_USER='pip'
# DB_PASS='pip2024##'
# DB_NAME='rattan'
# BATCH_SIZE=25

DB_HOST='localhost'
DB_USER='admin'
DB_PASS='redhat'
DB_NAME='priopassdb'
BATCH_SIZE=50
tableName=$1

mysqlHost="prodrds.prioticket.com"
mysqlUser=pipeuser
mysqlPassword=d4fb46eccNRAL
mysqlDatabase="prioprodrds"

# echo "vt_group_no,transaction_id,hotel_id,channel_id,ticketId,ticketpriceschedule_id,version,row_type,partner_net_price,salePrice,percentage_commission,commission_on_sale,partner_net_price_should_be" > MismatchRecords.csv

echo "vt_group_no,transaction_id,version,saleprice,purchasecost,distributorcomm,hgscomm,merchantcomm" > MismatchRecords.csv

vt_group_numbers=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "SELECT distinct vt_group_no FROM $tableName") || exit 1

# Convert the vt_group_numbers into an array
vt_group_array=($vt_group_numbers)
total_vt_groups=${#vt_group_array[@]}

# Print the total count of vt_group_no for the current ticket_id
echo "Processing Ticket ID: $total_vt_groups vt_group_no values"

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
        
        
        MISMATCHFInal="select vt_group_no, transaction_id,version, max(case when row_type = '1' then partner_net_price_should_be else 0 end) as saleprice,max(case when row_type = '2' then partner_net_price_should_be else 0 end) as purchasecost, max(case when row_type = '3' then partner_net_price_should_be else 0 end) as distributorCom, max(case when row_type = '4' then partner_net_price_should_be else 0 end) as hgscomm, max(case when row_type = '17' then partner_net_price_should_be else 0 end) as merchantcomm from (SELECT *, FORMAT(ROUND((salePrice*percentage_commission/100),2),2) as partner_net_price_should_be
FROM
    (
    SELECT
        vt_group_no,
        transaction_id,
        hotel_id, channel_id, ticketId, ticketpriceschedule_id, version, row_type, partner_net_price,salePrice, (case when row_type = '2' and tlc_ticketpriceschedule_id is not NULL then tlc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_res_per 
        when row_type = '3' and tlc_ticketpriceschedule_id is not NULL then tlc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_dist_per
        when row_type = '4' and tlc_ticketpriceschedule_id is not NULL then tlc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_hgs_per when row_type = '1' then '100.00' else 'No_Setting_found' end) as percentage_commission,
        case when tlc_ticketpriceschedule_id is not NULL then tlc_comm_on_sale when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_comm_on_sale when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_comm_on_sale else 'NO SETTING_FOUND' end as commission_on_sale
FROM
    (
    SELECT
        scdata.*,
        '----Price List Level---' AS type3,
        pl.ticketpriceschedule_id AS clc_ticketpriceschedule_id,
        pl.hotel_prepaid_commission_percentage as pl_dist_per,
        pl.hgs_prepaid_commission_percentage as pl_hgs_per,
        pl.merchant_fee_percentage as pl_mer_per,
        pl.resale_percentage as pl_res_per,
        pl.commission_on_sale_price as pl_comm_on_sale
FROM
    (
    SELECT
        tlcdata.*,
        '----Sub catalog Level---' AS type2,
        sc.catalog_id,
        sc.ticketpriceschedule_id AS sc_ticketpriceschedule_id,
        sc.resale_currency_level AS sc_resale_currency_level,
        sc.hotel_prepaid_commission_percentage as sc_dist_per,
        sc.hgs_prepaid_commission_percentage as sc_hgs_per,
        sc.merchant_fee_percentage as sc_mer_per,
        sc.resale_percentage as sc_res_per,
        sc.commission_on_sale_price as sc_comm_on_sale        
FROM
    (
    SELECT
        vt.vt_group_no,
        CONCAT(vt.transaction_id, 'R') AS transaction_id,
        vt.order_confirm_date,
        vt.created_date,
        vt.hotel_id,
        vt.channel_id,
        vt.ticketId,
        vt.ticketpriceschedule_id,
        vt.version,
        vt.row_type,
        vt.partner_gross_price,
        vt.partner_net_price,
        maxversion.salePrice,
        vt.order_currency_partner_gross_price,
        vt.order_currency_partner_net_price,
        vt.supplier_gross_price,
        vt.supplier_net_price,
        vt.col2,
        qc.cod_id AS company_id,
        qc.channel_id AS company_pricelist_id,
        qc.sub_catalog_id AS company_sub_catalog,
        '---TLC LEVEL---' AS TYPE,
        tlc.ticketpriceschedule_id AS tlc_ticketpriceschedule_id,
        tlc.resale_currency_level,
        tlc.hotel_prepaid_commission_percentage as tlc_dist_per,
        tlc.hgs_prepaid_commission_percentage as tlc_hgs_per,
        tlc.merchant_fee_percentage as tlc_mer_per,
        tlc.resale_percentage as tlc_res_per,
        tlc.commission_on_sale_price as tlc_comm_on_sale
FROM
    visitor_tickets vt
JOIN(
    SELECT
        vt_group_no,
        transaction_id,
        row_type,
        max(case when row_type = '1' then partner_net_price else 0 end) as salePrice,
        MAX(VERSION) AS VERSION
    FROM
        visitor_tickets
    WHERE
        vt_group_no IN($batch_str) AND col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%' and ticket_title not like '%Discount code%'
    GROUP BY
        vt_group_no,
        transaction_id
) AS maxversion
ON
    vt.vt_group_no = maxversion.vt_group_no AND vt.transaction_id = maxversion.transaction_id AND ABS(vt.version - maxversion.version) = '0'
LEFT JOIN tmp.qr_codes qc
ON
    qc.cod_id = vt.hotel_id AND qc.cashier_type = '1'
LEFT JOIN tmp.ticket_level_commission tlc
ON
    tlc.hotel_id = vt.hotel_id AND tlc.ticketpriceschedule_id = vt.ticketpriceschedule_id AND tlc.ticket_id = vt.ticketId AND tlc.deleted = '0' AND tlc.is_adjust_pricing = '1'
WHERE
    vt.col2 != '2'
) AS tlcdata
LEFT JOIN tmp.channel_level_commission sc
ON
    tlcdata.ticketpriceschedule_id = sc.ticketpriceschedule_id AND tlcdata.ticketId = sc.ticket_id AND IF(
        tlcdata.company_sub_catalog = '0',
        122222,
        tlcdata.company_sub_catalog
    ) = sc.catalog_id AND sc.is_adjust_pricing = '1' AND sc.deleted = '0'
) AS scdata
LEFT JOIN tmp.channel_level_commission pl
ON
    scdata.ticketpriceschedule_id = pl.ticketpriceschedule_id AND scdata.ticketId = pl.ticket_id AND scdata.channel_id = pl.channel_id AND pl.catalog_id = '0' AND pl.is_adjust_pricing = '1' AND pl.deleted = '0'
) AS shouldbe
) AS final) as targetvalue group by vt_group_no, transaction_id,version;"


    sleep 3
    echo "$MISMATCHFInal" >> dec.sql
    timeout $TIMEOUT_PERIOD time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -sN -e "$MISMATCHFInal" >> MismatchRecords.csv || exit 1

    # timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "update $tableName set status = '2' where visitor_group_no in ($mismatchvgn)" || exit 1

    
    echo "Sleep Started to Run next VGNS"
    echo "------$(date '+%Y-%m-%d %H:%M:%S.%3N')--------"

    sleep 1


done