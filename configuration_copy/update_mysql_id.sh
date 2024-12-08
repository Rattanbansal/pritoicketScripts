#!/bin/bash

# Database connection parameters
DBHOST='163.47.214.30'
DBUSER='datalook'
DBPWD='datalook2024$$'
DBDATABASE='priopassdb'
PORT="3307"

# Output files to store auto-increment values
AUTO_INCREMENT_FILE="/home/intersoft-admin/rattan/pritoicketScripts/configuration_copy/auto_increment_values.txt"
NO_AUTO_INCREMENT_FILE="/home/intersoft-admin/rattan/pritoicketScripts/configuration_copy/no_auto_increment_tables.txt"

# Function to get the next auto-increment value for a table
get_next_auto_increment() {
    local table="$1"
    # Query to get the next auto-increment value
    mysql -h "$DBHOST" --port="$PORT" -u "$DBUSER" -p"$DBPWD" -D "$DBDATABASE" -se \
        "SELECT AUTO_INCREMENT 
         FROM information_schema.TABLES 
         WHERE TABLE_SCHEMA = '$DBDATABASE' 
         AND TABLE_NAME = '$table'"
}

# Function to list all tables in the database
list_tables() {
    mysql -h "$DBHOST" --port="$PORT" -u "$DBUSER" -p"$DBPWD" -D "$DBDATABASE" -se \
        "SHOW TABLES"
}

# Clear previous output files
> "$AUTO_INCREMENT_FILE"
> "$NO_AUTO_INCREMENT_FILE"

# Main script
echo "Discovering tables in database: $DBDATABASE"

# Iterate through all tables
for table in $(list_tables); do
    auto_increment=$(get_next_auto_increment "$table")
    
    # Check if auto-increment exists
    if [[ -n "$auto_increment" && "$auto_increment" != "NULL" ]]; then
        # Store table name and auto-increment value in the auto-increment file
        echo "$table:$auto_increment" >> "$AUTO_INCREMENT_FILE"
        echo "Auto-Increment: $table with next auto-increment $auto_increment"
    else
        # Store tables without auto-increment in a separate file
        echo "$table" >> "$NO_AUTO_INCREMENT_FILE"
        echo "No Auto-Increment: $table"
    fi
done

echo "Auto-increment values have been stored in $AUTO_INCREMENT_FILE"
echo "Tables without auto-increment have been stored in $NO_AUTO_INCREMENT_FILE"
