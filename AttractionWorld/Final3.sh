#!/bin/bash

set -e # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=40

# SOURCE_DB_HOST='10.10.10.19'
# SOURCE_DB_USER='pip'
# SOURCE_DB_PASSWORD='pip2024##'
# SOURCE_DB_NAME='priopassdb'
# CatalogID='140267947063130'
# ResellerId='686'
# BATCH_SIZE=30

SOURCE_DB_HOST='production-primary-db-node-cluster.cluster-ck6w2al7sgpk.eu-west-1.rds.amazonaws.com'
SOURCE_DB_USER='pipeuser'
SOURCE_DB_PASSWORD='d4fb46eccNRAL'
SOURCE_DB_NAME='priopassdb'
CatalogID='160277418148092'
ResellerId='686'
BATCH_SIZE=150

echo "data Run for Catalog_id :---- $CatalogID" >> raja3.txt

Catalog_product_delete="update template_level_tickets set deleted = '8' where catalog_id = '$CatalogID' and deleted = '0' and template_id = '0'"

Linked_Distributors_LIST="select distinct(cod_id) as cod_id from qr_codes where sub_catalog_id = '$CatalogID' and cod_id not in (12917,12918,12919,12920,12921,12922,12923,12924,12925,12926,12927,12928,12929,12930,12931,12932,12933,12934,12935,12936,12937,12938,12939,12940,12941,12942,12943,12944,12945,12946,12947,12948,12949,12950,12951,12952,12953,12955,12956,12957,12958,12959,12960,12961,12962,12963,12964,12965,12966,12967,12968,12969,12970,12971,12972,12973,12974,12975,12976,12977,12978,12979,12980,12981,12982,12983,12984,12985,12986,12987,12988,12989,12990,12991,12992,12993,12994,12995,12996,12997,12998,12999,13000,13001,13002,13003,13004,13005,13006,13007,13008,13009,13010,13011,13012,13013,13014,13015,13016,13017,13018,13019,13020,13021,13022,13023,13024,13025,13026,13027,13028,13029,13030,13031,13032,13033,13034,13035,13036,13037,13038,13039,13040,13041,13042,13043,13044,13045,13046,13047,13048,13049,13050,13051,13052,13053,13054,13055,13056,13057,13058,13059,13060,13061,13062,13063,13064,13065,13066,13067,13068,13069,13070,13071,13072,13073,13074,13075,13076,13077,13078,13079,13080,13081,13082,13083,13084,13085,13086,13087,13088,13089,13090,13091,13092,13093,13094,13095,13096,13097,13098,13099,13100,13101,13102,13103,13104,13105,13106,13107,13108,13109,13110,13111,13112,13113,13114,13115,13116,13117,13118,13119,13120,13121,13122,13123,13124,13125,13126,13127,13128,13129,13130,13131,13132,13132,13133,13134,13135,13136,13137,13138,13139,13140,13141,13142,13143,13144,13145,13146,13147,13148,13149,13150,13151,13152,13153,13154,13155,13156,13157,13158,13159,13160,13161,13162,13163,13164,13165,13166,13167,13168,13169,13170,13171,13172,13173,13174,13175,13176,13177,13178,13179,13180,13181,13182,13183,13184,13185,13186,13187,13188,13189,13190,13191,13192,13193,13194,13195,13196,13197,13198,13199,13200,13201,13202,13203,13204,13205,13206,13207,13208,13209,13210,13211,13212,13213,13214,13215,13216,13217,13218,13219,13220,13221,13222,13223,13224,13225,13226,13227,13228,13229,13230,13231,13232,13233,13234,13235,13236,13237,13238,13239,13240,13241,13242,13243,13244,13245,13246,13247,13248,13249,13249,13250,13251,13252,13253,13254,13255,13256,13257,13258,13259,13260,13261,13262,13263,13264,13265,13266,13267,13268,13269,13270,13271,13272,13273,13274,13275,13276,13277,13278,13279,13280,13281,13282,13283,13284,13285,13286,13287,13288,13289,13290,13291,13292,13293,13294,13295,13296,13297,13298,13299,13300,13301,13302,13303,13304,13305,13306,13307,13308,13309,13310,13311,13312,13313,13314,13315,13316,13317,13318,13319,13320,13321,13322,13323,13324,13325,13326,13327,13328,13329,13330,13331,13332,13333,13334,13335,13336,13337,13338,13339,13340,13341,13342,13343,13344,13345,13346,13347,13348,13349,13350,13351,13352,13353) and cashier_type = '1'"

