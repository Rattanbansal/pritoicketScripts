select vt_group_no, ticketId, ticketpriceschedule_id, channel_id, hotel_id from visitor_tickets where vt_group_no in ($batch_str) and col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%' group by vt_group_no, ticketId, ticketpriceschedule_id, channel_id, hotel_id

---tlc data fetch

SELECT tlc.* FROM priopassdb.evanorders o join priopassdb.ticket_level_commission tlc on o.hotel_id = tlc.hotel_id and o.ticketId = tlc.ticket_id and o.ticketpriceschedule_id = tlc.ticketpriceschedule_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1'; 

--- subcatalog_data fect---
select clc.* from (SELECT o.*, qc.sub_catalog_id FROM priopassdb.evanorders o join priopassdb.qr_codes qc on o.hotel_id = qc.cod_id where qc.sub_catalog_id > '0' and qc.sub_catalog_id is not NULL) as base join priopassdb.channel_level_commission clc on base.sub_catalog_id = clc.catalog_id and base.ticketId = clc.ticket_id and base.ticketpriceschedule_id = clc.ticketpriceschedule_id and clc.deleted = '0' and clc.is_adjust_pricing = '1' group by clc.channel_level_commission_id


--- main catalog data fetch
SELECT channel_level_commission.* FROM priopassdb.evanorders o join priopassdb.channel_level_commission channel_level_commission on o.channel_id = channel_level_commission.channel_id and o.ticketId = channel_level_commission.ticket_id and o.ticketpriceschedule_id = channel_level_commission.ticketpriceschedule_id and channel_level_commission.deleted = '0' and channel_level_commission.is_adjust_pricing = '1' group by channel_level_commission.channel_level_commission_id



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