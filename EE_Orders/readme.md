select vt_group_no, ticketId, ticketpriceschedule_id, channel_id, hotel_id from visitor_tickets where vt_group_no in ($batch_str) and col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%' group by vt_group_no, ticketId, ticketpriceschedule_id, channel_id, hotel_id

---tlc data fetch

SELECT tlc.* FROM priopassdb.evanorders o join priopassdb.ticket_level_commission tlc on o.hotel_id = tlc.hotel_id and o.ticketId = tlc.ticket_id and o.ticketpriceschedule_id = tlc.ticketpriceschedule_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1'; 

--- subcatalog_data fect---
select clc.* from (SELECT o.*, qc.sub_catalog_id FROM priopassdb.evanorders o join priopassdb.qr_codes qc on o.hotel_id = qc.cod_id where qc.sub_catalog_id > '0' and qc.sub_catalog_id is not NULL) as base join priopassdb.channel_level_commission clc on base.sub_catalog_id = clc.catalog_id and base.ticketId = clc.ticket_id and base.ticketpriceschedule_id = clc.ticketpriceschedule_id and clc.deleted = '0' and clc.is_adjust_pricing = '1' group by clc.channel_level_commission_id


--- main catalog data fetch
SELECT channel_level_commission.* FROM priopassdb.evanorders o join priopassdb.channel_level_commission channel_level_commission on o.channel_id = channel_level_commission.channel_id and o.ticketId = channel_level_commission.ticket_id and o.ticketpriceschedule_id = channel_level_commission.ticketpriceschedule_id and channel_level_commission.deleted = '0' and channel_level_commission.is_adjust_pricing = '1' group by channel_level_commission.channel_level_commission_id
