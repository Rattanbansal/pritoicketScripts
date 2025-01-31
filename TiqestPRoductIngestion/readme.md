<!-- mismatch with clc -->

with vt as (SELECT DISTINCT ticket_id as vt_ticket_id FROM `viatoringestion` WHERE 1), cl as (select DISTINCT ticket_id as cl_ticket_id from channel_level_commission where channel_id ='680' and deleted ='0' and is_adjust_pricing='1'), aa as (select * from vt left join cl on vt.vt_ticket_id =cl.cl_ticket_id ) select * from aa where cl_ticket_id is null

<!-- mismatch with tlt -->
with vt as (SELECT DISTINCT ticket_id as vt_ticket_id FROM `viatoringestion` WHERE 1),cl as (select DISTINCT ticket_id as tl_ticket_id from template_level_tickets where template_id ='818' and deleted ='0'),aa as (select * from vt left join cl on vt.vt_ticket_id =cl.tl_ticket_id) select * from aa where tl_ticket_id is null

<!-- expired season -->
select DISTINCT ticket_id from viatoringestion where ticket_id not in (SELECT DISTINCT ticket_id from ticketpriceschedule where ticket_id in(select DISTINCT ticket_id from viatoringestion) and DATE( FROM_UNIXTIME( IF( end_date LIKE '%9999%', '1750343264', end_date ) ) ) >= CURRENT_DATE())