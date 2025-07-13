import os
import json
from datasets import Dataset

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARROW_PATH = os.path.join(
    ROOT, 'data', 'diseases_symptoms', 'QuyenAnhDE___diseases_symptoms', 'default', '0.0.0',
    'd06f2b069db182e43b55f1ca454589f66530eb26', 'diseases_symptoms-train.arrow'
)
JSON_DIR = os.path.join(ROOT, 'data-prep', 'json')
OUTPUT_PATH = os.path.join(JSON_DIR, 'diseases_symptoms.json')

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
    symptoms = (row.get('Symptoms') or '').strip()
    name = (row.get('Name') or '').strip()
    treatments = (row.get('Treatments') or '').strip()
    if not symptoms or not name or not treatments:
        continue
    output = f"It seems you may have {name}. The usual treatment is {treatments}."
    if not output.strip() or not symptoms.strip():
        continue
    if symptoms in existing_inputs:
        print(f"Skipping duplicate: {symptoms}")
        continue
    out.append({
        'input': symptoms,
        'context': '',
        'output': output
    })
    existing_inputs.add(symptoms)
    with open(OUTPUT_PATH, 'w') as f:
        json.dump(out, f, indent=2, ensure_ascii=False)
    print(f"Saved {idx+1}/{len(ds)}")

print(f"JSON file generated at: {OUTPUT_PATH}") 