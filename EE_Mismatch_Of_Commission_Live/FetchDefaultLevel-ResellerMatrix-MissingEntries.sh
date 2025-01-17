#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=15
DB_NAME="priopassdb"
outputFile="$PWD/records/reseller-Matrix_Missing_Entries.csv"
source ~/vault/vault_fetch_creds.sh

mkdir -p $PWD/records
# Fetch credentials for 20Server
fetch_db_credentials "PrioticketLivePriomaryroPipe"

## GEt Distinct Reseller_id from Pricelist table

echo "ticket_id,reseller_id,commission,channel_id,mec_end_date,tps_id,currency_code,clcproduct_id,ticketpriceschedule_id,resale_currency_level" > $outputFile

reseller_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN  -e "select distinct reseller_id from pricelist where reseller_id not in (541,671)") || exit 1

for reseller_id in ${reseller_ids}

do

    echo "Fetching Data for reseller_id :: $reseller_id"
    
    channel_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "select distinct channel_id from priopassdb.qr_codes where cashier_type = '1' and channel_id > '0' and channel_id is not NULL and reseller_id = '$reseller_id'")

    for channel_id in ${channel_ids}

    do 

        timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "select * from (with qr_codess as (select reseller_id,channel_id from priopassdb.qr_codes where channel_id = '$channel_id' and cashier_type = '1' and channel_id is not NULL and channel_id > '0'), channels as (select d.*, qc.channel_id from priopassdb.pricelist d join qr_codess qc on d.reseller_id = qc.reseller_id group by d.ticket_id, qc.channel_id), catalogs as (select * from channels where channel_id is not NULL), products as (select c.*, date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) as mec_end_date, tps.id as tps_id, tps.currency_code from catalogs c left join modeventcontent mec on c.ticket_id = mec.mec_id left join ticketpriceschedule tps on mec.mec_id = tps.ticket_id where mec.deleted = '0' and  date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) > CURRENT_DATE and tps.deleted = '0' and date(from_unixtime(if(tps.end_date like '9999999', '1794812755', tps.end_date))) > CURRENT_DATE) select p.*, clc.ticket_id as clcproduct_id, clc.ticketpriceschedule_id, clc.resale_currency_level from products p left join channel_level_commission clc on p.channel_id = clc.channel_id and clc.catalog_id = '0' and clc.channel_id > '0' and clc.deleted = '0' and p.ticket_id = clc.ticket_id and p.tps_id = clc.ticketpriceschedule_id and clc.is_adjust_pricing = '1') as final where clcproduct_id is NULL" >> $outputFile


        sleep 5


    done

sleep 5

done




