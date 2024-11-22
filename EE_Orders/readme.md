select vt_group_no, ticketId, ticketpriceschedule_id, channel_id, hotel_id from visitor_tickets where vt_group_no in ($batch_str) and col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%' group by vt_group_no, ticketId, ticketpriceschedule_id, channel_id, hotel_id

---tlc data fetch

SELECT o.vt_group_no, tlc.* FROM rattan.evanorders o join priopassdb.ticket_level_commission tlc on o.hotel_id = tlc.hotel_id and o.ticketId = tlc.ticket_id and o.ticketpriceschedule_id = tlc.ticketpriceschedule_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1'; 

--- subcatalog_data fect---
select * from (select base.vt_group_no, base.ticketId, base.sub_catalog_id, base.ticketpriceschedule_id as id,clc.* from (SELECT o.*, qc.sub_catalog_id FROM rattan.evanorders o join priopassdb.qr_codes qc on o.hotel_id = qc.cod_id where qc.sub_catalog_id > '0' and qc.sub_catalog_id is not NULL) as base left join priopassdb.channel_level_commission clc on base.sub_catalog_id = clc.catalog_id and base.ticketId = clc.ticket_id and base.ticketpriceschedule_id = clc.ticketpriceschedule_id and clc.deleted = '0' and clc.is_adjust_pricing = '1') as base1 where channel_level_commission_id is not NULL;


--- main catalog data fetch
select * from (SELECT o.vt_group_no, tlc.* FROM rattan.evanorders o join priopassdb.channel_level_commission tlc on o.channel_id = tlc.channel_id and o.ticketId = tlc.ticket_id and o.ticketpriceschedule_id = tlc.ticketpriceschedule_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') as base where channel_level_commission_id is NULL; 
