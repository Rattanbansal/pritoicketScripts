#!/bin/bash

# Input CSV file
INPUT_FILE="gray.csv"
OUTPUT_FILE="queriesauto.sql"

# Check if the input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file not found at $INPUT_FILE"
    exit 1
fi

# Clear the output file if it exists
> "$OUTPUT_FILE"

# Read the CSV file line by line, skipping the header
tail -n +2 "$INPUT_FILE" | while IFS=',' read -r visitor_group_no tpsid row1 row2; do
    # Validate if fields are not empty
    if [[ -n "$visitor_group_no" && -n "$tpsid" && -n "$row1" && -n "$row2" ]]; then
        # Prepare the SQL query
        echo "update visitor_tickets set action_performed = concat(action_performed, ', CommissionTP'), supplier_net_price = case when row_type = '1' then '${row1}' when row_type = '2' then '${row2}' else 0 end, supplier_gross_price = case when row_type = '1' then '${row1}' when row_type = '2' then '${row2}' else 0 end where vt_group_no = '${visitor_group_no}' and ticketpriceschedule_id = '${tpsid}' and action_performed not like '%CommissionTP';" >> "$OUTPUT_FILE"
    fi
done

echo "SQL queries have been generated in $OUTPUT_FILE"
