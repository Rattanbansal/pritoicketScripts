#!/bin/bash
TIMEOUT_PERIOD=450
TIMEOUT_PERIODLIVE=45
source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"
DB_NAME='rattan'

RESULT=$(timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "SELECT vt_group_no, hotel_id, ticketId, ticketpriceschedule_id FROM EEBigqueryMismatch where status = '0' and ticketpriceschedule_id != '0' group by vt_group_no, hotel_id, ticketId, ticketpriceschedule_id") || exit 1

# Check if the query was successful
if [ $? -ne 0 ]; then
  echo "Query failed or timed out."
  exit 1
fi

source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "PrioticketLivePriomaryroPipe"
DB_NAME='priopassdb'
echo "Verify information and press enter to continue....................>>>>>>>>>>"
echo $DB_HOST
read rattan



# Loop through the result
while read -r LINE; do
  VT_GROUP_NO=$(echo "$LINE" | awk '{print $1}')
  HOTEL_ID=$(echo "$LINE" | awk '{print $2}')
  TICKET_ID=$(echo "$LINE" | awk '{print $3}')
  TICKETPRICESCHEDULE_ID=$(echo "$LINE" | awk '{print $4}')
  
  # Perform actions with VT_GROUP_NO and TICKET_ID
  echo "Processing vt_group_no: $VT_GROUP_NO,hotel_id: $HOTEL_ID, ticket_id: $TICKET_ID, ticketpriceschedule_id: $TICKETPRICESCHEDULE_ID"

  if [[ $VT_GROUP_NO == "" ]]; then
    break
  fi

  getCatalogData="SELECT '$VT_GROUP_NO' as vt_group_no,channel_level_commission_id, channel_id, catalog_id, ticket_id, ticketpriceschedule_id, las_modified_at, 'CATALOG' as type FROM channel_level_commission where catalog_id in (select sub_catalog_id from qr_codes where cod_id = '$HOTEL_ID' and sub_catalog_id > '2') and ticketpriceschedule_id = '$TICKETPRICESCHEDULE_ID' and deleted = '0' and is_adjust_pricing = '1';"

  getCLCData="SELECT '$VT_GROUP_NO' as vt_group_no,channel_level_commission_id, channel_id, catalog_id, ticket_id, ticketpriceschedule_id, las_modified_at, '3' as type FROM channel_level_commission where channel_id in (select channel_id from qr_codes where cod_id = '$HOTEL_ID') and ticketpriceschedule_id = '$TICKETPRICESCHEDULE_ID' and deleted = '0' and is_adjust_pricing = '1';"

  getTLCData="select '$VT_GROUP_NO' as vt_group_no,ticket_level_commission_id, hotel_id,'0' as catalog_id, ticket_id, ticketpriceschedule_id, las_modified_at, '1' as type from ticket_level_commission where ticketpriceschedule_id = '411331' and hotel_id = '44587' and deleted = '0' and is_adjust_pricing = '1'"

  echo "$getCatalogData"
  echo "$getCLCData"
  echo "$getTLCData"

  exit 1
  timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "$getCatalogData" >> primarycommissionsetting.csv
  timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "$getCLCData" >> primarycommissionsetting.csv
  timeout $TIMEOUT_PERIOD time mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sN -e "$getTLCData" >> primarycommissionsetting.csv
  


  sleep 2

done <<< "$RESULT"

source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"
DB_NAME='rattan'
MYSQLTABLENEW='primarypricesettings'

echo "Verify information and press enter to continue....................>>>>>>>>>>"
echo $DB_HOST
read rattan


mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "DROP TABLE IF EXISTS $MYSQLTABLENEW;"

createtable="CREATE TABLE $MYSQLTABLENEW (
  vt_group_no bigint NOT NULL,
  clctlcid int NOT NULL,
  channel_id int NOT NULL,
  catalog_id int NOT NULL,
  ticket_id int NOT NULL,
  ticketpriceschedule_id int NOT NULL,
  las_modified_at timestamp NOT NULL,
  type int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;ALTER TABLE $MYSQLTABLENEW
  ADD KEY vt (vt_group_no),
  ADD KEY ticketid (ticket_id),
  ADD KEY tps (ticketpriceschedule_id),
  ADD KEY ci (channel_id),
  ADD KEY status (catalog_id),
  ADD KEY hi (hotel_id);
COMMIT;"

mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "$createtable"

mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "SET GLOBAL local_infile = 1;"

# Read CSV and insert into MySQL
mysql --local-infile=1 -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" <<EOF
LOAD DATA LOCAL INFILE primarycommissionsetting.csv
INTO TABLE $MYSQLTABLENEW
FIELDS TERMINATED BY '\n' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(vt_group_no,clctlcid,channel_id,catalog_id,ticket_id, ticketpriceschedule_id, las_modified_at, type);
EOF

if [ $? -ne 0 ]; then
    echo "MySQL data insertion failed. Exiting."
    exit 1
fi

echo "Data successfully inserted into MySQL table: $MYSQL_TABLE"