QueryTocheckProductNot_exist_in_Catalog="select * from (with allProducts as (select * from template_level_tickets where template_id in (select template_id from (select templatetype.*, catalogtype.catalog_id as subcatalog_id, catalogtype.catalog_type from (select base1.*, (case when resellers.template_id = base1.template_id then 2 else 1 end) as template_type from (select templates.template_id, templates.reseller_id, templates.is_default, templates.catalog_id from templates right join (select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '$ResellerId' and cashier_type = '1') group by template_id, catalog_id) as base on base.template_id = templates.template_id where templates.catalog_id is not NULL group by templates.template_id, templates.reseller_id, templates.catalog_id) as base1 left join resellers on base1.reseller_id = resellers.reseller_id) as templatetype left join (SELECT catalog_id, reseller_id, catalog_type FROM catalogs where catalog_category = '2' and reseller_id = '$ResellerId' and is_deleted = '0' and catalog_id = '$CatalogID') as catalogtype on templatetype.reseller_id = catalogtype.reseller_id and templatetype.template_type = catalogtype.catalog_type) as bbb where subcatalog_id is not NULL) and deleted = '0' and publish_catalog = '1') select exceptions.catalog_id as exception_catalog_id, exceptions.is_pos_list as exception_pos_list, exceptions.ticket_id as exception_ticket_id, allProducts.* from exceptions left join allProducts on exceptions.ticket_id = allProducts.ticket_id) as final where ticket_id is not NULL and exception_catalog_id != '0' and ticket_id not in (select ticket_id from template_level_tickets where catalog_id = '$CatalogID' and deleted = '0' and publish_catalog = '1');"

INSERT_QueryTocheckProductNot_exist_in_catalog="insert into template_level_tickets (template_id, ticket_id, is_pos_list, is_suspended, created_at, market_merchant_id, content_description_setting, last_modified_at, catalog_id, merchant_admin_id, publish_catalog, product_verify_status, deleted)  select '0' as template_id, ticket_id, exception_pos_list, is_suspended,CURRENT_TIMESTAMP as created_at,market_merchant_id,content_description_setting, CURRENT_TIMESTAMP as last_modified_at, exception_catalog_id as catalog_id, merchant_admin_id, publish_catalog, product_verify_status, deleted from (with allProducts as (select * from template_level_tickets where template_id in (select template_id from (select templatetype.*, catalogtype.catalog_id as subcatalog_id, catalogtype.catalog_type from (select base1.*, (case when resellers.template_id = base1.template_id then 2 else 1 end) as template_type from (select templates.template_id, templates.reseller_id, templates.is_default, templates.catalog_id from templates right join (select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '$ResellerId' and cashier_type = '1') group by template_id, catalog_id) as base on base.template_id = templates.template_id where templates.catalog_id is not NULL group by templates.template_id, templates.reseller_id, templates.catalog_id) as base1 left join resellers on base1.reseller_id = resellers.reseller_id) as templatetype left join (SELECT catalog_id, reseller_id, catalog_type FROM catalogs where catalog_category = '2' and reseller_id = '$ResellerId' and is_deleted = '0' and catalog_id = '$CatalogID') as catalogtype on templatetype.reseller_id = catalogtype.reseller_id and templatetype.template_type = catalogtype.catalog_type) as bbb where subcatalog_id is not NULL) and deleted = '0' and publish_catalog = '1') select exceptions.catalog_id as exception_catalog_id, exceptions.is_pos_list as exception_pos_list, exceptions.ticket_id as exception_ticket_id, allProducts.* from exceptions left join allProducts on exceptions.ticket_id = allProducts.ticket_id) as final where ticket_id is not NULL and exception_catalog_id != '0' and ticket_id not in (select ticket_id from template_level_tickets where catalog_id = '$CatalogID' and deleted = '0' and publish_catalog = '1');"

