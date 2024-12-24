import pandas as pd
import mysql.connector

# Database Configuration
DB_CONFIG = {
    'host': '10.10.10.19',  # Change this if your DB is on another server
    'user': 'pip',
    'password': 'pip2024##',
    'database': 'rattan'
}

# Load and Process Catalog Data
file_path = 'catalog.csv'
catalog_df = pd.read_csv(file_path, header=None)

# Process Data
current_catalog = None
catalog_data = []

for col in catalog_df.columns:
    catalog_name = catalog_df.iloc[0][col]
    for distributor_id in catalog_df.iloc[1:, col]:
        if pd.notnull(catalog_name):
            current_catalog = catalog_name
        if pd.notnull(distributor_id):
            catalog_data.append((current_catalog, int(distributor_id)))

# Database Insertion
try:
    connection = mysql.connector.connect(**DB_CONFIG)
    cursor = connection.cursor()

    insert_query = """
        INSERT INTO catalog_distributors (catalog_name, distributor_id)
        VALUES (%s, %s)
    """

    cursor.executemany(insert_query, catalog_data)
    connection.commit()
    print(f"{cursor.rowcount} rows inserted successfully!")

except mysql.connector.Error as e:
    print(f"Error: {e}")
    connection.rollback()

finally:
    if cursor:
        cursor.close()
    if connection:
        connection.close()


# CREATE TABLE catalog_distributors ( id SERIAL PRIMARY KEY, catalog_name VARCHAR(255) NOT NULL, distributor_id INT NOT NULL ); 