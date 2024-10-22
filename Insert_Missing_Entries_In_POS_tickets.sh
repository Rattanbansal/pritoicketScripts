#!/bin/bash

rm -rf pos_missing_entries.csv
rm -rf pos_tickets_enable_status.csv
# Define the CSV file path
csv_file="/home/rattan/Downloads/jassi1.csv"

# Define the column name you want to loop through
column_name="hotel_id"

# Read the CSV file and loop through the specified column
#hotel_ids=$(awk -F',' -v col_name="$column_name" 'BEGIN {getline; split($0, headers, ","); for (i=1; i<=NF; i++) {if (headers[i]==col_name) {col_index=i; break}}} {print $col_index}' "$csv_file")

product_ids="66767 66767 66768 66769 66812 66813 66853 66854 66873 66878 66889 66892 66898 66906 66908 66924 66925 66927 66934 66939"

#product_ids="66767"
for product_id in ${product_ids}

do

#curl https://cron.prioticket.com/backend/Script/insertion_posticket/$hotel_id/0/1 >> pos_missing_entries.csv
curl https://cron.prioticket.com/backend/Script/insertion_posticket/0/$product_id/1 >> pos_missing_entries.txt
echo "insertion for $product_id completed"
sleep 10

# curl https://cron.prioticket.com/backend/Update_posticket_poslist/update_poslist/$hotel_id/0/1 >> pos_tickets_enable_status.csv
curl https://cron.prioticket.com/backend/Update_posticket_poslist/update_poslist/0/$product_id/1 >> pos_tickets_enable_status.txt
echo "updations for $product_id completed"

echo $product_id


sleep 10
done

