#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=40


# DB_HOST='10.10.10.19'
# DB_USER='pip'
# DB_PASS='pip2024##'
# DB_NAME='rattan'
# BATCH_SIZE=25

DB_HOST='localhost'
DB_USER='admin'
DB_PASS='redhat'
DB_NAME='dummy'
BATCH_SIZE=5

# mysqlHost="prodrds.prioticket.com"
# mysqlUser=pipeuser
# mysqlPassword=d4fb46eccNRAL
# mysqlDatabase="prioprodrds"

mysqlDatabase='priopassdb'
mysqlHost='production-secondary-db-node.cluster-ck6w2al7sgpk.eu-west-1.rds.amazonaws.com'
mysqlUser='pipeuser'
mysqlPassword='d4fb46eccNRAL'

echo "vt_group_no,transaction_id,version,row_type,action_performed,is_refunded,transaction_type_name" > IcelandMissingRefundVT.csv

echo "visitor_group_no,prepaid_ticket_id,is_refunded,action_performed,version" > IcelandMissingRefundPT.csv

# Get all unique ticket_ids
vt_group_numbers="172424388652190 170533246837622 170118238959462 170627778020131 171309627556902 171239128693000 169668109051294 170896277663380 171163532233281 171345615906813 172225343176036 172622557836434 169946088980166 169037075294929 171870758045596 172615086758840 172527712030818 172606430505834 171777588346570 171405551805697 172053934201631 172112122522423 172328777988227 172328825905158 170852746294769 171508840100129 170074679344450 171871228627678 172434205234704 171154282586534 170593826936299 171258759371046 172354930993526 172296074113914 171053083607824 170921935331895 173023384129377 172080515917922 169001522280637 172832739760451 172328655950718 168821370449792 169685936949064 171714632915423 168552856699484 171026788129161 170506231045665 170923290485621 171075639029990 171318645195023 171759139847204 172405688304183 172475334635984 171223345042642"

# vt_group_numbers="171334036366002"

# Convert the vt_group_numbers into an array
vt_group_array=($vt_group_numbers)
total_vt_groups=${#vt_group_array[@]}

# Loop through vt_group_no array in batches
for ((i=0; i<$total_vt_groups; i+=BATCH_SIZE)); do
    # Create a batch of vt_group_no values
    batch=("${vt_group_array[@]:$i:$BATCH_SIZE}")
    batch_size=${#batch[@]}

    # Calculate the current progress level for this ticket_id
    current_progress=$((i + batch_size))
    
    # Join the batch into a comma-separated list
    batch_str=$(IFS=,; echo "${batch[*]}")

    echo "$batch_str"
    MISMATCHFInalVT="select vtt1.vt_group_no, vtt1.transaction_id,vtt1.version, vtt1.row_type, replace(vtt1.action_performed,',','-') as action_performed, vtt1.is_refunded, vtt1.transaction_type_name from visitor_tickets vtt1 join (select base.*, vtt.vt_group_no as order_id, vtt.transaction_id as order_transaction_id, vtt.row_type as order_row_type from (select vt.vt_group_no, vt.transaction_id,vt.hotel_id,vt.ticketId,vt.selected_date, vt.version, vt.row_type, vt.admin_currency_code, vt.partner_net_price, vt.partner_gross_price, vt.tax_value, vt.transaction_type_name, vt.col2, vt.action_performed, vt.is_refunded from visitor_tickets vt join (select vt_group_no, transaction_id, row_type, min(version) as version from visitor_tickets where vt_group_no in ($batch_str) and col2 != '2' and deleted = '0' group by vt_group_no, transaction_id, row_type) as maxv on maxv.vt_group_no = vt.vt_group_no and (maxv.transaction_id+1) = (vt.transaction_id+1) and maxv.row_type = vt.row_type and ABS(ROUND(maxv.version-vt.version,1)) = '0' and vt.deleted = '0' and vt.action_performed like '%ADMND_COR%' and vt.is_refunded = '0' where vt.vt_group_no in ($batch_str)) as base left join visitor_tickets vtt on vtt.vt_group_no = base.vt_group_no and ABS(base.version-vtt.version) = '0' and vtt.action_performed not like '%ADMND_COR' and vtt.is_refunded = '1' and vtt.deleted = '0' and vtt.transaction_type_name not like '%Reprice%' and vtt.vt_group_no in ($batch_str)) as base1 on base1.vt_group_no = vtt1.vt_group_no and ABS(base1.version-vtt1.version) = '0' and base1.row_type = vtt1.row_type where vtt1.deleted = '0' and base1.order_id is NULL and vtt1.transaction_type_name not like '%Reprice%' and vtt1.vt_group_no in ($batch_str) group by vtt1.vt_group_no, vtt1.transaction_id,vtt1.version, vtt1.row_type;"

    echo "$MISMATCHFInalVT" >> MISMATCHFInalVT.sql

    MISMATCHFInalPT="select ptt1.visitor_group_no, ptt1.prepaid_ticket_id, ptt1.is_refunded, replace(ptt1.action_performed,',','-') as action_performed, ptt1.version from prepaid_tickets ptt1 join (select base.visitor_group_no as order_id, base.version as version_to_update,ptt.visitor_group_no, ptt.prepaid_ticket_id, ptt.is_refunded, ptt.action_performed, ptt.version from prepaid_tickets ptt right join (select pt.visitor_group_no, pt.prepaid_ticket_id, pt.is_refunded, pt.action_performed, pt.version from prepaid_tickets pt join (select visitor_group_no,prepaid_ticket_id, min(version) as version from prepaid_tickets where deleted = '0' and visitor_group_no in ($batch_str) group by prepaid_ticket_id, visitor_group_no) as maxptv on maxptv.visitor_group_no = pt.visitor_group_no and maxptv.prepaid_ticket_id = pt.prepaid_ticket_id and ABS(ROUND(maxptv.version-pt.version,1)) = '0' where pt.is_refunded = '0' and pt.action_performed like '%ADMND_COR%' and pt.deleted = '0' and pt.visitor_group_no in ($batch_str)) as base on ptt.visitor_group_no = base.visitor_group_no and ABS(ptt.version-base.version) = '0' and ptt.is_refunded = '1' and ptt.deleted = '0' and ptt.visitor_group_no in ($batch_str)) as base1 on ptt1.visitor_group_no = base1.order_id and ABS(ptt1.version-base1.version_to_update) = '0' where ptt1.deleted = '0' and base1.visitor_group_no is NULL and ptt1.visitor_group_no in ($batch_str);"

    echo "$MISMATCHFInalPT" >> MISMATCHFInalPT.sql


    # sleep 3
    timeout $TIMEOUT_PERIOD time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -sN  -e "$MISMATCHFInalVT" >> IcelandMissingRefundVT.csv || exit 1

    timeout $TIMEOUT_PERIOD time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -sN  -e "$MISMATCHFInalPT" >> IcelandMissingRefundPT.csv || exit 1

    
    echo "Sleep Started to Run next VGNS"
    echo "------$(date '+%Y-%m-%d %H:%M:%S.%3N')--------"
    # exit 1
    sleep 5
done