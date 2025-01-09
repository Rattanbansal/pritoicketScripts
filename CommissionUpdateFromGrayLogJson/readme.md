---------- query to check conversion on basis of row_type = '1'

select vt.transaction_id,vt.vt_group_no, vt.row_type, vt.transaction_type_name, vt.partner_gross_price, vt.partner_net_price, vt.supplier_gross_price, vt.supplier_net_price, vt.action_performed, vt.version, base.conversion from visitor_tickets vt join  (select transaction_id,vt_group_no, row_type, transaction_type_name, partner_gross_price, partner_net_price, supplier_gross_price, supplier_net_price, action_performed, version, supplier_net_price/partner_net_price as conversion from visitor_tickets where vt_group_no = '173455973947224' and row_type = '1') as base on (vt.transaction_id+1) = (base.transaction_id+1) and vt.vt_group_no = base.vt_group_no and ABS(vt.version = base.version) = '0' where vt.row_type = '2'


---- update row_type = 2 commission

update visitor_tickets vt join  (select transaction_id,vt_group_no, row_type, transaction_type_name, partner_gross_price, partner_net_price, supplier_gross_price, supplier_net_price, action_performed, version, supplier_net_price/partner_net_price as conversion from visitor_tickets where vt_group_no = '173204793919088' and row_type = '1') as base on (vt.transaction_id+1) = (base.transaction_id+1) and vt.vt_group_no = base.vt_group_no and ABS(vt.version = base.version) = '0' set vt.partner_gross_price = vt.supplier_net_price/base.conversion,vt.partner_net_price = vt.supplier_net_price/base.conversion  where vt.row_type = '2'


SELECT channel_level_commission_id,channel_id, ticketpriceschedule_id, ticket_net_price, museum_net_commission, merchant_net_commission, subtotal_net_amount, hotel_commission_net_price, hgs_commission_net_price, commission_on_sale_price, resale_currency_level FROM `channel_level_commission` where ticketpriceschedule_id in (438203,
438204,
438205,
438206,
438207,
438208,
438209,
438210,
438211,
438212,
438213,
438215,
438216) and deleted = '0' and is_adjust_pricing = '1' order by channel_id, ticketpriceschedule_id, resale_currency_level



select vt.transaction_id,vt.vt_group_no, vt.row_type, vt.transaction_type_name, vt.partner_gross_price, vt.partner_net_price, vt.supplier_gross_price, vt.supplier_net_price, vt.action_performed, vt.version, base.conversion from visitor_tickets vt join  (select transaction_id,vt_group_no, row_type, transaction_type_name, partner_gross_price, partner_net_price, supplier_gross_price, supplier_net_price, action_performed, version, supplier_net_price/partner_net_price as conversion from visitor_tickets where vt_group_no = '173229251257561' and row_type = '1') as base on (vt.transaction_id+1) = (base.transaction_id+1) and vt.vt_group_no = base.vt_group_no and ABS(vt.version = base.version) = '0' where vt.row_type = '2'