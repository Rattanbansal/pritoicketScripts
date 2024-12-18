import pandas as pd
import json
from datetime import datetime
import argparse
import os

def load_data(input_file):
    try:
        with open(input_file, 'r') as file:
            data = json.load(file)
        df = pd.DataFrame(data)
        # Convert rn to integer if it's not already
        df['rn'] = pd.to_numeric(df['rn'], errors='coerce')
        return df
    except Exception as e:
        print(f"Error loading JSON file: {e}")
        return None

def compare_records(df, primary_key):
    if primary_key not in df.columns:
        raise ValueError(f"Primary key column '{primary_key}' not found in the data. Available columns: {', '.join(df.columns)}")
    
    # Convert DataFrame to dictionary grouped by primary_key
    grouped = df.groupby(primary_key)
    
    changes_list = []  # List to store changes in a format suitable for DataFrame
    skipped = 0
    
    for key_value, group in grouped:
        # Convert group to DataFrame if it's not already
        group_df = pd.DataFrame(group)
        
        # Check if we have both rn=1 and rn=2
        rn1_exists = (group_df['rn'] == 1).any()
        rn2_exists = (group_df['rn'] == 2).any()
        
        if not (rn1_exists and rn2_exists):
            skipped += 1
            continue
            
        try:
            new_record = group_df[group_df['rn'] == 1].iloc[0]
            old_record = group_df[group_df['rn'] == 2].iloc[0]
            
            # Compare all columns except certain ones we want to exclude
            exclude_columns = {'rn', 'last_modified_at'}
            
            for column in df.columns:
                if column not in exclude_columns:
                    old_val = old_record[column]
                    new_val = new_record[column]
                    
                    # Only record if values are different and not null
                    if pd.notna(old_val) and pd.notna(new_val) and old_val != new_val:
                        changes_list.append({
                            'primary_key': primary_key,
                            'key_value': str(key_value),
                            'column_name': column,
                            'old_value': str(old_val),
                            'new_value': str(new_val),
                            'modified_at': str(new_record['last_modified_at']) if 'last_modified_at' in new_record else None
                        })
                
        except Exception as e:
            print(f"Error processing {primary_key} {key_value}: {e}")
            continue
    
    # Create DataFrame from changes
    changes_df = pd.DataFrame(changes_list)
    
    summary = {
        'total_records_processed': len(df),
        f'unique_{primary_key}s': df[primary_key].nunique(),
        'records_with_rn1': len(df[df['rn'] == 1]),
        'records_with_rn2': len(df[df['rn'] == 2]),
        'skipped_records': skipped,
        'changes_found': len(changes_list),
        'generated_at': datetime.now().isoformat(),
        'primary_key_used': primary_key
    }
    
    return {
        'summary': summary,
        'changes_df': changes_df
    }

def save_report(report_data, output_file):
    try:
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(os.path.abspath(output_file)), exist_ok=True)
        
        # Save changes to CSV
        csv_file = output_file.rsplit('.', 1)[0] + '.csv'
        if not report_data['changes_df'].empty:
            report_data['changes_df'].to_csv(csv_file, index=False)
        
        # Save summary to JSON
        summary_file = output_file.rsplit('.', 1)[0] + '_summary.json'
        with open(summary_file, 'w') as f:
            json.dump(report_data['summary'], f, indent=2)
        
        print(f"\nChanges saved to {csv_file}")
        print(f"Summary saved to {summary_file}")
        
        # Print summary
        summary = report_data['summary']
        print("\nProcessing Summary:")
        print(f"Total records processed: {summary['total_records_processed']}")
        print(f"Unique {summary['primary_key_used']}s: {summary[f'unique_{summary['primary_key_used']}s']}")
        print(f"Records with rn=1: {summary['records_with_rn1']}")
        print(f"Records with rn=2: {summary['records_with_rn2']}")
        print(f"Skipped records: {summary['skipped_records']}")
        print(f"Changes found: {summary['changes_found']}")
        print(f"Generated at: {summary['generated_at']}")
        
    except Exception as e:
        print(f"Error saving report to file: {e}")

def parse_arguments():
    parser = argparse.ArgumentParser(description='Compare records from JSON file based on primary key and row number.')
    parser.add_argument('input_file', help='Input JSON file path')
    parser.add_argument('primary_key', help='Primary key column name (e.g., cod_id)')
    parser.add_argument('output_file', help='Output JSON file path')
    return parser.parse_args()

def main():
    # Parse command line arguments
    args = parse_arguments()
    
    print(f"Loading data from {args.input_file}...")
    df = load_data(args.input_file)
    
    if df is None:
        print("Failed to load data from JSON file")
        return
    
    print(f"\nComparing records using primary key: {args.primary_key}...")
    try:
        report_data = compare_records(df, args.primary_key)
    except ValueError as e:
        print(f"Error: {e}")
        return
    
    print("\nSaving report...")
    save_report(report_data, args.output_file)

if __name__ == "__main__":
    main()
