#!/bin/bash

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8


# Function to normalize MySQL data
normalize_mysql_data() {
    local mysql_raw=$1
    echo "$mysql_raw" | jq -c '[.[] | {
        channel_level_commission_id: (.channel_level_commission_id | tostring),
        ticket_id: (.ticket_id | tostring),
        ticketpriceschedule_id: (.ticketpriceschedule_id | tostring),
        deleted: (.deleted | tostring),
        last_modified_at: .last_modified_at
    }] | sort_by(.channel_level_commission_id)'
}

# Function to normalize BigQuery data
normalize_bq_data() {
    local bq_raw=$1
    echo "$bq_raw" | jq -c '[.[] | {
        channel_level_commission_id: .channel_level_commission_id,
        ticket_id: .ticket_id,
        ticketpriceschedule_id: .ticketpriceschedule_id,
        deleted: .deleted,
        last_modified_at: .last_modified_at
    }] | sort_by(.channel_level_commission_id)'
}

selectQueryColumns="channel_level_commission_id, ticket_id, ticketpriceschedule_id, deleted, last_modified_at"
partition_column="channel_level_commission_id"

# Clean up old files
echo "-------------Script Starting So removing all Json Files-----------"
rm -rf *.json

# BigQuery project setup
echo "-----------Started Fetching Data from BigQuery--------"
gcloud config set project prioticket-reporting

# MySQL connection details
DBHOST="10.10.10.19"
DBUSER="pip"
DBPWD="pip2024##"
DBDATABASE="priopassdb"

# Fetch catalog IDs from MySQL
echo "-----------Fetching Data from MySQL-----------"
catalog_ids=$(mysql -h $DBHOST -u $DBUSER -p$DBPWD $DBDATABASE -N -e \
"SELECT DISTINCT catalog_id 
 FROM channel_level_commission 
 WHERE deleted = '0' AND catalog_id > 2 AND channel_id = 0;" 2>/dev/null)

echo "------Script Started at: $(date '+%Y-%m-%d %H:%M:%S.%3N')--------"

for catalog_id in ${catalog_ids}

do

    # Define output file
    output_file="comparison_results_${catalog_id}.txt"

    echo "------$catalog_id - Started at: $(date '+%Y-%m-%d %H:%M:%S.%3N')--------"

    mysql_data=$(echo "SELECT $selectQueryColumns FROM channel_level_commission WHERE deleted = '0' AND catalog_id > 2 and catalog_id = '$catalog_id' AND channel_id = 0 and channel_level_commission_id = '10072103';" | time mysqlsh --sql --json --uri $DBUSER@$DBHOST -p$DBPWD --database=$DBDATABASE | jq 'select(.warning | not) | .rows | map(.)')
    

    bq_data=$(bq query --use_legacy_sql=False --max_rows=100000 --format=json \
    "with final as (select $selectQueryColumns, row_number () over ( partition by $partition_column order by last_modified_at desc) as rn from prioticket-reporting.prio_test.channel_level_commission where catalog_id = $catalog_id and channel_level_commission_id = 10072103) select *except(rn) from final where rn = 1")

    # Normalize MySQL data
    mysql_data=$(normalize_mysql_data "$mysql_data")

    echo "-------------------MYSQL Data----------------"

    echo "$mysql_data"
    

    echo "-------------------BQ Data----------------"

    # Normalize BigQuery data
    bq_data=$(normalize_bq_data "$bq_data")

    # Compare normalized datasets
    echo "Comparing MySQL and BigQuery data for catalog_id: $catalog_id" | tee -a "$output_file"
    diff_output=$(diff <(echo "$mysql_data") <(echo "$bq_data"))

    if [ -z "$diff_output" ]; then
        echo "Data matches for catalog_id: $catalog_id" | tee -a "$output_file"
    else
        echo "Data mismatch for catalog_id: $catalog_id" | tee -a "$output_file"
        echo "--------------------" | tee -a "$output_file"
        # echo "MySQL Data (Normalized):" | tee -a "$output_file"
        # echo "$mysql_data" | jq . | tee -a "$output_file"
        # echo "--------------------" | tee -a "$output_file"
        # echo "BigQuery Data (Normalized):" | tee -a "$output_file"
        # echo "$bq_data" | jq . | tee -a "$output_file"
        # echo "--------------------" | tee -a "$output_file"
        echo "Differences:" | tee -a "$output_file"
        echo "$diff_output" | tee -a "$output_file"
    fi


    echo "------$catalog_id - Ended at: $(date '+%Y-%m-%d %H:%M:%S.%3N')--------"


    exit 1

done

echo "------Script Ended at: $(date '+%Y-%m-%d %H:%M:%S.%3N')--------"