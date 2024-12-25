#!/bin/bash

DB_HOST="10.10.10.19"
DB_USER="pip"
DB_PASS="pip2024##"
DB_NAME="priopassdb"
Insertdata=$1

echo "" > channel_level_mismatch.csv
echo "" > catalog_level_mismatch.csv
echo "" > Hotel_not_linked_with_Sub_catalog.csv
echo "" > Hotel_catalog_level_mismatch.csv
echo "" > tlc_level_mismatch.csv
echo "" > reseller_matrix_on_tlc_level.csv
echo "" > Catalog_linking_still_not_provided_in_matrix_Sheet.csv
echo "" > Catalog_wrong_Linked.csv
echo "" > Product_id_Sold_But_not_In_matrix.csv
echo "" > Product_id_Sold_But_not_In_matrixReseller.csv
echo "" > distributor_id_Sold_But_not_In_matrix.csv
echo "" > reseller_id_Sold_But_not_In_matrixreseller.csv

if [[ $Insertdata == 2 ]]; then

    exit 1

    echo "Started Instering Data from Scratch"

    mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "TRUNCATE TABLE pricelist; TRUNCATE TABLE distributors; TRUNCATE TABLE catalog_distributors;"

    python pricelist.py pricelist.csv

    python distributors.py distributors.csv

    python catalog_distributors.py

else

    echo "Data Not need to insert Again"

fi

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "delete from distributors where hotel_id = '0'; delete from distributors where ticket_id = '0';delete from pricelist where reseller_id = '0';delete from pricelist where ticket_id = '0';"

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "update catalog_distributors set catalog_name = 'HIGH 30% WB' where catalog_name like '%HIGH WB%';update catalog_distributors set catalog_name = 'STANDALONE' where catalog_name like '%INDIVIDUAL%';"


mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "select base1.*, base2.catalog_name as client_provided_name from (SELECT catalog_id, if(catalog_name = 'HIGH 30%', 'HIGHER', catalog_name) as catalog_name FROM catalogs where reseller_id = '541') as base1 right join (select DISTINCT catalog_name from catalog_distributors) as base2 on base1.catalog_name like concat(base2.catalog_name, '%');"

read -r user_input

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "select * from (select main.*, cd.catalog_name as client_provided_catalog_name, cd.distributor_id from (SELECT qc.cod_id, qc.company, qc.sub_catalog_id, qc.own_supplier_id, if(c.catalog_name='HIGH 30%', 'HIGHER', c.catalog_name) as catalog_name, case when c.catalog_category = '1' then 'Main_catalog' when c.catalog_category = '2' then 'Sub_catalog' else 'No Condition' end as catalog_category, case when c.catalog_type = '1' then 'agent_catalog' when c.catalog_type = '2' then 'direct_catalog' else 'No condition' end as catalog_type FROM qr_codes qc left join catalogs c on qc.sub_catalog_id = c.catalog_id where qc.reseller_id = '541' and qc.cashier_type = '1') as main left join catalog_distributors cd on main.cod_id = cd.distributor_id) as raja where distributor_id is NULL;" >> Catalog_linking_still_not_provided_in_matrix_Sheet.csv

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "select * from (select main.*, cd.catalog_name as client_provided_catalog_name, cd.distributor_id from (SELECT qc.cod_id, qc.company, qc.sub_catalog_id, qc.own_supplier_id, if(c.catalog_name='HIGH 30%', 'HIGHER', c.catalog_name) as catalog_name, case when c.catalog_category = '1' then 'Main_catalog' when c.catalog_category = '2' then 'Sub_catalog' else 'No Condition' end as catalog_category, case when c.catalog_type = '1' then 'agent_catalog' when c.catalog_type = '2' then 'direct_catalog' else 'No condition' end as catalog_type FROM qr_codes qc left join catalogs c on qc.sub_catalog_id = c.catalog_id where qc.reseller_id = '541' and qc.cashier_type = '1') as main left join catalog_distributors cd on main.cod_id = cd.distributor_id) as raja where distributor_id is not NULL and catalog_name not like concat('%',client_provided_catalog_name,'%');" >> Catalog_wrong_Linked.csv

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "SELECT distributor_id, group_concat(catalog_name), count(*) as pp FROM catalog_distributors group by distributor_id having pp > '1';" ## check wrong data in the distributor_catalog

read -r user_input

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "select * from (select * from (select DISTINCT(ticket_id) as ordered_product from bigqueryData where reseller_id = '541') as orderData left join (select distinct(ticket_id) as ticket_id from distributors) d on orderData.ordered_product = d.ticket_id) as final where ticket_id is NULL limit 100;" >> Product_id_Sold_But_not_In_matrix.csv ## product oid sold but these product id commission not provided in the sheet of Matrix

read -r user_input

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "select * from (select * from (select DISTINCT(ticket_id) as ordered_product from bigqueryData where reseller_id != '541') as orderData left join (select distinct(ticket_id) as ticket_id from pricelist) d on orderData.ordered_product = d.ticket_id) as final where ticket_id is NULL limit 100;" >> Product_id_Sold_But_not_In_matrixReseller.csv ## product oid sold but these product id commission not provided in the sheet of Matrix

read -r user_input

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "select * from (select * from (select DISTINCT(hotel_id) as order_distributor from bigqueryData where reseller_id = '541') as orderData left join (select distinct(hotel_id) as hotel_id from distributors) d on orderData.order_distributor = d.hotel_id) as final where hotel_id is NULL limit 100;" >> distributor_id_Sold_But_not_In_matrix.csv ## product oid sold but these product id commission not provided in the sheet of Matrix

