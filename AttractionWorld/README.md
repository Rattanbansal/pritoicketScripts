# pritoicketScripts


- Missing Entries in POS tickets on basis of product id

insert into pos_tickets (mec_id,cat_id,hotel_id,museum_id,product_type,company,rezgo_ticket_id,rezgo_id,rezgo_key,tourcms_tour_id,tourcms_channel_id,tax_value,service_cost,latest_sold_date,shortDesc,eventImage,ticketwithdifferentpricing,saveamount,ticketPrice,pricetext,ticket_net_price,newPrice,totalticketPrice,new_discount_price,is_reservation,agefrom,ageto,ticketType,is_combi_ticket_allowed,is_booking_combi_ticket_allowed,start_date,end_date,extra_text_field,deleted,is_updated,third_party_id,third_party_ticket_id,third_party_parameters)

select mec_id,cat_id,hotel_id,museum_id,product_type,company,rezgo_ticket_id,rezgo_id,'lll' as rezgo_key,tourcms_tour_id,tourcms_channel_id,tax_value, service_cost,latest_sold_date, shortDesc,eventImage,ticketwithdifferentpricing,saveamount,ticketPrice,pricetext,ticket_net_price,newPrice,totalticketPrice,new_discount_price,is_reservation,agefrom,ageto,ticketType,is_combi_ticket_allowed,is_booking_combi_ticket_allowed,start_date,end_date,extra_text_field,deleted,is_updated,third_party_id,third_party_ticket_id,third_party_parameters from(select pos.mec_id as base_id,base2.ticket_id as mec_id,base2.cat_id as cat_id,base2.cod_id as hotel_id,base2.supplier_id as museum_id,base2.product_type as product_type,base2.company as company,'0' as rezgo_ticket_id, '0' as rezgo_id, '0' as rezgo_key,'0' as tourcms_tour_id, '0' as tourcms_channel_id,base2.tax_value as tax_value, '0' as service_cost, '2021-06-19' as latest_sold_date,base2.shortDesc as shortDesc,base2.eventImage as eventImage, '1' as ticketwithdifferentpricing,base2.saveamount as saveamount,base2.ticketPrice as ticketPrice,base2.pricetext as pricetext,base2.ticket_net_price as ticket_net_price,base2.newPrice as newPrice,base2.totalticketPrice as totalticketPrice,base2.new_discount_price as new_discount_price,base2.is_reservation as is_reservation,base2.agefrom as agefrom,base2.ageto as ageto,base2.ticketType as ticketType, '0' as is_combi_ticket_allowed, '0' as is_booking_combi_ticket_allowed,base2.start_date as start_date,base2.end_date as end_date, '0' as extra_text_field, '0' as deleted, '0' as is_updated,base2.third_party_id as third_party_id,base2.third_party_ticket_id as third_party_ticket_id,base2.third_party_parameters as third_party_parameters from (SELECT current_date() as date,date(from_unixtime(tps.start_date)) as tps_start_date, date(from_unixtime(if(tps.end_date like '%9999%', '1750343264', tps.end_date))) as tps_end_time, tps.ticket_id as tps_ticket_id, tps.default_listing,qc.cod_id, qc.template_id as company_template_id, tlt.template_id, tlt.ticket_id, mec.cat_id, mec.sub_cat_id, mec.cod_id as supplier_id, (case when mec.is_combi in ('2','3') then mec.is_combi else 0 end) as product_type, mec.museum_name as company, qc.country_code as country_code, qc.country as country,tps.ticket_tax_value as tax_value,mec.postingEventTitle as shortDesc,mec.eventImage as eventImage, tps.saveamount as saveamount, tps.pricetext as ticketPrice,tps.pricetext as pricetext, tps.newPrice as newPrice, tps.ticket_net_price as  ticket_net_price, tps.newPrice as totalticketPrice, tps.newPrice as new_discount_price, mec.isreservation as is_reservation, tps.agefrom as agefrom, tps.ageto as ageto, tps.ticket_type_label as ticketType,(case when mec.is_allow_pre_bookings ='1' and  mec.is_reservation='1' then mec.pre_booking_date else mec.startDate end) as start_date,mec.endDate as end_date, mec.third_party_id as  third_party_id, mec.third_party_ticket_id as third_party_ticket_id, mec.third_party_parameters as third_party_parameters, 'getQuery' AS action_performed from qr_codes qc left join template_level_tickets tlt on qc.template_id = tlt.template_id left join modeventcontent mec on mec.mec_id = tlt.ticket_id left join ticketpriceschedule tps on tps.ticket_id = mec.mec_id and tps.default_listing = '1' and date(from_unixtime(if(tps.end_date like '%9999%', '1750343264', tps.end_date))) >= current_date()where mec.mec_id = 66767 and mec.deleted = '0' and tlt.deleted = '0' and qc.cashier_type = '1' and tlt.template_id != '0' and tlt.publish_catalog = '1' and date(from_unixtime(if(tps.end_date like '%9999%', '1750343264', tps.end_date))) >= current_date() group by tlt.template_level_tickets_id, qc.cod_id, tps.ticket_id) as base2 left join pos_tickets pos on base2.cod_id = pos.hotel_id and base2.ticket_id = pos.mec_id) as final_missing_entries_in_pos_tickets where base_id is NULL


