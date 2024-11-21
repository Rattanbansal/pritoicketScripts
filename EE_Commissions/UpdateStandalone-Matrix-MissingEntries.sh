#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=25

### Database Credentials For 19 DB
DB_HOST="10.10.10.19"
DB_USER="pip"
DB_PASS="pip2024##"
DB_NAME="priopassdb"
AccountLEVELTABLE=ticket_level_commission # Define Variable which database table we are going to work
ChannelLEVELTABLE=channel_level_commission
BackupFILETLC="/home/intersoft-admin/rattan/backup/$AccountLEVELTABLE.sql"
BackupFILECLC="/home/intersoft-admin/rattan/backup/$AccountLEVELTABLE.sql"
TEMP_FILE="temp_query_result.csv"

### Database credentials for Local database so that can work without interuption
LOCAL_HOST="10.10.10.19"
LOCAL_USER="pip"
LOCAL_PASS="pip2024##"
LOCAL_NAME="priopassdb"
LOCAL_NAME_1="priopassdb"

# LOCAL_HOST="production-primary-db-node-cluster.cluster-ck6w2al7sgpk.eu-west-1.rds.amazonaws.com"
# LOCAL_USER="pipeuser"
# LOCAL_PASS="d4fb46eccNRAL"
# LOCAL_NAME="priopassdb"
# LOCAL_NAME_1="priopassdb"

## GEt Distinct Reseller_id from Pricelist table



echo "Fetching Data for reseller_id :: $reseller_id"

cod_ids="6860 7796 7091 7829 32795 38814 9527 44377"

for cod_id in ${cod_ids}

