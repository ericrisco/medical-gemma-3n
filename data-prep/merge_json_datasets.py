import os
import json

# Directory containing the JSON files to merge
DIR_PATH = 'data-prep/json'
# Output file path
OUT_PATH = 'data-prep/json/medical_training_dataset.json'
# Exclude this file from merging
EXCLUDE = {'pdf_embeddings.json'}

all_data = []

for fname in os.listdir(DIR_PATH):
    if not fname.endswith('.json') or fname in EXCLUDE:
        continue
    fpath = os.path.join(DIR_PATH, fname)
    with open(fpath, 'r') as f:
        try:
            data = json.load(f)
        except Exception as e:
            print(f"Error loading {fname}: {e}")
            continue
    # If the file contains a list of records, add each with its source
    if isinstance(data, list):
        for entry in data:
            entry['source'] = os.path.splitext(fname)[0]
            all_data.append(entry)
    # If the file contains a single record (dict), add it with its source
    elif isinstance(data, dict):
        data['source'] = os.path.splitext(fname)[0]
        all_data.append(data)

with open(OUT_PATH, 'w') as f:
    json.dump(all_data, f, indent=2, ensure_ascii=False)

print(f"Saved {len(all_data)} records to {OUT_PATH}") 