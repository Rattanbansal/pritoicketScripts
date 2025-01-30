#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status

source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"
DB_NAME='rattan'
start=$1
end=$2
tilldate=$3
BQ_QUERY_FILE="bq_query.sql"
TEMP_QUERY_FILE="bq_temp_query.sql"
OUTPUT_FILE="bq_output.csv"
MYSQL_TABLE="rdsarchive"
ArchiveDate="$tilldate 00:00:01"
startDate="$start 00:00:01"
endDate="$end 23:59:59"

echo $ArchiveDate


rm -f $OUTPUT_FILE

# Step 1: Replace the placeholder with the dynamic date in SQL file
echo "Preparing query..."
sed "s/{{archive_date}}/'$ArchiveDate'/g" $BQ_QUERY_FILE | sed "s/{{startDate}}/'$startDate'/g" | sed "s/{{endDate}}/'$endDate'/g" > $TEMP_QUERY_FILE


# exit 1
# Step 2: Run BigQuery Command
echo "Running BigQuery Query..."

gcloud config set project prioticket-reporting


bq query --use_legacy_sql=False --max_rows=10000000 --format=csv \
< $TEMP_QUERY_FILE > "$OUTPUT_FILE" || exit 1


if [ $? -ne 0 ]; then
    echo "BigQuery query failed. Exiting."
    exit 1
fi

# Clean up temporary query file
rm -f $TEMP_QUERY_FILE

echo "BigQuery query successful. Data saved to $OUTPUT_FILE."

# Step 3: Insert Data into MySQL
echo "Inserting data into MySQL table..."

time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "DROP TABLE IF EXISTS $MYSQL_TABLE" || exit 1

# Create the table if it does not exist
create_table_query="CREATE TABLE $MYSQL_TABLE (
  vt_group_no varchar(255) NOT NULL,
  max_las_modified_at timestamp NOT NULL,
  min_las_modified_at timestamp NOT NULL,
  status int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;ALTER TABLE $MYSQL_TABLE
  ADD KEY vt_group_no (vt_group_no),
  ADD KEY status (status);
COMMIT;"

echo "$create_table_query"

# Execute the query to create the table
time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "$create_table_query" || exit 1

mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "SET GLOBAL local_infile = 1;"

echo "status of query to alter table"

# Load the CSV data into the table
mysql --local-infile=1 -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" <<EOF
LOAD DATA LOCAL INFILE '$OUTPUT_FILE'
INTO TABLE $MYSQL_TABLE
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(vt_group_no, max_las_modified_at, min_las_modified_at, status);
EOF


echo "status of query to insert data"
echo "Data successfully loaded into table: $MYSQL_TABLE"