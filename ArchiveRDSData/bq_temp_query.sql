WITH
vt1 AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY last_modified_at DESC, IFNULL(version, '1') DESC) AS rn 
    FROM prioticket-reporting.prio_olap.financial_transactions
),
vt AS (
    SELECT * 
    FROM vt1 
    WHERE rn=1 AND deleted='0'
) select vt_group_no, max(last_modified_at) as max_last_modified_at, min(last_modified_at) as min_last_modified_at from vt group by vt_group_no having max_last_modified_at < @archive_date and min_last_modified_at < @archive_date;