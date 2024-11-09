----- Starting checking point regarding duplicate records first----

select dpv.*, base.pcs, base.keyyy from dynamic_price_variations dpv join (SELECT max(price_variation_id) as price_variation_id, concat(supplier_admin_id, partner_id, partner_type, variation_type, ticket_id, shared_capacity_id, tps_id, days,start_date, end_date, travel_date, from_time, to_time, sale_variation, resale_variation) as keyyy,supplier_admin_id, partner_id, partner_type, variation_type, ticket_id, shared_capacity_id, tps_id, days,start_date, end_date, travel_date, from_time, to_time, sale_variation, resale_variation, count(*) as pcs FROM `dynamic_price_variations` where deleted = '0' group by  supplier_admin_id, partner_id, partner_type, variation_type, ticket_id, shared_capacity_id, tps_id, days,start_date, end_date, travel_date, from_time, to_time, sale_variation, resale_variation having count(*) > '1') as base on base.price_variation_id != dpv.price_variation_id and base.keyyy = concat(dpv.supplier_admin_id, dpv.partner_id, dpv.partner_type, dpv.variation_type, dpv.ticket_id, dpv.shared_capacity_id, dpv.tps_id, dpv.days,dpv.start_date, dpv.end_date, dpv.travel_date, dpv.from_time, dpv.to_time, dpv.sale_variation, dpv.resale_variation) and dpv.deleted = '0' order by dpv.supplier_admin_id, dpv.partner_id, dpv.partner_type, dpv.variation_type, dpv.ticket_id, dpv.shared_capacity_id, dpv.tps_id, dpv.days,dpv.start_date, dpv.end_date, dpv.travel_date, dpv.from_time, dpv.to_time, dpv.sale_variation, dpv.resale_variation





insert into dynamic_price_variations_backup SELECT * FROM dynamic_price_variations where deleted = '1' limit 1, 1 


last_modified_when record deleted = 

	2024-11-09 12:22:39
	Edit Edit	Copy Copy	Delete Delete	2024-11-09 12:24:41
	Edit Edit	Copy Copy	Delete Delete	2024-11-09 16:09:49