#!/bin/bash
i=0
# Read each line from the CSV file
while IFS= read -r line; do
  # Print the line (each line represents one row in the single-column CSV)
  echo "$line"
  ((i++))
done < "/home/inteesoft-admin/Downloads/records.csv"

# Print the total row count
echo "Total rows: $i"