QueryTocheckProduct_exist_in_Catalog="select neww.*, tlts.catalog_id, tlts.ticket_id, tlts.is_pos_list from (select exception_catalog_id, exception_pos_list, exception_ticket_id from (with allProducts as (select * from template_level_tickets where template_id in (select template_id from (select templatetype.*, catalogtype.catalog_id as subcatalog_id, catalogtype.catalog_type from (select base1.*, (case when resellers.template_id = base1.template_id then 2 else 1 end) as template_type from (select templates.template_id, templates.reseller_id, templates.is_default, templates.catalog_id from templates right join (select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '$ResellerId' and cashier_type = '1') group by template_id, catalog_id) as base on base.template_id = templates.template_id where templates.catalog_id is not NULL group by templates.template_id, templates.reseller_id, templates.catalog_id) as base1 left join resellers on base1.reseller_id = resellers.reseller_id) as templatetype left join (SELECT catalog_id, reseller_id, catalog_type FROM catalogs where catalog_category = '2' and reseller_id = '$ResellerId' and is_deleted = '0' and catalog_id = '$CatalogID') as catalogtype on templatetype.reseller_id = catalogtype.reseller_id and templatetype.template_type = catalogtype.catalog_type) as bbb where subcatalog_id is not NULL) and deleted = '0' and publish_catalog = '1') select exceptions.catalog_id as exception_catalog_id, exceptions.is_pos_list as exception_pos_list, exceptions.ticket_id as exception_ticket_id, allProducts.* from exceptions left join allProducts on exceptions.ticket_id = allProducts.ticket_id) as final where ticket_id is not NULL and exception_catalog_id != '0' and ticket_id in (select ticket_id from template_level_tickets where catalog_id = '$CatalogID' and deleted = '0' and publish_catalog = '1')) as neww join template_level_tickets tlts on tlts.catalog_id = neww.exception_catalog_id and tlts.ticket_id = neww.exception_ticket_id and tlts.is_pos_list != neww.exception_pos_list;"

Update_QueryTocheckProduct_exist_in_Catalog="update exceptions join template_level_tickets tlt on exceptions.catalog_id = tlt.catalog_id and exceptions.ticket_id = tlt.ticket_id and exceptions.is_pos_list != tlt.is_pos_list set tlt.is_pos_list = exceptions.is_pos_list where tlt.catalog_id = '$CatalogID';"

LINKED_TEMPLATE="select template_id from (select templatetype.*, catalogtype.catalog_id as subcatalog_id, catalogtype.catalog_type from (select base1.*, (case when resellers.template_id = base1.template_id then 2 else 1 end) as template_type from (select templates.template_id, templates.reseller_id, templates.is_default, templates.catalog_id from templates right join (select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '$ResellerId' and cashier_type = '1') group by template_id, catalog_id) as base on base.template_id = templates.template_id where templates.catalog_id is not NULL group by templates.template_id, templates.reseller_id, templates.catalog_id) as base1 left join resellers on base1.reseller_id = resellers.reseller_id) as templatetype left join (SELECT catalog_id, reseller_id, catalog_type FROM catalogs where catalog_category = '2' and reseller_id = '$ResellerId' and is_deleted = '0' and catalog_id = '$CatalogID') as catalogtype on templatetype.reseller_id = catalogtype.reseller_id and templatetype.template_type = catalogtype.catalog_type) as bbb where subcatalog_id is not NULL"

echo "$Update_QueryTocheckProduct_exist_in_Catalog"

