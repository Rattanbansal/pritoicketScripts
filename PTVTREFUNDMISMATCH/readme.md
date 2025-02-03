<!-- Query to check mismatch between pt and vt -->

select prepaid_ticket_id, version, action_performed, used, redeem_date_time, 'PT' as type, last_modified_at,'0' row_type, is_refunded from prepaid_tickets where prepaid_ticket_id = '173831631566103006' and is_addon_ticket != '2'
union ALL
select transaction_id, version, action_performed, used, visit_date_time, 'VT' as type, last_modified_at, row_type, is_refunded from visitor_tickets where transaction_id = '173831631566103006' and col2!= '2'


<!-- Bigquery Query to get orders where we have mismatch -->

WITH
  pt1 AS (
      SELECT *, 
            ROW_NUMBER() OVER (PARTITION BY prepaid_ticket_id ORDER BY IFNULL(version, '1') DESC,last_modified_at DESC) AS rn 
      FROM prio_olap.scan_report
  ),
  pt AS (
      SELECT * 
      FROM pt1 
      WHERE rn=1 AND deleted=0
  ),vt1 AS (
      SELECT *, 
            ROW_NUMBER() OVER (PARTITION BY id ORDER BY IFNULL(version, '1') DESC,last_modified_at DESC) AS rn 
      FROM prio_olap.financial_transactions
  ),
  vt AS (
      SELECT * 
      FROM vt1 
      WHERE rn=1 AND deleted='0'
  ), scantborders as (select distinct visitor_group_no from pt where order_confirm_date > '2025-01-01'), ptfinal as (select pt.visitor_group_no,pt.order_confirm_date,pt.ticket_id,pt.tps_id,pt.is_refunded,pt.prepaid_ticket_id,pt.ticket_type,pt.used,pt.action_performed,pt.activated,pt.redeem_date_time,pt.redemption_notified_at ,pt.version from pt where pt.visitor_group_no in (select visitor_group_no from scantborders)), vtfinal as (select vt.vt_group_no, vt.order_confirm_date, vt.transaction_id, vt.tickettype_name,vt.ticketId,vt.ticketpriceschedule_id, vt.used, vt.action_performed, vt.visit_date_time, vt.version,vt.is_refunded, vt.row_type from vt where vt.vt_group_no in (select visitor_group_no from scantborders)), finalData as (select ptfinal.visitor_group_no as pt_order_id, vtfinal.vt_group_no as vt_order_id, concat(ptfinal.prepaid_ticket_id, 'R') as pt_transactionId, concat(vtfinal.transaction_id,'R') as vt_transactionId, ptfinal.version as pt_version, vtfinal.version as vt_version, ptfinal.ticket_id as ptticketId, vtfinal.ticketId as vt_ticketId, ptfinal.tps_id as pt_tpsId, vtfinal.ticketpriceschedule_id as vt_tpsId, ptfinal.action_performed as pt_actionPerformed, vtfinal.action_performed as vt_actionPeformed, ptfinal.used as pt_used, vtfinal.used as vt_used, ptfinal.redeem_date_time as pt_redeemDate, vtfinal.visit_date_time as vt_redeemDate, ptfinal.is_refunded as pt_refunded, vtfinal.is_refunded as vt_refunded,vtfinal.row_type as row_type, 0 as status from ptfinal left join vtfinal on ptfinal.visitor_group_no = vtfinal.vt_group_no and ptfinal.prepaid_ticket_id = vtfinal.transaction_id) select * from finalData where pt_refunded != vt_refunded