import os
import json
from datasets import Dataset

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARROW_PATH = os.path.join(
    ROOT, 'data', 'medical_o1_verifiable_problem', 'FreedomIntelligence___medical-o1-verifiable-problem', 'default', '0.0.0',
    '46d5175eb74fdef3516d51d52e8c40db04bbdf35', 'medical-o1-verifiable-problem-train.arrow'
)
JSON_DIR = os.path.join(ROOT, 'data-prep', 'json')
OUTPUT_PATH = os.path.join(JSON_DIR, 'medical_o1_verifiable_problem.json')

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
existing_questions = set(entry['input'] for entry in out)

for idx, row in enumerate(ds):
    question = row.get('Open-ended Verifiable Question', '').strip()
    if question in existing_questions:
        print(f"Skipping duplicate: {question}")
        continue
    answer = row.get('Ground-True Answer', '').strip()
    out.append({
        'input': question,
        'context': '',
        'output': answer
    })
    existing_questions.add(question)
    with open(OUTPUT_PATH, 'w') as f:
        json.dump(out, f, indent=2, ensure_ascii=False)
    print(f"Saved {idx+1}/{len(ds)}")

print(f"JSON file generated at: {OUTPUT_PATH}") 