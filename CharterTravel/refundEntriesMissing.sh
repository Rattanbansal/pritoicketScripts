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
vt_group_numbers="165591353002572 165695595920054 165634056585576 172164849136544 170697721306954 171406043450116 172164916742108 170743334442174 171561432071585 171527195227688 170600586356121 170696372402568 171404243734267 172286734153944 171619958145922 171154582470325 170352810983987 170352603415317 170087684014765 170076850557493 172182652260470 170708229019521 170600643967801 171334240422241 170817271453408 170673183026610 171085421037880 170488430795989 170507119596137 170119274113211 172164250584072 170378671491038 169437673827543 170135419861866 171578155419547 170531842779001 171171215402837 170419506994646 170446740445423 170420839045589 171594791597528 171074271558937 171276344442553 170965567330620 171028071143852 171052091835437 171325893999647 171403948324688 171922667127864 172087612696215 171441054131685 171480779951152 171865415098441 171154565525581 171447417714982 172346085383565 171465235199467 172330009214164 170531854786866 172409508067380 170378285767023 170378346096739 170505620500950 170678319134567 170816979793789 170359107879042 170378734076893 170386276531667 170421675278220 170420752008792 171074197075240 171135579040613 171006890023821 171028500133957 171155150288720 171171023811391 171171459893647 171657850997589 171658553894878 170989167822622 171362812652229 171440901091398 171871323202418 171947958473209 172330021736418 172346174951978 171085400726537 170456033981984 170618246669242 170600726709670 171328093720715 171447403782733 170352663931454 170393448036357 170317095803229 170393624476662 171007100599747 170998511137470 171028053354462 171156664382277 171181112372451 170819873257638 171170408619343 172008847746018 170989517229516 170965459716659 170998669037341 171017811844854 171388138566053 170965223834811 171343546028585 171474353355170 171480486648778 171863291748390 171863333975303 171871447462994 172045163408853 172296172963099 170965429852072 170965621571331 170965704957690 171027871894229 171027904547359 171135547841986 171138676743451 171742146380029 171156704066333 171164814104893 171164858651807 171171067110181 171171072179263 171171313688505 171784586968880 170965516380111 170990563817421 171172565257498 171172634857544 171172731815709 171172761486189 171172782601264 171480577480878 171666009247579 171666214388704 171750507736586 171862777815017 171870318994137 171871445156903 171907331148149 171059080394393 171448259354861 172346306596829 172668433561863 170359354414781 170359517877591 169564935520264 169623946398690 170378716063103 172330030525874 171933995306783 170998586477639 171860462529735 171887288128130 171283228299734 170998430076176 170998612943362 171172693783685 171862848262018 172260820818585 171828944203227 171871183896149 171155172898588 170904597205651 171405959852429 170359099357188 170352556760629 171027955909347 171171137974300 171171276384791 170965293528791 171886514016067 171042603514187 171018193635906 171172581441383 171666271035643 171448296313751 171155395821448 171480503005692 170990578945323 171871230379601 170359442131076 170989552507071 170965514799362 171049676767349 169995810168891 170998660612939 171657869529172 170359036187700 171664650858342 171620816809581 170998418140361 171172679330766 169806156021330 170998570787890 171138626385564 170990141188485 169849394204000 171155428322898 171181096131794 172052857361302 170418880125684 171155380126674 171171125152287 170415629504223 170359145563165 172571306098857 170937301878620 170989562893978 172326798342768 170937324530384 170420580890054 170989348595263 171171085880152 169806145491407 171164891412115 170619936335753 172571321552095"

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