select vt_group_no, ticketId, ticketpriceschedule_id, channel_id, hotel_id from visitor_tickets where vt_group_no in ($batch_str) and col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%' group by vt_group_no, ticketId, ticketpriceschedule_id, channel_id, hotel_id

---tlc data fetch

SELECT tlc.* FROM priopassdb.evanorders o join priopassdb.ticket_level_commission tlc on o.hotel_id = tlc.hotel_id and o.ticketId = tlc.ticket_id and o.ticketpriceschedule_id = tlc.ticketpriceschedule_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1' group by tlc.ticket_level_commission_id; 

--- subcatalog_data fect---
select clc.* from (SELECT o.*, qc.sub_catalog_id FROM priopassdb.evanorders o join priopassdb.qr_codes qc on o.hotel_id = qc.cod_id where qc.sub_catalog_id > '0' and qc.sub_catalog_id is not NULL) as base join priopassdb.channel_level_commission clc on base.sub_catalog_id = clc.catalog_id and base.ticketId = clc.ticket_id and base.ticketpriceschedule_id = clc.ticketpriceschedule_id and clc.deleted = '0' and clc.is_adjust_pricing = '1' group by clc.channel_level_commission_id


--- main catalog data fetch
SELECT channel_level_commission.* FROM priopassdb.evanorders o join priopassdb.channel_level_commission channel_level_commission on o.channel_id = channel_level_commission.channel_id and o.ticketId = channel_level_commission.ticket_id and o.ticketpriceschedule_id = channel_level_commission.ticketpriceschedule_id and channel_level_commission.deleted = '0' and channel_level_commission.is_adjust_pricing = '1' group by channel_level_commission.channel_level_commission_id

--- qr codes data


select * from qr_codes where cod_id in (select DISTINCT hotel_id from evanorders) and cashier_type = '1' 


---- no seeting found check from pricing table in rattan database on 19

tlc 
 
SELECT p.*,tlc.ticket_level_commission_id FROM `pricing` p left join priopassdb.ticket_level_commission tlc on tlc.hotel_id = p.hotel_id and p.ticket_id = tlc.ticket_id and p.tps_id = tlc.ticketpriceschedule_id and tlc.deleted ='0' and tlc.is_adjust_pricing ='1';
 
 
 
 
CLC
 
SELECT p.*,clc.channel_level_commission_id from `pricing` p left join priopassdb.channel_level_commission clc on clc.channel_id = p.channel_id and clc.ticket_id = p.ticket_id and  clc.ticketpriceschedule_id = p.tps_id and clc.deleted ='0' and clc.is_adjust_pricing ='1';

---------no seeting found check from pricing table in rattan database on 19 ended---------
 


Now we have multiple orders some which we not corrected on catalog level So we need to correct only the related product which we corrected


--- check which orders are missing in evanorders

select * from (SELECT m.*, e.* FROM matrix m left join evanorders e on m.visitor_group_no = e.vt_group_no) as base where vt_group_no is NULL; 


--- Records which are related to distributors

update matrix m join (SELECT e.vt_group_no FROM evanorders e join distributors d on e.hotel_id = d.hotel_id and e.ticketId = d.ticket_id) as base on m.visitor_group_no = base.vt_group_no set deleted = '2'


--- Records which are related to pricelist table

select * from (with qr_codess as (select channel_id, reseller_id, reseller_name from priopassdb.qr_codes where cashier_type = '1' and channel_id > '0' group by channel_id, reseller_id) SELECT e.*, qc.channel_id as pricelist_id, qc.reseller_id, qc.reseller_name FROM rattan.evanorders e join qr_codess qc on e.channel_id = qc.channel_id) as final where reseller_name like '%Evan%';  

update matrixReseller m join (select * from (with qr_codess as (select channel_id, reseller_id, reseller_name from priopassdb.qr_codes where cashier_type = '1' and channel_id > '0' group by channel_id, reseller_id) SELECT e.*, qc.channel_id as pricelist_id, qc.reseller_id, qc.reseller_name FROM rattan.evanorders e join qr_codess qc on e.channel_id = qc.channel_id) as final where reseller_name like '%Evan%') as tp on tp.vt_group_no = m.visitor_group_no set status = '2'; 



-- query to fetch commission on basis of latest version

select * from (select vt.vt_group_no,vt.row_type, vt.version, vt.ticketId, vt.ticketpriceschedule_id, vt.partner_net_price from visitor_tickets vt join (select vt_group_no,row_type, max(version) as version, ticketId, ticketpriceschedule_id from visitor_tickets where row_type = '3' and vt_group_no in (173265893518877) and transaction_type_name not like '%Extra%' and ticket_title not like '%Discount%' and transaction_type_name not like '%Reprice%' group by vt_group_no, ticketId, ticketpriceschedule_id) as base on vt.vt_group_no = base.vt_group_no and vt.ticketId = base.ticketId and vt.ticketpriceschedule_id = base.ticketpriceschedule_id and ABS(vt.version-base.version) = '0' and vt.row_type = base.row_type where vt.vt_group_no in (173265893518877)) as base group by vt_group_no,row_type,version, ticketId,ticketpriceschedule_id,partner_net_price


--- remove duplicate
update channel_level_commission clc join (SELECT max(channel_level_commission_id) as channel_level_commission_id,channel_id, catalog_id, ticket_id, ticketpriceschedule_id, resale_currency_level, count(*) FROM `channel_level_commission` where deleted = '0' group by channel_id, catalog_id, ticket_id, ticketpriceschedule_id, resale_currency_level having count(*) > '1') as base on clc.channel_id = base.channel_id and clc.catalog_id = base.catalog_id and clc.ticket_id = base.ticket_id and clc.ticketpriceschedule_id = base.ticketpriceschedule_id and clc.resale_currency_level = base.resale_currency_level and clc.channel_level_commission_id != base.channel_level_commission_id set clc.deleted = '1'

update ticket_level_commission clc join (SELECT max(ticket_level_commission_id) as ticket_level_commission_id,hotel_id, ticket_id, ticketpriceschedule_id, resale_currency_level, count(*) FROM `ticket_level_commission` where deleted = '0' group by hotel_id, ticket_id, ticketpriceschedule_id, resale_currency_level having count(*) > '1') as base on clc.hotel_id = base.hotel_id and clc.ticket_id = base.ticket_id and clc.ticketpriceschedule_id = base.ticketpriceschedule_id and clc.resale_currency_level = base.resale_currency_level and clc.ticket_level_commission_id != base.ticket_level_commission_id set clc.deleted = '1'

select channel_level_commission_id, count(*) as pcs from channel_level_commission where deleted = '0' group by channel_level_commission_id having pcs > '1';
select ticket_level_commission_id, count(*) as pcs from ticket_level_commission where deleted = '0' group by ticket_level_commission_id having pcs > '1';


<!-- Select query to check commission -->

SELECT * FROM `channel_level_commission` where catalog_id in (select sub_catalog_id from qr_codes where cod_id = '44587' and sub_catalog_id > '0') and ticketpriceschedule_id = '411331' and deleted = '0' and is_adjust_pricing = '1' 
SELECT * FROM `channel_level_commission` where channel_id in (select channel_id from qr_codes where cod_id = '44587') and ticketpriceschedule_id = '411331' and deleted = '0' and is_adjust_pricing = '1' 
select * from ticket_level_commission where ticketpriceschedule_id = '411331' and hotel_id = '44587' 