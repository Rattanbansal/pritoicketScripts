SOURCE_DB_HOST='10.10.10.19'
SOURCE_DB_USER='pip'
SOURCE_DB_PASSWORD='pip2024##'
SOURCE_DB_NAME='rattan'


mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "select vt_group_no, ticketid from orders" | while IFS=$'\t' read -r order_id ticket_id; do

  # Print the values of each column
  echo "Column1: $order_id"
  echo "Column2: $ticket_id"
  echo "---------------------"

done
