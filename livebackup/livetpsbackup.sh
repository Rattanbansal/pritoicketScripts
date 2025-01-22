#!/bin/bash

set -e  # Exit immediately if any command exits with a non-zero status
TIMEOUT_PERIOD=20

### Database Credentials For 19 DB
# LOCAL_HOST="10.10.10.19"
# LOCAL_USER="pip"
# LOCAL_PASS="pip2024##"
# LOCAL_NAME="priopassdb"

# DB_HOST="10.10.10.19"
# DB_USER="pip"
# DB_PASS="pip2024##"
# DB_NAME="priopassdb"


DB_HOST="production-primary-db-node-cluster.cluster-ck6w2al7sgpk.eu-west-1.rds.amazonaws.com"
DB_USER="prt_dbadmin"
DB_PASS="YI7g3zXYLaRLf06HTX2s"
DB_NAME="priopassdb"



time mysqldump --single-transaction --lock-tables=false --skip-comments --no-tablespaces --skip-lock-tables -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" ticketpriceschedule >> ticketpriceschedule.sql || exit 1

# time mysql -h"$LOCAL_HOST" -u"$LOCAL_USER" -p"$LOCAL_PASS" -D"$LOCAL_NAME" < ticketpriceschedule.sql || exit 1

