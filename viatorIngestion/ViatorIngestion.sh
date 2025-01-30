#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=25

source ~/vault/vault_fetch_creds.sh
# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"
DB_NAME='priopassdb'
MYSQLTABLENEW='viatoringestion'

TEMP_FILE="temp_query_result.csv"

### Database credentials for Local database so that can work without interuption
# LOCAL_HOST="10.10.10.19"
# LOCAL_USER="pip"
# LOCAL_PASS="pip2024##"
# LOCAL_NAME="priopassdb"
# LOCAL_NAME_1="priopassdb"

# # Live Credentials
LOCAL_HOST="production-primary-db-node-cluster.cluster-ck6w2al7sgpk.eu-west-1.rds.amazonaws.com"
LOCAL_USER="pipeuser"
LOCAL_PASS="d4fb46eccNRAL"
LOCAL_NAME="priopassdb"
LOCAL_NAME_1="priopassdb"


mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "DROP TABLE IF EXISTS $MYSQLTABLENEW;"

createtable="CREATE TABLE $MYSQLTABLENEW (
  ticket_id int NOT NULL,
  reseller_id int NOT NULL,
  resalecommission decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;ALTER TABLE $MYSQLTABLENEW
  ADD KEY ticket_id (ticket_id),
  ADD KEY reseller_id (reseller_id),
  ADD KEY resalecommission (resalecommission);
COMMIT;"

mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "$createtable"

mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "SET GLOBAL local_infile = 1;"

# Read CSV and insert into MySQL
mysql --local-infile=1 -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" <<EOF
LOAD DATA LOCAL INFILE 'viator.csv'
INTO TABLE $MYSQLTABLENEW
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(ticket_id,reseller_id,resalecommission);
EOF

if [ $? -ne 0 ]; then
    echo "MySQL data insertion failed. Exiting."
    exit 1
fi

echo "Data successfully inserted into MySQL table: $MYSQL_TABLE"

product_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN  -e "select distinct ticket_id from viatoringestion where ticket_id not in (88508,88527,88528,88529,88530,88534,88535,88537,88539,88540,88542,88544,88545,88546,88547,88548,88550,88551,88553,88554,88555,88557,88559,88560,88561,88562,88563,88564,88565,88567,88568,88569,88571,88573,88575,88576,88577,88578,88580,88581,88583,88585,88586,88588,88590,88591,88592,88593,88594,88595,88597,88600,88602,88621,88622,88623,88624,88625,88626,88627,88630,88632,88637,88639,88641,88643,88646,88648,88650,88651,88653,88654,88656,88658,88660,88662,88663,88664,88665,88666,88667,88668,88669,88670,88671,88673,88675,88677,88678,88679,88680,88681,88682,88683,88684,88685,88686,88691,88694,88696,88697,88699,88700,88701,88702,88704,88706,88708,88710,88712,88713,88714,88715,88717,88719,88721,88723,88724,88726,88728,88729,88731,88732,88734,88736,88737,88738,88740,88742,88744,88746,88748,88749,88751,88753,88757,88759,88761,88763,88766,88768,88770,88771,88773,88775,88777,88779,88781,88783,88785,88787,88788,88790,88791,88793,88795,88797,88799,88801,88803,88805,88807,88809,88810,88812,88814,88818,88819,88820,88821,88822,88823,88824,88825,88826,88827,88828,88829,88831,88833,88834,88836,88837,88840,88841,88842,88843,88845,88847,88849,88851,88854,88857,88859,88860,88861,88862,88865,88867,88869,88871,88873,88875,88877,88879,88881,88882,88883,88885,88886,88887,88888,88890,88892,88894,88896,88898,88900,88901,88902,88903,88904,88906,88907,88909,88911,88912,88913,88914,88916,88917,88919,88921,88922,88924,88926,88928,88930,88931,88932,88933,88942,88943,88945,88947,88948,88949,88950,88952,88953,88955,88957,88958,88960,88962,88963,88965,88966,88967,88969,88971,88974,88976,88977,88978,88979,88980,88982,88984,88986,88988,88990,88991,88993,88995,88997,88999,89001,89003,89005,89008,89010,89012,89014,89015,89017,89019,89021,89023,89026,89027,89028,89030,89032,89033,89037,89040,89042,89044,89046,89048,89049,89050,89051,89052,89053,89054,89055,89056,89057,89058,89059,89060,89061,89062,89063,89064,89065,89066,89068,89070,89072,89073,89074,89076,89077,89078,89079,89081,89082,89083,89084,89085,89086,89089,89091,89093,89095,89096,89100,89104,89105,89108,89110,89112,89114,89116,89118,89120,89122,89124,89125,89127,89129,89131,89133,89134,89136,89138,89140,89142,89143,89145,89147,89149,89151,89153,89155,89157,89159,89161,89163,89165,89166,89168,89169,89172,89174,89175,89177,89179,89181,89183,89184,89185,89186,89187,89188,89189,89190,89191,89193,89194,89196,89198,89199,89202,89204,89206,89208,89210,89211,89212,89213,89214,89216,89217,89218,89220,89222,89224,89226,89228,89229,89230,89231,89232,89233,89234,89235,89236,89237,89238,89239,89240,89241,89242,89243,89244,89245,89246,89247,89249,89251,89253,89255,89256,89257,89259,89261,89263,89265,89266,89267,89268,89269,89270,89272,89275,89278,89281,89285,89286,89288,89290,89292,89294,89296,89298,89299,89300,89301,89302,89304,89306,89308,89310,89311,89314,89316,89318,89320,89322,89324,89326,89328,89330,89332,89335,89337,89338,89340,89342,89343,89344,89345,89346,89347,89348,89349,89350,89373,90311)") || exit 1

