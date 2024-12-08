#!/bin/bash

# Input file with stored auto-increment values
INPUT_FILE="/home/intersoft-admin/rattan/pritoicketScripts/configuration_copy/auto_increment_values.txt"

# Increment value (can be modified as needed)
INCREMENT=50

# Database connection parameters
DBHOST='163.47.214.30'
DBUSER='datalook'
DBPWD='datalook2024$$'
DBDATABASE='priopassdb'
PORT="3307"

# Check if input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file $INPUT_FILE not found. Run update_mysql_id.sh first."
    exit 1
fi

# Function to get current auto-increment value
get_current_auto_increment() {
    local table="$1"
    mysql -h "$DBHOST" --port="$PORT" -u "$DBUSER" -p"$DBPWD" -D "$DBDATABASE" -se \
        "SELECT AUTO_INCREMENT 
         FROM information_schema.TABLES 
         WHERE TABLE_SCHEMA = '$DBDATABASE' 
         AND TABLE_NAME = '$table'"
}

# Read the input file and process each line
while IFS=':' read -r table current_increment; do
    # Calculate new increment
    new_increment=$((current_increment + INCREMENT))
    
    # Print the ALTER TABLE command for verification
    echo "Attempting to change AUTO_INCREMENT for $table:"
    echo "Current AUTO_INCREMENT: $current_increment"
    echo "Planned NEW AUTO_INCREMENT: $new_increment"
    echo "ALTER TABLE $table AUTO_INCREMENT = $new_increment"
    # Modify the auto-increment
    mysql -h "$DBHOST" --port="$PORT" -u "$DBUSER" -p"$DBPWD" -D "$DBDATABASE" -se \
        "ALTER TABLE $table AUTO_INCREMENT = $new_increment"
    
    mysql -h "$DBHOST" --port="$PORT" -u "$DBUSER" -p"$DBPWD" -D "$DBDATABASE" -se \
        "ANALYZE TABLE $table; "
    # Verify the change
    after_increment=$(get_current_auto_increment "$table")
    
    echo "Verified AUTO_INCREMENT after change: $after_increment"
    
    # Additional verification
    if [[ "$after_increment" == "$new_increment" ]]; then
        echo "SUCCESS: AUTO_INCREMENT updated successfully for $table"
    else
        echo "WARNING: AUTO_INCREMENT did not update as expected for $table"
        echo "Expected: $new_increment, Current: $after_increment"
    fi
    
    echo "----------------------------"
    
    # Add a small delay to ensure database has time to process
    sleep 2
done < "$INPUT_FILE"

echo "Auto-increment update process completed."
