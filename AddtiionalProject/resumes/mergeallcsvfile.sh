#!/bin/bash

# Output file name
output_file="merged.csv"

# Check if there are any CSV files in the current directory
if ls *.csv 1> /dev/null 2>&1; then
    # Initialize a variable to track if the header has been written
    header_written=false

    # Loop through all CSV files
    for file in *.csv; do
        if [ "$header_written" = false ]; then
            # Write the header and data for the first file
            cat "$file" > "$output_file"
            header_written=true
        else
            # Skip the header and append the data for subsequent files
            tail -n +2 "$file" >> "$output_file"
        fi
    done

    echo "All CSV files have been merged into $output_file."
else
    echo "No CSV files found in the current directory."
fi
