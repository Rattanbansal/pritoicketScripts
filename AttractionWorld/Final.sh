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
CatalogID='160277412652619'
ResellerId='686'
BATCH_SIZE=150

echo "data Run for Catalog_id :---- $CatalogID" >> raja.txt

Catalog_product_delete="update template_level_tickets set deleted = '8' where catalog_id = '$CatalogID' and deleted = '0' and template_id = '0'"

Linked_Distributors_LIST="select distinct(cod_id) as cod_id from qr_codes where sub_catalog_id = '$CatalogID' and cod_id not in (12368,12404,12606,12639,12640,12641,12642,12643,12644,12645,12646,12647,12648,12659,12666,12756,12757,12758,12759,12760,12761,12762,12763,12764,12765,12766,12767,12768,12769,12770,12771,12772,12773,12774,12775,12776,12777,12778,12779,12780,12781,12782,12783,12784,12785,12786,12787,12788,12789,12790,12791,12792,12793,12794,12795,12796,12797,12798,12799,12800,12801,12802,12803,12804,12805,12806,12807,12808,12809,12810,12811,12812,12813,12814,12815,12816,12817,12818,12819,12820,12821,12822,12823,12824,12825,12826,12827,12828,12829,12830,12831,12832,12833,12834,12835,12836,12837,12838,12839,12840,12841,12842,12843,12844,12845,12846,12847,12848,12849,12850,12851,12852,12853,12854,12855,12856,12857,12858,12859,12860,12861,12862,12863,12864,12865,12866,12867,12868,12869,12870,12871,12872,12873,12874,12875,12876,12877,12878,12879,12880,12881,12882,12883,12884,12885,12886,12887,12888,12889,12890,12891,12892,12893,12894,12895,12896,12897,12898,12899,12900,12901,12902,12903,12904,12905,12906,12907,12908,12909,12910,12911,12912,12913,12914,12915,12916,13660,13856,13857,13858,13859,13860,13861,13862,13884,13885,13886,13887,13888,13889,13890,13891,13892,13893,13894,13895,13896,13897,13949,13950,13951,13952,13953,13954,13955,13956,13957,13958,13959,13960,13961,13962,13964,13965,13966,13967,13968,13969,13970,13971,13972,13973,13974,13975,13976,13977,13978,13979,13980,13981,13982,13983,13984,13986,13987,13988,13989,13990,13991,13992,13993,13994,13995,13996,13997,13998,13999,14000,14001,14002,14003,14004,14005,14006,14007,14008,14009,14010,14011,14012,14013,14014,14015,14016,14017,14018,14019,14020,14021,14022,14023,14024,14025,14026,14027,14029,14030,14031,14032,14033,14034,14035,14036,14037,14038,14039,14040,14041,14042,14043,14044,14045,14046,14047,14048,14049,14050,14051,14052,14053,14054,14055,14056,14057,14058,14059,14060,14061,14062,14063,14064,14065,14066,14067,14068,14069,14070,14071,14072,14073,14074,14075,14076,14077,14078,14079,14080,14081,14082,14083,14084,14085,14086,14087,14088,14089,14090,14091,14093,14094,14095,14096,14097,14098,14099,14100,14101,14102,14103,14104,14105,14106,14107,14108,14109,14110,14111,14112,14113,14114,14115,14116,14117,14118,14119,14120,35782,35784,35786,35788,35790,35792,35794,36198,36200,36202,36204,36206,36208,36210,36212,36214,36216,36218,36220,36222,36224,36226,36228,36230,36232,36234,36236,36238,36240,36242,36244,36246,36248,36250,36252,36254,36256,36258,36260,36262,36264,36266,36268,36270,36272,36274,36276,36278,36280,36282,36284,36286,36288,36290,36292,36294,36296,36298,36300,36302,36304,36306,36308,36310,36312,36314,36316,36318,36320,36322,36324,36326,36328,36330,36332,36334,36336,36338,36340,36342,36344,36346,36348,36350,36352,36354,36356,36358,36360,36362,36364,36366,36368,36370,36372,36374,36376,36378,36380,36382,36384,36386,36388,36390,36392,36394,36396,36398,36400,36402,36404,36406,36408,36410,36412,36414,36416,36418,36420,36422,36424,36426,36428,36430,36432,36434,36436,36438,36440,36442,36444,36446,36448,36450,36452,36454,36456,36458,36460,36462,36464,36466,36468,36470,36472,36474,36476,36478,36480,36482,36484,36486,36488,36490,36492,36494,36496,36496,36498,36500,36502,36504,36506,36508,36510,36512,36514,36516,36518,36520,36522,36524,36526,36528,36530,36532,36534,36536,36538,36540,36542,36544,36546,36548,36550,36552,36554,36556,36558,36560,36562,36564,36566,36568,36570,36572,36574,36576,36578,36580,36582,36584,36586,36588,36590,36592,36594,36596,36598,36600,36602,36604,36606,36608,36610,36612,36614,36616,36618,36620,36622,36624,36626,36628,36630,36632,36634,36636,36638,36640,36642,36644,36646,36648,36650,36652,36654,36656,36658,36660,36662,36664,36666,36668,36670,36672,36674,36676,36678,36680,36682,36684,36686,36688,36690,36692,36694,36696,36698,36700,36702,36704,36706,36708,36710,36712,36714,36716,36718,36720,36722,36724,36726,36728,36730,36732,36734,36736,36738,36740,36742,36744,36746,36748,36750,36752,36754,36756,36758,36760,36762,36764,36766,36768,36770,36772,36774,36776,36778,36780,36782,36784,36786,36788,36790,36792,36794,36796,36798,36800,36802,36804,36806,36808,36810,36812,36814,36816,36818,36820,36822,36824,36826,36828,36830,36832,36834,36836,36838,36840,36842,36844,36846,36848,36850,36852,36854,36856,36858,36860,36862,36864,36866,36868,36870,36872,36874,36876,36878,36880,36882,36884,36886,36888,36890,36892,36894,36896,36898,36900,36902,36904,36908,36910,36912,36914,36916,36918,36920,36922,36924,36926) and cashier_type = '1'"

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

    echo "data Run for Distributor :---- $cod_id" >> raja.txt

    #Remove hotel_level_exceptions

    remove_account_level_exceptions="update ticket_level_commission tlcu join (select *, (case when sc_ticket_id is not NULL then CAST(sc_pos_list AS CHAR) when sc_ticket_id is NULL then CAST(default_pos_list AS CHAR) else CAST(tlc_pos_list AS CHAR) end) as shouldbe from (with qr_codess as (select cod_id, template_id, sub_catalog_id from qr_codes where cashier_type = '1' and cod_id = '$cod_id'), Accountlevel as (select qc.*, tlc.ticket_level_commission_id,tlc.hotel_id, tlc.ticket_id as tlc_ticket_id, (tlc.is_pos_list+0-1) as tlc_pos_list from qr_codess qc join ticket_level_commission tlc on qc.cod_id = tlc.hotel_id where tlc.deleted = '0'), subcatalog_level as (select a.*, sc.ticket_id as sc_ticket_id, sc.catalog_id, sc.is_pos_list as sc_pos_list from Accountlevel a left join template_level_tickets sc on a.tlc_ticket_id = sc.ticket_id and sc.catalog_id = a.sub_catalog_id and sc.template_id = '0' and sc.deleted = '0' and sc.catalog_id > '0' and sc.catalog_id is not NULL and a.sub_catalog_id is not NULL), defaultLevel as  (select sl.*, defaults.ticket_id as default_ticket_id, defaults.template_id as default_template_id, defaults.is_pos_list as default_pos_list from subcatalog_level sl left join template_level_tickets defaults on defaults.template_id = sl.template_id and defaults.ticket_id = sl.tlc_ticket_id and defaults.deleted = '0' and defaults.template_id > '0' and defaults.catalog_id = '0') select * from defaultLevel) as base where sc_ticket_id is not NULL or default_ticket_id is not null group by ticket_level_commission_id having shouldbe != tlc_pos_list) as cal on tlcu.ticket_level_commission_id = cal.ticket_level_commission_id set tlcu.is_pos_list = cal.shouldbe"

    echo "Update Exceptions on account Level Started"
    timeout $TIMEOUT_PERIOD time mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$remove_account_level_exceptions" || exit 1

    echo "Update Exceptions on account Level ended"

    sleep 2

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

    sleep 2

    update_POS_LIST="update pos_tickets poss FORCE INDEX (hotel_id_is_pos_list_deleted) join (select pos_primary_key, pos_hotel_id, pos_ticket_id, should_be from (select *, (case when tlc_is_pos_list is NULL and tlt_is_pos_list is NULL and main_template_pos_list is not NULL then main_template_pos_list when tlc_is_pos_list is NULL and tlt_is_pos_list is NOT NULL then tlt_is_pos_list when tlc_is_pos_list is not NULL then tlc_is_pos_list else pos_is_pos_list end) as should_be from (select base349.*, mec.postingEventTitle as product_title from
        (select * from
        (select base.*, 'Product on Main Catalog' as type2,tlt.ticket_id as main_linked_ticket_id, tlt.template_id as main_template_id, tlt.is_pos_list as main_template_pos_list from (
            select pos.pos_ticket_id as pos_primary_key,pos.hotel_id as pos_hotel_id, tlc.hotel_id as tlc_hotel_id,qc.cod_id as company_hotel_id,qc.template_id as company_template_id, tlt.template_id as template_template_id, pos.is_pos_list as pos_is_pos_list, (tlc.is_pos_list+0-1) as tlc_is_pos_list, tlt.is_pos_list as tlt_is_pos_list, pos.mec_id as pos_ticket_id, tlc.ticket_id as tlc_ticket_id, tlt.ticket_id as tlt_ticket_id,qc.sub_catalog_id as sub_catalog_id, 'If Sub Catalog Assigned' as type from pos_tickets pos left join ticket_level_commission tlc on tlc.hotel_id = pos.hotel_id and tlc.deleted = '0' and tlc.ticket_id = pos.mec_id left join qr_codes qc on pos.hotel_id = qc.cod_id and qc.cashier_type = '1' left join template_level_tickets tlt on if(ifnull(qc.sub_catalog_id, 0) > 0, qc.sub_catalog_id, qc.template_id) = if(tlt.template_id = '0', tlt.catalog_id, tlt.template_id) and pos.mec_id = tlt.ticket_id and tlt.deleted = '0' where qc.cod_id = '$cod_id' and qc.cashier_type = '1'
            ) as base left join template_level_tickets tlt on tlt.template_id = base.company_template_id and tlt.ticket_id = base.pos_ticket_id and tlt.deleted = '0' left join qr_codes qrc on qrc.template_id = tlt.template_id and qrc.cod_id = base.pos_hotel_id) as base2 where  (if(tlc_ticket_id IS NOT NULL and pos_is_pos_list != tlc_is_pos_list, 1, 0) = 1 or if((tlc_ticket_id IS NULL and tlt_ticket_id IS NOT NULL) and pos_is_pos_list != tlt_is_pos_list, 1, 0) = 1 or if((tlc_ticket_id is NULL and tlt_ticket_id IS  NULL) and pos_is_pos_list != main_template_pos_list, 1, 0) = 1)
        )
        as base349 left join modeventcontent mec on base349.pos_ticket_id = mec.mec_id where mec.deleted = '0') as nnn) as basess) as setdata on poss.pos_ticket_id = setdata.pos_primary_key and poss.hotel_id = setdata.pos_hotel_id and poss.mec_id = setdata.pos_ticket_id and poss.deleted = '0' and poss.is_pos_list != setdata.should_be set poss.is_pos_list = setdata.should_be where poss.hotel_id = '$cod_id' and poss.deleted = '0' and poss.is_pos_list != setdata.should_be;select ROW_COUNT();"

    echo "---------Update POS MISMATCH-----------" >>running_queries.sql

    sleep 2
    echo "$update_POS_LIST" >>running_queries.sql

    echo "Update pos list started"

    timeout $TIMEOUT_PERIOD time mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$update_POS_LIST" || exit 1
    echo "Update pos list ended"

    echo "Remove Duplicate Product started"
    querystring1="select post.pos_ticket_id from pos_tickets post join (with pos_data as (select pos_ticket_id, hotel_id, mec_id,company, shortDesc, museum_id, is_pos_list from pos_tickets where hotel_id = '$cod_id' and deleted = '0'), get_template_id as (select ps.*, qc.template_id from pos_data ps left join qr_codes qc on ps.hotel_id = qc.cod_id where qc.cashier_type = '1'), finaldata as (select gti.*, tlt.template_id as template_template_id, tlt.ticket_id from get_template_id gti left join template_level_tickets tlt on gti.template_id = tlt.template_id and gti.mec_id = tlt.ticket_id and tlt.deleted = '0') select * from finaldata where ticket_id is null) as base111 on post.pos_ticket_id = base111.pos_ticket_id where post.hotel_id = '$cod_id'"

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

        sleep 2
    done

    curl https://cron.prioticket.com/backend/purge_fastly/Custom_purge_fastly_cache/1/0/$cod_id

    sleep 5

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
