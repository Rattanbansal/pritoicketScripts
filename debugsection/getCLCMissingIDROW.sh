#!/bin/bash

# Start time
start_time=$(date +%s)
set -e  # Exit immediately if any command exits with a non-zero status

mysqlHost="prodrds.prioticket.com"
mysqlUser=pipeuser
mysqlPassword=d4fb46eccNRAL
mysqlDatabase="prioprodrds"
TIMEOUT_PERIOD=450
TIMEOUT_PERIODLIVE=45

source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"
DB_NAME='rattan'

echo "--------------Started with local------------"
sleep 5
source ~/vault/vault_fetch_creds.sh
# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"
DB_NAME='rattan'
MYSQLTABLENEW='primarypricesettings'
echo "Verify information and press enter to continue....................>>>>>>>>>>"
if [[ "$DB_HOST" == "163.47.214.30" ]]; then
  echo "Host Successfully changed"
  echo "$DB_HOST"
else
  echo "Host Not changed so exiting"
  echo "$DB_HOST"
  exit 1
fi

mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "DROP TABLE IF EXISTS $MYSQLTABLENEW;"

createtable="CREATE TABLE $MYSQLTABLENEW (
  vt_group_no varchar(255) NOT NULL,
  clctlcid varchar(255) NOT NULL,
  channel_id varchar(255) NOT NULL,
  catalog_id varchar(255) NOT NULL,
  ticket_id varchar(255) NOT NULL,
  ticketpriceschedule_id varchar(255) NOT NULL,
  las_modified_at timestamp NOT NULL,
  type varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;ALTER TABLE $MYSQLTABLENEW
  ADD KEY vt (vt_group_no),
  ADD KEY ticketid (ticket_id),
  ADD KEY tps (ticketpriceschedule_id),
  ADD KEY ci (channel_id),
  ADD KEY status (catalog_id),
  ADD KEY hi (clctlcid);
COMMIT;"

mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "$createtable"

mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -e "SET GLOBAL local_infile = 1;"

# Read CSV and insert into MySQL
mysql --local-infile=1 -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" <<EOF
LOAD DATA LOCAL INFILE 'primarycommissionsetting.csv'
INTO TABLE $MYSQLTABLENEW
FIELDS TERMINATED BY '\t' 
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

clcids=$(mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sse "SELECT group_concat(distinct(clctlcid)) FROM primarypricesettings where type in (2,3);") || exit 1

tlcids=$(mysql -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" -D"$DB_NAME" -sse "SELECT group_concat(distinct(clctlcid)) FROM primarypricesettings where type in (1);") || exit 1

if [ -z "$clcids" ]; then
  echo "VARIABLE is empty"
else

  clcliveids=$(timeout $TIMEOUT_PERIODLIVE time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"tmp" -e "select distinct channel_level_commission_id from channel_level_commission where channel_level_commission_id in ($clcids)") || exit 1
  echo "$clcids"
  echo "$clcliveids"

  tlcliveids=$(timeout $TIMEOUT_PERIODLIVE time mysql -h"$mysqlHost" -u"$mysqlUser" -p"$mysqlPassword" -D"tmp" -e "select distinct channel_level_commission_id from channel_level_commission where channel_level_commission_id in ($tlcids)") || exit 1
  echo "$tlcids"
  echo "$tlcliveids"

  # Find missing values
  missingclc=$(comm -23 <(echo "$clcids" | tr ',' '\n' | sort) <(echo "$clcliveids" | sort))

  missingtlc=$(comm -23 <(echo "$tlcids" | tr ',' '\n' | sort) <(echo "$tlcliveids" | sort))

  # Output result CLC
  if [ -z "$missingclc" ]; then
    echo "No values are missing."
  else
    echo "Missing values CLC: $missingclc"
  fi

  # Output result TLC
  if [ -z "$missingtlc" ]; then
    echo "No values are missing."
  else
    echo "Missing values TLC: $missingtlc"
  fi
fi