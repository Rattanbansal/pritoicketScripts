SELECT
    IFNULL(TRIM(TRAILING ',' FROM GROUP_CONCAT(DISTINCT(final.vt_group_no))), '') as order_id
FROM
    (
    SELECT
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
        ticketId = '$ticket_id' and vt_group_no IN($batch_str) AND col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%'
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
) AS shouldbe
) AS final where percentage_commission != 'No_Setting_found' and ABS(partner_net_price-(salePrice*percentage_commission/100)) > '0.02'








----------------Insert query----------------

insert into visitor_tickets (id, created_date, transaction_id, invoice_id, channel_id, channel_name, reseller_id, reseller_name, saledesk_id, saledesk_name, financial_id, financial_name, transaction_type_name, transaction_type_id, ticketId, shared_capacity_id, ticket_booking_id, related_order_id, related_booking_id, ticket_title, ticketwithdifferentpricing, ticketpriceschedule_id, ticket_extra_option_id, group_type_ticket, group_price, group_quantity, group_linked_with, selected_date, booking_selected_date, from_time, to_time, slot_type, amount_before_extra_discount, discount_before_extra_discount, hto_id, visitor_group_no, roomNo, nights, user_age, gender, user_image, visitor_country, merchantAccountCode, merchantReference, original_pspReference, shopperReference, partner_id, relational_partner_id, partner_name, museum_name, museum_id, hotel_name, hotel_id, pos_point_id, pos_point_name, shift_id, passNo, pass_type, ticketAmt, visit_date, visit_date_time, ticketType, tickettype_name, discount_applied_on_how_many_tickets, paid, payment_method, isBillToHotel, card_name, pspReference, card_type, captured, age_group, discount, isDiscountInPercent, updated_discount_type, without_elo_reference_no, debitor, creditor, split_cash_amount, split_card_amount, split_voucher_amount, split_direct_payment_amount, total_gross_commission, total_net_commission, commission_type, partner_gross_price, order_currency_partner_gross_price, partner_gross_price_without_combi_discount, partner_net_price, order_currency_partner_net_price, partner_net_price_without_combi_discount, isCommissionInPercent, tax_id, tax_value, tax_name, timezone, invoice_status, row_type, updated_by_id, updated_by_username, voucher_updated_by, voucher_updated_by_name, redeem_method, redeem_by_ticket_id, redeem_by_ticket_title, cashier_id, cashier_name, cashier_register_id, targetlocation, paymentMethodType, targetcity, service_name, adjustment_row_type, description, distributor_status, adyen_status, adjustment_method, all_ticket_ids, time_based_done, visitor_invoice_id, ticketPrice, deleted, is_refunded, is_block, is_edited, vt_group_no, user_name, issuer_country_code, distributor_commission_invoice, activation_method, is_prioticket, is_shop_product, shop_category_name, external_account_number, used, ticket_status, is_prepaid, is_purchased_with_postpaid, invoice_type, supplier_currency_symbol, order_currency_code, order_currency_symbol, currency_rate, invoice_variant, service_cost, service_cost_net_amount, service_cost_type, scanned_pass, groupTransactionId, booking_status, channel_type, is_voucher, extra_text_field_answer, distributor_type, distributor_partner_id, distributor_partner_name, issuer_country_name, chart_number, extra_discount, manual_payment_note, account_number, is_custom_setting, external_product_id, supplier_currency_code, col1, col2, partner_category_id, col4, partner_category_name, col6, col7, col8, is_data_moved, action_performed, updated_at, tp_payment_method, order_confirm_date, payment_date, order_cancellation_date, voucher_creation_date, primary_host_name,supplier_gross_price, supplier_discount, supplier_ticket_amt, supplier_tax_value,supplier_net_price, last_modified_at, market_merchant_id, merchant_admin_id, order_updated_cashier_id, order_updated_cashier_name, version, supplier_tax_id, merchant_currency_code, merchant_price, merchant_net_price, merchant_tax_id, admin_currency_code) select vtf.id, vtf.created_date, vtf.transaction_id, vtf.invoice_id, vtf.channel_id, vtf.channel_name, vtf.reseller_id, vtf.reseller_name, vtf.saledesk_id, vtf.saledesk_name, vtf.financial_id, vtf.financial_name, vtf.transaction_type_name, vtf.transaction_type_id, vtf.ticketId, vtf.shared_capacity_id, vtf.ticket_booking_id, vtf.related_order_id, vtf.related_booking_id, vtf.ticket_title, vtf.ticketwithdifferentpricing, vtf.ticketpriceschedule_id, vtf.ticket_extra_option_id, vtf.group_type_ticket, vtf.group_price, vtf.group_quantity, vtf.group_linked_with, vtf.selected_date, vtf.booking_selected_date, vtf.from_time, vtf.to_time, vtf.slot_type, vtf.amount_before_extra_discount, vtf.discount_before_extra_discount, vtf.hto_id, vtf.visitor_group_no, vtf.roomNo, vtf.nights, vtf.user_age, vtf.gender, vtf.user_image, vtf.visitor_country, vtf.merchantAccountCode, vtf.merchantReference, vtf.original_pspReference, vtf.shopperReference, vtf.partner_id, vtf.relational_partner_id, vtf.partner_name, vtf.museum_name, vtf.museum_id, vtf.hotel_name, vtf.hotel_id, vtf.pos_point_id, vtf.pos_point_name, vtf.shift_id, vtf.passNo, vtf.pass_type, vtf.ticketAmt, vtf.visit_date, vtf.visit_date_time, vtf.ticketType, vtf.tickettype_name, vtf.discount_applied_on_how_many_tickets, vtf.paid, vtf.payment_method, vtf.isBillToHotel, vtf.card_name, vtf.pspReference, vtf.card_type, vtf.captured, vtf.age_group, vtf.discount, vtf.isDiscountInPercent, vtf.updated_discount_type, vtf.without_elo_reference_no, vtf.debitor, vtf.creditor, vtf.split_cash_amount, vtf.split_card_amount, vtf.split_voucher_amount, vtf.split_direct_payment_amount, vtf.total_gross_commission, vtf.total_net_commission, vtf.commission_type, (case when vtf.row_type = ddd.ddd_row_type then ROUND(ddd.ddd_gross_should_be,2) else ROUND(vtf.partner_gross_price,2) end) as partner_gross_price, vtf.order_currency_partner_gross_price, vtf.partner_gross_price_without_combi_discount, (case when vtf.row_type = ddd.ddd_row_type then ROUND(ddd.ddd_should_be_net,2) else ROUND(vtf.partner_net_price,2) end) as partner_net_price, vtf.order_currency_partner_net_price, vtf.partner_net_price_without_combi_discount, vtf.isCommissionInPercent, vtf.tax_id, vtf.tax_value, vtf.tax_name, vtf.timezone, vtf.invoice_status, vtf.row_type, vtf.updated_by_id, vtf.updated_by_username, vtf.voucher_updated_by, vtf.voucher_updated_by_name, vtf.redeem_method, vtf.redeem_by_ticket_id, vtf.redeem_by_ticket_title, vtf.cashier_id, vtf.cashier_name, vtf.cashier_register_id, vtf.targetlocation, vtf.paymentMethodType, vtf.targetcity, vtf.service_name, vtf.adjustment_row_type, vtf.description, vtf.distributor_status, vtf.adyen_status, vtf.adjustment_method, vtf.all_ticket_ids, vtf.time_based_done, vtf.visitor_invoice_id, vtf.ticketPrice, vtf.deleted, vtf.is_refunded, vtf.is_block, vtf.is_edited, vtf.vt_group_no, vtf.user_name, vtf.issuer_country_code, vtf.distributor_commission_invoice, vtf.activation_method, vtf.is_prioticket, vtf.is_shop_product, vtf.shop_category_name, vtf.external_account_number, vtf.used, vtf.ticket_status, vtf.is_prepaid, vtf.is_purchased_with_postpaid, vtf.invoice_type, vtf.supplier_currency_symbol, vtf.order_currency_code, vtf.order_currency_symbol, vtf.currency_rate, vtf.invoice_variant, vtf.service_cost, vtf.service_cost_net_amount, vtf.service_cost_type, vtf.scanned_pass, vtf.groupTransactionId, vtf.booking_status, vtf.channel_type, vtf.is_voucher, vtf.extra_text_field_answer, vtf.distributor_type, vtf.distributor_partner_id, vtf.distributor_partner_name, vtf.issuer_country_name, vtf.chart_number, vtf.extra_discount, vtf.manual_payment_note, vtf.account_number, vtf.is_custom_setting, vtf.external_product_id, vtf.supplier_currency_code, vtf.col1, vtf.col2, vtf.partner_category_id, vtf.col4, vtf.partner_category_name, vtf.col6, vtf.col7, vtf.col8, vtf.is_data_moved,concat(vtf.action_performed, ', EECommission') as action_performed, vtf.updated_at, vtf.tp_payment_method, vtf.order_confirm_date, vtf.payment_date, vtf.order_cancellation_date, vtf.voucher_creation_date, vtf.primary_host_name,supplier_gross_price, vtf.supplier_discount, vtf.supplier_ticket_amt, vtf.supplier_tax_value, supplier_net_price, CURRENT_TIMESTAMP as last_modified_at, vtf.market_merchant_id, vtf.merchant_admin_id, vtf.order_updated_cashier_id, vtf.order_updated_cashier_name, ROUND(vtf.version+1,1) as version, vtf.supplier_tax_id, vtf.merchant_currency_code, vtf.merchant_price, vtf.merchant_net_price, vtf.merchant_tax_id, vtf.admin_currency_code from (select fvt.* from visitor_tickets fvt join (select vt_group_no, transaction_id,row_type, max(version) as version from visitor_tickets where ticketId in ($ticket_id) and vt_group_no in ($mismatchvgn) and col2 != '2' group by vt_group_no, transaction_id, row_type) as mv on mv.vt_group_no = fvt.vt_group_no and fvt.transaction_id = mv.transaction_id and fvt.row_type = mv.row_type and ABS(fvt.version-mv.version) = '0' where fvt.col2 != '2') vtf left join (select vtt.vt_group_no as ddd_vt_group_no, vtt.transaction_id as ddd_transaction_id, vtt.version as ddd_version,vtt.row_type as ddd_row_type,vtt.partner_net_price as ddd_partner_net_price, ROUND((final.salePrice*final.percentage_commission/100),2) as ddd_should_be_net, vtt.partner_gross_price as ddd_partner_gross_price,vtt.tax_value as ddd_tax_value, FORMAT(ROUND((final.salePrice*final.percentage_commission/100),2),2)*(100+vtt.tax_value)/100 as ddd_gross_should_be, vtt.supplier_net_price as ddd_supplier_bet_price, vtt.supplier_gross_price as ddd_supplier_gross_price,vtt.supplier_tax_value as ddd_supplier_tax, vtt.action_performed as dd_action_performed, concat(vtt.action_performed, ', EECommission') as dd_action_performed_should_be from visitor_tickets vtt join (SELECT
        vt_group_no,
        transaction_id,
        hotel_id, channel_id, ticketId, ticketpriceschedule_id, version, row_type, partner_net_price,salePrice, (case when row_type = '2' and tlc_ticketpriceschedule_id is not NULL then tlc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_res_per when row_type = '2' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_res_per 
        when row_type = '3' and tlc_ticketpriceschedule_id is not NULL then tlc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_dist_per when row_type = '3' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_dist_per
        when row_type = '4' and tlc_ticketpriceschedule_id is not NULL then tlc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is not NULL then sc_hgs_per when row_type = '4' and tlc_ticketpriceschedule_id is NULL and sc_ticketpriceschedule_id is NULL and clc_ticketpriceschedule_id is not NULL then pl_hgs_per when row_type = '1' then '100.00' else "No_Setting_found" end) as percentage_commission,
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
        ticketId in ($ticket_id) and vt_group_no in ($mismatchvgn) AND col2 != '2' and transaction_type_name not like '%Reprice Surcharge%' and transaction_type_name not like '%Reprice Discount%'
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
) AS shouldbe) as final on vtt.vt_group_no = final.vt_group_no and ABS(vtt.version-final.version) = '0' and vtt.transaction_id = final.transaction_id and vtt.row_type = final.row_type where ABS(final.partner_net_price-(final.salePrice*final.percentage_commission/100)) > '0.02' and final.percentage_commission != 'No_Setting_found' and final.row_type != '1' and vtt.col2 != '2') as ddd on ddd.ddd_vt_group_no = vtf.vt_group_no and (ddd.ddd_transaction_id+1) = (vtf.transaction_id+1) and ABS(ddd.ddd_version - vtf.version) = '0' and vtf.row_type = ddd.ddd_row_type;



