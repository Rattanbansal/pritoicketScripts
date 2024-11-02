#!/bin/bash

batch_size=1000  # Number of records to process in each batch
batch_values=()  # Array to store values for the current batch
total_rows=0     # Counter for total rows updated

# Read each line from the CSV file
while IFS= read -r line || [ -n "$line" ]; do
  # Add each vt_group_no to the current batch array
  batch_values+=("$line")

  # When batch size is reached, execute the batch update
  if (( ${#batch_values[@]} == batch_size )); then
    # Join the batch values into a comma-separated list
    batch_list=$(printf ",%s" "${batch_values[@]}")
    batch_list=${batch_list:1}  # Remove the leading comma

    query="UPDATE orders 
      SET status = '0' 
      WHERE vt_group_no IN ($batch_list) 
      AND status = '2';"
    # Run the MySQL update for the current batch
    mysql -uadmin -predhat dummy -e "
      UPDATE orders 
      SET status = '0' 
      WHERE vt_group_no IN ($batch_list) 
      AND status = '2';
    "

    echo "$query" >> updatestatus.sql
    echo "---------------->>>>><<<<<------------" >> updatestatus.sql
    
    # Get the number of rows affected and add it to the total
    rows_updated=$(mysql -uadmin -predhat dummy -N -e "SELECT ROW_COUNT();")
    total_rows=$((total_rows + rows_updated))

    # Clear the batch array for the next batch
    batch_values=()
  fi
done < "/home/inteesoft-admin/Downloads/records.csv"

# Process any remaining values in the last batch
if (( ${#batch_values[@]} > 0 )); then
  batch_list=$(printf ",%s" "${batch_values[@]}")
  batch_list=${batch_list:1}

  query1="UPDATE orders 
    SET status = '0' 
    WHERE vt_group_no IN ($batch_list) 
    AND status = '2';"

    echo "$query1" >> updatestatus1.sql
    echo "---------------->>>>><<<<<------------" >> updatestatus1.sql

  mysql -uadmin -predhat dummy -e "
    UPDATE orders 
    SET status = '0' 
    WHERE vt_group_no IN ($batch_list) 
    AND status = '2';
  "
  
  rows_updated=$(mysql -uadmin -predhat dummy -N -e "SELECT ROW_COUNT();")
  total_rows=$((total_rows + rows_updated))
fi

# Print the total row count
echo "Total rows updated: $total_rows"
