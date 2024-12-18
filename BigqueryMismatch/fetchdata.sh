#!/bin/bash


tableName=$1
nosofdays=$2
outputfilename=$3
partitioncolumn=$4

# Check if the required arguments are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
    echo "Error: All arguments are required."
    echo "Usage: $0 tableName noofDays outputfilename partitioncolumn"
    exit 1
fi

query="with qr_codesl as (select *,row_number() over(partition by $partitioncolumn order by last_modified_at desc ) as rn from prio_olap.$tableName), qr_codeslrn as (select * from qr_codesl where rn in (1) and last_modified_at > TIMESTAMP(CONCAT(CAST(DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL $nosofdays DAY)) AS STRING), ' 00:00:00'))), distinctcod_id as (select distinct($partitioncolumn) from qr_codeslrn) select * from qr_codesl where $partitioncolumn in (select $partitioncolumn from distinctcod_id) and rn in (1,2) order by $partitioncolumn desc"

echo "$query"


bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
"$query" > $outputfilename