read -r user_input

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "select * from (select * from (select DISTINCT(reseller_id) as order_reseller_id from bigqueryData where reseller_id != '541') as orderData left join (select distinct(reseller_id) as reseller_id from pricelist) d on orderData.order_reseller_id = d.reseller_id) as final where reseller_id is NULL limit 100;" >> reseller_id_Sold_But_not_In_matrixreseller.csv ## product oid sold but these product id commission not provided in the sheet of Matrix

read -r user_input

# mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "with qr_codess as (select reseller_id, channel_id from priopassdb.qr_codes where cashier_type = '1' and channel_id is not NULL group by reseller_id, channel_id), channels as (select d.*, qc.reseller_id as qc_reseller_id, qc.channel_id from rattan.pricelist d left join qr_codess qc on d.reseller_id = qc.reseller_id), final as (select c.*, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage, clc.ticket_net_price, clc.hotel_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join priopassdb.channel_level_commission clc on c.channel_id = clc.channel_id and c.ticket_id = clc.ticket_id and clc.deleted = '0' and clc.is_adjust_pricing = '1') select *, ABS(hotel_commission_net_price - hotel_commission_should_be) as gap from final where ABS(hotel_commission_net_price - hotel_commission_should_be) > '0.05' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ticketpriceschedule_id is NULL;" >> channel_level_mismatch.csv


# mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "with qr_codess as (select reseller_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0' group by reseller_id, sub_catalog_id), channels as (select d.*, qc.reseller_id as qc_reseller_id, qc.sub_catalog_id from rattan.pricelist d left join qr_codess qc on d.reseller_id = qc.reseller_id), final as (select c.*, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage, clc.ticket_net_price, clc.hotel_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join priopassdb.channel_level_commission clc on c.sub_catalog_id = clc.catalog_id and c.ticket_id = clc.ticket_id and clc.deleted = '0' and clc.is_adjust_pricing = '1') select *, ABS(hotel_commission_net_price - hotel_commission_should_be) as gap from final where ABS(hotel_commission_net_price - hotel_commission_should_be) > '0.05' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ticketpriceschedule_id is NULL;" >> catalog_level_mismatch.csv

# mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "with qr_codess as (select reseller_id,cod_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1'), channels as (select d.*, qc.* from rattan.distributors d left join qr_codess qc on d.hotel_id = qc.cod_id), final as (select c.*, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage, clc.ticket_net_price, clc.hotel_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join priopassdb.channel_level_commission clc on c.sub_catalog_id = clc.catalog_id and c.ticket_id = clc.ticket_id and clc.deleted = '0' and clc.is_adjust_pricing = '1') select distinct hotel_id, cod_id, sub_catalog_id from final where sub_catalog_id is NULL or sub_catalog_id = '0';" >> Hotel_not_linked_with_Sub_catalog.csv

# mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "with qr_codess as (select reseller_id,cod_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1' and sub_catalog_id is not NULL and sub_catalog_id > '0'), channels as (select d.*, qc.* from rattan.distributors d left join qr_codess qc on d.hotel_id = qc.cod_id group by d.ticket_id, qc.sub_catalog_id), final as (select c.*, clc.ticketpriceschedule_id, clc.resale_currency_level, clc.currency, clc.commission_on_sale_price, clc.is_hotel_prepaid_commission_percentage, clc.hotel_prepaid_commission_percentage, clc.ticket_net_price, clc.hotel_commission_net_price, (clc.ticket_net_price*c.commission/100) as hotel_commission_should_be from channels c left join priopassdb.channel_level_commission clc on c.sub_catalog_id = clc.catalog_id and c.ticket_id = clc.ticket_id and clc.deleted = '0' and clc.is_adjust_pricing = '1') select *, ABS(hotel_commission_net_price - hotel_commission_should_be) as gap from final where ABS(hotel_commission_net_price - hotel_commission_should_be) > '0.05' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1' or ticketpriceschedule_id is NULL;" >> Hotel_catalog_level_mismatch.csv


# mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "select * from (SELECT d.ticket_id as product_id, d.hotel_id as distributor_id, d.commission as commission, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hotel_commission_net_price, tlc.ticket_net_price FROM rattan.distributors d left join priopassdb.ticket_level_commission tlc on d.hotel_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') as base where ticket_net_price is not NULL and (ABS(commission-hotel_prepaid_commission_percentage) > '0.01' or commission_on_sale_price != '1' or is_hotel_prepaid_commission_percentage != '1');" >> tlc_level_mismatch.csv


# mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "with qr_codess as (select cod_id, reseller_id, sub_catalog_id from priopassdb.qr_codes where cashier_type = '1'), distributor as (select p.*, qc.cod_id, qc.sub_catalog_id from rattan.pricelist p join qr_codess qc on p.reseller_id = qc.reseller_id), final as (select d.ticket_id as product_id, d.reseller_id as admin_id, d.commission, d.cod_id, d.sub_catalog_id, tlc.ticket_id, tlc.ticketpriceschedule_id, tlc.hotel_prepaid_commission_percentage, tlc.is_hotel_prepaid_commission_percentage, tlc.commission_on_sale_price, tlc.hotel_commission_net_price, tlc.ticket_net_price from distributor d left join priopassdb.ticket_level_commission tlc on d.cod_id = tlc.hotel_id and d.ticket_id = tlc.ticket_id and tlc.deleted = '0' and tlc.is_adjust_pricing = '1') select * from final where ticket_id is not NULL;" >> reseller_matrix_on_tlc_level.csv