--------- product Mismatch primary and secondary template for one admin (Reseller)

select * from (select ticketdata.*, mec.mec_id, mec.deleted from (select ticket_id, count(*) as pcs, max(case when template_level_tickets_template_id = '818' then 1 else 0 end) as primary_table, max(case when template_level_tickets_template_id = '1452' then 1 else 0 end) as secondary_table   from (select base2.*, tlt.template_id as template_level_tickets_template_id, tlt.ticket_id, tlt.is_pos_list, tlt.deleted, tlt.publish_catalog, tlt.catalog_id as template_level_catalog_id from (select base1.*, (case when resellers.template_id = base1.template_id then 1 else 2 end) as template_type from (select templates.template_id, templates.reseller_id, templates.is_default, templates.catalog_id from templates right join (select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '686' and cashier_type = '1') group by template_id, catalog_id) as base on base.template_id = templates.template_id where templates.catalog_id is not NULL group by templates.template_id, templates.reseller_id, templates.catalog_id) as base1 left join resellers on base1.reseller_id = resellers.reseller_id) as base2 left join template_level_tickets tlt on base2.template_id = tlt.template_id where tlt.deleted = '0' and tlt.publish_catalog = '1' and tlt.catalog_id = '0') as base group by ticket_id having pcs != 2) as ticketdata left join modeventcontent mec on mec.mec_id = ticketdata.ticket_id) as final where deleted is not NULL and deleted = '0';


----------- pos List Mismatch on basis of Hotel_id


select base349.*, mec.postingEventTitle as product_title from 

        (select * from 
        (select base.*, 'Product on Main Catalog' as type2,tlt.ticket_id as main_linked_ticket_id, tlt.template_id as main_template_id, tlt.is_pos_list as main_template_pos_list from (
            
            select pos.hotel_id as pos_hotel_id, tlc.hotel_id as tlc_hotel_id,qc.cod_id as company_hotel_id,qc.template_id as company_template_id, tlt.template_id as template_template_id, pos.is_pos_list as pos_is_pos_list, (tlc.is_pos_list+0-1) as tlc_is_pos_list, tlt.is_pos_list as tlt_is_pos_list, pos.mec_id as pos_ticket_id, tlc.ticket_id as tlc_ticket_id, tlt.ticket_id as tlt_ticket_id,qc.sub_catalog_id as sub_catalog_id, 'If Sub Catalog Assigned' as type from pos_tickets pos left join ticket_level_commission tlc on tlc.hotel_id = pos.hotel_id and tlc.deleted = '0' and tlc.ticket_id = pos.mec_id left join qr_codes qc on pos.hotel_id = qc.cod_id and qc.cashier_type = '1' left join template_level_tickets tlt on if(ifnull(qc.sub_catalog_id, 0) > 0, qc.sub_catalog_id, qc.template_id) = if(tlt.template_id = '0', tlt.catalog_id, tlt.template_id) and pos.mec_id = tlt.ticket_id and tlt.deleted = '0' where qc.cod_id = '{$hotel_id}' and qc.cashier_type = '1'
            
            ) as base left join template_level_tickets tlt on tlt.template_id = base.company_template_id and tlt.ticket_id = base.pos_ticket_id and tlt.deleted = '0' left join qr_codes qrc on qrc.template_id = tlt.template_id and qrc.cod_id = base.pos_hotel_id) as base2 where  (if(tlc_ticket_id IS NOT NULL and pos_is_pos_list != tlc_is_pos_list, 1, 0) = 1 or if((tlc_ticket_id IS NULL and tlt_ticket_id IS NOT NULL) and pos_is_pos_list != tlt_is_pos_list, 1, 0) = 1 or if((tlc_ticket_id is NULL and tlt_ticket_id IS  NULL) and pos_is_pos_list != main_template_pos_list, 1, 0) = 1)
        ) 
        
        as base349 left join modeventcontent mec on base349.pos_ticket_id = mec.mec_id where mec.deleted = '0'


