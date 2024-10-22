SELECT
    mec_id,
    cat_id,
    hotel_id,
    museum_id,
    product_type,
    company,
    rezgo_ticket_id,
    rezgo_id,
    'lll' AS rezgo_key,
    tourcms_tour_id,
    tourcms_channel_id,
    tax_value,
    service_cost,
    latest_sold_date,
    shortDesc,
    eventImage,
    ticketwithdifferentpricing,
    saveamount,
    ticketPrice,
    pricetext,
    ticket_net_price,
    newPrice,
    totalticketPrice,
    new_discount_price,
    is_reservation,
    agefrom,
    ageto,
    ticketType,
    is_combi_ticket_allowed,
    is_booking_combi_ticket_allowed,
    start_date,
    end_date,
    extra_text_field,
    deleted,
    is_updated,
    third_party_id,
    third_party_ticket_id,
    third_party_parameters
FROM
    (
    SELECT
        pos.mec_id AS base_id,
        base2.ticket_id AS mec_id,
        base2.cat_id AS cat_id,
        base2.cod_id AS hotel_id,
        base2.supplier_id AS museum_id,
        base2.product_type AS product_type,
        base2.company AS company,
        '0' AS rezgo_ticket_id,
        '0' AS rezgo_id,
        '0' AS rezgo_key,
        '0' AS tourcms_tour_id,
        '0' AS tourcms_channel_id,
        base2.tax_value AS tax_value,
        '0' AS service_cost,
        '2021-06-19' AS latest_sold_date,
        base2.shortDesc AS shortDesc,
        base2.eventImage AS eventImage,
        '1' AS ticketwithdifferentpricing,
        base2.saveamount AS saveamount,
        base2.ticketPrice AS ticketPrice,
        base2.pricetext AS pricetext,
        base2.ticket_net_price AS ticket_net_price,
        base2.newPrice AS newPrice,
        base2.totalticketPrice AS totalticketPrice,
        base2.new_discount_price AS new_discount_price,
        base2.is_reservation AS is_reservation,
        base2.agefrom AS agefrom,
        base2.ageto AS ageto,
        base2.ticketType AS ticketType,
        '0' AS is_combi_ticket_allowed,
        '0' AS is_booking_combi_ticket_allowed,
        base2.start_date AS start_date,
        base2.end_date AS end_date,
        '0' AS extra_text_field,
        '0' AS deleted,
        '0' AS is_updated,
        base2.third_party_id AS third_party_id,
        base2.third_party_ticket_id AS third_party_ticket_id,
        base2.third_party_parameters AS third_party_parameters
    FROM
        (
        SELECT
            CURRENT_DATE() AS DATE, DATE(FROM_UNIXTIME(tps.start_date)) AS tps_start_date,
            DATE(
                FROM_UNIXTIME(
                    IF(
                        tps.end_date LIKE '%9999%',
                        '1750343264',
                        tps.end_date
                    )
                )
            ) AS tps_end_time,
            tps.ticket_id AS tps_ticket_id,
            tps.default_listing,
            qc.cod_id,
            qc.template_id AS company_template_id,
            tlt.template_id,
            tlt.ticket_id,
            mec.cat_id,
            mec.sub_cat_id,
            mec.cod_id AS supplier_id,
            (
                CASE WHEN mec.is_combi IN('2', '3') THEN mec.is_combi ELSE 0
            END
            ) AS product_type,
            mec.museum_name AS company,
            qc.country_code AS country_code,
            qc.country AS country,
            tps.ticket_tax_value AS tax_value,
            mec.postingEventTitle AS shortDesc,
            mec.eventImage AS eventImage,
            tps.saveamount AS saveamount,
            tps.pricetext AS ticketPrice,
            tps.pricetext AS pricetext,
            tps.newPrice AS newPrice,
            tps.ticket_net_price AS ticket_net_price,
            tps.newPrice AS totalticketPrice,
            tps.newPrice AS new_discount_price,
            mec.isreservation AS is_reservation,
            tps.agefrom AS agefrom,
            tps.ageto AS ageto,
            tps.ticket_type_label AS ticketType,
            (
                CASE WHEN mec.is_allow_pre_bookings = '1' AND mec.is_reservation = '1' THEN mec.pre_booking_date ELSE mec.startDate
            END
    ) AS start_date,
    mec.endDate AS end_date,
    mec.third_party_id AS third_party_id,
    mec.third_party_ticket_id AS third_party_ticket_id,
    mec.third_party_parameters AS third_party_parameters,
    'getQuery' AS action_performed
FROM
    qr_codes qc
LEFT JOIN template_level_tickets tlt ON
    qc.template_id = tlt.template_id
LEFT JOIN modeventcontent mec ON
    mec.mec_id = tlt.ticket_id
LEFT JOIN ticketpriceschedule tps ON
    tps.ticket_id = mec.mec_id AND tps.default_listing = '1' AND DATE(
        FROM_UNIXTIME(
            IF(
                tps.end_date LIKE '%9999%',
                '1750343264',
                tps.end_date
            )
        )
    ) >= CURRENT_DATE()
WHERE
    mec.mec_id = 66767 AND mec.deleted = '0' AND tlt.deleted = '0' AND qc.cashier_type = '1' AND tlt.template_id != '0' AND tlt.publish_catalog = '1' AND DATE(
        FROM_UNIXTIME(
            IF(
                tps.end_date LIKE '%9999%',
                '1750343264',
                tps.end_date
            )
        )
    ) >= CURRENT_DATE()
GROUP BY
    tlt.template_level_tickets_id, qc.cod_id, tps.ticket_id) AS base2
LEFT JOIN pos_tickets pos ON
    base2.cod_id = pos.hotel_id AND base2.ticket_id = pos.mec_id) AS final_missing_entries_in_pos_tickets
WHERE
    base_id IS NULL