#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=35

DB_HOST="10.10.10.19"
DB_USER="pip"
DB_PASS="pip2024##"
DB_NAME="priopassdb"
TEMP_FILE="Catalog_wrong_Linked.csv"

echo "" > Catalog_wrong_Linked.csv


timeout $TIMEOUT_PERIOD time mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "select * from (select main.*, cd.catalog_name as client_provided_catalog_name, cd.distributor_id from (SELECT qc.cod_id, qc.company, qc.sub_catalog_id, qc.own_supplier_id, ifnull(if(c.catalog_name='HIGH 30%', 'HIGHER', c.catalog_name),'RRRRR') as catalog_name, case when c.catalog_category = '1' then 'Main_catalog' when c.catalog_category = '2' then 'Sub_catalog' else 'No Condition' end as catalog_category, case when c.catalog_type = '1' then 'agent_catalog' when c.catalog_type = '2' then 'direct_catalog' else 'No condition' end as catalog_type FROM qr_codes qc left join catalogs c on qc.sub_catalog_id = c.catalog_id where qc.reseller_id = '541' and qc.cashier_type = '1') as main left join catalog_distributors cd on main.cod_id = cd.distributor_id) as raja where distributor_id is not NULL and catalog_name not like concat('%',client_provided_catalog_name,'%');" >> $TEMP_FILE || exit 1


# Check if the temporary file contains data
if [[ -s $TEMP_FILE ]]; then
    echo "Mismatch found for Catalog_id Appending to CSV."
    sleep 2
    # Append the result to the main CSV file

    timeout $TIMEOUT_PERIOD time mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -D $DB_NAME -e "update qr_codes qc join (select * from (select main.*, cd.catalog_name as client_provided_catalog_name, cd.distributor_id, cd.catalog_id from (SELECT qc.cod_id, qc.company, qc.sub_catalog_id, qc.own_supplier_id, ifnull(if(c.catalog_name='HIGH 30%', 'HIGHER', c.catalog_name),'RRRRR') as catalog_name, case when c.catalog_category = '1' then 'Main_catalog' when c.catalog_category = '2' then 'Sub_catalog' else 'No Condition' end as catalog_category, case when c.catalog_type = '1' then 'agent_catalog' when c.catalog_type = '2' then 'direct_catalog' else 'No condition' end as catalog_type FROM qr_codes qc left join catalogs c on qc.sub_catalog_id = c.catalog_id where qc.reseller_id = '541' and qc.cashier_type = '1') as main left join (select base1.catalog_id, base2.catalog_name, base2.distributor_id from (SELECT catalog_id, if(catalog_name = 'HIGH 30%', 'HIGHER', catalog_name) as catalog_name FROM catalogs where reseller_id = '541') as base1 right join (select DISTINCT catalog_name, distributor_id from catalog_distributors) as base2 on base1.catalog_name like concat(base2.catalog_name, '%')) cd on main.cod_id = cd.distributor_id) as raja where distributor_id is not NULL and catalog_name not like concat('%',client_provided_catalog_name,'%')) as dataa on qc.cod_id = dataa.distributor_id and qc.sub_catalog_id != dataa.catalog_id set qc.sub_catalog_id = dataa.catalog_id;select ROW_COUNT();" || exit 1

else
    echo "No mismatch found for For catalog"
fi