# Working With Data Analysing

 - Query to check distinct_template in pos_tickets

 SELECT distinct(template_id) FROM `qr_codes` where reseller_id = '686' and cashier_type = '1'



 --- How many catalogs linked with one template in the qr_codes table

 select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '686' and cashier_type = '1') group by template_id, catalog_id; 


 ---- Which teamplates linked with catalog actually that we get from the templates table as per following query

select templates.template_id, templates.reseller_id, templates.is_default, templates.catalog_id, base.* from templates right join (select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '686' and cashier_type = '1') group by template_id, catalog_id) as base on base.template_id = templates.template_id; 

 ----- Query to get Primary and secondary Template

select base1.*, (case when resellers.template_id = base1.template_id then 1 else 2 end) as template_type from (select templates.template_id, templates.reseller_id, templates.is_default, templates.catalog_id from templates right join (select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '686' and cashier_type = '1') group by template_id, catalog_id) as base on base.template_id = templates.template_id where templates.catalog_id is not NULL group by templates.template_id, templates.reseller_id, templates.catalog_id) as base1 left join resellers on base1.reseller_id = resellers.reseller_id; 

 ------ Query to fetch Product linked with Primary and Secondary template of one reseller

select * from (select base2.*, tlt.template_id as template_level_tickets_template_id, tlt.ticket_id, tlt.is_pos_list, tlt.deleted, tlt.publish_catalog, tlt.catalog_id as template_level_catalog_id from (select base1.*, (case when resellers.template_id = base1.template_id then 1 else 2 end) as template_type from (select templates.template_id, templates.reseller_id, templates.is_default, templates.catalog_id from templates right join (select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '686' and cashier_type = '1') group by template_id, catalog_id) as base on base.template_id = templates.template_id where templates.catalog_id is not NULL group by templates.template_id, templates.reseller_id, templates.catalog_id) as base1 left join resellers on base1.reseller_id = resellers.reseller_id) as base2 left join template_level_tickets tlt on base2.template_id = tlt.template_id where tlt.deleted = '0' and tlt.publish_catalog = '1' and tlt.catalog_id = '0') as base


--------- product Mismatch primary and secondary template for one admin

select * from (select ticketdata.*, mec.mec_id, mec.deleted from (select ticket_id, count(*) as pcs, max(case when template_level_tickets_template_id = '818' then 1 else 0 end) as primary_table, max(case when template_level_tickets_template_id = '1452' then 1 else 0 end) as secondary_table   from (select base2.*, tlt.template_id as template_level_tickets_template_id, tlt.ticket_id, tlt.is_pos_list, tlt.deleted, tlt.publish_catalog, tlt.catalog_id as template_level_catalog_id from (select base1.*, (case when resellers.template_id = base1.template_id then 1 else 2 end) as template_type from (select templates.template_id, templates.reseller_id, templates.is_default, templates.catalog_id from templates right join (select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '686' and cashier_type = '1') group by template_id, catalog_id) as base on base.template_id = templates.template_id where templates.catalog_id is not NULL group by templates.template_id, templates.reseller_id, templates.catalog_id) as base1 left join resellers on base1.reseller_id = resellers.reseller_id) as base2 left join template_level_tickets tlt on base2.template_id = tlt.template_id where tlt.deleted = '0' and tlt.publish_catalog = '1' and tlt.catalog_id = '0') as base group by ticket_id having pcs != 2) as ticketdata left join modeventcontent mec on mec.mec_id = ticketdata.ticket_id) as final where deleted is not NULL and deleted = '0';



mysql -h rattan-test-primary-db.ck6w2al7sgpk.eu-west-1.rds.amazonaws.com -u  prt_dbadmin -p'YI7g3zXYLaRLf06HTX2s'



# Query to remove product from catalog and add main template all product into it

--- Query to get agent catalogs 

SELECT * FROM catalogs where catalog_category = '2' and reseller_id = '686' and is_deleted = '0' and catalog_type = '1'; 


--- Query to get direct catalogs 

SELECT * FROM catalogs where catalog_category = '2' and reseller_id = '686' and is_deleted = '0' and catalog_type = '2';


# Select query to delete all product on catalog_level in template_level_tickets

select * from template_level_tickets where catalog_id = '160260192352124' and deleted = '0'

update template_level_tickets set deleted = '8' where catalog_id = '160260192352124' and deleted = '0' and template_id = '0'


# Get all product from the main template and assign it to sub catalog

--- Select Query to get all products