update_POS_LIST="update pos_tickets poss join (select *, (case when tlc_is_pos_list is NULL and tlt_is_pos_list is NULL and main_template_pos_list is not NULL then main_template_pos_list when tlc_is_pos_list is NULL and tlt_is_pos_list is NOT NULL then tlt_is_pos_list when tlc_is_pos_list is not NULL then tlc_is_pos_list else pos_is_pos_list end) as should_be from (select base349.*, mec.postingEventTitle as product_title from 

        (select * from 
        (select base.*, 'Product on Main Catalog' as type2,tlt.ticket_id as main_linked_ticket_id, tlt.template_id as main_template_id, tlt.is_pos_list as main_template_pos_list from (
            
            select pos.hotel_id as pos_hotel_id, tlc.hotel_id as tlc_hotel_id,qc.cod_id as company_hotel_id,qc.template_id as company_template_id, tlt.template_id as template_template_id, pos.is_pos_list as pos_is_pos_list, (tlc.is_pos_list+0-1) as tlc_is_pos_list, tlt.is_pos_list as tlt_is_pos_list, pos.mec_id as pos_ticket_id, tlc.ticket_id as tlc_ticket_id, tlt.ticket_id as tlt_ticket_id,qc.sub_catalog_id as sub_catalog_id, 'If Sub Catalog Assigned' as type from pos_tickets pos left join ticket_level_commission tlc on tlc.hotel_id = pos.hotel_id and tlc.deleted = '0' and tlc.ticket_id = pos.mec_id left join qr_codes qc on pos.hotel_id = qc.cod_id and qc.cashier_type = '1' left join template_level_tickets tlt on if(ifnull(qc.sub_catalog_id, 0) > 0, qc.sub_catalog_id, qc.template_id) = if(tlt.template_id = '0', tlt.catalog_id, tlt.template_id) and pos.mec_id = tlt.ticket_id and tlt.deleted = '0' where qc.cod_id = '$cod_id' and qc.cashier_type = '1'
            
            ) as base left join template_level_tickets tlt on tlt.template_id = base.company_template_id and tlt.ticket_id = base.pos_ticket_id and tlt.deleted = '0' left join qr_codes qrc on qrc.template_id = tlt.template_id and qrc.cod_id = base.pos_hotel_id) as base2 where  (if(tlc_ticket_id IS NOT NULL and pos_is_pos_list != tlc_is_pos_list, 1, 0) = 1 or if((tlc_ticket_id IS NULL and tlt_ticket_id IS NOT NULL) and pos_is_pos_list != tlt_is_pos_list, 1, 0) = 1 or if((tlc_ticket_id is NULL and tlt_ticket_id IS  NULL) and pos_is_pos_list != main_template_pos_list, 1, 0) = 1)
        ) 
        
        as base349 left join modeventcontent mec on base349.pos_ticket_id = mec.mec_id where mec.deleted = '0') as nnn) as setdata on poss.hotel_id = setdata.pos_hotel_id and poss.mec_id = setdata.pos_ticket_id and poss.is_pos_list != setdata.should_be set poss.is_pos_list = setdata.should_be; select ROW_COUNT();"

echo "Delete Catalog entried started"
timeout $TIMEOUT_PERIOD mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$Catalog_product_delete" || exit 1
echo "Delete Catalog entried ended"

sleep 1

#step not required as client mentioned not need to add exception for now
# mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$INSERT_QueryTocheckProductNot_exist_in_catalog"

sleep 1

# Client mentioned that they will not provide the exceptions so we need to remove these steps
# mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$Update_QueryTocheckProduct_exist_in_Catalog"

sleep 1

Distribitorcount=$(timeout $TIMEOUT_PERIOD time mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "select count(*) from qr_codes where sub_catalog_id = '$CatalogID' and cashier_type = '1'") || exit 1

echo "***********Total Distributors:   $Distribitorcount--****************"

