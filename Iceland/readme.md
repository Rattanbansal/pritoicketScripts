-- query to check the latest version to verify data

select vt.vt_group_no, vt.transaction_id,vt.hotel_id,vt.ticketId,vt.selected_date, vt.version, vt.row_type, vt.admin_currency_code, vt.partner_net_price, vt.partner_gross_price, vt.tax_value, vt.transaction_type_name, vt.col2 from visitor_tickets vt join (select vt_group_no, transaction_id, row_type, max(version) as version from visitor_tickets where vt_group_no = '166997241092017' and col2 != '2' group by vt_group_no, transaction_id, row_type) as maxv on maxv.vt_group_no = vt.vt_group_no and maxv.transaction_id = vt.transaction_id and maxv.row_type = vt.row_type and ABS(ROUND(maxv.version-vt.version,1)) = '0' 


---- After excluding refunded entries

select vt.vt_group_no, vt.transaction_id,vt.hotel_id,vt.ticketId,vt.selected_date, vt.version, vt.row_type, vt.admin_currency_code, vt.partner_net_price, vt.partner_gross_price, vt.tax_value, vt.transaction_type_name, vt.col2, vt.is_refunded from visitor_tickets vt join (select vt_group_no, transaction_id, row_type, max(version) as version from visitor_tickets where vt_group_no = '166997241092017' and col2 != '2' group by vt_group_no, transaction_id, row_type) as maxv on maxv.vt_group_no = vt.vt_group_no and maxv.transaction_id = vt.transaction_id and maxv.row_type = vt.row_type and ABS(ROUND(maxv.version-vt.version,1)) = '0' where vt.row_type = '1' and vt.is_refunded = '0' 