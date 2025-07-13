import os
import json
from datasets import Dataset
from run_ollama import run_ollama

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARROW_PATH = os.path.join(
    ROOT, 'data', 'medqa', 'truehealth___medqa', 'default', '0.0.0',
    'e8fc5634288cca740bdd1c8c973f3f41b0171085', 'medqa-train.arrow'
)
JSON_DIR = os.path.join(ROOT, 'data-prep', 'json')
OUTPUT_PATH = os.path.join(JSON_DIR, 'medqa.json')

MODEL = 'gemma3n'
TEMPERATURE = 0.3
MAX_TOKENS = 3000
SYSTEM_PROMPT = (
    "You are a world-class medical doctor. "
    "Answer as a top clinical expert would: be direct, confident, and provide clear, evidence-based explanations. "
    "Do NOT include any disclaimers, do NOT mention being an AI, and do NOT add any non-medical advice. "
    "Do NOT include any non-medical advice. "
    "Do NOT mention the options enumeration."
    "Focus only on the clinical reasoning and the correct answer."
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

existing_questions = set(entry['input'] for entry in out)

for idx, row in enumerate(ds):
    question = row.get('question', '').strip()
    if question in existing_questions:
        print(f"Skipping duplicate: {question}")
        continue
    options = row.get('options', {})
    options_str = "\n".join([f"{k}) {v}" for k, v in options.items() if v])
    answer = row.get('answer', '')
    user_prompt = (
        f"Question: {question}\nOptions:\n{options_str}\n"
        f"Correct answer: {answer}\n"
        "Explain why this is the correct answer, and why the other options are not, in a professional and concise manner."
    )
    response = run_ollama(
        model=MODEL,
        system_prompt=SYSTEM_PROMPT,
        user_input=user_prompt,
        temperature=TEMPERATURE,
        max_tokens=MAX_TOKENS
    )
    out.append({
        'input': question,
        'context': options_str,
        'output': response
    })
    # Save after each example to avoid data loss on interruption
    with open(OUTPUT_PATH, 'w') as f:
        json.dump(out, f, indent=2, ensure_ascii=False)
    print(f"Example {idx+1}/{len(ds)} saved.")

print(f"JSON file generated at: {OUTPUT_PATH}") 