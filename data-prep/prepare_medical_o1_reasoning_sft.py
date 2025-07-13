import os
import json
from datasets import Dataset

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARROW_PATH = os.path.join(
    ROOT, 'data', 'medical_o1_reasoning_sft', 'FreedomIntelligence___medical-o1-reasoning-sft', 'en', '0.0.0',
    'fc2c9e8a37b38f38da6d449564a8c350b244aef4', 'medical-o1-reasoning-sft-train.arrow'
)
JSON_DIR = os.path.join(ROOT, 'data-prep', 'json')
OUTPUT_PATH = os.path.join(JSON_DIR, 'medical_o1_reasoning_sft.json')

os.makedirs(JSON_DIR, exist_ok=True)

ds = Dataset.from_file(ARROW_PATH)

out = []
for row in ds:
    question = row.get('Question', '').strip()
    cot = row.get('Complex_CoT', '').strip()
    response = row.get('Response', '').strip()
    # Combine reasoning and response in a single output field
    output = f"<reasoning>\n{cot}\n</reasoning>\n{response}"
    out.append({
        'input': question,
        'context': '',
        'output': output
    })

with open(OUTPUT_PATH, 'w') as f:
    json.dump(out, f, indent=2, ensure_ascii=False)

print(f"JSON file generated at: {OUTPUT_PATH}") 