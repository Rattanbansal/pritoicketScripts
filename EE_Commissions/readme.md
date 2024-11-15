-- Query to fetch channel_level_commission data on basis of channel_id

with qr_codess as (select reseller_id, channel_id from priopassdb.qr_codes where cashier_type = '1' and channel_id is not NULL group by reseller_id, channel_id), channels as (select d.*, qc.reseller_id as qc_reseller_id, qc.channel_id from rattan.pricelist d left join qr_codess qc on d.reseller_id = qc.reseller_id), final as (select c.*, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage, clc.ticket_net_price, clc.hotel_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join priopassdb.channel_level_commission clc on c.channel_id = clc.channel_id and c.ticket_id = clc.ticket_id and clc.deleted = '0' and clc.is_adjust_pricing = '1') select *, ABS(hotel_commission_net_price - hotel_commission_should_be) as gap from final where ABS(hotel_commission_net_price - hotel_commission_should_be) > '0.05' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ticketpriceschedule_id is NULL;

-- Query to fetch channel_level_commission data on basis of catalog_id

with qr_codess as (select reseller_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0' group by reseller_id, sub_catalog_id), channels as (select d.*, qc.reseller_id as qc_reseller_id, qc.sub_catalog_id from rattan.pricelist d left join qr_codess qc on d.reseller_id = qc.reseller_id), final as (select c.*, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage, clc.ticket_net_price, clc.hotel_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join priopassdb.channel_level_commission clc on c.sub_catalog_id = clc.catalog_id and c.ticket_id = clc.ticket_id, clc.deleted = '0' and clc.is_adjust_pricing = '1') select *, ABS(hotel_commission_net_price - hotel_commission_should_be) as gap from final where ABS(hotel_commission_net_price - hotel_commission_should_be) > '0.05' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ticketpriceschedule_id is NULL;


-- Query to fetch channel_level_commission data on basis of distributors-catalog



step 1= Not assigned any subcatalog to distributor

with qr_codess as (select reseller_id,cod_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1'), channels as (select d.*, qc.* from rattan.distributors d left join qr_codess qc on d.hotel_id = qc.cod_id), final as (select c.*, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage, clc.ticket_net_price, clc.hotel_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join priopassdb.channel_level_commission clc on c.sub_catalog_id = clc.catalog_id and c.ticket_id = clc.ticket_id and clc.deleted = '0' and clc.is_adjust_pricing = '1') select distinct hotel_id, cod_id, sub_catalog_id from final where sub_catalog_id is NULL or sub_catalog_id = '0'; 


step 2- where we have the distributor commission gap

with qr_codess as (select reseller_id,cod_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0'), channels as (select d.*, qc.* from rattan.distributors d left join qr_codess qc on d.hotel_id = qc.cod_id group by d.ticket_id, qc.sub_catalog_id), final as (select c.*, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage, clc.ticket_net_price, clc.hotel_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join priopassdb.channel_level_commission clc on c.sub_catalog_id = clc.catalog_id and c.ticket_id = clc.ticket_id and clc.deleted = '0' and clc.is_adjust_pricing = '1') select *, ABS(hotel_commission_net_price - hotel_commission_should_be) as gap from final where ABS(hotel_commission_net_price - hotel_commission_should_be) > '0.05' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ticketpriceschedule_id is NULL;

-- Findout Combi Products

select p.*, ctd.hotel_id as old_cluster_hotel_id, ctd.main_ticket_id as cluster_product_id, ctd.main_ticket_price_schedule_id as cluster_product_id, ctd.cluster_ticket_id as cluster_sub_ticket_id, ctd.ticket_price_schedule_id as cluster_sub_product_type_id, ctd.is_deleted, ctd.list_price, ctd.new_price, ctd.ticket_gross_price, ctd.ticket_net_price from (SELECT qc.reseller_id, qc.cod_id as company_id, qc.company, mec.mec_id, mec.cod_id, mec.museum_name, mec.postingEventTitle, mec.is_combi, mec.deleted, mec.reseller_id as product_reseller_id FROM priopassdb.qr_codes qc left join modeventcontent mec on qc.cod_id = mec.cod_id where qc.cashier_type = '2' and qc.reseller_id = '686' and mec.deleted = '0' and mec.is_combi = '2') as p left join cluster_tickets_detail ctd on p.mec_id = ctd.main_ticket_id where ctd.is_deleted = '0';



--- Query to fetch data on basis of hotel_id

select * from (SELECT d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hotel_commission_net_price, tlc.ticket_net_price FROM rattan.distributors d left join priopassdb.ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') as base where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1');

mysql -h 163.47.214.30 --port=3307 -u datalook -p'datalook2024$$' -e "select * from (SELECT d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hotel_commission_net_price, tlc.ticket_net_price FROM rattan.distributors d left join priopassdb.ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') as base where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1') and product_id = '38688' and distributor_id = '44377';" > tlcdata.csv

---- Pricelist data if synched on tlc level then need to check

with qr_codess as (select cod_id, reseller_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1'), distributor as (select p.*, qc.cod_id, qc.sub_catalog_id from rattan.pricelist p left join qr_codess qc on p.reseller_id = qc.reseller_id), final as (select d.ticket_id as product_id, d.reseller_id as admin_id, d.commission, d.cod_id, d.sub_catalog_id, tlc.ticket_id, tlc.ticketpriceschedule_id, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hotel_commission_net_price, tlc.ticket_net_price from distributor d left join priopassdb.ticket_level_commission tlc on d.cod_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') select * from final where ticket_id is not NULL



Steps:

1. First of all all account leve setting difference need to check and need to update commission as per sheet

2. after that another challenge that all product setting for the mentioned distributors should be on subcatalog level.

3. if commission percentage mismatch then we need to update commission and rest need to allocate to purchase cost 

4. But there are some records found where commission percentage are ok but rest amount allocated to hgs which should not be the case so we need to correct those records as well.

5. if no entries on the sub catalog level then need to insert the new entries.

6. there are 3 distributors that first need to check if we can link with any one sub catalog that has been assigned to vikash rana

7. once all these things are done then need to update all orders for the month on november.



gunzip < ticket_level_commission.sql.gz | mysql -u admin -predhat priopassdb
