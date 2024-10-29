import mysql.connector
import re
import sys

def fetch_data(select_query):
    # Connect to your database
    conn = mysql.connector.connect(
        host='10.10.10.20',
        user='admin',
        password='root_12345',
        database='dummy_db'
    )
    cursor = conn.cursor()
    cursor.execute(select_query)
    data = cursor.fetchall()
    cursor.close()
    conn.close()
    return data

def generate_insert(select_query, data):
    # Extract table name
    table_name = re.search(r'from (\w+)', select_query, re.I).group(1)

    # Generate insert statement
    insert_query = f"INSERT INTO {table_name} VALUES\n"
    values_list = []

    for row in data:
        # Convert row into a comma-separated string
        values = ', '.join(f"'{str(value)}'" if isinstance(value, str) else str(value) for value in row)
        values_list.append(f"({values})")
    
    insert_query += ',\n'.join(values_list) + ';'
    return insert_query

def append_to_file(insert_query, filename):
    with open(filename, 'a') as file:
        file.write(insert_query + '\n')

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python generate_insert.py '<SELECT_QUERY>' <OUTPUT_FILE>")
        sys.exit(1)

    select_query = sys.argv[1]
    output_file = sys.argv[2]

    try:
        data = fetch_data(select_query)
        insert_query = generate_insert(select_query, data)
        append_to_file(insert_query, output_file)
        print(f"INSERT query appended to {output_file}")
    except Exception as e:
        print(f"Error: {e}")