import json
from deepdiff import DeepDiff
import pandas as pd

# Load JSON data fetched from BigQuery
with open('qr_codes_data.json', 'r') as file:
    data = json.load(file)

# Step 1: Convert data into a DataFrame for grouping
df = pd.DataFrame(data)

# Step 2: Group data by `cod_id` and compare rows
for cod_id, group in df.groupby("cod_id"):
    group = group.sort_values(by='rn')  # Sort by rn to ensure correct order
    json_old = json.loads(group[group['rn'] == 2]['json_data'].values[0])  # Old record (rn=2)
    json_new = json.loads(group[group['rn'] == 1]['json_data'].values[0])  # New record (rn=1)
    
    print(f"\n=== Differences for cod_id: {cod_id} ===")
    diff = DeepDiff(json_old, json_new, ignore_order=True, verbose_level=2)
    
    if diff:
        for change_type, changes in diff.items():
            print(f"{change_type}:")
            for key, value in changes.items():
                print(f"  {key}: {value}")
    else:
        print("No differences found!")
