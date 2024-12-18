#!/bin/bash

# Mismatch for QR_codes

tablename=qr_codes
days=$1
partitioncolumn=cod_id

rm -f *.json
rm -f *.csv

# Check if the required arguments are provided
if [ -z "$1" ]; then
    echo "Error: All arguments are required."
    echo "Usage: $0 noofDays"
    exit 1
fi

source fetchdata.sh $tablename $days $tablename.json $partitioncolumn

python compare_record.py $tablename.json $partitioncolumn $tablename-Diff.csv

# tablename=modeventcontent
# partitioncolumn=mec_id

# source fetchdata.sh $tablename $days $tablename.json $partitioncolumn

# python compare_record.py $tablename.json $partitioncolumn $tablename-Diff.csv

# tablename=ticketpriceschedule
# partitioncolumn=id

# source fetchdata.sh $tablename $days $tablename.json $partitioncolumn

# python compare_record.py $tablename.json $partitioncolumn $tablename-Diff.csv