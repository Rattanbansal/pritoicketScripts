-- Query to fetch channel_level_commission data on basis of channel_id

with qr_codess as (select reseller_id, channel_id from priopassdb.qr_codes where cashier_type = '1' and channel_id is not NULL group by reseller_id, channel_id), channels as (select d.*, qc.reseller_id as qc_reseller_id, qc.channel_id from rattan.pricelist d join qr_codess qc on d.reseller_id = qc.reseller_id), final as (select c.*, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage, clc.ticket_net_price, clc.hotel_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join priopassdb.channel_level_commission clc on c.channel_id = clc.channel_id and c.ticket_id = clc.ticket_id and clc.deleted = '0' and clc.is_adjust_pricing = '1') select *, ABS(hotel_commission_net_price - hotel_commission_should_be) as gap from final where ABS(hotel_commission_net_price - hotel_commission_should_be) > '0.05' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ticketpriceschedule_id is NULL;

-- Query to fetch channel_level_commission data on basis of catalog_id

with qr_codess as (select reseller_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0' and reseller_id = '1416' group by reseller_id, sub_catalog_id), channelsN as (select d.*, qc.reseller_id as qc_reseller_id, qc.sub_catalog_id from priopassdb.pricelist d left join qr_codess qc on d.reseller_id = qc.reseller_id), channels as (select * from channelsN where qc_reseller_id is not NULL), final as (select tlc.channel_level_commission_id,d.ticket_id as product_id, d.reseller_id as admin_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hgs_prepaid_commission_percentage, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price from channels d left join priopassdb.channel_level_commission tlc on d.sub_catalog_id = tlc.catalog_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') select * from final where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ABS(ticket_net_price-museum_net_commission-merchant_net_commission-hotel_commission_net_price-hgs_commission_net_price) > '0.02' or ABS(ticket_net_price-museum_net_commission-hotel_commission_net_price) > '0.02');


-- Query to fetch channel_level_commission data on basis of distributors-catalog



step 1= Not assigned any subcatalog to distributor

