import os
import json
from datasets import Dataset
from run_ollama import run_ollama

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARROW_PATH = os.path.join(
    ROOT, 'data', 'symptom_to_diagnosis', 'gretelai___symptom_to_diagnosis', 'default', '0.0.0',
    '722cfb0e11f8ae37339c7f573b5e10429b94df49', 'symptom_to_diagnosis-train.arrow'
)
JSON_DIR = os.path.join(ROOT, 'data-prep', 'json')
OUTPUT_PATH = os.path.join(JSON_DIR, 'symptom_to_diagnosis.json')

MODEL = "google/gemma-3n-e4b-it:free"
TEMPERATURE = 0.3
MAX_TOKENS = 300
SYSTEM_PROMPT = (
    "You are a medical doctor. Given the patient's symptoms and a possible diagnosis, respond as you would to a fellow doctor: "
    "be clear, professional, and direct. Do NOT justify with scientific evidence, just communicate the likely diagnosis in natural English. "
    "Do not include any disclaimers or mention being an AI."
)

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
    input_text = row.get('input_text', '').strip()
    output_text = row.get('output_text', '').strip()
    if not input_text or not output_text:
        continue
    if input_text in existing_inputs:
        print(f"Skipping duplicate: {input_text}")
        continue
    user_prompt = (
        f"Patient symptoms: {input_text}\n"
        f"Diagnosis: {output_text}\n"
        "Write a short, direct response as a doctor would say to another doctor, e.g. 'Based on these symptoms, the most likely diagnosis is ...'"
    )
    response = run_ollama(
        model=MODEL,
        system_prompt=SYSTEM_PROMPT,
        user_input=user_prompt,
        temperature=TEMPERATURE,
        max_tokens=MAX_TOKENS
    )
    out.append({
        'input': input_text,
        'context': '',
        'output': response.strip()
    })
    existing_inputs.add(input_text)
    with open(OUTPUT_PATH, 'w') as f:
        json.dump(out, f, indent=2, ensure_ascii=False)
    print(f"Saved {idx+1}/{len(ds)}")