for ticket_id in ${product_ids}

do
    echo "Script Running for Product_id: $ticket_id"

    reseller_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN  -e "select 686") || exit 1

    for reseller_id in ${reseller_ids}

    do

        echo "Fetching Data for reseller_id :: $reseller_id"
        
        channel_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "select 680")

        for channel_id in ${channel_ids}

        do 
            echo "Channel_id printed as $channel_id and query as : select * from (with qr_codess as (select reseller_id,channel_id from priopassdb.qr_codes where channel_id = '$channel_id' and cashier_type = '1' and channel_id is not NULL and channel_id > '0'), channels as (select d.*, qc.channel_id from priopassdb.viatoringestion d join qr_codess qc on d.reseller_id = qc.reseller_id where d.ticket_id = '$ticket_id' group by d.ticket_id, qc.channel_id), catalogs as (select * from channels where channel_id is not NULL), products as (select c.*, date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) as mec_end_date, tps.id as tps_id, tps.currency_code from catalogs c left join modeventcontent mec on c.ticket_id = mec.mec_id left join ticketpriceschedule tps on mec.mec_id = tps.ticket_id where mec.deleted = '0' and  date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) > CURRENT_DATE and tps.deleted = '0' and date(from_unixtime(if(tps.end_date like '9999999', '1794812755', tps.end_date))) > CURRENT_DATE) select p.*, clc.ticket_id as clcproduct_id, clc.ticketpriceschedule_id, clc.resale_currency_level from products p left join channel_level_commission clc on p.channel_id = clc.channel_id and clc.catalog_id = '0' and clc.channel_id > '0' and clc.deleted = '0' and p.ticket_id = clc.ticket_id and p.tps_id = clc.ticketpriceschedule_id and clc.is_adjust_pricing = '1') as final where clcproduct_id is NULL"

            timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -e "select * from (with qr_codess as (select reseller_id,channel_id from priopassdb.qr_codes where channel_id = '$channel_id' and cashier_type = '1' and channel_id is not NULL and channel_id > '0'), channels as (select d.*, qc.channel_id from priopassdb.viatoringestion d join qr_codess qc on d.reseller_id = qc.reseller_id where d.ticket_id = '$ticket_id' group by d.ticket_id, qc.channel_id), catalogs as (select * from channels where channel_id is not NULL), products as (select c.*, date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) as mec_end_date, tps.id as tps_id, tps.currency_code from catalogs c left join modeventcontent mec on c.ticket_id = mec.mec_id left join ticketpriceschedule tps on mec.mec_id = tps.ticket_id where mec.deleted = '0' and  date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) > CURRENT_DATE and tps.deleted = '0' and date(from_unixtime(if(tps.end_date like '9999999', '1794812755', tps.end_date))) > CURRENT_DATE) select p.*, clc.ticket_id as clcproduct_id, clc.ticketpriceschedule_id, clc.resale_currency_level from products p left join channel_level_commission clc on p.channel_id = clc.channel_id and clc.catalog_id = '0' and clc.channel_id > '0' and clc.deleted = '0' and p.ticket_id = clc.ticket_id and p.tps_id = clc.ticketpriceschedule_id and clc.is_adjust_pricing = '1') as final where clcproduct_id is NULL" > "$TEMP_FILE"

            # Check if the temporary file contains data
            if [[ -s $TEMP_FILE ]]; then
                echo "Mismatch found for Reseller_ID=$reseller_id. Appending to CSV."

                # Append the result to the main CSV file
                cat "$TEMP_FILE" >> Missing_Entries.csv

                echo "Script started for product_id: $ticket_id to add entried in the channel_level_commission.........."
                timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "insert into channel_level_commission (created_at, channel_id, ticket_id, ticketpriceschedule_id, museum_name,ticket_title,ticket_type,ticket_scan_price,ticket_list_price,ticket_new_price,ticket_discount,is_discount_in_percent,ticket_gross_price,ticket_tax_value,ticket_tax_id,ticket_net_price,museum_commission_old,museum_gross_commission,museum_net_commission,museum_commission_tax_value,museum_commission_tax_id,subtotal_net_amount,subtotal_gross_amount,subtotal_tax_value,subtotal_tax_id,is_combi_ticket_allowed,is_combi_discount,tickets_for_combi_discount,combi_discount_gross_amount,combi_discount_net_amount,combi_discount_tax_value, combi_discount_tax_id, commission_updated_at, ip_address, hotel_prepaid_commission_percentage, hotel_postpaid_commission_percentage, hotel_commission_tax_id, hotel_commission_tax_value, hgs_prepaid_commission_percentage, hgs_postpaid_commission_percentage, hgs_commission_tax_id, hgs_commission_tax_value, merchant_gross_commission, is_adjust_pricing, is_custom_setting, apply_service_tax, external_product_id, account_number, chart_number, deleted, market_merchant_id, merchant_net_commission, merchant_admin_id, merchant_admin_name, is_cluster_ticket_added, default_listing, catalog_id, last_modified_at, resale_percentage, is_resale_percentage, merchant_fee_percentage, is_merchant_fee_percentage, is_hotel_prepaid_commission_percentage, commission_on_sale_price, hotel_commission_gross_price, hotel_commission_net_price, hgs_commission_gross_price, hgs_commission_net_price, product_type, currency, resale_currency_level, resale_commission, affected_before_date, affected_date, is_active, publish_level, channel_level, reseller_id, own_merchant_id, discount_label, discount_setting_type) select CURRENT_TIMESTAMP as created_at,channel_id,ticket_id,tps_id as ticketpriceschedule_id, museum_name,ticket_title,LEFT(ticket_type, 10) AS ticket_type,ticket_scan_price,ticket_list_price, ticket_new_price, '0' as ticket_discount,'0' as is_discount_in_percent, ticket_gross_price,'0.00' as ticket_tax_value, '3' as ticket_tax_id,ticket_gross_price as ticket_net_price,museumNetPrice as museum_commission_old, museumNetPrice as museum_gross_commission,museumNetPrice as museum_net_commission,'0.00' as museum_commission_tax_value, '3' as museum_commission_tax_id,ticket_gross_price-museumNetPrice as subtotal_net_amount, ticket_gross_price-museumNetPrice as subtotal_gross_amount,'0.00' as subtotal_tax_value, '3' as subtotal_tax_id,'0' as is_combi_ticket_allowed,'0' as is_combi_discount, '0' as tickets_for_combi_discount,'0' as combi_discount_gross_amount,'0' as combi_discount_net_amount, '0.00' as combi_discount_tax_value,'3' as combi_discount_tax_id,CURRENT_TIMESTAMP as commission_updated_at,'163.47.214.55' as ip_address,'100.00' as hotel_prepaid_commission_percentage,'100.00' as hotel_postpaid_commission_percentage, '2' as hotel_commission_tax_id,'21.00' as hotel_commission_tax_value,'0.00' as hgs_prepaid_commission_percentage,'0.00' as hgs_postpaid_commission_percentage, '3' as hgs_commission_tax_id,'0.00' as hgs_commission_tax_value,'0.00' as merchant_gross_commission, '1' as is_adjust_pricing,'0' as is_custom_setting,'0' as apply_service_tax,'0' as external_product_id, '1' as account_number,'1' as chart_number,'0' as deleted,'4' as market_merchant_id, '0.00' as merchant_net_commission,'4453' as merchant_admin_id,'Attraction World Viator' as merchant_admin_name,(case when is_combi in ('2', '3') then '1' else '0' end) as is_cluster_ticket_added,'0' default_listing,'0' as catalog_id,CURRENT_TIMESTAMP as last_modified_at,'0.00' as resale_percentage,'0' as is_resale_percentage, '0.00' as merchant_fee_percentage,'0' as is_merchant_fee_percentage,'1' as is_hotel_prepaid_commission_percentage,'0' as commission_on_sale_price, ((ticket_gross_price-museumNetPrice)*(121/100)) as hotel_commission_gross_price, (ticket_gross_price-museumNetPrice) as hotel_commission_net_price,'0.00' as hgs_commission_gross_price,'0.00' as hgs_commission_net_price,is_combi as product_type,currency_code as currency,'1' as resale_currency_level,'0' as resale_commission,CURRENT_TIMESTAMP as affected_before_date,CURRENT_TIMESTAMP as affected_date,'1' as is_active,'1' as publish_level,'1' as channel_level,reseller_id,'0' as own_merchant_id,'0' as discount_label,'0' as discount_setting_type from (with qr_codess as (select reseller_id, channel_id from priopassdb.qr_codes where channel_id = '$channel_id' and cashier_type = '1' and channel_id is not NULL and channel_id > '0'), channels as (select d.*, qc.channel_id from priopassdb.viatoringestion d join qr_codess qc on d.reseller_id = qc.reseller_id where d.ticket_id = '$ticket_id' group by d.ticket_id, qc.channel_id), catalogs as (select * from channels where channel_id is not NULL), products as (select c.*, date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) as mec_end_date,mec.museum_name,mec.postingEventTitle as ticket_title,tps.ticket_type_label as ticket_type,tps.newPrice as ticket_scan_price, tps.newPrice as ticket_list_price, tps.newPrice as ticket_new_price,tps.newPrice as ticket_gross_price, tps.id as tps_id, tps.currency_code, mec.is_combi, tps.museumNetPrice from catalogs c left join modeventcontent mec on c.ticket_id = mec.mec_id left join ticketpriceschedule tps on mec.mec_id = tps.ticket_id where mec.deleted = '0' and date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) > CURRENT_DATE and tps.deleted = '0' and date(from_unixtime(if(tps.end_date like '9999999', '1794812755', tps.end_date))) > CURRENT_DATE) select p.*, clc.ticket_id as clcproduct_id, clc.ticketpriceschedule_id, clc.resale_currency_level from products p left join channel_level_commission clc on p.channel_id = clc.channel_id and clc.catalog_id = '0' and clc.channel_id > '0' and clc.deleted = '0' and p.ticket_id = clc.ticket_id and p.tps_id = clc.ticketpriceschedule_id and clc.is_adjust_pricing = '1') as final where clcproduct_id is NULL;select ROW_COUNT();"

                echo "Script started for product_id: $ticket_id to add entries in the channel_level_commission..........Ended"


                echo "Script started for product_id: $ticket_id to add entries in the template_level_tickets.........."
                timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "insert into template_level_tickets (template_id, ticket_id, is_pos_list, is_suspended, created_at, market_merchant_id, content_description_setting, last_modified_at, catalog_id, merchant_admin_id, publish_catalog, product_verify_status, deleted) select template_id, ticket_id,'0' as is_pos_list,'0' as is_suspended,CURRENT_TIMESTAMP as created_at,'4' as market_merchant_id, '12635' as content_description_setting,CURRENT_TIMESTAMP as last_modified_at,'0' as catalog_id,'4453' as merchant_admin_id,'0' as publish_catalog, '0' as product_verify_status,'0' as deleted from (with qr_codess as (select reseller_id, template_id from priopassdb.qr_codes where channel_id = '$channel_id' and cashier_type = '1' and channel_id is not NULL and channel_id > '0'), channels as (select d.*, qc.template_id from priopassdb.viatoringestion d join qr_codess qc on d.reseller_id = qc.reseller_id where d.ticket_id = $ticket_id group by d.ticket_id, qc.template_id), catalogs as (select * from channels where template_id is not NULL), products as (select c.*, date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) as mec_end_date,mec.museum_name,mec.postingEventTitle as ticket_title,tps.ticket_type_label as ticket_type,tps.newPrice as ticket_scan_price, tps.newPrice as ticket_list_price, tps.newPrice as ticket_new_price,tps.newPrice as ticket_gross_price, tps.id as tps_id, tps.currency_code, mec.is_combi, tps.museumNetPrice from catalogs c left join modeventcontent mec on c.ticket_id = mec.mec_id left join ticketpriceschedule tps on mec.mec_id = tps.ticket_id where mec.deleted = '0' and date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) > CURRENT_DATE and tps.deleted = '0' and date(from_unixtime(if(tps.end_date like '9999999', '1794812755', tps.end_date))) > CURRENT_DATE) select p.*, tlt.ticket_id as tltproduct_id from products p left join template_level_tickets tlt on p.template_id = tlt.template_id and tlt.template_id > '0' and tlt.deleted = '0' and p.ticket_id = tlt.ticket_id) as final where tltproduct_id is NULL group by template_id, ticket_id;select ROW_COUNT();"
                echo "Script started for product_id: $ticket_id to add entries in the template_level_tickets..........Ended"

            else
                echo "No mismatch found for RESELLER_ID=$reseller_id. Skipping."
                echo "No mismatch found for RESELLER_ID=$reseller_id. Skipping. for product_id::: $ticket_id"
                cat "$TEMP_FILE" >> Missing_Entries.csv
            fi

            sleep 1

            rm -f "$TEMP_FILE"


        done
    sleep 1
    done
    echo "$ticket_id" >> processed.txt
    # break
