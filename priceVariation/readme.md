----- Starting checking point regarding duplicate records first----

select dpv.*, base.pcs, base.keyyy from dynamic_price_variations dpv join (SELECT max(price_variation_id) as price_variation_id, concat(supplier_admin_id, partner_id, partner_type, variation_type, ticket_id, shared_capacity_id, tps_id, days,start_date, end_date, travel_date, from_time, to_time, sale_variation, resale_variation) as keyyy,supplier_admin_id, partner_id, partner_type, variation_type, ticket_id, shared_capacity_id, tps_id, days,start_date, end_date, travel_date, from_time, to_time, sale_variation, resale_variation, count(*) as pcs FROM `dynamic_price_variations` where deleted = '0' group by  supplier_admin_id, partner_id, partner_type, variation_type, ticket_id, shared_capacity_id, tps_id, days,start_date, end_date, travel_date, from_time, to_time, sale_variation, resale_variation having count(*) > '1') as base on base.price_variation_id != dpv.price_variation_id and base.keyyy = concat(dpv.supplier_admin_id, dpv.partner_id, dpv.partner_type, dpv.variation_type, dpv.ticket_id, dpv.shared_capacity_id, dpv.tps_id, dpv.days,dpv.start_date, dpv.end_date, dpv.travel_date, dpv.from_time, dpv.to_time, dpv.sale_variation, dpv.resale_variation) and dpv.deleted = '0' order by dpv.supplier_admin_id, dpv.partner_id, dpv.partner_type, dpv.variation_type, dpv.ticket_id, dpv.shared_capacity_id, dpv.tps_id, dpv.days,dpv.start_date, dpv.end_date, dpv.travel_date, dpv.from_time, dpv.to_time, dpv.sale_variation, dpv.resale_variation





insert into dynamic_price_variations_backup SELECT * FROM dynamic_price_variations where deleted = '1' limit 1, 1 


last_modified_when record deleted = 

	2024-11-09 12:22:39
	Edit Edit	Copy Copy	Delete Delete	2024-11-09 12:24:41
	Edit Edit	Copy Copy	Delete Delete	2024-11-09 16:09:49


------

New FLow
partner_type:0 = supplier_admin_id => KEY : cat-0-supplier_admin_id
partner_type:1 = {DELETED in NEW FLOW}
partner_type:2 = partner_id {distributor_id} - {DELETED IN NEW FLOW}
partner_type:3 = partner_id (Agent catalog_id) => KEY : cat-partner_id
Partner_type:4 = partner_Id (Reseller sub_catalog_id) => KEY: sub_cat-partner_id
partner_type:5 = partner_id (Agent sub_catalog_id) => KEY: sub_cat-partner_id

else case reseller_id = 686


 
Old Flow
Partner_type:0 = supplier_admin_id => KEY {Reseller-supplier_admin_id }
Partner_type:1= partner_id {hotel_admin_id} => Key {Reseller-partner_id}
Partner_type:2 = partner_id (distributor_id) => KEY {distributor_id}
Partner_type:3 = partner_id(catalog_id) => KEY {distributor_id}
Partner_type:4 = DOES NOT EXIST
Partner_type:5 = partner_id(sub_catalog_id) => KEY {distributor_id}




---- 


SELECT * FROM `dynamic_price_variations` where partner_type = '1' and deleted = '0' and supplier_admin_id != '971' and end_date > CURRENT_DATE

