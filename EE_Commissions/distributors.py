import pandas as pd
import mysql.connector
from mysql.connector import Error
import argparse
import os

def create_connection():
    """Create a connection to the MySQL database"""
    try:
        connection = mysql.connector.connect(
            host='10.10.10.19',      # e.g., 'localhost' or IP address
            user='pip',      # your MySQL username
            password='pip2024##',  # your MySQL password
            database='rattan'     # your database name
        )
        if connection.is_connected():
            print("Connected to MySQL database")
        return connection
    except Error as e:
        print(f"Error: {e}")
        return None

def insert_batch_to_mysql(batch, connection):
    """Insert a batch of records into the MySQL database"""
    cursor = connection.cursor()
    try:
        # Prepare the insert query
        insert_query = """
            INSERT INTO distributors (ticket_id, hotel_id, commission)
            VALUES (%s, %s, %s)
        """
        # Execute the batch insert
        cursor.executemany(insert_query, batch)
        connection.commit()  # Commit the transaction
        print(f"{cursor.rowcount} records inserted successfully.")
    except Error as e:
        print(f"Error inserting batch: {e}")
        connection.rollback()  # Rollback on error
    finally:
        cursor.close()

def modify_csv(input_file, output_file):
    # Step 1: Read the CSV file into a pandas DataFrame
    df = pd.read_csv(input_file)
    
    # Step 2: Drop the first 5 rows
    df = df.iloc[4:]
    
    # Step 3: Drop the first 3 columns
    df = df.iloc[:, 2:]

    # Step 4: Keep the 4th column delete next 4 columns
    df = df.iloc[:, [0] + list(range(5, df.shape[1]))]
    
    # Step 5: Write the modified DataFrame back to a new CSV
    df.to_csv(output_file, index=False, header=False)

def process_csv_and_insert_batch(csv_file_path, connection):
    # Read the CSV into a pandas DataFrame
    df = pd.read_csv(csv_file_path)

    # Initialize a list to store records for the current batch
    batch = []

    #
    batch_size = 100
    
    # Iterate through each row in the DataFrame
    for _, row in df.iterrows():
        ticket_id = row['Product Id - Prio']  # Assuming the first column is TicketId
        # Iterate over all the DistId columns (assuming the first column is TicketId)
        for dist_id_column in df.columns[1:]:
            dist_id = dist_id_column  # DistId (column name)
            commission = row[dist_id_column]  # Commission for this DistId
            
            # Convert commission to numeric, coercing errors to NaN
            commission = pd.to_numeric(commission, errors='coerce')
            
            # Skip if commission is zero, missing (NaN), or not a valid number
            if pd.isna(commission):
                continue
            # Add the current record to the batch
            commission = f"{commission:.2f}"
            batch.append((ticket_id, dist_id, commission))

            # If batch reaches the specified batch_size, process and reset the batch
            if len(batch) >= batch_size:
                insert_batch_to_mysql(batch, connection)
                batch = []  # Reset batch for next set of records
                
    # If there are any remaining records in the batch, process them
    if batch:
        insert_batch_to_mysql(batch, connection)

def main():
    # Set up argparse to handle command-line arguments
    parser = argparse.ArgumentParser(description="Insert records into MySQL database from a CSV file.")
    parser.add_argument('csv_file_path', help="Path to the CSV file to process")

    # Parse arguments
    args = parser.parse_args()
    # MySQL database connection
    connection = create_connection()
    if connection:
         # Path to your CSV file
        csv_file_path = args.csv_file_path  # Replace with your actual CSV file path
        directory, filename = os.path.split(csv_file_path)
        name, ext = os.path.splitext(filename)
        # Create a new file name by appending 'modified' to the original name
        modified_filename = f"{name}_modified{ext}"
        # Construct the full path for the modified file
        modified_file_path = os.path.join(directory, modified_filename)
        modify_csv(csv_file_path,modified_file_path)
        process_csv_and_insert_batch(modified_file_path, connection)
        connection.close()  # Close the connection after processing

if __name__ == "__main__":
    main()
