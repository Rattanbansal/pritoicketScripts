select vtf.id, vtf.created_date, vtf.transaction_id, vtf.invoice_id, vtf.channel_id, vtf.channel_name, vtf.reseller_id, vtf.reseller_name, vtf.saledesk_id, vtf.saledesk_name, vtf.financial_id, vtf.financial_name, vtf.transaction_type_name, vtf.transaction_type_id, vtf.ticketId, vtf.shared_capacity_id, vtf.ticket_booking_id, vtf.related_order_id, vtf.related_booking_id, vtf.ticket_title, vtf.ticketwithdifferentpricing, vtf.ticketpriceschedule_id, vtf.ticket_extra_option_id, vtf.group_type_ticket, vtf.group_price, vtf.group_quantity, vtf.group_linked_with, vtf.selected_date, vtf.booking_selected_date, vtf.from_time, vtf.to_time, vtf.slot_type, vtf.amount_before_extra_discount, vtf.discount_before_extra_discount, vtf.hto_id, vtf.visitor_group_no, vtf.roomNo, vtf.nights, vtf.user_age, vtf.gender, vtf.user_image, vtf.visitor_country, vtf.merchantAccountCode, vtf.merchantReference, vtf.original_pspReference, vtf.shopperReference, vtf.partner_id, vtf.relational_partner_id, vtf.partner_name, vtf.museum_name, vtf.museum_id, vtf.hotel_name, vtf.hotel_id, vtf.pos_point_id, vtf.pos_point_name, vtf.shift_id, vtf.passNo, vtf.pass_type, vtf.ticketAmt, vtf.visit_date, vtf.visit_date_time, vtf.ticketType, vtf.tickettype_name, vtf.discount_applied_on_how_many_tickets, vtf.paid, vtf.payment_method, vtf.isBillToHotel, vtf.card_name, vtf.pspReference, vtf.card_type, vtf.captured, vtf.age_group, vtf.discount, vtf.isDiscountInPercent, vtf.updated_discount_type, vtf.without_elo_reference_no, vtf.debitor, vtf.creditor, vtf.split_cash_amount, vtf.split_card_amount, vtf.split_voucher_amount, vtf.split_direct_payment_amount, vtf.total_gross_commission, vtf.total_net_commission, vtf.commission_type, (case when vtf.row_type = ddd.ddd_row_type then ROUND(ddd.ddd_gross_should_be,2) else ROUND(vtf.partner_gross_price,2) end) as partner_gross_price, vtf.order_currency_partner_gross_price, vtf.partner_gross_price_without_combi_discount, (case when vtf.row_type = ddd.ddd_row_type then ROUND(ddd.ddd_should_be_net,2) else ROUND(vtf.partner_net_price,2) end) as partner_net_price, vtf.order_currency_partner_net_price, vtf.partner_net_price_without_combi_discount, vtf.isCommissionInPercent, vtf.tax_id, vtf.tax_value, vtf.tax_name, vtf.timezone, vtf.invoice_status, vtf.row_type, vtf.updated_by_id, vtf.updated_by_username, vtf.voucher_updated_by, vtf.voucher_updated_by_name, vtf.redeem_method, vtf.redeem_by_ticket_id, vtf.redeem_by_ticket_title, vtf.cashier_id, vtf.cashier_name, vtf.cashier_register_id, vtf.targetlocation, vtf.paymentMethodType, vtf.targetcity, vtf.service_name, vtf.adjustment_row_type, vtf.description, vtf.distributor_status, vtf.adyen_status, vtf.adjustment_method, vtf.all_ticket_ids, vtf.time_based_done, vtf.visitor_invoice_id, vtf.ticketPrice, vtf.deleted, vtf.is_refunded, vtf.is_block, vtf.is_edited, vtf.vt_group_no, vtf.user_name, vtf.issuer_country_code, vtf.distributor_commission_invoice, vtf.activation_method, vtf.is_prioticket, vtf.is_shop_product, vtf.shop_category_name, vtf.external_account_number, vtf.used, vtf.ticket_status, vtf.is_prepaid, vtf.is_purchased_with_postpaid, vtf.invoice_type, vtf.supplier_currency_symbol, vtf.order_currency_code, vtf.order_currency_symbol, vtf.currency_rate, vtf.invoice_variant, vtf.service_cost, vtf.service_cost_net_amount, vtf.service_cost_type, vtf.scanned_pass, vtf.groupTransactionId, vtf.booking_status, vtf.channel_type, vtf.is_voucher, vtf.extra_text_field_answer, vtf.distributor_type, vtf.distributor_partner_id, vtf.distributor_partner_name, vtf.issuer_country_name, vtf.chart_number, vtf.extra_discount, vtf.manual_payment_note, vtf.account_number, vtf.is_custom_setting, vtf.external_product_id, vtf.supplier_currency_code, vtf.col1, vtf.col2, vtf.partner_category_id, vtf.col4, vtf.partner_category_name, vtf.col6, vtf.col7, vtf.col8, vtf.is_data_moved,concat(vtf.action_performed, ', EECommission') as action_performed, vtf.updated_at, vtf.tp_payment_method, vtf.order_confirm_date, vtf.payment_date, vtf.order_cancellation_date, vtf.voucher_creation_date, vtf.primary_host_name,supplier_gross_price, vtf.supplier_discount, vtf.supplier_ticket_amt, vtf.supplier_tax_value, supplier_net_price, CURRENT_TIMESTAMP as last_modified_at, vtf.market_merchant_id, vtf.merchant_admin_id, vtf.order_updated_cashier_id, vtf.order_updated_cashier_name, ROUND(vtf.version+1,1) as version, vtf.supplier_tax_id, vtf.merchant_currency_code, vtf.merchant_price, vtf.merchant_net_price, vtf.merchant_tax_id, vtf.admin_currency_code from (select fvt.* from visitor_tickets fvt join (select vt_group_no, transaction_id,row_type, max(version) as version from visitor_tickets where ticketId in (14069) and vt_group_no in (171154200372866) and col2 != '2' group by vt_group_no, transaction_id, row_type) as mv on mv.vt_group_no = fvt.vt_group_no and fvt.transaction_id = mv.transaction_id and fvt.row_type = mv.row_type and ABS(fvt.version-mv.version) = '0' where fvt.col2 != '2') vtf left join (select vtt.vt_group_no as ddd_vt_group_no, vtt.transaction_id as ddd_transaction_id, vtt.version as ddd_version,vtt.row_type as ddd_row_type,vtt.partner_net_price as ddd_partner_net_price, ROUND((final.salePrice*final.percentage_commission/100),2) as ddd_should_be_net, vtt.partner_gross_price as ddd_partner_gross_price,vtt.tax_value as ddd_tax_value, FORMAT(ROUND((final.salePrice*final.percentage_commission/100),2),2)*(100+vtt.tax_value)/100 as ddd_gross_should_be, vtt.supplier_net_price as ddd_supplier_bet_price, vtt.supplier_gross_price as ddd_supplier_gross_price,vtt.supplier_tax_value as ddd_supplier_tax, vtt.action_performed as dd_action_performed, concat(vtt.action_performed, ', EECommission') as dd_action_performed_should_be from visitor_tickets vtt join (SELECT
        vt_group_no,
        transaction_id,
        hotel_id, channel_id, ticketId, ticketpriceschedule_id, version, row_type, partner_net_price,salePrice, (case when row_type = '2' and tlc_ticketpriceschedule_id is not NULL then tlc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_res_per 
        when row_type = '3' and tlc_ticketpriceschedule_id is not NULL then tlc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_dist_per
        when row_type = '4' and tlc_ticketpriceschedule_id is not NULL then tlc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_hgs_per when row_type = '1' then '100.00' else 'No_Setting_found' end) as percentage_commission,
        case when tlc_ticketpriceschedule_id is not NULL then tlc_comm_on_sale when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_comm_on_sale when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_comm_on_sale else 'No_Setting_found' end as commission_on_sale
FROM
    (
    SELECT
        scdata.*,
        '----Price List Level---' AS type3,
        pl.ticketpriceschedule_id AS clc_ticketpriceschedule_id,
        pl.hotel_prepaid_commission_percentage as pl_dist_per,
        pl.hgs_prepaid_commission_percentage as pl_hgs_per,
        pl.merchant_fee_percentage as pl_mer_per,
        pl.resale_percentage as pl_res_per,
        pl.commission_on_sale_price as pl_comm_on_sale
FROM
    (
    SELECT
        tlcdata.*,
        '----Sub catalog Level---' AS type2,
        sc.catalog_id,
        sc.ticketpriceschedule_id AS sc_ticketpriceschedule_id,
        sc.resale_currency_level AS sc_resale_currency_level,
        sc.hotel_prepaid_commission_percentage as sc_dist_per,
        sc.hgs_prepaid_commission_percentage as sc_hgs_per,
        sc.merchant_fee_percentage as sc_mer_per,
        sc.resale_percentage as sc_res_per,
        sc.commission_on_sale_price as sc_comm_on_sale        
FROM
    (
    SELECT
        vt.vt_group_no,
        CONCAT(vt.transaction_id, 'R') AS transaction_id,
        vt.order_confirm_date,
        vt.created_date,
        vt.hotel_id,
        vt.channel_id,
        vt.ticketId,
        vt.ticketpriceschedule_id,
        vt.version,
        vt.row_type,
        vt.partner_gross_price,
        vt.partner_net_price,
        maxversion.salePrice,
        vt.order_currency_partner_gross_price,
        vt.order_currency_partner_net_price,
        vt.supplier_gross_price,
        vt.supplier_net_price,
        vt.col2,
        qc.cod_id AS company_id,
        qc.channel_id AS company_pricelist_id,
        qc.sub_catalog_id AS company_sub_catalog,
        '---TLC LEVEL---' AS TYPE,
        tlc.ticketpriceschedule_id AS tlc_ticketpriceschedule_id,
        tlc.resale_currency_level,
        tlc.hotel_prepaid_commission_percentage as tlc_dist_per,
        tlc.hgs_prepaid_commission_percentage as tlc_hgs_per,
        tlc.merchant_fee_percentage as tlc_mer_per,
        tlc.resale_percentage as tlc_res_per,
        tlc.commission_on_sale_price as tlc_comm_on_sale
FROM
    visitor_tickets vt
JOIN(
    SELECT
        vt_group_no,
        transaction_id,
        row_type,
        max(case when row_type = '1' then partner_net_price else 0 end) as salePrice,
        MAX(VERSION) AS VERSION
    FROM
        visitor_tickets
    WHERE
        ticketId in (14069) and vt_group_no in (171154200372866) AND col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%'
    GROUP BY
        vt_group_no,
        transaction_id
) AS maxversion
ON
    vt.vt_group_no = maxversion.vt_group_no AND vt.transaction_id = maxversion.transaction_id AND ABS(vt.version - maxversion.version) = '0'
LEFT JOIN tmp.qr_codes qc
ON
    qc.cod_id = vt.hotel_id AND qc.cashier_type = '1'
LEFT JOIN tmp.ticket_level_commission tlc
ON
    tlc.hotel_id = vt.hotel_id AND tlc.ticketpriceschedule_id = vt.ticketpriceschedule_id AND tlc.ticket_id = vt.ticketId AND tlc.deleted = '0' AND tlc.is_adjust_pricing = '1'
WHERE
    vt.col2 != '2'
) AS tlcdata
LEFT JOIN tmp.channel_level_commission sc
ON
    tlcdata.ticketpriceschedule_id = sc.ticketpriceschedule_id AND tlcdata.ticketId = sc.ticket_id AND IF(
        tlcdata.company_sub_catalog = '0',
        122222,
        tlcdata.company_sub_catalog
    ) = sc.catalog_id AND sc.is_adjust_pricing = '1' AND sc.deleted = '0'
) AS scdata
LEFT JOIN tmp.channel_level_commission pl
ON
    scdata.ticketpriceschedule_id = pl.ticketpriceschedule_id AND scdata.ticketId = pl.ticket_id AND scdata.channel_id = pl.channel_id AND pl.catalog_id = '0' AND pl.is_adjust_pricing = '1' AND pl.deleted = '0'
) AS shouldbe) as final on vtt.vt_group_no = final.vt_group_no and ABS(vtt.version-final.version) = '0' and vtt.transaction_id = final.transaction_id and vtt.row_type = final.row_type where ABS(final.partner_net_price-(final.salePrice*final.percentage_commission/100)) > '0.02' and final.percentage_commission != 'No_Setting_found' and final.row_type != '1' and vtt.col2 != '2') as ddd on ddd.ddd_vt_group_no = vtf.vt_group_no and (ddd.ddd_transaction_id+1) = (vtf.transaction_id+1) and ABS(ddd.ddd_version - vtf.version) = '0' and vtf.row_type = ddd.ddd_row_type;SELECT ROW_COUNT();
------2024-11-25 18:47:50.841--------
insert into visitor_tickets (id, created_date, transaction_id, invoice_id, channel_id, channel_name, reseller_id, reseller_name, saledesk_id, saledesk_name, financial_id, financial_name, transaction_type_name, transaction_type_id, ticketId, shared_capacity_id, ticket_booking_id, related_order_id, related_booking_id, ticket_title, ticketwithdifferentpricing, ticketpriceschedule_id, ticket_extra_option_id, group_type_ticket, group_price, group_quantity, group_linked_with, selected_date, booking_selected_date, from_time, to_time, slot_type, amount_before_extra_discount, discount_before_extra_discount, hto_id, visitor_group_no, roomNo, nights, user_age, gender, user_image, visitor_country, merchantAccountCode, merchantReference, original_pspReference, shopperReference, partner_id, relational_partner_id, partner_name, museum_name, museum_id, hotel_name, hotel_id, pos_point_id, pos_point_name, shift_id, passNo, pass_type, ticketAmt, visit_date, visit_date_time, ticketType, tickettype_name, discount_applied_on_how_many_tickets, paid, payment_method, isBillToHotel, card_name, pspReference, card_type, captured, age_group, discount, isDiscountInPercent, updated_discount_type, without_elo_reference_no, debitor, creditor, split_cash_amount, split_card_amount, split_voucher_amount, split_direct_payment_amount, total_gross_commission, total_net_commission, commission_type, partner_gross_price, order_currency_partner_gross_price, partner_gross_price_without_combi_discount, partner_net_price, order_currency_partner_net_price, partner_net_price_without_combi_discount, isCommissionInPercent, tax_id, tax_value, tax_name, timezone, invoice_status, row_type, updated_by_id, updated_by_username, voucher_updated_by, voucher_updated_by_name, redeem_method, redeem_by_ticket_id, redeem_by_ticket_title, cashier_id, cashier_name, cashier_register_id, targetlocation, paymentMethodType, targetcity, service_name, adjustment_row_type, description, distributor_status, adyen_status, adjustment_method, all_ticket_ids, time_based_done, visitor_invoice_id, ticketPrice, deleted, is_refunded, is_block, is_edited, vt_group_no, user_name, issuer_country_code, distributor_commission_invoice, activation_method, is_prioticket, is_shop_product, shop_category_name, external_account_number, used, ticket_status, is_prepaid, is_purchased_with_postpaid, invoice_type, supplier_currency_symbol, order_currency_code, order_currency_symbol, currency_rate, invoice_variant, service_cost, service_cost_net_amount, service_cost_type, scanned_pass, groupTransactionId, booking_status, channel_type, is_voucher, extra_text_field_answer, distributor_type, distributor_partner_id, distributor_partner_name, issuer_country_name, chart_number, extra_discount, manual_payment_note, account_number, is_custom_setting, external_product_id, supplier_currency_code, col1, col2, partner_category_id, col4, partner_category_name, col6, col7, col8, is_data_moved, action_performed, updated_at, tp_payment_method, order_confirm_date, payment_date, order_cancellation_date, voucher_creation_date, primary_host_name,supplier_gross_price, supplier_discount, supplier_ticket_amt, supplier_tax_value,supplier_net_price, last_modified_at, market_merchant_id, merchant_admin_id, order_updated_cashier_id, order_updated_cashier_name, version, supplier_tax_id, merchant_currency_code, merchant_price, merchant_net_price, merchant_tax_id, admin_currency_code) select vtf.id, vtf.created_date, vtf.transaction_id, vtf.invoice_id, vtf.channel_id, vtf.channel_name, vtf.reseller_id, vtf.reseller_name, vtf.saledesk_id, vtf.saledesk_name, vtf.financial_id, vtf.financial_name, vtf.transaction_type_name, vtf.transaction_type_id, vtf.ticketId, vtf.shared_capacity_id, vtf.ticket_booking_id, vtf.related_order_id, vtf.related_booking_id, vtf.ticket_title, vtf.ticketwithdifferentpricing, vtf.ticketpriceschedule_id, vtf.ticket_extra_option_id, vtf.group_type_ticket, vtf.group_price, vtf.group_quantity, vtf.group_linked_with, vtf.selected_date, vtf.booking_selected_date, vtf.from_time, vtf.to_time, vtf.slot_type, vtf.amount_before_extra_discount, vtf.discount_before_extra_discount, vtf.hto_id, vtf.visitor_group_no, vtf.roomNo, vtf.nights, vtf.user_age, vtf.gender, vtf.user_image, vtf.visitor_country, vtf.merchantAccountCode, vtf.merchantReference, vtf.original_pspReference, vtf.shopperReference, vtf.partner_id, vtf.relational_partner_id, vtf.partner_name, vtf.museum_name, vtf.museum_id, vtf.hotel_name, vtf.hotel_id, vtf.pos_point_id, vtf.pos_point_name, vtf.shift_id, vtf.passNo, vtf.pass_type, vtf.ticketAmt, vtf.visit_date, vtf.visit_date_time, vtf.ticketType, vtf.tickettype_name, vtf.discount_applied_on_how_many_tickets, vtf.paid, vtf.payment_method, vtf.isBillToHotel, vtf.card_name, vtf.pspReference, vtf.card_type, vtf.captured, vtf.age_group, vtf.discount, vtf.isDiscountInPercent, vtf.updated_discount_type, vtf.without_elo_reference_no, vtf.debitor, vtf.creditor, vtf.split_cash_amount, vtf.split_card_amount, vtf.split_voucher_amount, vtf.split_direct_payment_amount, vtf.total_gross_commission, vtf.total_net_commission, vtf.commission_type, (case when vtf.row_type = ddd.ddd_row_type then ROUND(ddd.ddd_gross_should_be,2) else ROUND(vtf.partner_gross_price,2) end) as partner_gross_price, vtf.order_currency_partner_gross_price, vtf.partner_gross_price_without_combi_discount, (case when vtf.row_type = ddd.ddd_row_type then ROUND(ddd.ddd_should_be_net,2) else ROUND(vtf.partner_net_price,2) end) as partner_net_price, vtf.order_currency_partner_net_price, vtf.partner_net_price_without_combi_discount, vtf.isCommissionInPercent, vtf.tax_id, vtf.tax_value, vtf.tax_name, vtf.timezone, vtf.invoice_status, vtf.row_type, vtf.updated_by_id, vtf.updated_by_username, vtf.voucher_updated_by, vtf.voucher_updated_by_name, vtf.redeem_method, vtf.redeem_by_ticket_id, vtf.redeem_by_ticket_title, vtf.cashier_id, vtf.cashier_name, vtf.cashier_register_id, vtf.targetlocation, vtf.paymentMethodType, vtf.targetcity, vtf.service_name, vtf.adjustment_row_type, vtf.description, vtf.distributor_status, vtf.adyen_status, vtf.adjustment_method, vtf.all_ticket_ids, vtf.time_based_done, vtf.visitor_invoice_id, vtf.ticketPrice, vtf.deleted, vtf.is_refunded, vtf.is_block, vtf.is_edited, vtf.vt_group_no, vtf.user_name, vtf.issuer_country_code, vtf.distributor_commission_invoice, vtf.activation_method, vtf.is_prioticket, vtf.is_shop_product, vtf.shop_category_name, vtf.external_account_number, vtf.used, vtf.ticket_status, vtf.is_prepaid, vtf.is_purchased_with_postpaid, vtf.invoice_type, vtf.supplier_currency_symbol, vtf.order_currency_code, vtf.order_currency_symbol, vtf.currency_rate, vtf.invoice_variant, vtf.service_cost, vtf.service_cost_net_amount, vtf.service_cost_type, vtf.scanned_pass, vtf.groupTransactionId, vtf.booking_status, vtf.channel_type, vtf.is_voucher, vtf.extra_text_field_answer, vtf.distributor_type, vtf.distributor_partner_id, vtf.distributor_partner_name, vtf.issuer_country_name, vtf.chart_number, vtf.extra_discount, vtf.manual_payment_note, vtf.account_number, vtf.is_custom_setting, vtf.external_product_id, vtf.supplier_currency_code, vtf.col1, vtf.col2, vtf.partner_category_id, vtf.col4, vtf.partner_category_name, vtf.col6, vtf.col7, vtf.col8, vtf.is_data_moved,concat(vtf.action_performed, ', EECommission') as action_performed, vtf.updated_at, vtf.tp_payment_method, vtf.order_confirm_date, vtf.payment_date, vtf.order_cancellation_date, vtf.voucher_creation_date, vtf.primary_host_name,supplier_gross_price, vtf.supplier_discount, vtf.supplier_ticket_amt, vtf.supplier_tax_value, supplier_net_price, CURRENT_TIMESTAMP as last_modified_at, vtf.market_merchant_id, vtf.merchant_admin_id, vtf.order_updated_cashier_id, vtf.order_updated_cashier_name, ROUND(vtf.version+1,1) as version, vtf.supplier_tax_id, vtf.merchant_currency_code, vtf.merchant_price, vtf.merchant_net_price, vtf.merchant_tax_id, vtf.admin_currency_code from (select fvt.* from visitor_tickets fvt join (select vt_group_no, transaction_id,row_type, max(version) as version from visitor_tickets where ticketId in (14069) and vt_group_no in (171154200372866) and col2 != '2' group by vt_group_no, transaction_id, row_type) as mv on mv.vt_group_no = fvt.vt_group_no and fvt.transaction_id = mv.transaction_id and fvt.row_type = mv.row_type and ABS(fvt.version-mv.version) = '0' where fvt.col2 != '2') vtf left join (select vtt.vt_group_no as ddd_vt_group_no, vtt.transaction_id as ddd_transaction_id, vtt.version as ddd_version,vtt.row_type as ddd_row_type,vtt.partner_net_price as ddd_partner_net_price,ROUND((final.salePrice*final.percentage_commission/100),2) as ddd_should_be_net, vtt.partner_gross_price as ddd_partner_gross_price,vtt.tax_value as ddd_tax_value, FORMAT(ROUND((final.salePrice*final.percentage_commission/100),2),2)*(100+vtt.tax_value)/100 as ddd_gross_should_be, vtt.supplier_net_price as ddd_supplier_bet_price, vtt.supplier_gross_price as ddd_supplier_gross_price,vtt.supplier_tax_value as ddd_supplier_tax, vtt.action_performed as dd_action_performed, concat(vtt.action_performed, ', EECommission') as dd_action_performed_should_be from visitor_tickets vtt join (SELECT
        vt_group_no,
        transaction_id,
        hotel_id, channel_id, ticketId, ticketpriceschedule_id, version, row_type, partner_net_price,salePrice, (case when row_type = '2' and tlc_ticketpriceschedule_id is not NULL then tlc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_res_per 
        when row_type = '3' and tlc_ticketpriceschedule_id is not NULL then tlc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_dist_per
        when row_type = '4' and tlc_ticketpriceschedule_id is not NULL then tlc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_hgs_per when row_type = '1' then '100.00' else 'No_Setting_found' end) as percentage_commission,
        case when tlc_ticketpriceschedule_id is not NULL then tlc_comm_on_sale when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_comm_on_sale when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_comm_on_sale else 'No_Setting_found' end as commission_on_sale
FROM
    (
    SELECT
        scdata.*,
        '----Price List Level---' AS type3,
        pl.ticketpriceschedule_id AS clc_ticketpriceschedule_id,
        pl.hotel_prepaid_commission_percentage as pl_dist_per,
        pl.hgs_prepaid_commission_percentage as pl_hgs_per,
        pl.merchant_fee_percentage as pl_mer_per,
        pl.resale_percentage as pl_res_per,
        pl.commission_on_sale_price as pl_comm_on_sale
FROM
    (
    SELECT
        tlcdata.*,
        '----Sub catalog Level---' AS type2,
        sc.catalog_id,
        sc.ticketpriceschedule_id AS sc_ticketpriceschedule_id,
        sc.resale_currency_level AS sc_resale_currency_level,
        sc.hotel_prepaid_commission_percentage as sc_dist_per,
        sc.hgs_prepaid_commission_percentage as sc_hgs_per,
        sc.merchant_fee_percentage as sc_mer_per,
        sc.resale_percentage as sc_res_per,
        sc.commission_on_sale_price as sc_comm_on_sale        
FROM
    (
    SELECT
        vt.vt_group_no,
        CONCAT(vt.transaction_id, 'R') AS transaction_id,
        vt.order_confirm_date,
        vt.created_date,
        vt.hotel_id,
        vt.channel_id,
        vt.ticketId,
        vt.ticketpriceschedule_id,
        vt.version,
        vt.row_type,
        vt.partner_gross_price,
        vt.partner_net_price,
        maxversion.salePrice,
        vt.order_currency_partner_gross_price,
        vt.order_currency_partner_net_price,
        vt.supplier_gross_price,
        vt.supplier_net_price,
        vt.col2,
        qc.cod_id AS company_id,
        qc.channel_id AS company_pricelist_id,
        qc.sub_catalog_id AS company_sub_catalog,
        '---TLC LEVEL---' AS TYPE,
        tlc.ticketpriceschedule_id AS tlc_ticketpriceschedule_id,
        tlc.resale_currency_level,
        tlc.hotel_prepaid_commission_percentage as tlc_dist_per,
        tlc.hgs_prepaid_commission_percentage as tlc_hgs_per,
        tlc.merchant_fee_percentage as tlc_mer_per,
        tlc.resale_percentage as tlc_res_per,
        tlc.commission_on_sale_price as tlc_comm_on_sale
FROM
    visitor_tickets vt
JOIN(
    SELECT
        vt_group_no,
        transaction_id,
        row_type,
        max(case when row_type = '1' then partner_net_price else 0 end) as salePrice,
        MAX(VERSION) AS VERSION
    FROM
        visitor_tickets
    WHERE
        ticketId in (14069) and vt_group_no in (171154200372866) AND col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%'
    GROUP BY
        vt_group_no,
        transaction_id
) AS maxversion
ON
    vt.vt_group_no = maxversion.vt_group_no AND vt.transaction_id = maxversion.transaction_id AND ABS(vt.version - maxversion.version) = '0'
LEFT JOIN tmp.qr_codes qc
ON
    qc.cod_id = vt.hotel_id AND qc.cashier_type = '1'
LEFT JOIN tmp.ticket_level_commission tlc
ON
    tlc.hotel_id = vt.hotel_id AND tlc.ticketpriceschedule_id = vt.ticketpriceschedule_id AND tlc.ticket_id = vt.ticketId AND tlc.deleted = '0' AND tlc.is_adjust_pricing = '1'
WHERE
    vt.col2 != '2'
) AS tlcdata
LEFT JOIN tmp.channel_level_commission sc
ON
    tlcdata.ticketpriceschedule_id = sc.ticketpriceschedule_id AND tlcdata.ticketId = sc.ticket_id AND IF(
        tlcdata.company_sub_catalog = '0',
        122222,
        tlcdata.company_sub_catalog
    ) = sc.catalog_id AND sc.is_adjust_pricing = '1' AND sc.deleted = '0'
) AS scdata
LEFT JOIN tmp.channel_level_commission pl
ON
    scdata.ticketpriceschedule_id = pl.ticketpriceschedule_id AND scdata.ticketId = pl.ticket_id AND scdata.channel_id = pl.channel_id AND pl.catalog_id = '0' AND pl.is_adjust_pricing = '1' AND pl.deleted = '0'
) AS shouldbe) as final on vtt.vt_group_no = final.vt_group_no and ABS(vtt.version-final.version) = '0' and vtt.transaction_id = final.transaction_id and vtt.row_type = final.row_type where ABS(final.partner_net_price-(final.salePrice*final.percentage_commission/100)) > '0.02' and final.percentage_commission != 'No_Setting_found' and final.row_type != '1' and vtt.col2 != '2') as ddd on ddd.ddd_vt_group_no = vtf.vt_group_no and (ddd.ddd_transaction_id+1) = (vtf.transaction_id+1) and ABS(ddd.ddd_version - vtf.version) = '0' and vtf.row_type = ddd.ddd_row_type;SELECT ROW_COUNT();
------2024-11-25 18:48:06.452--------
insert into visitor_tickets (id, created_date, transaction_id, invoice_id, channel_id, channel_name, reseller_id, reseller_name, saledesk_id, saledesk_name, financial_id, financial_name, transaction_type_name, transaction_type_id, ticketId, shared_capacity_id, ticket_booking_id, related_order_id, related_booking_id, ticket_title, ticketwithdifferentpricing, ticketpriceschedule_id, ticket_extra_option_id, group_type_ticket, group_price, group_quantity, group_linked_with, selected_date, booking_selected_date, from_time, to_time, slot_type, amount_before_extra_discount, discount_before_extra_discount, hto_id, visitor_group_no, roomNo, nights, user_age, gender, user_image, visitor_country, merchantAccountCode, merchantReference, original_pspReference, shopperReference, partner_id, relational_partner_id, partner_name, museum_name, museum_id, hotel_name, hotel_id, pos_point_id, pos_point_name, shift_id, passNo, pass_type, ticketAmt, visit_date, visit_date_time, ticketType, tickettype_name, discount_applied_on_how_many_tickets, paid, payment_method, isBillToHotel, card_name, pspReference, card_type, captured, age_group, discount, isDiscountInPercent, updated_discount_type, without_elo_reference_no, debitor, creditor, split_cash_amount, split_card_amount, split_voucher_amount, split_direct_payment_amount, total_gross_commission, total_net_commission, commission_type, partner_gross_price, order_currency_partner_gross_price, partner_gross_price_without_combi_discount, partner_net_price, order_currency_partner_net_price, partner_net_price_without_combi_discount, isCommissionInPercent, tax_id, tax_value, tax_name, timezone, invoice_status, row_type, updated_by_id, updated_by_username, voucher_updated_by, voucher_updated_by_name, redeem_method, redeem_by_ticket_id, redeem_by_ticket_title, cashier_id, cashier_name, cashier_register_id, targetlocation, paymentMethodType, targetcity, service_name, adjustment_row_type, description, distributor_status, adyen_status, adjustment_method, all_ticket_ids, time_based_done, visitor_invoice_id, ticketPrice, deleted, is_refunded, is_block, is_edited, vt_group_no, user_name, issuer_country_code, distributor_commission_invoice, activation_method, is_prioticket, is_shop_product, shop_category_name, external_account_number, used, ticket_status, is_prepaid, is_purchased_with_postpaid, invoice_type, supplier_currency_symbol, order_currency_code, order_currency_symbol, currency_rate, invoice_variant, service_cost, service_cost_net_amount, service_cost_type, scanned_pass, groupTransactionId, booking_status, channel_type, is_voucher, extra_text_field_answer, distributor_type, distributor_partner_id, distributor_partner_name, issuer_country_name, chart_number, extra_discount, manual_payment_note, account_number, is_custom_setting, external_product_id, supplier_currency_code, col1, col2, partner_category_id, col4, partner_category_name, col6, col7, col8, is_data_moved, action_performed, updated_at, tp_payment_method, order_confirm_date, payment_date, order_cancellation_date, voucher_creation_date, primary_host_name,supplier_gross_price, supplier_discount, supplier_ticket_amt, supplier_tax_value,supplier_net_price, last_modified_at, market_merchant_id, merchant_admin_id, order_updated_cashier_id, order_updated_cashier_name, version, supplier_tax_id, merchant_currency_code, merchant_price, merchant_net_price, merchant_tax_id, admin_currency_code) select vtf.id, vtf.created_date, vtf.transaction_id, vtf.invoice_id, vtf.channel_id, vtf.channel_name, vtf.reseller_id, vtf.reseller_name, vtf.saledesk_id, vtf.saledesk_name, vtf.financial_id, vtf.financial_name, vtf.transaction_type_name, vtf.transaction_type_id, vtf.ticketId, vtf.shared_capacity_id, vtf.ticket_booking_id, vtf.related_order_id, vtf.related_booking_id, vtf.ticket_title, vtf.ticketwithdifferentpricing, vtf.ticketpriceschedule_id, vtf.ticket_extra_option_id, vtf.group_type_ticket, vtf.group_price, vtf.group_quantity, vtf.group_linked_with, vtf.selected_date, vtf.booking_selected_date, vtf.from_time, vtf.to_time, vtf.slot_type, vtf.amount_before_extra_discount, vtf.discount_before_extra_discount, vtf.hto_id, vtf.visitor_group_no, vtf.roomNo, vtf.nights, vtf.user_age, vtf.gender, vtf.user_image, vtf.visitor_country, vtf.merchantAccountCode, vtf.merchantReference, vtf.original_pspReference, vtf.shopperReference, vtf.partner_id, vtf.relational_partner_id, vtf.partner_name, vtf.museum_name, vtf.museum_id, vtf.hotel_name, vtf.hotel_id, vtf.pos_point_id, vtf.pos_point_name, vtf.shift_id, vtf.passNo, vtf.pass_type, vtf.ticketAmt, vtf.visit_date, vtf.visit_date_time, vtf.ticketType, vtf.tickettype_name, vtf.discount_applied_on_how_many_tickets, vtf.paid, vtf.payment_method, vtf.isBillToHotel, vtf.card_name, vtf.pspReference, vtf.card_type, vtf.captured, vtf.age_group, vtf.discount, vtf.isDiscountInPercent, vtf.updated_discount_type, vtf.without_elo_reference_no, vtf.debitor, vtf.creditor, vtf.split_cash_amount, vtf.split_card_amount, vtf.split_voucher_amount, vtf.split_direct_payment_amount, vtf.total_gross_commission, vtf.total_net_commission, vtf.commission_type, (case when vtf.row_type = ddd.ddd_row_type then ROUND(ddd.ddd_gross_should_be,2) else ROUND(vtf.partner_gross_price,2) end) as partner_gross_price, vtf.order_currency_partner_gross_price, vtf.partner_gross_price_without_combi_discount, (case when vtf.row_type = ddd.ddd_row_type then ROUND(ddd.ddd_should_be_net,2) else ROUND(vtf.partner_net_price,2) end) as partner_net_price, vtf.order_currency_partner_net_price, vtf.partner_net_price_without_combi_discount, vtf.isCommissionInPercent, vtf.tax_id, vtf.tax_value, vtf.tax_name, vtf.timezone, vtf.invoice_status, vtf.row_type, vtf.updated_by_id, vtf.updated_by_username, vtf.voucher_updated_by, vtf.voucher_updated_by_name, vtf.redeem_method, vtf.redeem_by_ticket_id, vtf.redeem_by_ticket_title, vtf.cashier_id, vtf.cashier_name, vtf.cashier_register_id, vtf.targetlocation, vtf.paymentMethodType, vtf.targetcity, vtf.service_name, vtf.adjustment_row_type, vtf.description, vtf.distributor_status, vtf.adyen_status, vtf.adjustment_method, vtf.all_ticket_ids, vtf.time_based_done, vtf.visitor_invoice_id, vtf.ticketPrice, vtf.deleted, vtf.is_refunded, vtf.is_block, vtf.is_edited, vtf.vt_group_no, vtf.user_name, vtf.issuer_country_code, vtf.distributor_commission_invoice, vtf.activation_method, vtf.is_prioticket, vtf.is_shop_product, vtf.shop_category_name, vtf.external_account_number, vtf.used, vtf.ticket_status, vtf.is_prepaid, vtf.is_purchased_with_postpaid, vtf.invoice_type, vtf.supplier_currency_symbol, vtf.order_currency_code, vtf.order_currency_symbol, vtf.currency_rate, vtf.invoice_variant, vtf.service_cost, vtf.service_cost_net_amount, vtf.service_cost_type, vtf.scanned_pass, vtf.groupTransactionId, vtf.booking_status, vtf.channel_type, vtf.is_voucher, vtf.extra_text_field_answer, vtf.distributor_type, vtf.distributor_partner_id, vtf.distributor_partner_name, vtf.issuer_country_name, vtf.chart_number, vtf.extra_discount, vtf.manual_payment_note, vtf.account_number, vtf.is_custom_setting, vtf.external_product_id, vtf.supplier_currency_code, vtf.col1, vtf.col2, vtf.partner_category_id, vtf.col4, vtf.partner_category_name, vtf.col6, vtf.col7, vtf.col8, vtf.is_data_moved,concat(vtf.action_performed, ', EECommission') as action_performed, vtf.updated_at, vtf.tp_payment_method, vtf.order_confirm_date, vtf.payment_date, vtf.order_cancellation_date, vtf.voucher_creation_date, vtf.primary_host_name,supplier_gross_price, vtf.supplier_discount, vtf.supplier_ticket_amt, vtf.supplier_tax_value, supplier_net_price, CURRENT_TIMESTAMP as last_modified_at, vtf.market_merchant_id, vtf.merchant_admin_id, vtf.order_updated_cashier_id, vtf.order_updated_cashier_name, ROUND(vtf.version+1,1) as version, vtf.supplier_tax_id, vtf.merchant_currency_code, vtf.merchant_price, vtf.merchant_net_price, vtf.merchant_tax_id, vtf.admin_currency_code from (select fvt.* from visitor_tickets fvt join (select vt_group_no, transaction_id,row_type, max(version) as version from visitor_tickets where ticketId in (23623) and vt_group_no in (173211444753171) and col2 != '2' group by vt_group_no, transaction_id, row_type) as mv on mv.vt_group_no = fvt.vt_group_no and fvt.transaction_id = mv.transaction_id and fvt.row_type = mv.row_type and ABS(fvt.version-mv.version) = '0' where fvt.col2 != '2') vtf left join (select vtt.vt_group_no as ddd_vt_group_no, vtt.transaction_id as ddd_transaction_id, vtt.version as ddd_version,vtt.row_type as ddd_row_type,vtt.partner_net_price as ddd_partner_net_price,ROUND((final.salePrice*final.percentage_commission/100),2) as ddd_should_be_net, vtt.partner_gross_price as ddd_partner_gross_price,vtt.tax_value as ddd_tax_value, FORMAT(ROUND((final.salePrice*final.percentage_commission/100),2),2)*(100+vtt.tax_value)/100 as ddd_gross_should_be, vtt.supplier_net_price as ddd_supplier_bet_price, vtt.supplier_gross_price as ddd_supplier_gross_price,vtt.supplier_tax_value as ddd_supplier_tax, vtt.action_performed as dd_action_performed, concat(vtt.action_performed, ', EECommission') as dd_action_performed_should_be from visitor_tickets vtt join (SELECT
        vt_group_no,
        transaction_id,
        hotel_id, channel_id, ticketId, ticketpriceschedule_id, version, row_type, partner_net_price,salePrice, (case when row_type = '2' and tlc_ticketpriceschedule_id is not NULL then tlc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_res_per 
        when row_type = '3' and tlc_ticketpriceschedule_id is not NULL then tlc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_dist_per
        when row_type = '4' and tlc_ticketpriceschedule_id is not NULL then tlc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_hgs_per when row_type = '1' then '100.00' else 'No_Setting_found' end) as percentage_commission,
        case when tlc_ticketpriceschedule_id is not NULL then tlc_comm_on_sale when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_comm_on_sale when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_comm_on_sale else 'No_Setting_found' end as commission_on_sale
FROM
    (
    SELECT
        scdata.*,
        '----Price List Level---' AS type3,
        pl.ticketpriceschedule_id AS clc_ticketpriceschedule_id,
        pl.hotel_prepaid_commission_percentage as pl_dist_per,
        pl.hgs_prepaid_commission_percentage as pl_hgs_per,
        pl.merchant_fee_percentage as pl_mer_per,
        pl.resale_percentage as pl_res_per,
        pl.commission_on_sale_price as pl_comm_on_sale
FROM
    (
    SELECT
        tlcdata.*,
        '----Sub catalog Level---' AS type2,
        sc.catalog_id,
        sc.ticketpriceschedule_id AS sc_ticketpriceschedule_id,
        sc.resale_currency_level AS sc_resale_currency_level,
        sc.hotel_prepaid_commission_percentage as sc_dist_per,
        sc.hgs_prepaid_commission_percentage as sc_hgs_per,
        sc.merchant_fee_percentage as sc_mer_per,
        sc.resale_percentage as sc_res_per,
        sc.commission_on_sale_price as sc_comm_on_sale        
FROM
    (
    SELECT
        vt.vt_group_no,
        CONCAT(vt.transaction_id, 'R') AS transaction_id,
        vt.order_confirm_date,
        vt.created_date,
        vt.hotel_id,
        vt.channel_id,
        vt.ticketId,
        vt.ticketpriceschedule_id,
        vt.version,
        vt.row_type,
        vt.partner_gross_price,
        vt.partner_net_price,
        maxversion.salePrice,
        vt.order_currency_partner_gross_price,
        vt.order_currency_partner_net_price,
        vt.supplier_gross_price,
        vt.supplier_net_price,
        vt.col2,
        qc.cod_id AS company_id,
        qc.channel_id AS company_pricelist_id,
        qc.sub_catalog_id AS company_sub_catalog,
        '---TLC LEVEL---' AS TYPE,
        tlc.ticketpriceschedule_id AS tlc_ticketpriceschedule_id,
        tlc.resale_currency_level,
        tlc.hotel_prepaid_commission_percentage as tlc_dist_per,
        tlc.hgs_prepaid_commission_percentage as tlc_hgs_per,
        tlc.merchant_fee_percentage as tlc_mer_per,
        tlc.resale_percentage as tlc_res_per,
        tlc.commission_on_sale_price as tlc_comm_on_sale
FROM
    visitor_tickets vt
JOIN(
    SELECT
        vt_group_no,
        transaction_id,
        row_type,
        max(case when row_type = '1' then partner_net_price else 0 end) as salePrice,
        MAX(VERSION) AS VERSION
    FROM
        visitor_tickets
    WHERE
        ticketId in (23623) and vt_group_no in (173211444753171) AND col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%'
    GROUP BY
        vt_group_no,
        transaction_id
) AS maxversion
ON
    vt.vt_group_no = maxversion.vt_group_no AND vt.transaction_id = maxversion.transaction_id AND ABS(vt.version - maxversion.version) = '0'
LEFT JOIN tmp.qr_codes qc
ON
    qc.cod_id = vt.hotel_id AND qc.cashier_type = '1'
LEFT JOIN tmp.ticket_level_commission tlc
ON
    tlc.hotel_id = vt.hotel_id AND tlc.ticketpriceschedule_id = vt.ticketpriceschedule_id AND tlc.ticket_id = vt.ticketId AND tlc.deleted = '0' AND tlc.is_adjust_pricing = '1'
WHERE
    vt.col2 != '2'
) AS tlcdata
LEFT JOIN tmp.channel_level_commission sc
ON
    tlcdata.ticketpriceschedule_id = sc.ticketpriceschedule_id AND tlcdata.ticketId = sc.ticket_id AND IF(
        tlcdata.company_sub_catalog = '0',
        122222,
        tlcdata.company_sub_catalog
    ) = sc.catalog_id AND sc.is_adjust_pricing = '1' AND sc.deleted = '0'
) AS scdata
LEFT JOIN tmp.channel_level_commission pl
ON
    scdata.ticketpriceschedule_id = pl.ticketpriceschedule_id AND scdata.ticketId = pl.ticket_id AND scdata.channel_id = pl.channel_id AND pl.catalog_id = '0' AND pl.is_adjust_pricing = '1' AND pl.deleted = '0'
) AS shouldbe) as final on vtt.vt_group_no = final.vt_group_no and ABS(vtt.version-final.version) = '0' and vtt.transaction_id = final.transaction_id and vtt.row_type = final.row_type where ABS(final.partner_net_price-(final.salePrice*final.percentage_commission/100)) > '0.02' and final.percentage_commission != 'No_Setting_found' and final.row_type != '1' and vtt.col2 != '2') as ddd on ddd.ddd_vt_group_no = vtf.vt_group_no and (ddd.ddd_transaction_id+1) = (vtf.transaction_id+1) and ABS(ddd.ddd_version - vtf.version) = '0' and vtf.row_type = ddd.ddd_row_type;SELECT ROW_COUNT();
------2024-11-25 18:48:22.211--------
insert into visitor_tickets (id, created_date, transaction_id, invoice_id, channel_id, channel_name, reseller_id, reseller_name, saledesk_id, saledesk_name, financial_id, financial_name, transaction_type_name, transaction_type_id, ticketId, shared_capacity_id, ticket_booking_id, related_order_id, related_booking_id, ticket_title, ticketwithdifferentpricing, ticketpriceschedule_id, ticket_extra_option_id, group_type_ticket, group_price, group_quantity, group_linked_with, selected_date, booking_selected_date, from_time, to_time, slot_type, amount_before_extra_discount, discount_before_extra_discount, hto_id, visitor_group_no, roomNo, nights, user_age, gender, user_image, visitor_country, merchantAccountCode, merchantReference, original_pspReference, shopperReference, partner_id, relational_partner_id, partner_name, museum_name, museum_id, hotel_name, hotel_id, pos_point_id, pos_point_name, shift_id, passNo, pass_type, ticketAmt, visit_date, visit_date_time, ticketType, tickettype_name, discount_applied_on_how_many_tickets, paid, payment_method, isBillToHotel, card_name, pspReference, card_type, captured, age_group, discount, isDiscountInPercent, updated_discount_type, without_elo_reference_no, debitor, creditor, split_cash_amount, split_card_amount, split_voucher_amount, split_direct_payment_amount, total_gross_commission, total_net_commission, commission_type, partner_gross_price, order_currency_partner_gross_price, partner_gross_price_without_combi_discount, partner_net_price, order_currency_partner_net_price, partner_net_price_without_combi_discount, isCommissionInPercent, tax_id, tax_value, tax_name, timezone, invoice_status, row_type, updated_by_id, updated_by_username, voucher_updated_by, voucher_updated_by_name, redeem_method, redeem_by_ticket_id, redeem_by_ticket_title, cashier_id, cashier_name, cashier_register_id, targetlocation, paymentMethodType, targetcity, service_name, adjustment_row_type, description, distributor_status, adyen_status, adjustment_method, all_ticket_ids, time_based_done, visitor_invoice_id, ticketPrice, deleted, is_refunded, is_block, is_edited, vt_group_no, user_name, issuer_country_code, distributor_commission_invoice, activation_method, is_prioticket, is_shop_product, shop_category_name, external_account_number, used, ticket_status, is_prepaid, is_purchased_with_postpaid, invoice_type, supplier_currency_symbol, order_currency_code, order_currency_symbol, currency_rate, invoice_variant, service_cost, service_cost_net_amount, service_cost_type, scanned_pass, groupTransactionId, booking_status, channel_type, is_voucher, extra_text_field_answer, distributor_type, distributor_partner_id, distributor_partner_name, issuer_country_name, chart_number, extra_discount, manual_payment_note, account_number, is_custom_setting, external_product_id, supplier_currency_code, col1, col2, partner_category_id, col4, partner_category_name, col6, col7, col8, is_data_moved, action_performed, updated_at, tp_payment_method, order_confirm_date, payment_date, order_cancellation_date, voucher_creation_date, primary_host_name,supplier_gross_price, supplier_discount, supplier_ticket_amt, supplier_tax_value,supplier_net_price, last_modified_at, market_merchant_id, merchant_admin_id, order_updated_cashier_id, order_updated_cashier_name, version, supplier_tax_id, merchant_currency_code, merchant_price, merchant_net_price, merchant_tax_id, admin_currency_code) select vtf.id, vtf.created_date, vtf.transaction_id, vtf.invoice_id, vtf.channel_id, vtf.channel_name, vtf.reseller_id, vtf.reseller_name, vtf.saledesk_id, vtf.saledesk_name, vtf.financial_id, vtf.financial_name, vtf.transaction_type_name, vtf.transaction_type_id, vtf.ticketId, vtf.shared_capacity_id, vtf.ticket_booking_id, vtf.related_order_id, vtf.related_booking_id, vtf.ticket_title, vtf.ticketwithdifferentpricing, vtf.ticketpriceschedule_id, vtf.ticket_extra_option_id, vtf.group_type_ticket, vtf.group_price, vtf.group_quantity, vtf.group_linked_with, vtf.selected_date, vtf.booking_selected_date, vtf.from_time, vtf.to_time, vtf.slot_type, vtf.amount_before_extra_discount, vtf.discount_before_extra_discount, vtf.hto_id, vtf.visitor_group_no, vtf.roomNo, vtf.nights, vtf.user_age, vtf.gender, vtf.user_image, vtf.visitor_country, vtf.merchantAccountCode, vtf.merchantReference, vtf.original_pspReference, vtf.shopperReference, vtf.partner_id, vtf.relational_partner_id, vtf.partner_name, vtf.museum_name, vtf.museum_id, vtf.hotel_name, vtf.hotel_id, vtf.pos_point_id, vtf.pos_point_name, vtf.shift_id, vtf.passNo, vtf.pass_type, vtf.ticketAmt, vtf.visit_date, vtf.visit_date_time, vtf.ticketType, vtf.tickettype_name, vtf.discount_applied_on_how_many_tickets, vtf.paid, vtf.payment_method, vtf.isBillToHotel, vtf.card_name, vtf.pspReference, vtf.card_type, vtf.captured, vtf.age_group, vtf.discount, vtf.isDiscountInPercent, vtf.updated_discount_type, vtf.without_elo_reference_no, vtf.debitor, vtf.creditor, vtf.split_cash_amount, vtf.split_card_amount, vtf.split_voucher_amount, vtf.split_direct_payment_amount, vtf.total_gross_commission, vtf.total_net_commission, vtf.commission_type, (case when vtf.row_type = ddd.ddd_row_type then ROUND(ddd.ddd_gross_should_be,2) else ROUND(vtf.partner_gross_price,2) end) as partner_gross_price, vtf.order_currency_partner_gross_price, vtf.partner_gross_price_without_combi_discount, (case when vtf.row_type = ddd.ddd_row_type then ROUND(ddd.ddd_should_be_net,2) else ROUND(vtf.partner_net_price,2) end) as partner_net_price, vtf.order_currency_partner_net_price, vtf.partner_net_price_without_combi_discount, vtf.isCommissionInPercent, vtf.tax_id, vtf.tax_value, vtf.tax_name, vtf.timezone, vtf.invoice_status, vtf.row_type, vtf.updated_by_id, vtf.updated_by_username, vtf.voucher_updated_by, vtf.voucher_updated_by_name, vtf.redeem_method, vtf.redeem_by_ticket_id, vtf.redeem_by_ticket_title, vtf.cashier_id, vtf.cashier_name, vtf.cashier_register_id, vtf.targetlocation, vtf.paymentMethodType, vtf.targetcity, vtf.service_name, vtf.adjustment_row_type, vtf.description, vtf.distributor_status, vtf.adyen_status, vtf.adjustment_method, vtf.all_ticket_ids, vtf.time_based_done, vtf.visitor_invoice_id, vtf.ticketPrice, vtf.deleted, vtf.is_refunded, vtf.is_block, vtf.is_edited, vtf.vt_group_no, vtf.user_name, vtf.issuer_country_code, vtf.distributor_commission_invoice, vtf.activation_method, vtf.is_prioticket, vtf.is_shop_product, vtf.shop_category_name, vtf.external_account_number, vtf.used, vtf.ticket_status, vtf.is_prepaid, vtf.is_purchased_with_postpaid, vtf.invoice_type, vtf.supplier_currency_symbol, vtf.order_currency_code, vtf.order_currency_symbol, vtf.currency_rate, vtf.invoice_variant, vtf.service_cost, vtf.service_cost_net_amount, vtf.service_cost_type, vtf.scanned_pass, vtf.groupTransactionId, vtf.booking_status, vtf.channel_type, vtf.is_voucher, vtf.extra_text_field_answer, vtf.distributor_type, vtf.distributor_partner_id, vtf.distributor_partner_name, vtf.issuer_country_name, vtf.chart_number, vtf.extra_discount, vtf.manual_payment_note, vtf.account_number, vtf.is_custom_setting, vtf.external_product_id, vtf.supplier_currency_code, vtf.col1, vtf.col2, vtf.partner_category_id, vtf.col4, vtf.partner_category_name, vtf.col6, vtf.col7, vtf.col8, vtf.is_data_moved,concat(vtf.action_performed, ', EECommission') as action_performed, vtf.updated_at, vtf.tp_payment_method, vtf.order_confirm_date, vtf.payment_date, vtf.order_cancellation_date, vtf.voucher_creation_date, vtf.primary_host_name,supplier_gross_price, vtf.supplier_discount, vtf.supplier_ticket_amt, vtf.supplier_tax_value, supplier_net_price, CURRENT_TIMESTAMP as last_modified_at, vtf.market_merchant_id, vtf.merchant_admin_id, vtf.order_updated_cashier_id, vtf.order_updated_cashier_name, ROUND(vtf.version+1,1) as version, vtf.supplier_tax_id, vtf.merchant_currency_code, vtf.merchant_price, vtf.merchant_net_price, vtf.merchant_tax_id, vtf.admin_currency_code from (select fvt.* from visitor_tickets fvt join (select vt_group_no, transaction_id,row_type, max(version) as version from visitor_tickets where ticketId in (23621) and vt_group_no in (173077058055605) and col2 != '2' group by vt_group_no, transaction_id, row_type) as mv on mv.vt_group_no = fvt.vt_group_no and fvt.transaction_id = mv.transaction_id and fvt.row_type = mv.row_type and ABS(fvt.version-mv.version) = '0' where fvt.col2 != '2') vtf left join (select vtt.vt_group_no as ddd_vt_group_no, vtt.transaction_id as ddd_transaction_id, vtt.version as ddd_version,vtt.row_type as ddd_row_type,vtt.partner_net_price as ddd_partner_net_price,ROUND((final.salePrice*final.percentage_commission/100),2) as ddd_should_be_net, vtt.partner_gross_price as ddd_partner_gross_price,vtt.tax_value as ddd_tax_value, FORMAT(ROUND((final.salePrice*final.percentage_commission/100),2),2)*(100+vtt.tax_value)/100 as ddd_gross_should_be, vtt.supplier_net_price as ddd_supplier_bet_price, vtt.supplier_gross_price as ddd_supplier_gross_price,vtt.supplier_tax_value as ddd_supplier_tax, vtt.action_performed as dd_action_performed, concat(vtt.action_performed, ', EECommission') as dd_action_performed_should_be from visitor_tickets vtt join (SELECT
        vt_group_no,
        transaction_id,
        hotel_id, channel_id, ticketId, ticketpriceschedule_id, version, row_type, partner_net_price,salePrice, (case when row_type = '2' and tlc_ticketpriceschedule_id is not NULL then tlc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_res_per 
        when row_type = '3' and tlc_ticketpriceschedule_id is not NULL then tlc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_dist_per
        when row_type = '4' and tlc_ticketpriceschedule_id is not NULL then tlc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_hgs_per when row_type = '1' then '100.00' else 'No_Setting_found' end) as percentage_commission,
        case when tlc_ticketpriceschedule_id is not NULL then tlc_comm_on_sale when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_comm_on_sale when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_comm_on_sale else 'No_Setting_found' end as commission_on_sale
FROM
    (
    SELECT
        scdata.*,
        '----Price List Level---' AS type3,
        pl.ticketpriceschedule_id AS clc_ticketpriceschedule_id,
        pl.hotel_prepaid_commission_percentage as pl_dist_per,
        pl.hgs_prepaid_commission_percentage as pl_hgs_per,
        pl.merchant_fee_percentage as pl_mer_per,
        pl.resale_percentage as pl_res_per,
        pl.commission_on_sale_price as pl_comm_on_sale
FROM
    (
    SELECT
        tlcdata.*,
        '----Sub catalog Level---' AS type2,
        sc.catalog_id,
        sc.ticketpriceschedule_id AS sc_ticketpriceschedule_id,
        sc.resale_currency_level AS sc_resale_currency_level,
        sc.hotel_prepaid_commission_percentage as sc_dist_per,
        sc.hgs_prepaid_commission_percentage as sc_hgs_per,
        sc.merchant_fee_percentage as sc_mer_per,
        sc.resale_percentage as sc_res_per,
        sc.commission_on_sale_price as sc_comm_on_sale        
FROM
    (
    SELECT
        vt.vt_group_no,
        CONCAT(vt.transaction_id, 'R') AS transaction_id,
        vt.order_confirm_date,
        vt.created_date,
        vt.hotel_id,
        vt.channel_id,
        vt.ticketId,
        vt.ticketpriceschedule_id,
        vt.version,
        vt.row_type,
        vt.partner_gross_price,
        vt.partner_net_price,
        maxversion.salePrice,
        vt.order_currency_partner_gross_price,
        vt.order_currency_partner_net_price,
        vt.supplier_gross_price,
        vt.supplier_net_price,
        vt.col2,
        qc.cod_id AS company_id,
        qc.channel_id AS company_pricelist_id,
        qc.sub_catalog_id AS company_sub_catalog,
        '---TLC LEVEL---' AS TYPE,
        tlc.ticketpriceschedule_id AS tlc_ticketpriceschedule_id,
        tlc.resale_currency_level,
        tlc.hotel_prepaid_commission_percentage as tlc_dist_per,
        tlc.hgs_prepaid_commission_percentage as tlc_hgs_per,
        tlc.merchant_fee_percentage as tlc_mer_per,
        tlc.resale_percentage as tlc_res_per,
        tlc.commission_on_sale_price as tlc_comm_on_sale
FROM
    visitor_tickets vt
JOIN(
    SELECT
        vt_group_no,
        transaction_id,
        row_type,
        max(case when row_type = '1' then partner_net_price else 0 end) as salePrice,
        MAX(VERSION) AS VERSION
    FROM
        visitor_tickets
    WHERE
        ticketId in (23621) and vt_group_no in (173077058055605) AND col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%'
    GROUP BY
        vt_group_no,
        transaction_id
) AS maxversion
ON
    vt.vt_group_no = maxversion.vt_group_no AND vt.transaction_id = maxversion.transaction_id AND ABS(vt.version - maxversion.version) = '0'
LEFT JOIN tmp.qr_codes qc
ON
    qc.cod_id = vt.hotel_id AND qc.cashier_type = '1'
LEFT JOIN tmp.ticket_level_commission tlc
ON
    tlc.hotel_id = vt.hotel_id AND tlc.ticketpriceschedule_id = vt.ticketpriceschedule_id AND tlc.ticket_id = vt.ticketId AND tlc.deleted = '0' AND tlc.is_adjust_pricing = '1'
WHERE
    vt.col2 != '2'
) AS tlcdata
LEFT JOIN tmp.channel_level_commission sc
ON
    tlcdata.ticketpriceschedule_id = sc.ticketpriceschedule_id AND tlcdata.ticketId = sc.ticket_id AND IF(
        tlcdata.company_sub_catalog = '0',
        122222,
        tlcdata.company_sub_catalog
    ) = sc.catalog_id AND sc.is_adjust_pricing = '1' AND sc.deleted = '0'
) AS scdata
LEFT JOIN tmp.channel_level_commission pl
ON
    scdata.ticketpriceschedule_id = pl.ticketpriceschedule_id AND scdata.ticketId = pl.ticket_id AND scdata.channel_id = pl.channel_id AND pl.catalog_id = '0' AND pl.is_adjust_pricing = '1' AND pl.deleted = '0'
) AS shouldbe) as final on vtt.vt_group_no = final.vt_group_no and ABS(vtt.version-final.version) = '0' and vtt.transaction_id = final.transaction_id and vtt.row_type = final.row_type where ABS(final.partner_net_price-(final.salePrice*final.percentage_commission/100)) > '0.02' and final.percentage_commission != 'No_Setting_found' and final.row_type != '1' and vtt.col2 != '2') as ddd on ddd.ddd_vt_group_no = vtf.vt_group_no and (ddd.ddd_transaction_id+1) = (vtf.transaction_id+1) and ABS(ddd.ddd_version - vtf.version) = '0' and vtf.row_type = ddd.ddd_row_type;SELECT ROW_COUNT();
------2024-11-25 18:48:37.609--------
insert into visitor_tickets (id, created_date, transaction_id, invoice_id, channel_id, channel_name, reseller_id, reseller_name, saledesk_id, saledesk_name, financial_id, financial_name, transaction_type_name, transaction_type_id, ticketId, shared_capacity_id, ticket_booking_id, related_order_id, related_booking_id, ticket_title, ticketwithdifferentpricing, ticketpriceschedule_id, ticket_extra_option_id, group_type_ticket, group_price, group_quantity, group_linked_with, selected_date, booking_selected_date, from_time, to_time, slot_type, amount_before_extra_discount, discount_before_extra_discount, hto_id, visitor_group_no, roomNo, nights, user_age, gender, user_image, visitor_country, merchantAccountCode, merchantReference, original_pspReference, shopperReference, partner_id, relational_partner_id, partner_name, museum_name, museum_id, hotel_name, hotel_id, pos_point_id, pos_point_name, shift_id, passNo, pass_type, ticketAmt, visit_date, visit_date_time, ticketType, tickettype_name, discount_applied_on_how_many_tickets, paid, payment_method, isBillToHotel, card_name, pspReference, card_type, captured, age_group, discount, isDiscountInPercent, updated_discount_type, without_elo_reference_no, debitor, creditor, split_cash_amount, split_card_amount, split_voucher_amount, split_direct_payment_amount, total_gross_commission, total_net_commission, commission_type, partner_gross_price, order_currency_partner_gross_price, partner_gross_price_without_combi_discount, partner_net_price, order_currency_partner_net_price, partner_net_price_without_combi_discount, isCommissionInPercent, tax_id, tax_value, tax_name, timezone, invoice_status, row_type, updated_by_id, updated_by_username, voucher_updated_by, voucher_updated_by_name, redeem_method, redeem_by_ticket_id, redeem_by_ticket_title, cashier_id, cashier_name, cashier_register_id, targetlocation, paymentMethodType, targetcity, service_name, adjustment_row_type, description, distributor_status, adyen_status, adjustment_method, all_ticket_ids, time_based_done, visitor_invoice_id, ticketPrice, deleted, is_refunded, is_block, is_edited, vt_group_no, user_name, issuer_country_code, distributor_commission_invoice, activation_method, is_prioticket, is_shop_product, shop_category_name, external_account_number, used, ticket_status, is_prepaid, is_purchased_with_postpaid, invoice_type, supplier_currency_symbol, order_currency_code, order_currency_symbol, currency_rate, invoice_variant, service_cost, service_cost_net_amount, service_cost_type, scanned_pass, groupTransactionId, booking_status, channel_type, is_voucher, extra_text_field_answer, distributor_type, distributor_partner_id, distributor_partner_name, issuer_country_name, chart_number, extra_discount, manual_payment_note, account_number, is_custom_setting, external_product_id, supplier_currency_code, col1, col2, partner_category_id, col4, partner_category_name, col6, col7, col8, is_data_moved, action_performed, updated_at, tp_payment_method, order_confirm_date, payment_date, order_cancellation_date, voucher_creation_date, primary_host_name,supplier_gross_price, supplier_discount, supplier_ticket_amt, supplier_tax_value,supplier_net_price, last_modified_at, market_merchant_id, merchant_admin_id, order_updated_cashier_id, order_updated_cashier_name, version, supplier_tax_id, merchant_currency_code, merchant_price, merchant_net_price, merchant_tax_id, admin_currency_code) select vtf.id, vtf.created_date, vtf.transaction_id, vtf.invoice_id, vtf.channel_id, vtf.channel_name, vtf.reseller_id, vtf.reseller_name, vtf.saledesk_id, vtf.saledesk_name, vtf.financial_id, vtf.financial_name, vtf.transaction_type_name, vtf.transaction_type_id, vtf.ticketId, vtf.shared_capacity_id, vtf.ticket_booking_id, vtf.related_order_id, vtf.related_booking_id, vtf.ticket_title, vtf.ticketwithdifferentpricing, vtf.ticketpriceschedule_id, vtf.ticket_extra_option_id, vtf.group_type_ticket, vtf.group_price, vtf.group_quantity, vtf.group_linked_with, vtf.selected_date, vtf.booking_selected_date, vtf.from_time, vtf.to_time, vtf.slot_type, vtf.amount_before_extra_discount, vtf.discount_before_extra_discount, vtf.hto_id, vtf.visitor_group_no, vtf.roomNo, vtf.nights, vtf.user_age, vtf.gender, vtf.user_image, vtf.visitor_country, vtf.merchantAccountCode, vtf.merchantReference, vtf.original_pspReference, vtf.shopperReference, vtf.partner_id, vtf.relational_partner_id, vtf.partner_name, vtf.museum_name, vtf.museum_id, vtf.hotel_name, vtf.hotel_id, vtf.pos_point_id, vtf.pos_point_name, vtf.shift_id, vtf.passNo, vtf.pass_type, vtf.ticketAmt, vtf.visit_date, vtf.visit_date_time, vtf.ticketType, vtf.tickettype_name, vtf.discount_applied_on_how_many_tickets, vtf.paid, vtf.payment_method, vtf.isBillToHotel, vtf.card_name, vtf.pspReference, vtf.card_type, vtf.captured, vtf.age_group, vtf.discount, vtf.isDiscountInPercent, vtf.updated_discount_type, vtf.without_elo_reference_no, vtf.debitor, vtf.creditor, vtf.split_cash_amount, vtf.split_card_amount, vtf.split_voucher_amount, vtf.split_direct_payment_amount, vtf.total_gross_commission, vtf.total_net_commission, vtf.commission_type, (case when vtf.row_type = ddd.ddd_row_type then ROUND(ddd.ddd_gross_should_be,2) else ROUND(vtf.partner_gross_price,2) end) as partner_gross_price, vtf.order_currency_partner_gross_price, vtf.partner_gross_price_without_combi_discount, (case when vtf.row_type = ddd.ddd_row_type then ROUND(ddd.ddd_should_be_net,2) else ROUND(vtf.partner_net_price,2) end) as partner_net_price, vtf.order_currency_partner_net_price, vtf.partner_net_price_without_combi_discount, vtf.isCommissionInPercent, vtf.tax_id, vtf.tax_value, vtf.tax_name, vtf.timezone, vtf.invoice_status, vtf.row_type, vtf.updated_by_id, vtf.updated_by_username, vtf.voucher_updated_by, vtf.voucher_updated_by_name, vtf.redeem_method, vtf.redeem_by_ticket_id, vtf.redeem_by_ticket_title, vtf.cashier_id, vtf.cashier_name, vtf.cashier_register_id, vtf.targetlocation, vtf.paymentMethodType, vtf.targetcity, vtf.service_name, vtf.adjustment_row_type, vtf.description, vtf.distributor_status, vtf.adyen_status, vtf.adjustment_method, vtf.all_ticket_ids, vtf.time_based_done, vtf.visitor_invoice_id, vtf.ticketPrice, vtf.deleted, vtf.is_refunded, vtf.is_block, vtf.is_edited, vtf.vt_group_no, vtf.user_name, vtf.issuer_country_code, vtf.distributor_commission_invoice, vtf.activation_method, vtf.is_prioticket, vtf.is_shop_product, vtf.shop_category_name, vtf.external_account_number, vtf.used, vtf.ticket_status, vtf.is_prepaid, vtf.is_purchased_with_postpaid, vtf.invoice_type, vtf.supplier_currency_symbol, vtf.order_currency_code, vtf.order_currency_symbol, vtf.currency_rate, vtf.invoice_variant, vtf.service_cost, vtf.service_cost_net_amount, vtf.service_cost_type, vtf.scanned_pass, vtf.groupTransactionId, vtf.booking_status, vtf.channel_type, vtf.is_voucher, vtf.extra_text_field_answer, vtf.distributor_type, vtf.distributor_partner_id, vtf.distributor_partner_name, vtf.issuer_country_name, vtf.chart_number, vtf.extra_discount, vtf.manual_payment_note, vtf.account_number, vtf.is_custom_setting, vtf.external_product_id, vtf.supplier_currency_code, vtf.col1, vtf.col2, vtf.partner_category_id, vtf.col4, vtf.partner_category_name, vtf.col6, vtf.col7, vtf.col8, vtf.is_data_moved,concat(vtf.action_performed, ', EECommission') as action_performed, vtf.updated_at, vtf.tp_payment_method, vtf.order_confirm_date, vtf.payment_date, vtf.order_cancellation_date, vtf.voucher_creation_date, vtf.primary_host_name,supplier_gross_price, vtf.supplier_discount, vtf.supplier_ticket_amt, vtf.supplier_tax_value, supplier_net_price, CURRENT_TIMESTAMP as last_modified_at, vtf.market_merchant_id, vtf.merchant_admin_id, vtf.order_updated_cashier_id, vtf.order_updated_cashier_name, ROUND(vtf.version+1,1) as version, vtf.supplier_tax_id, vtf.merchant_currency_code, vtf.merchant_price, vtf.merchant_net_price, vtf.merchant_tax_id, vtf.admin_currency_code from (select fvt.* from visitor_tickets fvt join (select vt_group_no, transaction_id,row_type, max(version) as version from visitor_tickets where ticketId in (14120) and vt_group_no in (172987384434171) and col2 != '2' group by vt_group_no, transaction_id, row_type) as mv on mv.vt_group_no = fvt.vt_group_no and fvt.transaction_id = mv.transaction_id and fvt.row_type = mv.row_type and ABS(fvt.version-mv.version) = '0' where fvt.col2 != '2') vtf left join (select vtt.vt_group_no as ddd_vt_group_no, vtt.transaction_id as ddd_transaction_id, vtt.version as ddd_version,vtt.row_type as ddd_row_type,vtt.partner_net_price as ddd_partner_net_price,ROUND((final.salePrice*final.percentage_commission/100),2) as ddd_should_be_net, vtt.partner_gross_price as ddd_partner_gross_price,vtt.tax_value as ddd_tax_value, FORMAT(ROUND((final.salePrice*final.percentage_commission/100),2),2)*(100+vtt.tax_value)/100 as ddd_gross_should_be, vtt.supplier_net_price as ddd_supplier_bet_price, vtt.supplier_gross_price as ddd_supplier_gross_price,vtt.supplier_tax_value as ddd_supplier_tax, vtt.action_performed as dd_action_performed, concat(vtt.action_performed, ', EECommission') as dd_action_performed_should_be from visitor_tickets vtt join (SELECT
        vt_group_no,
        transaction_id,
        hotel_id, channel_id, ticketId, ticketpriceschedule_id, version, row_type, partner_net_price,salePrice, (case when row_type = '2' and tlc_ticketpriceschedule_id is not NULL then tlc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_res_per 
        when row_type = '3' and tlc_ticketpriceschedule_id is not NULL then tlc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_dist_per
        when row_type = '4' and tlc_ticketpriceschedule_id is not NULL then tlc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_hgs_per when row_type = '1' then '100.00' else 'No_Setting_found' end) as percentage_commission,
        case when tlc_ticketpriceschedule_id is not NULL then tlc_comm_on_sale when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_comm_on_sale when tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_comm_on_sale else 'No_Setting_found' end as commission_on_sale
FROM
    (
    SELECT
        scdata.*,
        '----Price List Level---' AS type3,
        pl.ticketpriceschedule_id AS clc_ticketpriceschedule_id,
        pl.hotel_prepaid_commission_percentage as pl_dist_per,
        pl.hgs_prepaid_commission_percentage as pl_hgs_per,
        pl.merchant_fee_percentage as pl_mer_per,
        pl.resale_percentage as pl_res_per,
        pl.commission_on_sale_price as pl_comm_on_sale
FROM
    (
    SELECT
        tlcdata.*,
        '----Sub catalog Level---' AS type2,
        sc.catalog_id,
        sc.ticketpriceschedule_id AS sc_ticketpriceschedule_id,
        sc.resale_currency_level AS sc_resale_currency_level,
        sc.hotel_prepaid_commission_percentage as sc_dist_per,
        sc.hgs_prepaid_commission_percentage as sc_hgs_per,
        sc.merchant_fee_percentage as sc_mer_per,
        sc.resale_percentage as sc_res_per,
        sc.commission_on_sale_price as sc_comm_on_sale        
FROM
    (
    SELECT
        vt.vt_group_no,
        CONCAT(vt.transaction_id, 'R') AS transaction_id,
        vt.order_confirm_date,
        vt.created_date,
        vt.hotel_id,
        vt.channel_id,
        vt.ticketId,
        vt.ticketpriceschedule_id,
        vt.version,
        vt.row_type,
        vt.partner_gross_price,
        vt.partner_net_price,
        maxversion.salePrice,
        vt.order_currency_partner_gross_price,
        vt.order_currency_partner_net_price,
        vt.supplier_gross_price,
        vt.supplier_net_price,
        vt.col2,
        qc.cod_id AS company_id,
        qc.channel_id AS company_pricelist_id,
        qc.sub_catalog_id AS company_sub_catalog,
        '---TLC LEVEL---' AS TYPE,
        tlc.ticketpriceschedule_id AS tlc_ticketpriceschedule_id,
        tlc.resale_currency_level,
        tlc.hotel_prepaid_commission_percentage as tlc_dist_per,
        tlc.hgs_prepaid_commission_percentage as tlc_hgs_per,
        tlc.merchant_fee_percentage as tlc_mer_per,
        tlc.resale_percentage as tlc_res_per,
        tlc.commission_on_sale_price as tlc_comm_on_sale
FROM
    visitor_tickets vt
JOIN(
    SELECT
        vt_group_no,
        transaction_id,
        row_type,
        max(case when row_type = '1' then partner_net_price else 0 end) as salePrice,
        MAX(VERSION) AS VERSION
    FROM
        visitor_tickets
    WHERE
        ticketId in (14120) and vt_group_no in (172987384434171) AND col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%'
    GROUP BY
        vt_group_no,
        transaction_id
) AS maxversion
ON
    vt.vt_group_no = maxversion.vt_group_no AND vt.transaction_id = maxversion.transaction_id AND ABS(vt.version - maxversion.version) = '0'
LEFT JOIN tmp.qr_codes qc
ON
    qc.cod_id = vt.hotel_id AND qc.cashier_type = '1'
LEFT JOIN tmp.ticket_level_commission tlc
ON
    tlc.hotel_id = vt.hotel_id AND tlc.ticketpriceschedule_id = vt.ticketpriceschedule_id AND tlc.ticket_id = vt.ticketId AND tlc.deleted = '0' AND tlc.is_adjust_pricing = '1'
WHERE
    vt.col2 != '2'
) AS tlcdata
LEFT JOIN tmp.channel_level_commission sc
ON
    tlcdata.ticketpriceschedule_id = sc.ticketpriceschedule_id AND tlcdata.ticketId = sc.ticket_id AND IF(
        tlcdata.company_sub_catalog = '0',
        122222,
        tlcdata.company_sub_catalog
    ) = sc.catalog_id AND sc.is_adjust_pricing = '1' AND sc.deleted = '0'
) AS scdata
LEFT JOIN tmp.channel_level_commission pl
ON
    scdata.ticketpriceschedule_id = pl.ticketpriceschedule_id AND scdata.ticketId = pl.ticket_id AND scdata.channel_id = pl.channel_id AND pl.catalog_id = '0' AND pl.is_adjust_pricing = '1' AND pl.deleted = '0'
) AS shouldbe) as final on vtt.vt_group_no = final.vt_group_no and ABS(vtt.version-final.version) = '0' and vtt.transaction_id = final.transaction_id and vtt.row_type = final.row_type where ABS(final.partner_net_price-(final.salePrice*final.percentage_commission/100)) > '0.02' and final.percentage_commission != 'No_Setting_found' and final.row_type != '1' and vtt.col2 != '2') as ddd on ddd.ddd_vt_group_no = vtf.vt_group_no and (ddd.ddd_transaction_id+1) = (vtf.transaction_id+1) and ABS(ddd.ddd_version - vtf.version) = '0' and vtf.row_type = ddd.ddd_row_type;SELECT ROW_COUNT();
