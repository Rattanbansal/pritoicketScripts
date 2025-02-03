#!/bin/bash

BUILD_USER_ID="rattan"

echo "Full Name" :: $BUILD_USER
echo "First name" :: $BUILD_USER_FIRST_NAME
echo "Last name" :: $BUILD_USER_LAST_NAME
echo "BUILD_USER_ID" :: $BUILD_USER_ID
if [[ $BUILD_USER_ID == "timer" ]] || [[ $BUILD_USER_ID == "rattan" ]] || [[ $BUILD_USER_ID == "puneet" ]]; then

today=$(date  '+%Y-%m-%d')
echo "Today: $today"
yesterday=$(date -d "-1 day" '+%Y-%m-%d')
echo "Yesterday: $yesterday"
OneYearFuture=$(date -d "+365 day" '+%Y-%m-%d')
echo "TwodaysFuture: $OneYearFuture"


echo "------------------->>>>>> Script Started at Time: $(date +'%d-%m-%Y %H:%M:%S')<<<<<<<<<<<<<<<<<-------------"

currenttime=$(date +%H:%M)

echo $currenttime
#if [[ "$currenttime" > "01:00" ]] && [[ "$currenttime" < "11:00" ]]; then
    echo 'Condition True'

gcloud config set project prioticket-reporting
capacities=$(bq query --max_rows=100000 --use_legacy_sql=false --format=sparse \
'select distinct(shared_capacity_id) as shared_capacity_id from prioticket-reporting.prio_test.IMR_ScanReportCapacityMismatch_vs_ticketCapacityV1 where  museum_id not in (43,706)')
#capacities=$(curl https://cron.prioticket.com/backend/script/get_shared_capacity_ids)

echo "$capacity"

echo $capacities


for capacity in ${capacities}
do
echo $capacity

re='^[0-9]+$'
if  [[ $capacity =~ $re ]] ; then

echo "rattan"

#id=$(($user))

Mismatch=$(time curl https://cron.prioticket.com/backend/ccm/test_index/$capacity/0)

#Mismatch=1
echo "$Mismatch" >> rattan.txt
echo ${Mismatch}

str=$Mismatch

lnth=${#str}

echo "Mismatch of Capacity Length: $lnth"

if [[ "$lnth" > 1700 ]]; then
    echo 'Condition True'
    
  sleep 3;
 Mismatchadjustment=$(curl https://cron.prioticket.com/backend/Get_csv_capacity_from_redis/get_capacity_from_redis_sold_count/$capacity/$today/$OneYearFuture/0/0/empty/1/empty/1)

#Mismatch=
echo "$Mismatchadjustment" >> adjustment.txt
echo ${Mismatchadjustment}

stradjustment=$Mismatchadjustment

lnthstradjustment=${#strstradjustment}

echo "Mismatch of Capacity Length for adjustment: $lnthstradjustment"

sleep 5;
Mismatchslotstatus=$(curl https://cron.prioticket.com/backend/Get_csv_capacity_from_redis/get_capacity_from_redis_sold_count/$capacity/$today/$OneYearFuture/0/0/0/empty/empty/1)
echo "https://cron.prioticket.com/backend/Get_csv_capacity_from_redis/get_capacity_from_redis_sold_count/$capacity/$today/$OneYearFuture/0/0/0/empty/empty/1"

#Mismatch=1
echo "$Mismatchslotstatus" >> slotstatus.txt
echo ${Mismatchslotstatus}

strslotstatus=$Mismatchslotstatus

lnthslotstatus=${#strslotstatus}

echo "Mismatch of Capacity Length: $lnthslotstatus"

if [[ "$lnthstradjustment" -le 1700 ]] && [[ "$lnthslotstatus" -le 1700 ]]; then
    echo 'Condition True for active and adjustment'
    
    
    # time curl https://cron.prioticket.com/backend/ccm/test_index/$capacity/1 >> /dev/null
    
    else
    
    echo  "Difference in SLOT_STATUS OR ADJUSTEMENT for CAPACITY_ID:$capacity"
    
    fi
    
    else
      echo "No Mismatch Found For Capacity: $capacity"
      
      fi

sleep 5

else 

echo "error: Not a number" >&2

fi


done


#else
    #echo 'Not Alllowed'
#fi

echo "------------------->>>>>> Script Ended at Time: $(date +'%d-%m-%Y %H:%M:%S')<<<<<<<<<<<<<<<<<-------------"

else
    
    echo 'User Not Fount Please Contact Administrator without Playing with System Critical Things'
fi