--------- Combi Product_Insert Rows For VT------------

insert into visitor_tickets (id, created_date, transaction_id, invoice_id, channel_id, channel_name, reseller_id, reseller_name, saledesk_id, saledesk_name, financial_id, financial_name, transaction_type_name, transaction_type_id, ticketId, shared_capacity_id, ticket_booking_id, related_order_id, related_booking_id, ticket_title, ticketwithdifferentpricing, ticketpriceschedule_id, ticket_extra_option_id, group_type_ticket, group_price, group_quantity, group_linked_with, selected_date, booking_selected_date, from_time, to_time, slot_type, amount_before_extra_discount, discount_before_extra_discount, hto_id, visitor_group_no, roomNo, nights, user_age, gender, user_image, visitor_country, merchantAccountCode, merchantReference, original_pspReference, shopperReference, partner_id, relational_partner_id, partner_name, museum_name, museum_id, hotel_name, hotel_id, pos_point_id, pos_point_name, shift_id, passNo, pass_type, ticketAmt, visit_date, visit_date_time, ticketType, tickettype_name, discount_applied_on_how_many_tickets, paid, payment_method, isBillToHotel, card_name, pspReference, card_type, captured, age_group, discount, isDiscountInPercent, updated_discount_type, without_elo_reference_no, debitor, creditor, split_cash_amount, split_card_amount, split_voucher_amount, split_direct_payment_amount, total_gross_commission, total_net_commission, commission_type, partner_gross_price, order_currency_partner_gross_price, partner_gross_price_without_combi_discount, partner_net_price, order_currency_partner_net_price, partner_net_price_without_combi_discount, isCommissionInPercent, tax_id, tax_value, tax_name, timezone, invoice_status, row_type, updated_by_id, updated_by_username, voucher_updated_by, voucher_updated_by_name, redeem_method, redeem_by_ticket_id, redeem_by_ticket_title, cashier_id, cashier_name, cashier_register_id, targetlocation, paymentMethodType, targetcity, service_name, adjustment_row_type, description, distributor_status, adyen_status, adjustment_method, all_ticket_ids, time_based_done, visitor_invoice_id, ticketPrice, deleted, is_refunded, is_block, is_edited, vt_group_no, user_name, issuer_country_code, distributor_commission_invoice, activation_method, is_prioticket, is_shop_product, shop_category_name, external_account_number, used, ticket_status, is_prepaid, is_purchased_with_postpaid, invoice_type, supplier_currency_symbol, order_currency_code, order_currency_symbol, currency_rate, invoice_variant, service_cost, service_cost_net_amount, service_cost_type, scanned_pass, groupTransactionId, booking_status, channel_type, is_voucher, extra_text_field_answer, distributor_type, distributor_partner_id, distributor_partner_name, issuer_country_name, chart_number, extra_discount, manual_payment_note, account_number, is_custom_setting, external_product_id, supplier_currency_code, col1, col2, partner_category_id, col4, partner_category_name, col6, col7, col8, is_data_moved, action_performed, updated_at, tp_payment_method, order_confirm_date, payment_date, order_cancellation_date, voucher_creation_date, primary_host_name,supplier_gross_price, supplier_discount, supplier_ticket_amt, supplier_tax_value,supplier_net_price, last_modified_at, market_merchant_id, merchant_admin_id, order_updated_cashier_id, order_updated_cashier_name, version, supplier_tax_id, merchant_currency_code, merchant_price, merchant_net_price, merchant_tax_id, admin_currency_code) select vt.id, vt.created_date, vt.transaction_id, vt.invoice_id, vt.channel_id, vt.channel_name, vt.reseller_id, vt.reseller_name, vt.saledesk_id, vt.saledesk_name, vt.financial_id, vt.financial_name, vt.transaction_type_name, vt.transaction_type_id, vt.ticketId, vt.shared_capacity_id, vt.ticket_booking_id, vt.related_order_id, vt.related_booking_id, vt.ticket_title, vt.ticketwithdifferentpricing, vt.ticketpriceschedule_id, vt.ticket_extra_option_id, vt.group_type_ticket, vt.group_price, vt.group_quantity, vt.group_linked_with, vt.selected_date, vt.booking_selected_date, vt.from_time, vt.to_time, vt.slot_type, vt.amount_before_extra_discount, vt.discount_before_extra_discount, vt.hto_id, vt.visitor_group_no, vt.roomNo, vt.nights, vt.user_age, vt.gender, vt.user_image, vt.visitor_country, vt.merchantAccountCode, vt.merchantReference, vt.original_pspReference, vt.shopperReference, vt.partner_id, vt.relational_partner_id, vt.partner_name, vt.museum_name, vt.museum_id, vt.hotel_name, vt.hotel_id, vt.pos_point_id, vt.pos_point_name, vt.shift_id, vt.passNo, vt.pass_type, vt.ticketAmt, vt.visit_date, vt.visit_date_time, vt.ticketType, vt.tickettype_name, vt.discount_applied_on_how_many_tickets, vt.paid, vt.payment_method, vt.isBillToHotel, vt.card_name, vt.pspReference, vt.card_type, vt.captured, vt.age_group, vt.discount, vt.isDiscountInPercent, vt.updated_discount_type, vt.without_elo_reference_no, vt.debitor, vt.creditor, vt.split_cash_amount, vt.split_card_amount, vt.split_voucher_amount, vt.split_direct_payment_amount, vt.total_gross_commission, vt.total_net_commission, vt.commission_type,'0.00' as partner_gross_price, vt.order_currency_partner_gross_price, vt.partner_gross_price_without_combi_discount,'0.00' partner_net_price, vt.order_currency_partner_net_price, vt.partner_net_price_without_combi_discount, vt.isCommissionInPercent, vt.tax_id, vt.tax_value, vt.tax_name, vt.timezone, vt.invoice_status, vt.row_type, vt.updated_by_id, vt.updated_by_username, vt.voucher_updated_by, vt.voucher_updated_by_name, vt.redeem_method, vt.redeem_by_ticket_id, vt.redeem_by_ticket_title, vt.cashier_id, vt.cashier_name, vt.cashier_register_id, vt.targetlocation, vt.paymentMethodType, vt.targetcity, vt.service_name, vt.adjustment_row_type, vt.description, vt.distributor_status, vt.adyen_status, vt.adjustment_method, vt.all_ticket_ids, vt.time_based_done, vt.visitor_invoice_id, vt.ticketPrice, vt.deleted, vt.is_refunded, vt.is_block, vt.is_edited, vt.vt_group_no, vt.user_name, vt.issuer_country_code, vt.distributor_commission_invoice, vt.activation_method, vt.is_prioticket, vt.is_shop_product, vt.shop_category_name, vt.external_account_number, vt.used, vt.ticket_status, vt.is_prepaid, vt.is_purchased_with_postpaid, vt.invoice_type, vt.supplier_currency_symbol, vt.order_currency_code, vt.order_currency_symbol, vt.currency_rate, vt.invoice_variant, vt.service_cost, vt.service_cost_net_amount, vt.service_cost_type, vt.scanned_pass, vt.groupTransactionId, vt.booking_status, vt.channel_type, vt.is_voucher, vt.extra_text_field_answer, vt.distributor_type, vt.distributor_partner_id, vt.distributor_partner_name, vt.issuer_country_name, vt.chart_number, vt.extra_discount, vt.manual_payment_note, vt.account_number, vt.is_custom_setting, vt.external_product_id, vt.supplier_currency_code, vt.col1, vt.col2, vt.partner_category_id, vt.col4, vt.partner_category_name, vt.col6, vt.col7, vt.col8, vt.is_data_moved, concat(vt.action_performed, ' EECOMBICommission'), vt.updated_at, vt.tp_payment_method, vt.order_confirm_date, vt.payment_date, vt.order_cancellation_date, vt.voucher_creation_date, vt.primary_host_name,vt.supplier_gross_price, vt.supplier_discount, vt.supplier_ticket_amt, vt.supplier_tax_value,vt.supplier_net_price, vt.last_modified_at, vt.market_merchant_id, vt.merchant_admin_id, vt.order_updated_cashier_id, vt.order_updated_cashier_name, ROUND((vt.version+1),2) as version, vt.supplier_tax_id, vt.merchant_currency_code, vt.merchant_price, vt.merchant_net_price, vt.merchant_tax_id, vt.admin_currency_code from visitor_tickets vt join (SELECT transaction_id, vt_group_no, ticketId, ticketpriceschedule_id, max(version) as version FROM visitor_tickets where transaction_id = '171873357893317001' and col2 = 2 group by transaction_id, vt_group_no, ticketId, ticketpriceschedule_id) as mv on vt.vt_group_no = mv.vt_group_no and (vt.transaction_id+1) = (mv.transaction_id+1) and ABS(vt.version - mv.version) = '0' and vt.ticketId = mv.ticketId and vt.ticketpriceschedule_id = mv.ticketpriceschedule_id