select '0' as template_id, tlt.ticket_id, tlt.is_pos_list, tlt.is_suspended, tlt.created_at, tlt.market_merchant_id, tlt.content_description_setting, CURRENT_TIMESTAMP as last_modified_at, cataloglinked_template.subcatalog_id as catalog_id, tlt.merchant_admin_id, tlt.publish_catalog, tlt.product_verify_status, tlt.deleted from (select templatetype.*, catalogtype.catalog_id as subcatalog_id, catalogtype.catalog_type from (select base1.*, (case when resellers.template_id = base1.template_id then 2 else 1 end) as template_type from (select templates.template_id, templates.reseller_id, templates.is_default, templates.catalog_id from templates right join (select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '686' and cashier_type = '1') group by template_id, catalog_id) as base on base.template_id = templates.template_id where templates.catalog_id is not NULL group by templates.template_id, templates.reseller_id, templates.catalog_id) as base1 left join resellers on base1.reseller_id = resellers.reseller_id) as templatetype left join (SELECT catalog_id, reseller_id, catalog_type FROM catalogs where catalog_category = '2' and reseller_id = '686' and is_deleted = '0' and catalog_id = '160260192352124') as catalogtype on templatetype.reseller_id = catalogtype.reseller_id and templatetype.template_type = catalogtype.catalog_type) as cataloglinked_template left join template_level_tickets tlt on cataloglinked_template.template_id = tlt.template_id where cataloglinked_template.catalog_type is not NULL and tlt.deleted = '0' and tlt.publish_catalog = '1' and tlt.catalog_id = '0';


---- Insert Query

insert into template_level_tickets (template_id, ticket_id, is_pos_list, is_suspended, created_at, market_merchant_id, content_description_setting, last_modified_at, catalog_id, merchant_admin_id, publish_catalog, product_verify_status, deleted)  select '0' as template_id, tlt.ticket_id, tlt.is_pos_list, tlt.is_suspended, tlt.created_at, tlt.market_merchant_id, tlt.content_description_setting, CURRENT_TIMESTAMP as last_modified_at, cataloglinked_template.subcatalog_id as catalog_id, tlt.merchant_admin_id, tlt.publish_catalog, tlt.product_verify_status, tlt.deleted from (select templatetype.*, catalogtype.catalog_id as subcatalog_id, catalogtype.catalog_type from (select base1.*, (case when resellers.template_id = base1.template_id then 2 else 1 end) as template_type from (select templates.template_id, templates.reseller_id, templates.is_default, templates.catalog_id from templates right join (select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '686' and cashier_type = '1') group by template_id, catalog_id) as base on base.template_id = templates.template_id where templates.catalog_id is not NULL group by templates.template_id, templates.reseller_id, templates.catalog_id) as base1 left join resellers on base1.reseller_id = resellers.reseller_id) as templatetype left join (SELECT catalog_id, reseller_id, catalog_type FROM catalogs where catalog_category = '2' and reseller_id = '686' and is_deleted = '0' and catalog_id = '160260192352124') as catalogtype on templatetype.reseller_id = catalogtype.reseller_id and templatetype.template_type = catalogtype.catalog_type) as cataloglinked_template left join template_level_tickets tlt on cataloglinked_template.template_id = tlt.template_id where cataloglinked_template.catalog_type is not NULL and tlt.deleted = '0' and tlt.publish_catalog = '1' and tlt.catalog_id = '0';






Check entries on tlc level

select * from ticket_level_commission where hotel_id in (select DISTINCT cod_id from qr_codes where cashier_type = '1' and reseller_id = '686'); 

mysql -h 10.10.10.19 -u pip -p'pip2024##' priopassdb -e "with distributors as (SELECT cod_id FROM qr_codes where reseller_id = '686' and cashier_type = '1') select d.*, tlc.* from distributors d left join ticket_level_commission tlc on d.cod_id = tlc.hotel_id and tlc.deleted = '0';" > tlcdata.csv




=== Query to get mismatch with tlc vs subcatalog and primary so that we can update tlc