echo "Fetch Distributor ID started"
cod_ids=$(timeout $TIMEOUT_PERIOD time mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$Linked_Distributors_LIST") || exit 1

for cod_id in ${cod_ids}; do

    echo $cod_id

    echo "data Run for Distributor :---- $cod_id" >> raja3.txt

    #Remove hotel_level_exceptions

    remove_account_level_exceptions="update ticket_level_commission tlcu join (select *, (case when sc_ticket_id is not NULL then CAST(sc_pos_list AS CHAR) when sc_ticket_id is NULL then CAST(default_pos_list AS CHAR) else CAST(tlc_pos_list AS CHAR) end) as shouldbe from (with qr_codess as (select cod_id, template_id, sub_catalog_id from qr_codes where cashier_type = '1' and cod_id = '$cod_id'), Accountlevel as (select qc.*, tlc.ticket_level_commission_id,tlc.hotel_id, tlc.ticket_id as tlc_ticket_id, (tlc.is_pos_list+0-1) as tlc_pos_list from qr_codess qc join ticket_level_commission tlc on qc.cod_id = tlc.hotel_id where tlc.deleted = '0'), subcatalog_level as (select a.*, sc.ticket_id as sc_ticket_id, sc.catalog_id, sc.is_pos_list as sc_pos_list from Accountlevel a left join template_level_tickets sc on a.tlc_ticket_id = sc.ticket_id and sc.catalog_id = a.sub_catalog_id and sc.template_id = '0' and sc.deleted = '0' and sc.catalog_id > '0' and sc.catalog_id is not NULL and a.sub_catalog_id is not NULL), defaultLevel as  (select sl.*, defaults.ticket_id as default_ticket_id, defaults.template_id as default_template_id, defaults.is_pos_list as default_pos_list from subcatalog_level sl left join template_level_tickets defaults on defaults.template_id = sl.template_id and defaults.ticket_id = sl.tlc_ticket_id and defaults.deleted = '0' and defaults.template_id > '0' and defaults.catalog_id = '0') select * from defaultLevel) as base where sc_ticket_id is not NULL or default_ticket_id is not null group by ticket_level_commission_id having shouldbe != tlc_pos_list) as cal on tlcu.ticket_level_commission_id = cal.ticket_level_commission_id set tlcu.is_pos_list = cal.shouldbe"

    echo "Update Exceptions on account Level Started"
    timeout $TIMEOUT_PERIOD time mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$remove_account_level_exceptions" || exit 1

    echo "Update Exceptions on account Level ended"

    sleep 3

    INSERT_MISSING_PRODUCT="insert into pos_tickets (mec_id,cat_id,hotel_id,museum_id,product_type,company,rezgo_ticket_id,rezgo_id,rezgo_key,tourcms_tour_id,tourcms_channel_id,tax_value,service_cost,latest_sold_date,shortDesc,eventImage,ticketwithdifferentpricing,saveamount,ticketPrice,pricetext,ticket_net_price,newPrice,totalticketPrice,new_discount_price,is_reservation,agefrom,ageto,ticketType,is_combi_ticket_allowed,is_booking_combi_ticket_allowed,start_date,end_date,extra_text_field,deleted,is_updated,third_party_id,third_party_ticket_id,third_party_parameters) SELECT
    mec_id,
    cat_id,
    hotel_id,
    museum_id,
    product_type,
    company,
    rezgo_ticket_id,
    rezgo_id,
    rezgo_key,
    tourcms_tour_id,
    tourcms_channel_id,
    tax_value,
    service_cost,
    latest_sold_date,
    shortDesc,
    eventImage,
    ticketwithdifferentpricing,
    saveamount,
    ticketPrice,
    pricetext,
    ticket_net_price,
    newPrice,
    totalticketPrice,
    new_discount_price,
    is_reservation,
    agefrom,
    ageto,
    ticketType,
    is_combi_ticket_allowed,
    is_booking_combi_ticket_allowed,
    start_date,
    end_date,
    extra_text_field,
    deleted,
    is_updated,
    third_party_id,
    third_party_ticket_id,
    third_party_parameters
FROM
    (
    SELECT
        pos.mec_id AS base_id,
        base2.ticket_id AS mec_id,
        base2.cat_id AS cat_id,
        base2.cod_id AS hotel_id,
        base2.supplier_id AS museum_id,
        base2.product_type AS product_type,
        base2.company AS company,
        '0' AS rezgo_ticket_id,
        '0' AS rezgo_id,
        '192168110' AS rezgo_key,
        '0' AS tourcms_tour_id,
        '0' AS tourcms_channel_id,
        base2.tax_value AS tax_value,
        '0' AS service_cost,
        '2021-06-19' AS latest_sold_date,
        base2.shortDesc AS shortDesc,
        base2.eventImage AS eventImage,
        '1' AS ticketwithdifferentpricing,
        base2.saveamount AS saveamount,
        base2.ticketPrice AS ticketPrice,
        base2.pricetext AS pricetext,
        base2.ticket_net_price AS ticket_net_price,
        base2.newPrice AS newPrice,
        base2.totalticketPrice AS totalticketPrice,
        base2.new_discount_price AS new_discount_price,
        base2.is_reservation AS is_reservation,
        base2.agefrom AS agefrom,
        base2.ageto AS ageto,
        base2.ticketType AS ticketType,
        '0' AS is_combi_ticket_allowed,
        '0' AS is_booking_combi_ticket_allowed,
        base2.start_date AS start_date,
        base2.end_date AS end_date,
        '0' AS extra_text_field,
        '0' AS deleted,
        '0' AS is_updated,
        base2.third_party_id AS third_party_id,
        base2.third_party_ticket_id AS third_party_ticket_id,
        base2.third_party_parameters AS third_party_parameters
    FROM
        (
        SELECT
            CURRENT_DATE() AS DATE, DATE(FROM_UNIXTIME(tps.start_date)) AS tps_start_date,
            DATE(
                FROM_UNIXTIME(
                    IF(
                        tps.end_date LIKE '%9999%',
                        '1750343264',
                        tps.end_date
                    )
                )
            ) AS tps_end_time,
            tps.ticket_id AS tps_ticket_id,
            tps.default_listing,
            qc.cod_id,
            qc.template_id AS company_template_id,
            tlt.template_id,
            tlt.ticket_id,
            mec.cat_id,
            mec.sub_cat_id,
            mec.cod_id AS supplier_id,
            (
                CASE WHEN mec.is_combi IN('2', '3') THEN mec.is_combi ELSE 0
            END
            ) AS product_type,
            mec.museum_name AS company,
            qc.country_code AS country_code,
            qc.country AS country,
            tps.ticket_tax_value AS tax_value,
            mec.postingEventTitle AS shortDesc,
            mec.eventImage AS eventImage,
            tps.saveamount AS saveamount,
            tps.pricetext AS ticketPrice,
            tps.pricetext AS pricetext,
            tps.newPrice AS newPrice,
            tps.ticket_net_price AS ticket_net_price,
            tps.newPrice AS totalticketPrice,
            tps.newPrice AS new_discount_price,
            mec.isreservation AS is_reservation,
            tps.agefrom AS agefrom,
            tps.ageto AS ageto,
            tps.ticket_type_label AS ticketType,
            (
                CASE WHEN mec.is_allow_pre_bookings = '1' AND mec.is_reservation = '1' THEN mec.pre_booking_date ELSE mec.startDate
            END
    ) AS start_date,
    mec.endDate AS end_date,
    mec.third_party_id AS third_party_id,
    mec.third_party_ticket_id AS third_party_ticket_id,
    mec.third_party_parameters AS third_party_parameters,
    'getQuery' AS action_performed
FROM
    qr_codes qc
LEFT JOIN template_level_tickets tlt ON
    qc.template_id = tlt.template_id
LEFT JOIN modeventcontent mec ON
    mec.mec_id = tlt.ticket_id
LEFT JOIN ticketpriceschedule tps ON
    tps.ticket_id = mec.mec_id AND tps.default_listing = '1' AND DATE(
        FROM_UNIXTIME(
            IF(
                tps.end_date LIKE '%9999%',
                '1750343264',
                tps.end_date
            )
        )
    ) >= CURRENT_DATE()
WHERE
    qc.cod_id = '$cod_id' AND mec.deleted = '0' AND tlt.deleted = '0' AND qc.cashier_type = '1' AND tlt.template_id != '0' AND DATE(
        FROM_UNIXTIME(
            IF(
                tps.end_date LIKE '%9999%',
                '1750343264',
                tps.end_date
            )
        )
    ) >= CURRENT_DATE()
GROUP BY
    tlt.template_level_tickets_id, qc.cod_id, tps.ticket_id) AS base2
LEFT JOIN pos_tickets pos ON
    base2.cod_id = pos.hotel_id AND base2.ticket_id = pos.mec_id and pos.deleted = '0') AS final_missing_entries_in_pos_tickets
WHERE
    base_id IS NULL;select ROW_COUNT();"

    echo "----------INSERT_MISSING_PRODUCT----------" >>running_queries.sql

    echo "$INSERT_MISSING_PRODUCT" >>running_queries.sql

    echo "Insert Missing Entries in Pos tickets Started"

    timeout $TIMEOUT_PERIOD time mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$INSERT_MISSING_PRODUCT" || exit 1
    echo "Insert Missing Entries in Pos tickets Ended"

    sleep 3

    update_POS_LIST="update pos_tickets poss FORCE INDEX (hotel_id_is_pos_list_deleted) join (select pos_primary_key, pos_hotel_id, pos_ticket_id, should_be from (select *, (case when tlc_is_pos_list is NULL and tlt_is_pos_list is NULL and main_template_pos_list is not NULL then main_template_pos_list when tlc_is_pos_list is NULL and tlt_is_pos_list is NOT NULL then tlt_is_pos_list when tlc_is_pos_list is not NULL then tlc_is_pos_list else pos_is_pos_list end) as should_be from (select base349.*, mec.postingEventTitle as product_title from
        (select * from
        (select base.*, 'Product on Main Catalog' as type2,tlt.ticket_id as main_linked_ticket_id, tlt.template_id as main_template_id, tlt.is_pos_list as main_template_pos_list from (
            select pos.pos_ticket_id as pos_primary_key,pos.hotel_id as pos_hotel_id, tlc.hotel_id as tlc_hotel_id,qc.cod_id as company_hotel_id,qc.template_id as company_template_id, tlt.template_id as template_template_id, pos.is_pos_list as pos_is_pos_list, (tlc.is_pos_list+0-1) as tlc_is_pos_list, tlt.is_pos_list as tlt_is_pos_list, pos.mec_id as pos_ticket_id, tlc.ticket_id as tlc_ticket_id, tlt.ticket_id as tlt_ticket_id,qc.sub_catalog_id as sub_catalog_id, 'If Sub Catalog Assigned' as type from pos_tickets pos left join ticket_level_commission tlc on tlc.hotel_id = pos.hotel_id and tlc.deleted = '0' and tlc.ticket_id = pos.mec_id left join qr_codes qc on pos.hotel_id = qc.cod_id and qc.cashier_type = '1' left join template_level_tickets tlt on if(ifnull(qc.sub_catalog_id, 0) > 0, qc.sub_catalog_id, qc.template_id) = if(tlt.template_id = '0', tlt.catalog_id, tlt.template_id) and pos.mec_id = tlt.ticket_id and tlt.deleted = '0' where qc.cod_id = '$cod_id' and qc.cashier_type = '1'
            ) as base left join template_level_tickets tlt on tlt.template_id = base.company_template_id and tlt.ticket_id = base.pos_ticket_id and tlt.deleted = '0' left join qr_codes qrc on qrc.template_id = tlt.template_id and qrc.cod_id = base.pos_hotel_id) as base2 where  (if(tlc_ticket_id IS NOT NULL and pos_is_pos_list != tlc_is_pos_list, 1, 0) = 1 or if((tlc_ticket_id IS NULL and tlt_ticket_id IS NOT NULL) and pos_is_pos_list != tlt_is_pos_list, 1, 0) = 1 or if((tlc_ticket_id is NULL and tlt_ticket_id IS  NULL) and pos_is_pos_list != main_template_pos_list, 1, 0) = 1)
        )
        as base349 left join modeventcontent mec on base349.pos_ticket_id = mec.mec_id where mec.deleted = '0') as nnn) as basess) as setdata on poss.pos_ticket_id = setdata.pos_primary_key and poss.hotel_id = setdata.pos_hotel_id and poss.mec_id = setdata.pos_ticket_id and poss.deleted = '0' and poss.is_pos_list != setdata.should_be set poss.is_pos_list = setdata.should_be where poss.hotel_id = '$cod_id' and poss.deleted = '0' and poss.is_pos_list != setdata.should_be;select ROW_COUNT();"

    echo "---------Update POS MISMATCH-----------" >>running_queries.sql

    sleep 3
    echo "$update_POS_LIST" >>running_queries.sql

    echo "Update pos list started"

    timeout $TIMEOUT_PERIOD time mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$update_POS_LIST" || exit 1
    echo "Update pos list ended"

    echo "Remove Duplicate Product started"
    querystring1="select post.pos_ticket_id from pos_tickets post join (with pos_data as (select pos_ticket_id, hotel_id, mec_id,company, shortDesc, museum_id, is_pos_list from pos_tickets where hotel_id = '$cod_id' and deleted = '0'), get_template_id as (select ps.*, qc.template_id from pos_data ps left join qr_codes qc on ps.hotel_id = qc.cod_id where qc.cashier_type = '1' and qc.cod_id = '$cod_id'), finaldata as (select gti.*, tlt.template_id as template_template_id, tlt.ticket_id from get_template_id gti left join template_level_tickets tlt on gti.template_id = tlt.template_id and gti.mec_id = tlt.ticket_id and tlt.deleted = '0') select * from finaldata where ticket_id is null) as base111 on post.pos_ticket_id = base111.pos_ticket_id where post.hotel_id = '$cod_id'"

    echo "$querystring1"

    pos_ticket_id=$(timeout $TIMEOUT_PERIOD time mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$querystring1") || exit 1

    echo "Remove Duplicate Product Ended"

    # Convert the vt_group_numbers into an array
    pos_ticket_array=($pos_ticket_id)
    total_pos_ids=${#pos_ticket_array[@]}

    # Print the total count of vt_group_no for the current ticket_id
    echo "Processing Ticket ID: $ticket_id with $total_pos_ids pos_ticket_id values"

    # Initialize the progress tracking for the current ticket_id
    current_progress=0

    # Loop through vt_group_no array in batches
    for ((i = 0; i < $total_pos_ids; i += BATCH_SIZE)); do
        # Create a batch of vt_group_no values
        batch=("${pos_ticket_array[@]:$i:$BATCH_SIZE}")
        batch_size=${#batch[@]}

        # Calculate the current progress level for this ticket_id
        current_progress=$((i + batch_size))

        # Join the batch into a comma-separated list
        batch_str=$(
            IFS=,
            echo "${batch[*]}"
        )

        # Print progress information for the current ticket_id
        echo "Processing batch of size $batch_size for Ticket ID: $cod_id ($current_progress / $total_pos_ids processed)" >>log.txt

        pos_update="update pos_tickets set deleted = '7' where pos_ticket_id in ($batch_str);select ROW_COUNT();"

        echo "$pos_update"

        if [ -z "$pos_ticket_id" ]; then

            echo "No results found. Proceeding with further steps. for ($batch_str)" >>no_mismatch.txt

        else

            echo "------$(date '+%Y-%m-%d %H:%M:%S.%3N')--------" >>found_mismatch.txt
            echo "$batch_str" >>found_mismatch.txt
            echo "Mismatch Out of above" >>found_mismatch.txt
            echo "Query returned results:"

            timeout $TIMEOUT_PERIOD time mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$pos_update"
        fi

        sleep 3
    done

    curl https://cron.prioticket.com/backend/purge_fastly/Custom_purge_fastly_cache/1/0/$cod_id

    sleep 8

done
#------------------- Backup script for live with above same code--------------

#curl https://cron.prioticket.com/backend/Script/insertion_posticket/$hotel_id/ticket_id/1 >> pos_missing_entries.csv
#0 = to print
#1 to update

# curl https://cron.prioticket.com/backend/Script/insertion_posticket/75250/0/0 >> pos_missing_entries.txt
# echo "insertion for $product_id completed"
# sleep 10

# # curl https://cron.prioticket.com/backend/Update_posticket_poslist/update_poslist/$hotel_id/0/1 >> pos_tickets_enable_status.csv
# curl https://cron.prioticket.com/backend/Update_posticket_poslist/update_poslist/0/$product_id/1 >> pos_tickets_enable_status.txt
# echo "updations for $product_id completed"

# Steps To Perform Attraction World Activity

# 1. Remove All product from Catalog first, which we can set deleted directly passing the catalog id

# 2. After that client will provide exception sheet that we will insert it in database and update/insert the records for related sub catalog

# 3. Then for each distributor id we will prepare the queries for the missing entries in the pos_tickets

# 4. After Run the get quries in database we will run the update query for the pos_list mismatch

# All these steps are manual

# Earlier it was planned that queries will be run by rakesh sir but now I will try to run those queries.

# Problem in data:

# 1. Direct and Agent catalog have difference: Gagandeep sir suggested that we will do it for direct but when discussed with client then they mentioned we will start with agent so that still need to finalize

# CREATE TABLE `exceptions` (
#   `catalog_id` bigint NOT NULL,
#   `ticket_id` int NOT NULL,
#   `is_pos_list` int NOT NULL
# ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
# COMMIT;
