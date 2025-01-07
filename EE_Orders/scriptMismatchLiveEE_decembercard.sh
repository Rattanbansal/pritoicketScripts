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

echo "vt_group_no,transaction_id,hotel_id,channel_id,ticketId,ticketpriceschedule_id,version,row_type,partner_net_price,salePrice,percentage_commission,commission_on_sale,partner_net_price_should_be" > MismatchRecords.csv

# vt_group_numbers=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "SELECT distinct vt_group_no FROM $tableName") || exit 1

vt_group_numbers="170758177249029 170870170377087 171050057165456 171216314733621 171706740101861 171895925851419 171996200946373 172008345238444 172112416147164 172181704535728 172226874210067 172299358685922 172423824991832 172463081348933 172510408155175 172535904943475 172549508654748 172587427069191 172623859449538 172641529827070 172643455572165 172686804436826 172702126395073 172713519268761 172718161439315 172734324976974 172746381476441 172750842340569 172771121979827 172776490830362 172777317139279 172788197910100 172788790240540 172823009000290 172847765024612 172849467538613 172881121911509 172881808079216 172882407359780 172884367246104 172884469646856 172895130159665 172896836907821 172908260032784 172910794009034 172923418811871 172924743638348 172944492078739 172956962986046 172961546566080 172972699432144 172977461127944 172979735649501 172984503514014 172985119847231 172992371417119 172994560164686 172995199554935 172995529157157 173002469061919 173019736157115 173021162433514 173029686244266 173032161151401 173034176746328 173037330434198 173048343991475 173048348325534 173052046364728 173054266980588 173055695548753 173058112434630 173058595389355 173059408632850 173068771855637 173069945177871 173076492811069 173082957496684 173082967193090 173086768282586 173095257522817 173095687958402 173100118966732 173100139491684 173101878340304 173102650761131 173103264305560 173124949490040 173127785817334 173129372794611 173132660589528 173145620540411 173147927306779 173149359566990 173153296862113 173157085086260 173158587019106 173160623231712 173167479032240 173172833982751 173175429536739 173176690044841 173177377753979 173181796174841 173185183427733 173187233241944 173187952133185 173191361473678 173201322598502 173205645321522 173209442077525 173210249955733 173222063135032 173229270129332 173240752538149 173246133142186 173248815390889 173249703241463 173249882093212 173256826485899 173256938522263 173257776161320 173260495373589 173260751345517 173263592131320 173264922323109 173273604311959 173275657812125 173279939871350 173280731213415 173283420969327 173287444672218 173287539558611 173292987824779 173294098762648 173295288641663 173304280551313 173305463255506 173315697821349 173316645884801 173320496672950 173330970350503 173339087106569 173340813224803 173360834902192 173365400925392 173374559942344 173381723892007 173384234803140 173386790570657 173387059390679 173395469427932 173395934089112 173397303984410 173397984613006 173400379609166 173414477376615 173416695510230 173429223896322 173443992832408 173446513791122 173446694335739 173454756576014 173459969419749 173461930673582 173462232401547 173462249632190 173466608401089 173470518884957 173477822419019 173480349375735 173480723840496 173489473013699 173494626706393 173495202526830 173498566381461 173503734005412 173504331309310 173512380911483 173513361583176 173513925787125 173514163627600 173514290033290 173523940511259 173547110929399 173547338031972 173547909451837 173555999977254 173556080886162 173556605993043 173556680065467"

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
        
        
        MISMATCHFInal="SELECT *, FORMAT(ROUND((salePrice*percentage_commission/100),2),2) as partner_net_price_should_be
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
) AS final;"


    sleep 3
    echo "$MISMATCHFInal" >> dec.sql
    timeout $TIMEOUT_PERIOD time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -sN -e "$MISMATCHFInal" >> MismatchRecords.csv || exit 1

    # timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -sN -e "update $tableName set status = '2' where visitor_group_no in ($mismatchvgn)" || exit 1

    
    echo "Sleep Started to Run next VGNS"
    echo "------$(date '+%Y-%m-%d %H:%M:%S.%3N')--------"

    sleep 1


done