do 

    timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -e "select CURRENT_TIMESTAMP as created_at,hotel_id,ticket_id,tps_id as ticketpriceschedule_id, museum_name,ticket_title,LEFT(ticket_type, 10) AS ticket_type,ticket_scan_price,ticket_list_price, ticket_new_price, '0' as ticket_discount,'0' as is_discount_in_percent, ticket_gross_price,'0.00' as ticket_tax_value, '227' as ticket_tax_id,ticket_gross_price as ticket_net_price,'0' as museum_commission_old,'0.00' as museum_gross_commission,'0.00' as museum_net_commission,'0.00' as museum_commission_tax_value, '227' as museum_commission_tax_id,ticket_gross_price as subtotal_net_amount, ticket_gross_price as subtotal_gross_amount,'0.00' as subtotal_tax_value, '227' as subtotal_tax_id,'0' as is_combi_ticket_allowed,'0' as is_combi_discount, '0' as tickets_for_combi_discount,'0' as combi_discount_gross_amount,'0' as combi_discount_net_amount, '0.00' as combi_discount_tax_value,'227' as combi_discount_tax_id,CURRENT_TIMESTAMP as commission_updated_at,'192.168.1.18' as ip_address,commission as hotel_prepaid_commission_percentage,'0.00' as hotel_postpaid_commission_percentage, '2' as hotel_commission_tax_id,'21.00' as hotel_commission_tax_value,'0.00' as hgs_prepaid_commission_percentage,'0.00' as hgs_postpaid_commission_percentage, '227' as hgs_commission_tax_id,'0.00' as hgs_commission_tax_value,'0.00' as merchant_gross_commission, '1' as is_adjust_pricing,'0' as is_custom_setting,'0' as apply_service_tax,'0' as external_product_id, '1' as account_number,'1' as chart_number,'0' as deleted,'4' as market_merchant_id, '0.00' as merchant_net_commission,'49758' as merchant_admin_id,'Evan Evans' as merchant_admin_name,(case when is_combi in ('2', '3') then '1' else '0' end) as is_cluster_ticket_added,'0' default_listing,'0' as catalog_id,CURRENT_TIMESTAMP as last_modified_at,'0.00' as resale_percentage,'1' as is_resale_percentage, '0.00' as merchant_fee_percentage,'0' as is_merchant_fee_percentage,'1' as is_hotel_prepaid_commission_percentage,'1' as commission_on_sale_price, ((ticket_gross_price*commission/100)*(121/100)) as hotel_commission_gross_price, (ticket_gross_price*commission/100) as hotel_commission_net_price,ticket_gross_price*(100-commission)/100 as hgs_commission_gross_price,ticket_gross_price*(100-commission)/100 as hgs_commission_net_price,is_combi as product_type,currency_code as currency,'1' as resale_currency_level,'0' as resale_commission,CURRENT_TIMESTAMP as affected_before_date,'0' as own_merchant_id,'0' as discount_label,'0' as discount_setting_type from (with qr_codess as (select cod_id from priopassdb.qr_codes where cod_id = '$cod_id' and cashier_type = '1'), channels as (select d.*, qc.cod_id from priopassdb.distributors d join qr_codess qc on d.hotel_id = qc.cod_id group by d.ticket_id, qc.cod_id), catalogs as (select * from channels where cod_id is not NULL), products as (select c.*, date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) as mec_end_date,mec.museum_name,mec.postingEventTitle as ticket_title,tps.ticket_type_label as ticket_type,tps.newPrice as ticket_scan_price, tps.newPrice as ticket_list_price, tps.newPrice as ticket_new_price,tps.newPrice as ticket_gross_price, tps.id as tps_id, tps.currency_code, mec.is_combi from catalogs c left join modeventcontent mec on c.ticket_id = mec.mec_id left join ticketpriceschedule tps on mec.mec_id = tps.ticket_id where mec.deleted = '0' and date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) > CURRENT_DATE and tps.deleted = '0' and date(from_unixtime(if(tps.end_date like '9999999', '1794812755', tps.end_date))) > CURRENT_DATE) select p.*, clc.ticket_id as clcproduct_id, clc.ticketpriceschedule_id, clc.resale_currency_level from products p left join ticket_level_commission clc on p.hotel_id = clc.hotel_id and clc.deleted = '0' and p.ticket_id = clc.ticket_id and p.tps_id = clc.ticketpriceschedule_id and clc.is_adjust_pricing = '1') as final where clcproduct_id is NULL;" > "$TEMP_FILE"

    # Check if the temporary file contains data
    if [[ -s $TEMP_FILE ]]; then
        echo "Mismatch found for Distributor_id=$cod_id. Appending to CSV."

        # Append the result to the main CSV file
        cat "$TEMP_FILE" >> Matrix_Missing_Entries.csv

        timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "insert into ticket_level_commission (created_at, hotel_id, ticket_id, ticketpriceschedule_id, museum_name,ticket_title,ticket_type,ticket_scan_price,ticket_list_price,ticket_new_price,ticket_discount,is_discount_in_percent,ticket_gross_price,ticket_tax_value,ticket_tax_id,ticket_net_price,museum_commission_old,museum_gross_commission,museum_net_commission,museum_commission_tax_value,museum_commission_tax_id,subtotal_net_amount,subtotal_gross_amount,subtotal_tax_value,subtotal_tax_id,is_combi_ticket_allowed,is_combi_discount,tickets_for_combi_discount,combi_discount_gross_amount,combi_discount_net_amount,combi_discount_tax_value, combi_discount_tax_id, commission_updated_at, ip_address, hotel_prepaid_commission_percentage, hotel_postpaid_commission_percentage, hotel_commission_tax_id, hotel_commission_tax_value, hgs_prepaid_commission_percentage, hgs_postpaid_commission_percentage, hgs_commission_tax_id, hgs_commission_tax_value, merchant_gross_commission, is_adjust_pricing, is_custom_setting, apply_service_tax, external_product_id, account_number, chart_number, deleted, market_merchant_id, merchant_net_commission, merchant_admin_id, merchant_admin_name, is_cluster_ticket_added, default_listing, catalog_id, last_modified_at, resale_percentage, is_resale_percentage, merchant_fee_percentage, is_merchant_fee_percentage, is_hotel_prepaid_commission_percentage, commission_on_sale_price, hotel_commission_gross_price, hotel_commission_net_price, hgs_commission_gross_price, hgs_commission_net_price, product_type, currency, resale_currency_level, resale_commission, own_merchant_id, discount_label, discount_setting_type) select CURRENT_TIMESTAMP as created_at,hotel_id,ticket_id,tps_id as ticketpriceschedule_id, museum_name,ticket_title,LEFT(ticket_type, 10) AS ticket_type,ticket_scan_price,ticket_list_price, ticket_new_price, '0' as ticket_discount,'0' as is_discount_in_percent, ticket_gross_price,'0.00' as ticket_tax_value, '227' as ticket_tax_id,ticket_gross_price as ticket_net_price,'0' as museum_commission_old, '0.00' as museum_gross_commission,'0.00' as museum_net_commission,'0.00' as museum_commission_tax_value, '227' as museum_commission_tax_id,ticket_gross_price as subtotal_net_amount, ticket_gross_price as subtotal_gross_amount,'0.00' as subtotal_tax_value, '227' as subtotal_tax_id,'0' as is_combi_ticket_allowed,'0' as is_combi_discount, '0' as tickets_for_combi_discount,'0' as combi_discount_gross_amount,'0' as combi_discount_net_amount, '0.00' as combi_discount_tax_value,'227' as combi_discount_tax_id,CURRENT_TIMESTAMP as commission_updated_at,'200.168.1.18' as ip_address,commission as hotel_prepaid_commission_percentage,'0.00' as hotel_postpaid_commission_percentage, '2' as hotel_commission_tax_id,'21.00' as hotel_commission_tax_value,ROUND(100-commission,2) as hgs_prepaid_commission_percentage,'0.00' as hgs_postpaid_commission_percentage, '227' as hgs_commission_tax_id,'0.00' as hgs_commission_tax_value,'0.00' as merchant_gross_commission, '1' as is_adjust_pricing,'0' as is_custom_setting,'0' as apply_service_tax,'0' as external_product_id, '1' as account_number,'1' as chart_number,'0' as deleted,'4' as market_merchant_id, '0.00' as merchant_net_commission,'49758' as merchant_admin_id,'Evan Evans' as merchant_admin_name,(case when is_combi in ('2', '3') then '1' else '0' end) as is_cluster_ticket_added,'0' default_listing,'0' as catalog_id,CURRENT_TIMESTAMP as last_modified_at,'0.00' as resale_percentage,'1' as is_resale_percentage, '0.00' as merchant_fee_percentage,'0' as is_merchant_fee_percentage,'1' as is_hotel_prepaid_commission_percentage,'1' as commission_on_sale_price, ((ticket_gross_price*commission/100)*(121/100)) as hotel_commission_gross_price, (ticket_gross_price*commission/100) as hotel_commission_net_price,(ticket_gross_price*(100-commission)/100) as hgs_commission_gross_price,(ticket_gross_price*(100-commission)/100) as hgs_commission_net_price,is_combi as product_type,currency_code as currency,'1' as resale_currency_level,'0' as resale_commission,'0' as own_merchant_id,'0' as discount_label,'0' as discount_setting_type from (with qr_codess as (select cod_id from priopassdb.qr_codes where cod_id = '$cod_id' and cashier_type = '1'), channels as (select d.*, qc.cod_id from priopassdb.distributors d join qr_codess qc on d.hotel_id = qc.cod_id group by d.ticket_id, qc.cod_id), catalogs as (select * from channels where cod_id is not NULL), products as (select c.*, date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) as mec_end_date,mec.museum_name,mec.postingEventTitle as ticket_title,tps.ticket_type_label as ticket_type,tps.newPrice as ticket_scan_price, tps.newPrice as ticket_list_price, tps.newPrice as ticket_new_price,tps.newPrice as ticket_gross_price, tps.id as tps_id, tps.currency_code, mec.is_combi from catalogs c left join modeventcontent mec on c.ticket_id = mec.mec_id left join ticketpriceschedule tps on mec.mec_id = tps.ticket_id where mec.deleted = '0' and date(from_unixtime(if(mec.endDate like '9999999', '1794812755', mec.endDate))) > CURRENT_DATE and tps.deleted = '0' and date(from_unixtime(if(tps.end_date like '9999999', '1794812755', tps.end_date))) > CURRENT_DATE) select p.*, clc.ticket_id as clcproduct_id, clc.ticketpriceschedule_id, clc.resale_currency_level from products p left join ticket_level_commission clc on p.hotel_id = clc.hotel_id and clc.deleted = '0' and p.ticket_id = clc.ticket_id and p.tps_id = clc.ticketpriceschedule_id and clc.is_adjust_pricing = '1') as final where clcproduct_id is NULL;select ROW_COUNT();"

        timeout $TIMEOUT_PERIOD time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" -sN -e "update ticket_level_commission tlcu join (select *, (case when sc_ticket_id is not NULL then CAST(sc_pos_list AS CHAR) when sc_ticket_id is NULL then CAST(default_pos_list AS CHAR) else CAST(tlc_pos_list AS CHAR) end) as shouldbe from (with qr_codess as (select cod_id, template_id, sub_catalog_id from qr_codes where cashier_type = '1' and cod_id = '$cod_id'), Accountlevel as (select qc.*, tlc.ticket_level_commission_id,tlc.hotel_id, tlc.ticket_id as tlc_ticket_id, (tlc.is_pos_list+0-1) as tlc_pos_list from qr_codess qc join ticket_level_commission tlc on qc.cod_id = tlc.hotel_id where tlc.deleted = '0'), subcatalog_level as (select a.*, sc.ticket_id as sc_ticket_id, sc.catalog_id, sc.is_pos_list as sc_pos_list from Accountlevel a left join template_level_tickets sc on a.tlc_ticket_id = sc.ticket_id and sc.catalog_id = a.sub_catalog_id and sc.template_id = '0' and sc.deleted = '0' and sc.catalog_id > '0' and sc.catalog_id is not NULL and a.sub_catalog_id is not NULL), defaultLevel as  (select sl.*, defaults.ticket_id as default_ticket_id, defaults.template_id as default_template_id, defaults.is_pos_list as default_pos_list from subcatalog_level sl left join template_level_tickets defaults on defaults.template_id = sl.template_id and defaults.ticket_id = sl.tlc_ticket_id and defaults.deleted = '0' and defaults.template_id > '0' and defaults.catalog_id = '0') select * from defaultLevel) as base where sc_ticket_id is not NULL or default_ticket_id is not null group by ticket_level_commission_id having shouldbe != tlc_pos_list) as cal on tlcu.ticket_level_commission_id = cal.ticket_level_commission_id set tlcu.is_pos_list = cal.shouldbe where tlcu.ip_address = '200.168.1.18'; select ROW_COUNT();"

    else
        echo "No mismatch found for distributor_id=$cod_id. Skipping."
        cat "$TEMP_FILE" >> Matrix_Missing_Entries.csv
    fi

    sleep 1

    rm -f "$TEMP_FILE"


done

sleep 1