select *, (case when sc_ticket_id is not NULL then sc_pos_list when sc_ticket_id is NULL then default_pos_list else tlc_pos_list end) as shouldbe from (with qr_codess as (select cod_id, template_id, sub_catalog_id from qr_codes where cashier_type = '1' and cod_id = '7121'), Accountlevel as (select qc.*, tlc.ticket_level_commission_id,tlc.hotel_id, tlc.ticket_id as tlc_ticket_id, (tlc.is_pos_list+0-1) as tlc_pos_list from qr_codess qc join ticket_level_commission tlc on qc.cod_id = tlc.hotel_id where tlc.deleted = '0'), subcatalog_level as (select a.*, sc.ticket_id as sc_ticket_id, sc.catalog_id, sc.is_pos_list as sc_pos_list from Accountlevel a left join template_level_tickets sc on a.tlc_ticket_id = sc.ticket_id and sc.catalog_id = a.sub_catalog_id and sc.template_id = '0' and sc.deleted = '0' and sc.catalog_id > '0' and sc.catalog_id is not NULL and a.sub_catalog_id is not NULL), defaultLevel as  (select sl.*, defaults.ticket_id as default_ticket_id, defaults.template_id as default_template_id, defaults.is_pos_list as default_pos_list from subcatalog_level sl left join template_level_tickets defaults on defaults.template_id = sl.template_id and defaults.ticket_id = sl.tlc_ticket_id and defaults.deleted = '0' and defaults.template_id > '0' and defaults.catalog_id = '0') select * from defaultLevel) as base where sc_ticket_id is not NULL or default_ticket_id is not null group by ticket_level_commission_id having shouldbe != tlc_pos_list limit 800


update ticket_level_commission tlcu join (select *, (case when sc_ticket_id is not NULL then CAST(sc_pos_list AS CHAR) when sc_ticket_id is NULL then CAST(default_pos_list AS CHAR) else CAST(tlc_pos_list AS CHAR) end) as shouldbe from (with qr_codess as (select cod_id, template_id, sub_catalog_id from qr_codes where cashier_type = '1' and cod_id = '7121'), Accountlevel as (select qc.*, tlc.ticket_level_commission_id,tlc.hotel_id, tlc.ticket_id as tlc_ticket_id, (tlc.is_pos_list+0-1) as tlc_pos_list from qr_codess qc join ticket_level_commission tlc on qc.cod_id = tlc.hotel_id where tlc.deleted = '0'), subcatalog_level as (select a.*, sc.ticket_id as sc_ticket_id, sc.catalog_id, sc.is_pos_list as sc_pos_list from Accountlevel a left join template_level_tickets sc on a.tlc_ticket_id = sc.ticket_id and sc.catalog_id = a.sub_catalog_id and sc.template_id = '0' and sc.deleted = '0' and sc.catalog_id > '0' and sc.catalog_id is not NULL and a.sub_catalog_id is not NULL), defaultLevel as  (select sl.*, defaults.ticket_id as default_ticket_id, defaults.template_id as default_template_id, defaults.is_pos_list as default_pos_list from subcatalog_level sl left join template_level_tickets defaults on defaults.template_id = sl.template_id and defaults.ticket_id = sl.tlc_ticket_id and defaults.deleted = '0' and defaults.template_id > '0' and defaults.catalog_id = '0') select * from defaultLevel) as base where sc_ticket_id is not NULL or default_ticket_id is not null group by ticket_level_commission_id having shouldbe != tlc_pos_list) as cal on tlcu.ticket_level_commission_id = cal.ticket_level_commission_id set tlcu.is_pos_list = cal.shouldbe



select * from pos_tickets post join (with pos_data as (select pos_ticket_id, hotel_id, mec_id,company, shortDesc, museum_id, is_pos_list from pos_tickets where hotel_id = '47726' and deleted = '0'), get_template_id as (select ps.*, qc.template_id from pos_data ps left join qr_codes qc on ps.hotel_id = qc.cod_id where qc.cashier_type = '1'), finaldata as (select gti.*, tlt.template_id as template_template_id, tlt.ticket_id from get_template_id gti left join template_level_tickets tlt on gti.template_id = tlt.template_id and gti.mec_id = tlt.ticket_id) select * from finaldata where ticket_id is null) as base111 on post.pos_ticket_id = base111.pos_ticket_id where post.hotel_id = '47726';

---- get tlt product which are active

SELECT template_level_tickets.ticket_id, template_level_tickets.is_pos_list FROM `template_level_tickets` join modeventcontent mec on template_level_tickets.ticket_id = mec.mec_id left join ticketpriceschedule tps on tps.ticket_id = mec.mec_id  WHERE template_level_tickets.template_id = '1452' and template_level_tickets.deleted = '0' and template_level_tickets.publish_catalog = '1' and mec.deleted = '0' and tps.deleted = '0' and mec.deleted = '0' and date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) > CURRENT_DATE and tps.deleted = '0' and date(from_unixtime(if(tps.end_date like '9999999', '1794812755', tps.end_date))) > CURRENT_DATE group by template_level_tickets.ticket_id, template_level_tickets.is_pos_list