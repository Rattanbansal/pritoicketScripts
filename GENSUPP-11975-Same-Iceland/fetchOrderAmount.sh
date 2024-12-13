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
DB_NAME='dummy'
BATCH_SIZE=30
tableName=$1

# mysqlHost="prodrds.prioticket.com"
# mysqlUser=pipeuser
# mysqlPassword=d4fb46eccNRAL
# mysqlDatabase="prioprodrds"

mysqlDatabase='priopassdb'
mysqlHost='production-secondary-db-node.cluster-ck6w2al7sgpk.eu-west-1.rds.amazonaws.com'
mysqlUser='pipeuser'
mysqlPassword='d4fb46eccNRAL'

echo "vt_group_no,transaction_id,hotel_id,ticketId,selected_date,version,admin_currency_code,quantity,saleprice,purchaseprice,commission,hgscommission,merchantcommission,salepriceDiscount,purchasepriceDiscount,commissionDiscount,hgscommissionDiscount,merchantcommissionDiscount" > GENSUPP11975.csv

# Get all unique ticket_ids
vt_group_numbers="172424388652190 170533246837622 170118238959462 170627778020131 171309627556902 171239128693000 169668109051294 170896277663380 171163532233281 171345615906813 172225343176036 172622557836434 169946088980166 169037075294929 171870758045596 172615086758840 172527712030818 171334036366002 172606430505834 171777588346570 171405551805697 172053934201631 172112122522423 172328777988227 172328825905158 170852746294769 171508840100129 170074679344450 171871228627678 172434205234704 171154282586534 170593826936299 171258759371046 172354930993526 172296074113914 171053083607824 170921935331895 173023384129377 172080515917922 169001522280637 172832739760451 172328655950718 168821370449792 169685936949064 171714632915423 168552856699484 171026788129161 170506231045665 170923290485621 171075639029990 171318645195023 171759139847204 172405688304183 172475334635984 171223345042642"

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
    MISMATCHFInal="select vt_group_no, transaction_id, hotel_id, ticketId, selected_date, version, max(admin_currency_code) as admin_currency_code,sum(case when row_type = '1' and transaction_type_name not like '%Reprice%' then 1 else 0 end) as quantity,sum(case when row_type = '1' and transaction_type_name not like '%Reprice%' then partner_net_price else 0 end) as saleprice,sum(case when row_type = '2' and transaction_type_name not like '%Reprice%' then partner_net_price else 0 end) as purchaseprice,sum(case when row_type = '3' and transaction_type_name not like '%Reprice%' then partner_net_price else 0 end) as commission,sum(case when row_type = '4' and transaction_type_name not like '%Reprice%' then partner_net_price else 0 end) as hgscommission,sum(case when row_type = '17' and transaction_type_name not like '%Reprice%' then partner_net_price else 0 end) as merchantcommission,sum(case when row_type = '1' and transaction_type_name like '%Reprice%' then partner_net_price else 0 end) as salepriceDiscount,sum(case when row_type = '2' and transaction_type_name like '%Reprice%' then partner_net_price else 0 end) as purchasepriceDiscount,sum(case when row_type = '3' and transaction_type_name like '%Reprice%' then partner_net_price else 0 end) as commissionDiscount,sum(case when row_type = '4' and transaction_type_name like '%Reprice%' then partner_net_price else 0 end) as hgscommissionDiscount,sum(case when row_type = '17' and transaction_type_name like '%Reprice%' then partner_net_price else 0 end) as merchantcommissionDiscount  from (select vt.vt_group_no, concat(vt.transaction_id, 'R') as transaction_id,vt.hotel_id,vt.ticketId,vt.ticketpriceschedule_id,vt.selected_date, vt.version, vt.row_type, vt.admin_currency_code, vt.partner_net_price, vt.partner_gross_price, vt.tax_value, vt.transaction_type_name, vt.col2, vt.is_refunded from visitor_tickets vt join (select vt_group_no, transaction_id, row_type, max(version) as version from visitor_tickets where vt_group_no in ($batch_str) and deleted = '0' and col2 != '2' group by vt_group_no, transaction_id, row_type, ticketId, ticketpriceschedule_id) as maxv on maxv.vt_group_no = vt.vt_group_no and maxv.transaction_id = vt.transaction_id and maxv.row_type = vt.row_type and ABS(ROUND(maxv.version-vt.version,1)) = '0' where vt.is_refunded = '0') as base group by vt_group_no, ticketId, ticketpriceschedule_id;"

    echo "$MISMATCHFInal"
    # sleep 3
    timeout $TIMEOUT_PERIOD time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -sN -e "$MISMATCHFInal" >> GENSUPP11975.csv || exit 1

    
    echo "Sleep Started to Run next VGNS"
    echo "------$(date '+%Y-%m-%d %H:%M:%S.%3N')--------"

    sleep 5
done