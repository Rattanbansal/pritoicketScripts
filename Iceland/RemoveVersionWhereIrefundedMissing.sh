#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=40


DB_HOST='localhost'
DB_USER='admin'
DB_PASS='redhat'
DB_NAME='dummy'
BATCH_SIZE=5
tablename=$1

mysqlHost="prodrds.prioticket.com"
mysqlUser=pipeuser
mysqlPassword=d4fb46eccNRAL
mysqlDatabase="prioprodrds"

SECDATABASE='priopassdb'
SECHOST='production-secondary-db-node.cluster-ck6w2al7sgpk.eu-west-1.rds.amazonaws.com'
SECUSER='pipeuser'
SECPASSWORD='d4fb46eccNRAL'

# vt_group_numbers="167344709177764 167516134614071 167465893687046 168906527638070 167751022482078 167248376982761 168838417240142 169538189794274 169831553710913 169539844481350 169606418364958 168665177092016 168371889682501 169929325801853 170611862739977 169988386359790 170531322846551 168277999488069 168321532684477 170307822913479 168312802342226 168718701147284 168355137442404 168753587509413 168778021504415 170680299145206 170066269101366 169841753039939 168820496475948 168400886560496"

vt_group_numbers="172345532691306"

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



    PTUPDATE="update prepaid_tickets ptt1 join (select base.visitor_group_no as order_id, base.version as version_to_update,ptt.visitor_group_no, ptt.prepaid_ticket_id, ptt.is_refunded, ptt.action_performed, ptt.version from prepaid_tickets ptt right join (select pt.visitor_group_no, pt.prepaid_ticket_id, pt.is_refunded, pt.action_performed, pt.version from prepaid_tickets pt join (select visitor_group_no,prepaid_ticket_id, max(version) as version from prepaid_tickets where visitor_group_no in ($batch_str) group by prepaid_ticket_id, visitor_group_no) as maxptv on maxptv.visitor_group_no = pt.visitor_group_no and maxptv.prepaid_ticket_id = pt.prepaid_ticket_id and ABS(ROUND(maxptv.version-pt.version,1)) = '0' where pt.is_refunded = '0' and pt.action_performed like '%ADMND_COR' and pt.deleted = '0') as base on ptt.visitor_group_no = base.visitor_group_no and ABS(ptt.version-base.version) = '0' and ptt.is_refunded = '1') as base1 on ptt1.visitor_group_no = base1.order_id and ABS(ptt1.version-base1.version_to_update) = '0' set ptt1.deleted = '3', ptt1.action_performed = concat(ptt1.action_performed, ' Iceland_Refund_Missing_Entries') where base1.visitor_group_no is NULL"
            
            
    echo "PT RDS insert query vt"
    timeout $TIMEOUT_PERIOD time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -sN -e "$PTUPDATE" || exit 1

    sleep 3

    echo "PT secondary insert query vt"
    timeout $TIMEOUT_PERIOD time mysql -h"$SECHOST" -u"$SECUSER" -p"$SECPASSWORD" -D"$SECDATABASE" -sN -e "$PTUPDATE" || exit 1
    
    sleep 3
    VTUPDATE="update visitor_tickets vtt1 join (select base.*, vtt.vt_group_no as order_id, vtt.transaction_id as order_transaction_id, vtt.row_type as order_row_type from (select vt.vt_group_no, vt.transaction_id,vt.hotel_id,vt.ticketId,vt.selected_date, vt.version, vt.row_type, vt.admin_currency_code, vt.partner_net_price, vt.partner_gross_price, vt.tax_value, vt.transaction_type_name, vt.col2, vt.action_performed, vt.is_refunded from visitor_tickets vt join (select vt_group_no, transaction_id, row_type, max(version) as version from visitor_tickets where vt_group_no in ($batch_str) and col2 != '2' group by vt_group_no, transaction_id, row_type) as maxv on maxv.vt_group_no = vt.vt_group_no and (maxv.transaction_id+1) = (vt.transaction_id+1) and maxv.row_type = vt.row_type and ABS(ROUND(maxv.version-vt.version,1)) = '0' and vt.deleted = '0' and vt.action_performed like '%ADMND_COR' and vt.is_refunded = '0') as base left join visitor_tickets vtt on vtt.vt_group_no = base.vt_group_no and ABS(base.version-vtt.version) = '0' and vtt.action_performed not like '%ADMND_COR' and vtt.is_refunded = '1' and vtt.transaction_type_name not like '%Reprice%') as base1 on base1.vt_group_no = vtt1.vt_group_no and ABS(base1.version-vtt1.version) = '0' set vtt1.deleted = '3', vtt1.action_performed = concat(vtt1.action_performed, ' Iceland_Refund_Missing_Entries') where base1.order_id is NULL"


    timeout $TIMEOUT_PERIOD time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -sN -e "$VTUPDATE" || exit 1

    sleep 3

    echo "VT update query sec"

    timeout $TIMEOUT_PERIOD time mysql -h"$SECHOST" -u"$SECUSER" -p"$SECPASSWORD" -D"$SECDATABASE" -sN -e "$VTUPDATE" || exit 1

    sleep 3


    echo "Sleep Started to Run next VGNS"
    echo "------$(date '+%Y-%m-%d %H:%M:%S.%3N')--------"

    echo "https://report.prioticket.com/Insert_api_data_nested/api_results_v2/$batch_str"
    curl https://report.prioticket.com/Insert_api_data_nested/api_results_v2/$batch_str


done
