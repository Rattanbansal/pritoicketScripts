SOURCE_DB_HOST='10.10.10.19'
SOURCE_DB_USER='pip'
SOURCE_DB_PASSWORD='pip2024##'
SOURCE_DB_NAME='priopassdb'
CatalogID='140267947063130'
ResellerId='686'


Catalog_product_list="select * from template_level_tickets where catalog_id = '$CatalogID' and deleted = '0'"

Catalog_product_delete="update template_level_tickets set deleted = '8' where catalog_id = '$CatalogID' and deleted = '0' and template_id = '0'"

GETPRODUCT_LINKED_TEMPLATE="select '0' as template_id, tlt.ticket_id, tlt.is_pos_list, tlt.is_suspended, tlt.created_at, tlt.market_merchant_id, tlt.content_description_setting, CURRENT_TIMESTAMP as last_modified_at, cataloglinked_template.subcatalog_id as catalog_id, tlt.merchant_admin_id, tlt.publish_catalog, tlt.product_verify_status, tlt.deleted from (select templatetype.*, catalogtype.catalog_id as subcatalog_id, catalogtype.catalog_type from (select base1.*, (case when resellers.template_id = base1.template_id then 2 else 1 end) as template_type from (select templates.template_id, templates.reseller_id, templates.is_default, templates.catalog_id from templates right join (select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '$ResellerId' and cashier_type = '1') group by template_id, catalog_id) as base on base.template_id = templates.template_id where templates.catalog_id is not NULL group by templates.template_id, templates.reseller_id, templates.catalog_id) as base1 left join resellers on base1.reseller_id = resellers.reseller_id) as templatetype left join (SELECT catalog_id, reseller_id, catalog_type FROM catalogs where catalog_category = '2' and reseller_id = '$ResellerId' and is_deleted = '0' and catalog_id = '$CatalogID') as catalogtype on templatetype.reseller_id = catalogtype.reseller_id and templatetype.template_type = catalogtype.catalog_type) as cataloglinked_template left join template_level_tickets tlt on cataloglinked_template.template_id = tlt.template_id where cataloglinked_template.catalog_type is not NULL and tlt.deleted = '0' and tlt.publish_catalog = '1' and tlt.catalog_id = '0';"

INSERT_GETPRODUCT_LINKED_TEMPLATE="insert into template_level_tickets (template_id, ticket_id, is_pos_list, is_suspended, created_at, market_merchant_id, content_description_setting, last_modified_at, catalog_id, merchant_admin_id, publish_catalog, product_verify_status, deleted)  select '0' as template_id, tlt.ticket_id, tlt.is_pos_list, tlt.is_suspended, tlt.created_at, tlt.market_merchant_id, tlt.content_description_setting, CURRENT_TIMESTAMP as last_modified_at, cataloglinked_template.subcatalog_id as catalog_id, tlt.merchant_admin_id, tlt.publish_catalog, tlt.product_verify_status, tlt.deleted from (select templatetype.*, catalogtype.catalog_id as subcatalog_id, catalogtype.catalog_type from (select base1.*, (case when resellers.template_id = base1.template_id then 2 else 1 end) as template_type from (select templates.template_id, templates.reseller_id, templates.is_default, templates.catalog_id from templates right join (select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '$ResellerId' and cashier_type = '1') group by template_id, catalog_id) as base on base.template_id = templates.template_id where templates.catalog_id is not NULL group by templates.template_id, templates.reseller_id, templates.catalog_id) as base1 left join resellers on base1.reseller_id = resellers.reseller_id) as templatetype left join (SELECT catalog_id, reseller_id, catalog_type FROM catalogs where catalog_category = '2' and reseller_id = '$ResellerId' and is_deleted = '0' and catalog_id = '$CatalogID') as catalogtype on templatetype.reseller_id = catalogtype.reseller_id and templatetype.template_type = catalogtype.catalog_type) as cataloglinked_template left join template_level_tickets tlt on cataloglinked_template.template_id = tlt.template_id where cataloglinked_template.catalog_type is not NULL and tlt.deleted = '0' and tlt.publish_catalog = '1' and tlt.catalog_id = '0';"


COUNT_CATALOG_PRODUCT="select count(*) from template_level_tickets where catalog_id = '$CatalogID' and deleted = '0' and publish_catalog = '1';"

