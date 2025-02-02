#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status


MYSQL_HOST="10.10.10.19"
MYSQL_USER="pip"
MYSQL_PASSWORD="pip2024##"
MYSQL_DB="priopassdb"
BQ_QUERY_FILE="bq_query.sql"
OUTPUT_FILE="bq_output.csv"
MYSQL_TABLE="bigqueryData"

rm -f $OUTPUT_FILE

BQ_QUERY_FILE="WITH
pt1 AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY prepaid_ticket_id ORDER BY last_modified_at DESC, IFNULL(version, '1') DESC) AS rn 
    FROM prioticket-reporting.prio_olap.scan_report
),
pt AS (
    SELECT * 
    FROM pt1 
    WHERE rn=1 AND deleted=0
),
mec1 AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY mec_id ORDER BY last_modified_at DESC) AS rn 
    FROM prioticket-reporting.prio_olap.modeventcontent
),
mec AS (
    SELECT * 
    FROM mec1 
    WHERE rn=1 AND deleted='0' AND reseller_id=541
)
SELECT DISTINCT ticket_id, tps_id, hotel_id, channel_id, reseller_id 
FROM pt 
WHERE order_confirm_date > '2024-12-01 00:00:00' 
AND ticket_id IN (SELECT mec_id FROM mec)"

# Step 2: Run BigQuery Command
echo "Running BigQuery Query..."

gcloud config set project prioticket-reporting


bq query --use_legacy_sql=False --max_rows=1000000 --format=csv \
"$BQ_QUERY_FILE" > $OUTPUT_FILE || exit 1

if [ $? -ne 0 ]; then
    echo "BigQuery query failed. Exiting."
    exit 1
fi

echo "BigQuery query successful. Data saved to $OUTPUT_FILE."

# Step 3: Insert Data into MySQL
echo "Inserting data into MySQL table..."

mysql -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" -e "Truncate Table bigqueryData;"

mysql -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" -e "SET GLOBAL local_infile = 1;"

# Read CSV and insert into MySQL
mysql --local-infile=1 -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" <<EOF
LOAD DATA LOCAL INFILE '$OUTPUT_FILE'
INTO TABLE $MYSQL_TABLE
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(ticket_id, tps_id, hotel_id, channel_id, reseller_id);
EOF

if [ $? -ne 0 ]; then
    echo "MySQL data insertion failed. Exiting."
    exit 1
fi

echo "Data successfully inserted into MySQL table: $MYSQL_TABLE"


echo "Process completed successfully."



# CREATE TABLE bigqueryData (
#     ticket_id INT(11),
#     tps_id INT(11),
#     hotel_id INT(11),
#     channel_id INT(11),
#     reseller_id INT(11)
# );