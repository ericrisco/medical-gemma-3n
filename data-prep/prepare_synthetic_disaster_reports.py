import os
import json
from datasets import Dataset

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARROW_PATH = os.path.join(
    ROOT, 'data', 'synthetic_disaster_reports', 'paulelliotco___synthetic-disaster-reports', 'default', '0.0.0',
    '6b1c51f0d706ab286e2ea8831ae738b03f4eec24', 'synthetic-disaster-reports-train.arrow'
)
JSON_DIR = os.path.join(ROOT, 'data-prep', 'json')
OUTPUT_PATH = os.path.join(JSON_DIR, 'synthetic_disaster_reports.json')

os.makedirs(JSON_DIR, exist_ok=True)

ds = Dataset.from_file(ARROW_PATH)

def load_existing(path):
    if os.path.exists(path):
        with open(path, 'r') as f:
            try:
                return json.load(f)
            except Exception:
                return []
    return []

out = load_existing(OUTPUT_PATH)
existing_inputs = set(entry['input'] for entry in out)

for idx, row in enumerate(ds):
    disaster_type = (row.get('disaster_type') or '').strip()
    severity = (row.get('severity_level') or '').strip()
    responder_notes = (row.get('responder_notes') or '').strip()
    resource_needs = row.get('resource_needs') or []
    if not disaster_type or not severity or not responder_notes or not resource_needs:
        continue
    input_text = f"There is a {severity.lower()} {disaster_type.lower()}. Situation: {responder_notes}"
    output_text = f"The main resources needed are: {', '.join(resource_needs)}."
    if not input_text.strip() or not output_text.strip():
        continue
    if input_text in existing_inputs:
        print(f"Skipping duplicate: {input_text}")
        continue
    out.append({
        'input': input_text,
        'context': '',
        'output': output_text
    })
    existing_inputs.add(input_text)
    with open(OUTPUT_PATH, 'w') as f:
        json.dump(out, f, indent=2, ensure_ascii=False)
    print(f"Saved {idx+1}/{len(ds)}")

print(f"JSON file generated at: {OUTPUT_PATH}") 