COUNT_CATALOG_LINKED_MAIN_TEMPLATE="select count(tlt.ticket_id) as pcs from (select templatetype.*, catalogtype.catalog_id as subcatalog_id, catalogtype.catalog_type from (select base1.*, (case when resellers.template_id = base1.template_id then 2 else 1 end) as template_type from (select templates.template_id, templates.reseller_id, templates.is_default, templates.catalog_id from templates right join (select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '$ResellerId' and cashier_type = '1') group by template_id, catalog_id) as base on base.template_id = templates.template_id where templates.catalog_id is not NULL group by templates.template_id, templates.reseller_id, templates.catalog_id) as base1 left join resellers on base1.reseller_id = resellers.reseller_id) as templatetype left join (SELECT catalog_id, reseller_id, catalog_type FROM catalogs where catalog_category = '2' and reseller_id = '$ResellerId' and is_deleted = '0' and catalog_id = '$CatalogID') as catalogtype on templatetype.reseller_id = catalogtype.reseller_id and templatetype.template_type = catalogtype.catalog_type) as cataloglinked_template left join template_level_tickets tlt on cataloglinked_template.template_id = tlt.template_id where cataloglinked_template.catalog_type is not NULL and tlt.deleted = '0' and tlt.publish_catalog = '1' and tlt.catalog_id = '0';"

LINKED_TEMPLATE="select template_id from (select templatetype.*, catalogtype.catalog_id as subcatalog_id, catalogtype.catalog_type from (select base1.*, (case when resellers.template_id = base1.template_id then 2 else 1 end) as template_type from (select templates.template_id, templates.reseller_id, templates.is_default, templates.catalog_id from templates right join (select template_id, catalog_id from qr_codes where template_id in (SELECT distinct(template_id) FROM qr_codes where reseller_id = '$ResellerId' and cashier_type = '1') group by template_id, catalog_id) as base on base.template_id = templates.template_id where templates.catalog_id is not NULL group by templates.template_id, templates.reseller_id, templates.catalog_id) as base1 left join resellers on base1.reseller_id = resellers.reseller_id) as templatetype left join (SELECT catalog_id, reseller_id, catalog_type FROM catalogs where catalog_category = '2' and reseller_id = '$ResellerId' and is_deleted = '0' and catalog_id = '$CatalogID') as catalogtype on templatetype.reseller_id = catalogtype.reseller_id and templatetype.template_type = catalogtype.catalog_type) as bbb where subcatalog_id is not NULL"


Linked_Distributors_LIST="select distinct(cod_id) as cod_id from qr_codes where sub_catalog_id = '$CatalogID' and cashier_type = '1'"

echo "" > queries.sql

echo "---------Catalog_product_list--------" >> queries.sql

echo "$Catalog_product_list" >> queries.sql

echo "---------GETPRODUCT_LINKED_TEMPLATE--------" >> queries.sql

echo "$GETPRODUCT_LINKED_TEMPLATE" >> queries.sql

echo "-------COUNT_CATALOG_PRODUCT----------" >> queries.sql
 
echo "$COUNT_CATALOG_PRODUCT" >> queries.sql

echo "-------COUNT_CATALOG_LINKED_MAIN_TEMPLATE----------" >> queries.sql

echo "$COUNT_CATALOG_LINKED_MAIN_TEMPLATE" >> queries.sql

echo "-------LINKED_TEMPLATE----------" >> queries.sql

echo "$LINKED_TEMPLATE" >> queries.sql

echo "-------Linked_Distributors_LIST----------" >> queries.sql

echo "$Linked_Distributors_LIST" >> queries.sql


CatalogLinkedTemplate=$(mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$LINKED_TEMPLATE")

mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$Linked_Distributors_LIST"

SubCatalogCount=$(mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$COUNT_CATALOG_PRODUCT")

echo "Sub catalog Count:- $SubCatalogCount"

MainTemplateCount=$(mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$COUNT_CATALOG_LINKED_MAIN_TEMPLATE")

echo "Main Template ID $CatalogLinkedTemplate having Count:- $MainTemplateCount"

if [[ $SubCatalogCount !=  $MainTemplateCount ]]; then

    echo "Sub catalog Count: $SubCatalogCount Not match with Main Template Count: $MainTemplateCount"

    mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -e "$Catalog_product_delete"

    echo "-------INSERT_GETPRODUCT_LINKED_TEMPLATE----------" >> queries.sql

    echo "$INSERT_GETPRODUCT_LINKED_TEMPLATE" >> queries.sql

    mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -e "$INSERT_GETPRODUCT_LINKED_TEMPLATE"

    SubCatalogCountAfter=$(mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$COUNT_CATALOG_PRODUCT")

    echo "Sub catalog Count:- $SubCatalogCountAfter"

    MainTemplateCountAfter=$(mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "$COUNT_CATALOG_LINKED_MAIN_TEMPLATE")

    echo "Main Template ID $CatalogLinkedTemplate having Count:- $MainTemplateCountAfter"

    if [[ $SubCatalogCountAfter ==  $MainTemplateCountAfter ]]; then

    echo "Count Matched"

    else

    echo "Still Mismatch"
    exit;

    fi 

fi

