#!/bin/bash

# Database credentials
DB_HOST="10.10.10.19"
DB_USER="pip"
DB_PASS="pip2024##"
DB_NAME="priopassdb"

# Variables
BATCH_SIZE=5000
ROW_OFFSET=0

# Loop until there are no more records to insert
while :; do
    # Execute the insert query with a limit and offset, and check row count
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
        INSERT INTO dynamic_price_variations_backup
        SELECT * FROM dynamic_price_variations
        WHERE deleted = '1'
        LIMIT $ROW_OFFSET, $BATCH_SIZE;
        SELECT ROW_COUNT();
    " > row_count_output.txt

    # Extract the row count from the output
    ROW_COUNT=$(tail -n 1 row_count_output.txt)

    # Exit the loop if no more rows were inserted
    if [[ "$ROW_COUNT" -eq 0 ]]; then
        echo "All records have been inserted."
        break
    fi

    # Increment the offset for the next batch
    ROW_OFFSET=$((ROW_OFFSET + ROW_COUNT))

    echo "$ROW_COUNT rows inserted, moving to the next batch..."

    sleep 2
    
done

# Clean up
# rm row_count_output.txt