---- visitor_tickets query after inserting data

SELECT transaction_id, vt_group_no, ticketId, ticketpriceschedule_id, version FROM `visitor_tickets` where transaction_id = '171873357893317001' and col2 = 2 


---- Query to check data in prepaid_tickets

SELECT visitor_group_no, prepaid_ticket_id,version, action_performed, is_addon_ticket, ticket_id, tps_id, cluster_group_id, clustering_id, price, oroginal_price FROM prepaid_tickets WHERE visitor_group_no = '171873357893317' limit 200 



---Prepaid_tickets insert query for combi product with price value = 0

insert into prepaid_tickets (prepaid_ticket_id, is_combi_ticket, visitor_group_no, ticket_id, shared_capacity_id, ticket_booking_id, related_order_id, related_booking_id, hotel_ticket_overview_id, hotel_id, own_supplier_id, distributor_partner_id, distributor_partner_name, hotel_name, shift_id, cashier_register_id, pos_point_id, pos_point_name, channel_id, channel_name, reseller_id, reseller_name, saledesk_id, saledesk_name, title, age_group, museum_id, museum_name, additional_information, location, highlights, image, oroginal_price, order_currency_oroginal_price, discount, order_currency_discount, is_discount_in_percent, price, order_currency_price, ticket_scan_price, cc_rows_value, tax, distributor_type, tax_name, net_price, order_currency_net_price, ticket_amount_before_extra_discount, extra_discount, extra_fee, order_currency_extra_discount, is_combi_discount, combi_discount_gross_amount, order_currency_combi_discount_gross_amount, is_discount_code, discount_code_value, discount_code_amount, order_currency_discount_code_amount, discount_code_promotion_title, service_cost_type, service_cost, net_service_cost, ticket_type, ticket_type_additional_info, discount_applied_on_how_many_tickets, quantity, refund_quantity, timeslot, from_time, to_time, selected_date, booking_selected_date, valid_till, created_date_time, created_at, scanned_at, redemption_notified_at,action_performed, redeem_date_time, is_prioticket, product_type, shop_category_name, rezgo_id, rezgo_ticket_id, rezgo_ticket_price, tps_id, group_type_ticket, group_price, group_quantity, group_linked_with, group_id, supplier_currency_code, supplier_currency_symbol, order_currency_code, order_currency_symbol, currency_rate, selected_quantity, min_qty, max_qty, passNo, bleep_pass_no, pass_type, used, activated, visitor_tickets_id, activation_method, invoice_method_label, booking_type, split_payment_detail, timezone, is_pre_selected_ticket, is_prepaid, is_cancelled, deleted, time_based_done, booking_status, order_status, is_refunded, refunded_by, without_elo_reference_no, is_voucher, is_iticket_product, reference_id, is_addon_ticket, cluster_group_id, clustering_id, related_product_id, parent_product_id, related_product_title, pos_point_id_on_redeem, pos_point_name_on_redeem, distributor_id_on_redeem, distributor_cashier_id_on_redeem, third_party_type, third_party_booking_reference, third_party_response_data, supplier_original_price, supplier_discount, supplier_price, supplier_tax, supplier_net_price,museum_net_fee, distributor_net_fee,hgs_net_fee,museum_gross_fee, distributor_gross_fee,hgs_gross_fee, second_party_type, second_party_booking_reference, second_party_passNo, batch_id, batch_reference, cashier_id, cashier_name, redeem_users, cashier_code, location_code, voucher_updated_by, voucher_updated_by_name, redeem_method, tp_payment_method, order_confirm_date, payment_date, museum_cashier_id, museum_cashier_name, extra_text_field_answer, pick_up_location, refund_note, manual_payment_note, channel_type, financial_id, financial_name, is_custom_setting, external_product_id, account_number, chart_number, is_invoice, split_card_amount, split_cash_amount, split_voucher_amount, split_direct_payment_amount, is_data_moved, last_imported_date, redeem_by_ticket_id, redeem_by_ticket_title, updated_at, commission_type, barcode_type, guest_names, guest_emails, secondary_guest_email, secondary_guest_name, passport_number, order_status_hto, pspReference, merchantReference, merchantAccountCode, reserved_1, reserved_2, reserved_3, authcode, payment_gateway, payment_conditions, payment_term_category, order_cancellation_date, voucher_creation_date, partner_category_id, partner_category_name,last_modified_at, order_updated_cashier_id, order_updated_cashier_name, primary_host_name, is_order_confirmed, booking_information, extra_booking_information, contact_details, contact_information, phone_number, booking_details, market_merchant_id, merchant_admin_id, pax, capacity, commission_json, supplier_cost, partner_cost, tax_id, tax_exception_applied, version, supplier_tax_id, merchant_currency_code, merchant_price, merchant_net_price, merchant_tax_id, admin_currency_code, expiry_date, validity_date, \`unlock\`, checkin_uid, checkin_date, voucher_release_date) select pt1.prepaid_ticket_id, pt1.is_combi_ticket, pt1.visitor_group_no, pt1.ticket_id, pt1.shared_capacity_id, pt1.ticket_booking_id, pt1.related_order_id, pt1.related_booking_id, pt1.hotel_ticket_overview_id, pt1.hotel_id, pt1.own_supplier_id, pt1.distributor_partner_id, pt1.distributor_partner_name, pt1.hotel_name, pt1.shift_id, pt1.cashier_register_id, pt1.pos_point_id, pt1.pos_point_name, pt1.channel_id, pt1.channel_name, pt1.reseller_id, pt1.reseller_name, pt1.saledesk_id, pt1.saledesk_name, pt1.title, pt1.age_group, pt1.museum_id, pt1.museum_name, pt1.additional_information, pt1.location, pt1.highlights, pt1.image,'0.00' as oroginal_price, pt1.order_currency_oroginal_price, pt1.discount, pt1.order_currency_discount, pt1.is_discount_in_percent,'0.00' as price, pt1.order_currency_price, pt1.ticket_scan_price, pt1.cc_rows_value, pt1.tax, pt1.distributor_type, pt1.tax_name,'0.00' as net_price, pt1.order_currency_net_price, pt1.ticket_amount_before_extra_discount, pt1.extra_discount, pt1.extra_fee, pt1.order_currency_extra_discount, pt1.is_combi_discount, pt1.combi_discount_gross_amount, pt1.order_currency_combi_discount_gross_amount, pt1.is_discount_code, pt1.discount_code_value, pt1.discount_code_amount, pt1.order_currency_discount_code_amount, pt1.discount_code_promotion_title, pt1.service_cost_type, pt1.service_cost, pt1.net_service_cost, pt1.ticket_type, pt1.ticket_type_additional_info, pt1.discount_applied_on_how_many_tickets, pt1.quantity, pt1.refund_quantity, pt1.timeslot, pt1.from_time, pt1.to_time, pt1.selected_date, pt1.booking_selected_date, pt1.valid_till, pt1.created_date_time, pt1.created_at, pt1.scanned_at, pt1.redemption_notified_at,concat(pt1.action_performed, 'EECombiCommission') as action_performed, pt1.redeem_date_time, pt1.is_prioticket, pt1.product_type, pt1.shop_category_name, pt1.rezgo_id, pt1.rezgo_ticket_id, pt1.rezgo_ticket_price, pt1.tps_id, pt1.group_type_ticket, pt1.group_price, pt1.group_quantity, pt1.group_linked_with, pt1.group_id, pt1.supplier_currency_code, pt1.supplier_currency_symbol, pt1.order_currency_code, pt1.order_currency_symbol, pt1.currency_rate, pt1.selected_quantity, pt1.min_qty, pt1.max_qty, pt1.passNo, pt1.bleep_pass_no, pt1.pass_type, pt1.used, pt1.activated, pt1.visitor_tickets_id, pt1.activation_method, pt1.invoice_method_label, pt1.booking_type, pt1.split_payment_detail, pt1.timezone, pt1.is_pre_selected_ticket, pt1.is_prepaid, pt1.is_cancelled, pt1.deleted, pt1.time_based_done, pt1.booking_status, pt1.order_status, pt1.is_refunded, pt1.refunded_by, pt1.without_elo_reference_no, pt1.is_voucher, pt1.is_iticket_product, pt1.reference_id, pt1.is_addon_ticket, pt1.cluster_group_id, pt1.clustering_id, pt1.related_product_id, pt1.parent_product_id, pt1.related_product_title, pt1.pos_point_id_on_redeem, pt1.pos_point_name_on_redeem, pt1.distributor_id_on_redeem, pt1.distributor_cashier_id_on_redeem, pt1.third_party_type, pt1.third_party_booking_reference, pt1.third_party_response_data, pt1.supplier_original_price, pt1.supplier_discount, pt1.supplier_price, pt1.supplier_tax, pt1.supplier_net_price,pt1.museum_net_fee, pt1.distributor_net_fee,pt1.hgs_net_fee,pt1.museum_gross_fee, pt1.distributor_gross_fee,pt1.hgs_gross_fee, pt1.second_party_type, pt1.second_party_booking_reference, pt1.second_party_passNo, pt1.batch_id, pt1.batch_reference, pt1.cashier_id, pt1.cashier_name, pt1.redeem_users, pt1.cashier_code, pt1.location_code, pt1.voucher_updated_by, pt1.voucher_updated_by_name, pt1.redeem_method, pt1.tp_payment_method, pt1.order_confirm_date, pt1.payment_date, pt1.museum_cashier_id, pt1.museum_cashier_name, pt1.extra_text_field_answer, pt1.pick_up_location, pt1.refund_note, pt1.manual_payment_note, pt1.channel_type, pt1.financial_id, pt1.financial_name, pt1.is_custom_setting, pt1.external_product_id, pt1.account_number, pt1.chart_number, pt1.is_invoice, pt1.split_card_amount, pt1.split_cash_amount, pt1.split_voucher_amount, pt1.split_direct_payment_amount, pt1.is_data_moved, pt1.last_imported_date, pt1.redeem_by_ticket_id, pt1.redeem_by_ticket_title, pt1.updated_at, pt1.commission_type, pt1.barcode_type, pt1.guest_names, pt1.guest_emails, pt1.secondary_guest_email, pt1.secondary_guest_name, pt1.passport_number, pt1.order_status_hto, pt1.pspReference, pt1.merchantReference, pt1.merchantAccountCode, pt1.reserved_1, pt1.reserved_2, pt1.reserved_3, pt1.authcode, pt1.payment_gateway, pt1.payment_conditions, pt1.payment_term_category, pt1.order_cancellation_date, pt1.voucher_creation_date, pt1.partner_category_id, pt1.partner_category_name,CURRENT_TIMESTAMP as last_modified_at, pt1.order_updated_cashier_id, pt1.order_updated_cashier_name, pt1.primary_host_name, pt1.is_order_confirmed, pt1.booking_information, pt1.extra_booking_information, pt1.contact_details, pt1.contact_information, pt1.phone_number, pt1.booking_details, pt1.market_merchant_id, pt1.merchant_admin_id, pt1.pax, pt1.capacity, pt1.commission_json, pt1.supplier_cost, pt1.partner_cost, pt1.tax_id, pt1.tax_exception_applied, ROUND(pt1.version+1) as version, pt1.supplier_tax_id, pt1.merchant_currency_code, pt1.merchant_price, pt1.merchant_net_price, pt1.merchant_tax_id, pt1.admin_currency_code, pt1.expiry_date, pt1.validity_date, pt1.unlock, pt1.checkin_uid, pt1.checkin_date, pt1.voucher_release_date from prepaid_tickets pt1 join (select pt.prepaid_ticket_id, max(pt.version) as version, pt.visitor_group_no from prepaid_tickets pt join (SELECT vt_group_no, targetlocation, ticketId, ticketpriceschedule_id FROM `visitor_tickets` where transaction_id = '171873357893317001' and col2 = 2 and action_performed like '%EECombiCommission') as base on pt.visitor_group_no = base.vt_group_no and pt.ticket_id = base.ticketId and pt.tps_id = base.ticketpriceschedule_id and pt.is_addon_ticket = '2' group by pt.visitor_group_no, pt.prepaid_ticket_id) as mv on pt1.visitor_group_no = mv.visitor_group_no and pt1.prepaid_ticket_id = mv.prepaid_ticket_id and pt1.version = mv.version and pt1.is_addon_ticket = '2'; 