done

# exit 1

distributor_ids=$(timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN  -e "SELECT DISTINCT cod_id FROM qr_codes where reseller_id = '686' and cashier_type = '1' and own_supplier_id > '0';") || exit 1

for distributor_id in ${distributor_ids}

do

    echo "Script Running for distributor id: $distributor_id"
    INSERT_MISSING_PRODUCT="insert into pos_tickets(mec_id,cat_id,hotel_id,museum_id,product_type,company,rezgo_ticket_id,rezgo_id,rezgo_key,tourcms_tour_id,tourcms_channel_id,tax_value,service_cost,latest_sold_date,shortDesc,eventImage,ticketwithdifferentpricing,saveamount,ticketPrice,pricetext,ticket_net_price,newPrice,totalticketPrice,new_discount_price,is_reservation,agefrom,ageto,ticketType,is_combi_ticket_allowed,is_booking_combi_ticket_allowed,start_date,end_date,extra_text_field,deleted,is_updated,third_party_id,third_party_ticket_id,third_party_parameters) SELECT mec_id, cat_id, hotel_id, museum_id, product_type, company, rezgo_ticket_id, rezgo_id, rezgo_key, tourcms_tour_id, tourcms_channel_id, tax_value, service_cost, latest_sold_date, shortDesc, eventImage, ticketwithdifferentpricing, saveamount, ticketPrice, pricetext, ticket_net_price, newPrice, totalticketPrice, new_discount_price, is_reservation, agefrom, ageto, ticketType, is_combi_ticket_allowed, is_booking_combi_ticket_allowed, start_date, end_date, extra_text_field, deleted, is_updated, third_party_id, third_party_ticket_id, third_party_parameters FROM ( SELECT pos.mec_id AS base_id, base2.ticket_id AS mec_id, base2.cat_id AS cat_id, base2.cod_id AS hotel_id, base2.supplier_id AS museum_id, base2.product_type AS product_type, base2.company AS company, '0' AS rezgo_ticket_id, '0' AS rezgo_id, '192168110' AS rezgo_key, '0' AS tourcms_tour_id, '0' AS tourcms_channel_id, base2.tax_value AS tax_value, '0' AS service_cost, '2021-06-19' AS latest_sold_date, base2.shortDesc AS shortDesc, base2.eventImage AS eventImage, '1' AS ticketwithdifferentpricing, base2.saveamount AS saveamount, base2.ticketPrice AS ticketPrice, base2.pricetext AS pricetext, base2.ticket_net_price AS ticket_net_price, base2.newPrice AS newPrice, base2.totalticketPrice AS totalticketPrice, base2.new_discount_price AS new_discount_price, base2.is_reservation AS is_reservation, base2.agefrom AS agefrom, base2.ageto AS ageto, base2.ticketType AS ticketType, '0' AS is_combi_ticket_allowed, '0' AS is_booking_combi_ticket_allowed, base2.start_date AS start_date, base2.end_date AS end_date, '0' AS extra_text_field, '0' AS deleted, '0' AS is_updated, base2.third_party_id AS third_party_id, base2.third_party_ticket_id AS third_party_ticket_id, base2.third_party_parameters AS third_party_parameters FROM ( SELECT CURRENT_DATE() AS DATE, DATE(FROM_UNIXTIME(tps.start_date)) AS tps_start_date, DATE( FROM_UNIXTIME( IF( tps.end_date LIKE '%9999%', '1750343264', tps.end_date) ) ) AS tps_end_time, tps.ticket_id AS tps_ticket_id, tps.default_listing, qc.cod_id, qc.template_id AS company_template_id, tlt.template_id, tlt.ticket_id, mec.cat_id, mec.sub_cat_id, mec.cod_id AS supplier_id, ( CASE WHEN mec.is_combi IN('2', '3') THEN mec.is_combi ELSE 0 END ) AS product_type, mec.museum_name AS company, qc.country_code AS country_code, qc.country AS country, tps.ticket_tax_value AS tax_value, mec.postingEventTitle AS shortDesc, mec.eventImage AS eventImage, tps.saveamount AS saveamount, tps.pricetext AS ticketPrice, tps.pricetext AS pricetext, tps.newPrice AS newPrice, tps.ticket_net_price AS ticket_net_price, tps.newPrice AS totalticketPrice, tps.newPrice AS new_discount_price, mec.isreservation AS is_reservation, tps.agefrom AS agefrom, tps.ageto AS ageto, tps.ticket_type_label AS ticketType, ( CASE WHEN mec.is_allow_pre_bookings = '1' AND mec.is_reservation = '1' THEN mec.pre_booking_date ELSE mec.startDate END ) AS start_date, mec.endDate AS end_date, mec.third_party_id AS third_party_id, mec.third_party_ticket_id AS third_party_ticket_id, mec.third_party_parameters AS third_party_parameters, 'getQuery' AS action_performed FROM qr_codes qc LEFT JOIN template_level_tickets tlt ON qc.template_id = tlt.template_id LEFT JOIN modeventcontent mec ON mec.mec_id = tlt.ticket_id LEFT JOIN ticketpriceschedule tps ON tps.ticket_id = mec.mec_id AND tps.default_listing = '1' AND DATE( FROM_UNIXTIME( IF( tps.end_date LIKE '%9999%', '1750343264', tps.end_date ) ) ) >= CURRENT_DATE() WHERE qc.cod_id = '$distributor_id' AND mec.deleted = '0' AND tlt.deleted = '0' AND qc.cashier_type = '1' AND tlt.template_id != '0' AND DATE( FROM_UNIXTIME( IF( tps.end_date LIKE '%9999%', '1750343264', tps.end_date ) ) ) >= CURRENT_DATE() GROUP BY tlt.template_level_tickets_id, qc.cod_id, tps.ticket_id) AS base2 LEFT JOIN pos_tickets pos ON base2.cod_id = pos.hotel_id AND base2.ticket_id = pos.mec_id and pos.deleted = '0') AS final_missing_entries_in_pos_tickets WHERE base_id IS NULL;select ROW_COUNT();"

    timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN  -e "$INSERT_MISSING_PRODUCT" || exit 1
    
    echo "Insert Query completed for Ditributorid : $distributor_id"
    sleep 2
    curl https://cron.prioticket.com/backend/purge_fastly/Custom_purge_fastly_cache/1/0/$distributor_id

    sleep 5
    echo "$distributor_id" >> hotels.txt
    # break
done


# SELECT DISTINCT cod_id FROM qr_codes where reseller_id = '686' and cashier_type = '1' and own_supplier_id > '0';