import os
import json
from datasets import Dataset

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARROW_PATH = os.path.join(
    ROOT, 'data', 'medicationqa', 'truehealth___medicationqa', 'default', '0.0.0',
    'f8ae96155ac234a54aaf2b70ca4e02d22cfe31af', 'medicationqa-train.arrow'
)
JSON_DIR = os.path.join(ROOT, 'data-prep', 'json')
OUTPUT_PATH = os.path.join(JSON_DIR, 'medicationqa.json')

os.makedirs(JSON_DIR, exist_ok=True)

ds = Dataset.from_file(ARROW_PATH)

out = []
for row in ds:
    out.append({
        'input': row.get('Question', ''),
        'context': '',
        'output': row.get('Answer', '')
    })

with open(OUTPUT_PATH, 'w') as f:
    json.dump(out, f, indent=2, ensure_ascii=False)

print(f"JSON file generated at: {OUTPUT_PATH}") 