with qr_codess as (select reseller_id,cod_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1'), channels as (select d.*, qc.* from rattan.distributors d left join qr_codess qc on d.hotel_id = qc.cod_id), final as (select c.*, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage, clc.ticket_net_price, clc.hotel_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join priopassdb.channel_level_commission clc on c.sub_catalog_id = clc.catalog_id and c.ticket_id = clc.ticket_id and clc.deleted = '0' and clc.is_adjust_pricing = '1') select distinct hotel_id, cod_id, sub_catalog_id from final where sub_catalog_id is NULL or sub_catalog_id = '0'; 


step 2- where we have the distributor commission gap

with qr_codess as (select reseller_id,cod_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0'), channels as (select d.*, qc.* from rattan.distributors d left join qr_codess qc on d.hotel_id = qc.cod_id group by d.ticket_id, qc.sub_catalog_id), final as (select c.*, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage, clc.ticket_net_price, clc.hotel_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join priopassdb.channel_level_commission clc on c.sub_catalog_id = clc.catalog_id and c.ticket_id = clc.ticket_id and clc.deleted = '0' and clc.is_adjust_pricing = '1') select *, ABS(hotel_commission_net_price - hotel_commission_should_be) as gap from final where ABS(hotel_commission_net_price - hotel_commission_should_be) > '0.05' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ticketpriceschedule_id is NULL;

-- Findout Combi Products

select p.*, ctd.cluster_row_id,ctd.hotel_id as old_cluster_hotel_id, ctd.main_ticket_id as cluster_product_id, ctd.main_ticket_price_schedule_id as cluster_product_id, ctd.cluster_ticket_id as cluster_sub_ticket_id, ctd.ticket_price_schedule_id as cluster_sub_product_type_id, ctd.is_deleted, ctd.list_price, ctd.new_price, ctd.ticket_gross_price, ctd.ticket_net_price from (SELECT qc.reseller_id, qc.cod_id as company_id, qc.company, mec.mec_id, mec.cod_id, mec.museum_name, mec.postingEventTitle, mec.is_combi, mec.deleted, mec.reseller_id as product_reseller_id FROM priopassdb.qr_codes qc left join modeventcontent mec on qc.cod_id = mec.cod_id where qc.cashier_type = '2' and qc.reseller_id = '686' and mec.deleted = '0' and mec.is_combi = '2') as p left join cluster_tickets_detail ctd on p.mec_id = ctd.main_ticket_id where ctd.is_deleted = '0';

update cluster_tickets_detail set list_price = '0.00', new_price = '0.00', ticket_gross_price = '0.00', ticket_net_price = '0.00' where 
cluster_row_id in ()


select * from channel_level_commission where ticket_id in (13682,13685,13793,13796,13799,13802,13805,13829,13832,13838,13844,13847,13850,13865,13868,13880,13883,13886,13892,13901,13904,13907,13910,13916,13922,13928,13931,13949,13952,13955,13958,13961,13982,13985,13988,13991,13994,13997,14003,14006,14012,14015,14021,14024,14027,14030,14033,14036,14039,14042,14045,14048,14051,14054,14057,14060,14063,14171,14369,15014,15035,15041,15047,15089,15092,15098,15113,15218,15224,15230,15236,15239,15365,15368,15566,15569,15590,15599,15605,15620,15635,15638,15641,15650,15653,15659,15707,15713,17675,18164,18470,18558,19107,19677,22578,22584,22591,22618,22621,22622,22624,22625,22634,22636,22886,22902,23051,23140,23158,23494,23499,23504,23506,23512,23513,23515,23523,23539,23540,23541,23542,23543,23544,23545,23546,23550,23551,23553,23555,23560,24857,25085,25087,25088,25094,25095,25096,25097,25098,25099,26683,26687,26688,28584,28586,28588,28590,28678,35383,35385,35387,35692,36300,36312,40338,40352,40354,44260,44704,44710,45698,52565,54475,56241,56949,57036,57039,57379,57384,61342,61384,61637,61742,61743,61744,62148,63163,63185,65952,70893,70902,71740,71742,71743,71869,72091,72121,73023,74762,74965,77959,79659,79967,79970,81206,81699,81707,81709,81715,81721,81726,81775,81782,81787,81830,81832,81859,82820,82988,85998,86194,86198,86202,87582,87583,87585,87587,87589,87594,87622,87628,87658,87659,87660,87686,87688) and is_cluster_ticket_added != '1' and is_adjust_pricing = '1' and deleted = '0'



--- Query to fetch data on basis of hotel_id

select * from (SELECT d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hotel_commission_net_price, tlc.ticket_net_price FROM rattan.distributors d left join priopassdb.ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') as base where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1');

mysql -h 163.47.214.30 --port=3307 -u datalook -p'datalook2024$$' -e "select * from (SELECT d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hotel_commission_net_price, tlc.ticket_net_price FROM rattan.distributors d left join priopassdb.ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') as base where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1') and product_id = '38688' and distributor_id = '44377';" > tlcdata.csv

---- Pricelist data if synched on tlc level then need to check

with qr_codess as (select cod_id, reseller_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1'), distributor as (select p.*, qc.cod_id, qc.sub_catalog_id from rattan.pricelist p join qr_codess qc on p.reseller_id = qc.reseller_id), final as (select d.ticket_id as product_id, d.reseller_id as admin_id, d.commission, d.cod_id, d.sub_catalog_id, tlc.ticket_id, tlc.ticketpriceschedule_id, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hotel_commission_net_price, tlc.ticket_net_price from distributor d left join priopassdb.ticket_level_commission tlc on d.cod_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') select * from final where ticket_id is not NULL



Steps to Handle Commission and Data Updates

1.  Check for Commission Mismatch at Ticket Level
        Validate the provided commission against the ticket_level_commission table based on the following conditions:
            sheet_commission = tlc_commission
            distributor_commission + museum_commission = 100%
        If any mismatch is found, update the commission in the system as per the provided sheet.

2.  Validate and Update Channel Level Commissions
        For all mentioned distributors, retrieve the catalog_id.
        Based on the catalog_id, check for commission mismatches in the channel_level_commission table.
        If discrepancies are found:
            Update all commissions as per the provided percentage.
            Allocate the remaining amount to the museum.
            Set all other levels to 0% commission.

3.  Insert Missing TPS IDs
        Identify any missing TPS IDs for the products.
        Insert the missing entries as per the commission percentages provided in the sheet.

4.  Handle Adjust Pricing and HGS Commission Cases
        Identify records where adjust_pricing = 0 but the sum of hotel_prepaid_commission_percentage + hgs_commission_percentage > 0.
        Discuss these records with Rutger to decide the next steps.

5.  Update Commissions for November Orders
        After completing the above steps, update commissions specifically for November orders.
        Focus on updating the partner_net_price column, as this is a complex process.


gunzip < ticket_level_commission.sql.gz | mysql -u admin -predhat priopassdb


product type mising on catalog_level

with qr_codess as (select reseller_id,cod_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0'), channels as (select d.*, qc.* from priopassdb.distributors d left join qr_codess qc on d.hotel_id = qc.cod_id group by d.ticket_id, qc.sub_catalog_id), catalogs as (select * from channels where sub_catalog_id is not NULL), products as (select c.*, date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) as mec_end_date, tps.id as tps_id, tps.currency_code from catalogs c left join modeventcontent mec on c.ticket_id = mec.mec_id left join ticketpriceschedule tps on mec.mec_id = tps.ticket_id where mec.deleted = '0' and  date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) > CURRENT_DATE and tps.deleted = '0' and date(from_unixtime(if(tps.end_date like '9999999', '1794812755', tps.end_date))) > CURRENT_DATE), final as (select p.*, clc.ticket_id as clcproduct_id, clc.ticketpriceschedule_id, clc.resale_currency_level from products p left join channel_level_commission clc on p.sub_catalog_id = clc.catalog_id and clc.channel_id = '0' and clc.catalog_id > '0' and clc.deleted = '0' and p.ticket_id = clc.ticket_id and p.tps_id = clc.ticketpriceschedule_id and clc.is_adjust_pricing = '1') select * from final where clcproduct_id is NULL;

hotel_not_linked with sb catalog

with qr_codess as (select reseller_id,cod_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0'), channels as (select d.*, qc.* from priopassdb.distributors d left join qr_codess qc on d.hotel_id = qc.cod_id) select * from channels where sub_catalog_id is NULL group by hotel_id;


-- Product not have custom pricing

select * from (SELECT d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission,tlc.ticket_id, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.ticket_net_price, tlc.museum_net_commission, tlc.merchant_net_commission, tlc.hotel_commission_net_price, tlc.hgs_commission_net_price, tlc.hgs_prepaid_commission_percentage, tlc.is_adjust_pricing FROM priopassdb.distributors d left join priopassdb.ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') as base where ticket_id is not NULL and (hotel_prepaid_commission_percentage + hgs_prepaid_commission_percentage > '0.02') and is_adjust_pricing != '1';



----------------Orders Related Process----------------------

select concat(transaction_id,'R') as transaction_id, row_type, transaction_type_name, partner_net_price, hotel_id, ticketId, channel_id, ticketpriceschedule_id from visitor_tickets where transaction_id = '173175217632517003' 



------------Get List of Linked catalogs---------

SELECT qc.cod_id, qc.company, qc.sub_catalog_id, qc.own_supplier_id, c.catalog_name, case when c.catalog_category = '1' then 'Main_catalog' when c.catalog_category = '2' then 'Sub_catalog' else 'No Condition' end as catalog_category, case when c.catalog_type = '1' then 'agent_catalog' when c.catalog_type = '2' then 'direct_catalog' else 'No condition' end as catalog_type FROM qr_codes qc left join catalogs c on qc.sub_catalog_id = c.catalog_id where qc.reseller_id = '541' and qc.cashier_type = '1'

---- In this query we are checking which catalog_linking provided by client and which are exist in our database---

select * from (select main.*, cd.catalog_name as client_provided_catalog_name, cd.distributor_id from (SELECT qc.cod_id, qc.company, qc.sub_catalog_id, qc.own_supplier_id, c.catalog_name, case when c.catalog_category = '1' then 'Main_catalog' when c.catalog_category = '2' then 'Sub_catalog' else 'No Condition' end as catalog_category, case when c.catalog_type = '1' then 'agent_catalog' when c.catalog_type = '2' then 'direct_catalog' else 'No condition' end as catalog_type FROM qr_codes qc left join catalogs c on qc.sub_catalog_id = c.catalog_id where qc.reseller_id = '541' and qc.cashier_type = '1') as main left join catalog_distributors cd on main.cod_id = cd.distributor_id) as raja where distributor_id is NULL; 