import sys
import os
from collections import defaultdict

def create_change_summary(csv_file):
    # Dictionary to store changes for each key
    changes_by_key = defaultdict(list)
    
    with open(csv_file, 'r') as f:
        # Read header
        header = f.readline().strip().split(',')
        key_idx = header.index('key_value')
        col_idx = header.index('column_name')
        old_idx = header.index('old_value')
        new_idx = header.index('new_value')
        
        # Process each line
        for line in f:
            parts = line.strip().split(',')
            key_value = parts[key_idx]
            column = parts[col_idx]
            old_val = parts[old_idx]
            new_val = parts[new_idx]
            
            changes_by_key[key_value].append({
                'column': column,
                'old': old_val,
                'new': new_val
            })
    
    # Create output file with changes
    output_file = csv_file.replace('.csv', '_changes.txt')
    with open(output_file, 'w') as f:
        for key in sorted(changes_by_key.keys()):
            f.write(f"\nKey Value: {key}\n")
            f.write("=" * 50 + "\n")
            
            for change in changes_by_key[key]:
                f.write(f"Column: {change['column']}\n")
                f.write(f"  Old Value: {change['old']}\n")
                f.write(f"  New Value: {change['new']}\n")
                f.write("-" * 30 + "\n")
    
    print(f"\nChange summary saved to: {output_file}")
    print(f"Total records with changes: {len(changes_by_key)}")

def main():
    if len(sys.argv) != 2:
        print("Usage: python create_pivot.py <diff_csv_file>")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    if not os.path.exists(csv_file):
        print(f"Error: File {csv_file} not found")
        sys.exit(1)
    
    create_change_summary(csv_file)

if __name__ == "__main__":
    main()
