import os
import json
from datasets import Dataset

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARROW_PATH = os.path.join(
    ROOT, 'data', 'first_aid_dataset', 'badri55___first_aid__dataset', 'default', '0.0.0',
    '2e6b21cec15c74df188a04a2a347bbe9fb25fb3e', 'first_aid__dataset-train.arrow'
)
JSON_DIR = os.path.join(ROOT, 'data-prep', 'json')
OUTPUT_PATH = os.path.join(JSON_DIR, 'first_aid_dataset.json')

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
    patterns = row.get('patterns', [])
    responses = row.get('responses', [])
    if not patterns or not responses:
        continue
    input_text = patterns[0].strip()
    output_text = responses[0].strip()
    if not output_text:
        print(f"Skipping empty output for input: {input_text}")
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