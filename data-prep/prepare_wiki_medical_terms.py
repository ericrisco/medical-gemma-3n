import os
import json
from datasets import Dataset
from run_ollama import run_ollama

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARROW_PATH = os.path.join(
    ROOT, 'data', 'wiki_medical_terms', 'gamino___wiki_medical_terms', 'default', '0.0.0',
    '7eb458284a4cf38dd8baf9f2697b46682b9e168b', 'wiki_medical_terms-train.arrow'
)
JSON_DIR = os.path.join(ROOT, 'data-prep', 'json')
OUTPUT_PATH = os.path.join(JSON_DIR, 'wiki_medical_terms.json')

MODEL = 'gemma3n'
TEMPERATURE = 0.4
MAX_TOKENS = 500
SYSTEM_PROMPT_QUESTION = (
    "Given the following medical context, generate a single, highly specific and realistic question that a doctor might have in a moment of doubt about this subject. "
    "The question must be answerable ONLY using the information in the context. "
    "It should reflect a genuine clinical uncertainty or decision point, not general knowledge. "
    "It must be concise (max 20 words), practical, and relevant for medical professionals. "
    "Do not include any disclaimers or mention being an AI. "
    "Do not explain how you arrived at the question, just create it.\n"
)
SYSTEM_PROMPT_ANSWER = (
    "You are a medical expert. Answer ONLY using the information provided in the context below. "
    "Be concise, precise, and do NOT invent or hallucinate information."
    "Do not explain how you are going to answer the question, just create the answer."
    "Do not include any disclaimers or mention being an AI."
    "Do not explain how you arrived to the answer, just create it."
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

# Track already generated questions to avoid duplicates
existing_questions = set(entry['input'] for entry in out)

for idx, row in enumerate(ds):
    title = row.get('page_title', '').strip()
    context = row.get('page_text', '').strip()
    # Prompt for a specific, context-based medical question
    user_prompt_q = (
        f"Context: {context}"
        "QUESTION MUST BE ONLY OF MEDICAL TERMS, NOT DAILY MEDICAL PROBLEMS."
        "QUESTION MUST BE VERY CONCISE, NOT MORE THAN 20 WORDS."
        "QUESTION MUST BE ANSWERABLE ONLY USING THE INFORMATION IN THE CONTEXT."
        "QUESTION MUST BE RELEVANT FOR MEDICAL PROFESSIONALS."
        "QUESTION MUST BE PRACTICAL AND REALISTIC."
        "QUESTION MUST BE ONLY OF MEDICAL TERMS, NOT DAILY MEDICAL PROBLEMS."
        "QUESTION MUST BE VERY CONCISE, NOT MORE THAN 20 WORDS."
        "QUESTION MUST BE ANSWERABLE ONLY USING THE INFORMATION IN THE CONTEXT."
    )
    question = run_ollama(
        model=MODEL,
        system_prompt=SYSTEM_PROMPT_QUESTION,
        user_input=user_prompt_q,
        temperature=TEMPERATURE,
        max_tokens=MAX_TOKENS
    )
    question_stripped = question.strip()
    if question_stripped in existing_questions:
        print(f"Skipping duplicate: {question_stripped}")
        continue
    # Prompt for answer based only on the context
    user_prompt_a = (
        f"{context}\n"
        f"Q: {question_stripped}\n"
        f"A:"
    )
    answer = run_ollama(
        model=MODEL,
        system_prompt=SYSTEM_PROMPT_ANSWER,
        user_input=user_prompt_a,
        temperature=TEMPERATURE,
        max_tokens=MAX_TOKENS
    )
    out.append({
        'input': question_stripped,
        'context': context,
        'output': answer.strip()
    })
    existing_questions.add(question_stripped)
    with open(OUTPUT_PATH, 'w') as f:
        json.dump(out, f, indent=2, ensure_ascii=False)
    print(f"Saved Q&A for record {idx+1}/{len(ds)}")

print(f"JSON file generated at: {OUTPUT_PATH}") 