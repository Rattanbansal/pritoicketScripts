#!/bin/bash

set -e

# Source the shared credential fetcher
source ~/vault/vault_fetch_creds.sh

# Fetch credentials for 20Server
fetch_db_credentials "19ServerNoVPN_db-creds"

DB_NAME="priopassdb"
from_date=$1

time mysqldump -h"$DB_HOST" -u"$DB_USER" --port=$DB_PORT -p"$DB_PASSWORD" "$DB_NAME" evanevansorders >> test.sql
