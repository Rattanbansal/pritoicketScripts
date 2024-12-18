#!/bin/bash

# Mismatch for QR_codes

tablename=qr_codes
days=$1
partitioncolumn=cod_id

rm -f *.json
rm -f *.csv
rm -f *.txt

# Check if the required arguments are provided
if [ -z "$1" ]; then
    echo "Error: All arguments are required."
    echo "Usage: $0 noofDays"
    exit 1
fi

source fetchdata.sh $tablename $days $tablename.json $partitioncolumn

python compare_record.py $tablename.json $partitioncolumn $tablename-Diff.csv

python create_pivot.py $tablename-Diff.csv

rm -f $tablename.json

tablename=channel_level_commission
partitioncolumn=channel_level_commission_id

source fetchdata.sh $tablename $days $tablename.json $partitioncolumn

python compare_record.py $tablename.json $partitioncolumn $tablename-Diff.csv

python create_pivot.py $tablename-Diff.csv

rm -f $tablename.json

tablename=ticket_level_commission
partitioncolumn=ticket_level_commission_id

source fetchdata.sh $tablename $days $tablename.json $partitioncolumn

python compare_record.py $tablename.json $partitioncolumn $tablename-Diff.csv

python create_pivot.py $tablename-Diff.csv

rm -f $tablename.json

tablename=ticketpriceschedule
partitioncolumn=id

source fetchdata.sh $tablename $days $tablename.json $partitioncolumn

python compare_record.py $tablename.json $partitioncolumn $tablename-Diff.csv

python create_pivot.py $tablename-Diff.csv

rm -f $tablename.json


tablename=modeventcontent
partitioncolumn=mec_id

source fetchdata.sh $tablename $days $tablename.json $partitioncolumn

python compare_record_json.py $tablename.json $partitioncolumn $tablename-Diff.json


rm -f $tablename.json