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

echo "vt_group_no,transaction_id,version,row_type,action_performed,is_refunded,transaction_type_name" > charterTravelVT.csv

echo "visitor_group_no,prepaid_ticket_id,is_refunded,action_performed,version" > charterTravelPT.csv

# Get all unique ticket_ids
vt_group_numbers="170989827341753 170989774976309 170989789399250 170989793941156 170989799239740 170989804054976 170989811714496 170989815590920 170989819665248 170989823472794 171102251062596 171102271933620 171102276929699 171102283798859 171102290552630 171102295307183 171102300112232 171102304779519 171102310719394 171102318067965 171102323496496 171102328127961 171102338402778 171102343970440 171102349975768 171102711609478 171102717325119 171102722657299 171102740277589 171102824069036 171102830346351 171102840586646 171102850852957 171102855688674 171102860209951 171102864898916 171102887580676 171103224396271 171103228515611 171103233271795 171103238315623 171103243508817 171103248669466 171284056127624 171284062914767 171284067300091 171284103139049 171284107362241 171284115304721 171284139467575 171284142893022 171284146834421 171284150270042 171284154134199 171284157873736 171284161498287 171284165275907 171284168901170 171284172237247 171284175561277 171284179359204 171284182940018 171284186236338 171284189609299 171284193320560 171472949651384 171472955798486 171472959652098 171472964041344 171472968078481 171472971875711 171525754291984 171525762344019 171525766784829 171525775349013 171525780240856 171525786038022 171525790564219 171525797775541 171525801716219 171525806670226 171525810479545 171525817751750 171525821428340 171525825176853 171645546262331 171645639461142 171645643661384 171689734248654 171645647323239 171645656782075 171645662187464 171645676139655 171645679399505 171645683443781 171645690622778 171645723803051 171645727640553 171645731483234 171645734667117 171645738414735 171645749791079 171645753189874 171645791751855 171645855624237 171645858959390 171645862477499 171645866309722 171645869856205 171645872952230 171645876364183 171645879876640 171645882815831 171776016009409 171776021532385 171776051241761 171776055464100 171776059219141 171776062705980 171776066409338 171776070026729 171776080646393 171776089698251 171776094624625 171776098804256 171776102823297 171776107403225 171776110986729 171776114887471 171776118172427 171776121318613 171776124833951 171776128593291 171776132774677 171776136218893 171776139607156 171776142592893 171776146590485 171776150221028 171776153267999 171776156562398 171776159610279 171776163026136 171871146070942 171871150956577 171871155744739 171871160143762 171871165027485 171871228627678 171871235648418 171871239957472 171871246061332 171871253470529 171871348241538 171871354626496 171871361828364 171871367364956 171871384116119 171871388821298 171871393858758 171871400082501 171871405320528 171871410545087 171871415962027 171871420539289 171871425175456 171871430079569 171871434565114 171871438898473 171871443249658 171871448445705 171871452675233 171871457317411 171871462077151 171871466925506 171871471264680 171871476284874 172546337551034 172546350251712 172546356007864 172546873058114 172546895563747 172546899424390 172546903425389 172546907453410 172546911703049 172546926932391 172546930948281 172546935835221 172546939972869 172612811856424 172612817571036 172612822096953 172612826275971 172612830393108 172612835066252 172612839446740 172612845412222 172612849404908 172612852962513 172612865971501 172612873118963 172787668083806"

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
    timeout $TIMEOUT_PERIOD time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -sN  -e "$MISMATCHFInalVT" >> charterTravelVT.csv || exit 1

    timeout $TIMEOUT_PERIOD time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"$mysqlDatabase" -sN  -e "$MISMATCHFInalPT" >> charterTravelPT.csv || exit 1

    
    echo "Sleep Started to Run next VGNS"
    echo "------$(date '+%Y-%m-%d %H:%M:%S.%3N')--------"
    # exit 1
    sleep 5
done