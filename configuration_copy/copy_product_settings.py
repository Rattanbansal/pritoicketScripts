import mysql.connector
from mysql.connector import Error
import argparse
from typing import Dict, Any, List
import logging
import json

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class DatabaseMigration:
    def __init__(self, source_config: Dict[str, Any], target_config: Dict[str, Any]):
        self.source_conn = None
        self.target_conn = None
        self.source_config = source_config
        self.target_config = target_config
        
    def connect(self):
        """Establish connections to both databases"""
        try:
            self.source_conn = mysql.connector.connect(**self.source_config)
            self.target_conn = mysql.connector.connect(**self.target_config)
            logger.info("Successfully connected to both databases")
        except Error as e:
            logger.error(f"Error connecting to databases: {e}")
            raise

    def close(self):
        """Close database connections"""
        if self.source_conn:
            self.source_conn.close()
        if self.target_conn:
            self.target_conn.close()

    def get_table_data(self, table_name: str, where_clause: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Fetch data from any table based on where conditions"""
        cursor = self.source_conn.cursor(dictionary=True)
        
        where_conditions = " AND ".join([f"{k} = %s" for k in where_clause.keys()])
        query = f"""
        SELECT * FROM {table_name} 
        WHERE {where_conditions}
        """
        
        cursor.execute(query, list(where_clause.values()))
        data = cursor.fetchall()
        cursor.close()
        return data

    def get_related_data(self, table_name: str, relation: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Fetch related data based on foreign key relationship"""
        return self.get_table_data(table_name, relation)

    def insert_data(self, table_name: str, data: Dict[str, Any], id_mappings: Dict[str, Dict[int, int]]) -> int:
        """Insert data into target table and return new ID"""
        cursor = self.target_conn.cursor()
        
        # Create a copy of data to modify
        insert_data = data.copy()
        
        # Update foreign keys based on id_mappings
        for column, mapping in id_mappings.items():
            if column in insert_data and insert_data[column] in mapping:
                insert_data[column] = mapping[column][insert_data[column]]
        
        # Remove primary key to let database generate new one
        primary_key = self.get_primary_key(table_name)
        if primary_key in insert_data:
            old_id = insert_data.pop(primary_key)
        
        columns = ', '.join(insert_data.keys())
        placeholders = ', '.join(['%s'] * len(insert_data))
        
        query = f"""
        INSERT INTO {table_name} ({columns})
        VALUES ({placeholders})
        """
        
        cursor.execute(query, list(insert_data.values()))
        new_id = cursor.lastrowid
        self.target_conn.commit()
        cursor.close()
        
        logger.info(f"Inserted into {table_name}. Old ID: {old_id}, New ID: {new_id}")
        return new_id, old_id

    def get_primary_key(self, table_name: str) -> str:
        """Get primary key column name for a table"""
        cursor = self.source_conn.cursor()
        cursor.execute(f"""
            SELECT COLUMN_NAME
            FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
            WHERE TABLE_SCHEMA = %s
            AND TABLE_NAME = %s
            AND CONSTRAINT_NAME = 'PRIMARY'
        """, (self.source_config['database'], table_name))
        
        result = cursor.fetchone()
        cursor.close()
        
        if not result:
            raise ValueError(f"No primary key found for table {table_name}")
        
        return result[0]

    def copy_table_data(self, config: Dict[str, Any]):
        """Copy data from source to target based on configuration"""
        try:
            id_mappings = {}  # Store mappings between old and new IDs for each table
            
            def process_table(table_config: Dict[str, Any], parent_values: Dict[str, Any] = None):
                table_name = table_config['table']
                where_clause = parent_values if parent_values else table_config.get('where', {})
                
                # Get data from source table
                source_data = self.get_table_data(table_name, where_clause)
                if not source_data:
                    logger.warning(f"No data found in {table_name} with conditions: {where_clause}")
                    return
                
                # Initialize ID mapping for this table
                if table_name not in id_mappings:
                    id_mappings[table_name] = {}
                
                # Process each row
                for row in source_data:
                    # Insert into target and get new ID
                    new_id, old_id = self.insert_data(table_name, row, id_mappings)
                    id_mappings[table_name][old_id] = new_id
                    
                    # Process related tables
                    if 'related_tables' in table_config:
                        for related_config in table_config['related_tables']:
                            related_where = {
                                related_config['foreign_key']: new_id
                            }
                            process_table(related_config, related_where)
            
            # Start processing from main table
            process_table(config)
            
            logger.info("Successfully copied all related data")
            return id_mappings
            
        except Error as e:
            self.target_conn.rollback()
            logger.error(f"Error during migration: {e}")
            raise

def main():
    parser = argparse.ArgumentParser(description='Copy data between databases with relationships')
    parser.add_argument('config_file', type=str, help='JSON configuration file path')
    parser.add_argument('--source-host', required=True, help='Source database host')
    parser.add_argument('--source-user', required=True, help='Source database user')
    parser.add_argument('--source-password', required=True, help='Source database password')
    parser.add_argument('--source-database', required=True, help='Source database name')
    parser.add_argument('--target-host', required=True, help='Target database host')
    parser.add_argument('--target-user', required=True, help='Target database user')
    parser.add_argument('--target-password', required=True, help='Target database password')
    parser.add_argument('--target-database', required=True, help='Target database name')

    args = parser.parse_args()

    # Read configuration
    with open(args.config_file, 'r') as f:
        config = json.load(f)

    source_config = {
        'host': args.source_host,
        'user': args.source_user,
        'password': args.source_password,
        'database': args.source_database
    }

    target_config = {
        'host': args.target_host,
        'user': args.target_user,
        'password': args.target_password,
        'database': args.target_database
    }

    migration = DatabaseMigration(source_config, target_config)
    
    try:
        migration.connect()
        id_mappings = migration.copy_table_data(config)
        print("Migration completed successfully")
        print("ID mappings:", json.dumps(id_mappings, indent=2))
    except Exception as e:
        print(f"Error: {e}")
    finally:
        migration.close()

if __name__ == "__main__":
    main()
