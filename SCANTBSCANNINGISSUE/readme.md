<!-- Bigquery query -->

WITH
pt1 AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY prepaid_ticket_id ORDER BY last_modified_at DESC, IFNULL(version, '1') DESC) AS rn 
    FROM prioticket-reporting.prio_olap.scan_report
),
pt AS (
    SELECT * 
    FROM pt1 
    WHERE rn=1 AND deleted=0
),vt1 AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY last_modified_at DESC, IFNULL(version, '1') DESC) AS rn 
    FROM prioticket-reporting.prio_olap.financial_transactions
),
vt AS (
    SELECT * 
    FROM vt1 
    WHERE rn=1 AND deleted='0'
), scantborders as (select distinct visitor_group_no from pt where action_performed like '%SCAN_TB%' and order_confirm_date > '2024-01-01 00:00:01') select visitor_group_no,order_confirm_date,prepaid_ticket_id,ticket_type,used,action_performed,activated,redeem_date_time,redemption_notified_at ,version from pt where visitor_group_no in (select visitor_group_no from scantborders) and is_addon_ticket != '2'

