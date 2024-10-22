#!/bin/bash

# Define variables
SOURCE_DB_HOST='rattan-test-primary-db.ck6w2al7sgpk.eu-west-1.rds.amazonaws.com'
SOURCE_DB_USER='prt_dbadmin'
SOURCE_DB_PASSWORD='YI7g3zXYLaRLf06HTX2s'
SOURCE_DB_NAME='priopassdb'

# primary secondasry template Mismatch

mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -e "select ticket_id, primary_table as exist_in_primary, secondary_table as exist_in_secondary from (select ticketdata.*, mec.mec_id, mec.deleted from (select ticket_id, count(*) as pcs, max(case when template_level_tickets_template_id = '818' then 1 else 0 end) as primary_table, max(case when template_level_tickets_template_id = '1452' then 1 else 0 end) as secondary_table   from (select base2.*, tlt.template_id as template_level_tickets_template_id, tlt.ticket_id, tlt.is_pos_list, tlt.deleted, tlt.publish_catalog, tlt.catalog_id as template_level_catalog_id from (select base1.*, (case when resellers.template_id = base1.template_id then 1 else 2 end) as template_type from (select templates.template_id, templates.reseller_id, templates.is_default, templates.catalog_id from templates right join (select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '686' and cashier_type = '1') group by template_id, catalog_id) as base on base.template_id = templates.template_id where templates.catalog_id is not NULL group by templates.template_id, templates.reseller_id, templates.catalog_id) as base1 left join resellers on base1.reseller_id = resellers.reseller_id) as base2 left join template_level_tickets tlt on base2.template_id = tlt.template_id where tlt.deleted = '0' and tlt.publish_catalog = '1' and tlt.catalog_id = '0') as base group by ticket_id having pcs != 2) as ticketdata left join modeventcontent mec on mec.mec_id = ticketdata.ticket_id) as final where deleted is not NULL and deleted = '0';" > primarysecondary_mismatch.csv