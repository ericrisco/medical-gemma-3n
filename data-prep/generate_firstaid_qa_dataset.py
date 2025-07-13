"""
Generate Q&A dataset for extreme first aid scenarios using RAG with PDF embeddings
"""
import os
import json
import numpy as np
import faiss
from tqdm import tqdm
from run_ollama import run_ollama
import random

import cohere
import dotenv
dotenv.load_dotenv()
co = cohere.Client(os.getenv('COHERE_API_KEY'))

# Configuration
EMBED_JSON = 'data-prep/json/pdf_embeddings.json'
OUT_JSON = 'data-prep/json/extreme_firstaid_qa_dataset.json'
N_CONTEXT = 5  # Number of context chunks to retrieve for each question
MODEL = 'gemma3n'  # Ollama model for text generation
TEMPERATURE = 0.7  # Higher temperature for creative question generation
MAX_TOKENS = 350
GENERATIONS = 1000  # Number of Q&A pairs to generate

# Medical emergency topics for question generation
TOPICS = [
    "severe bleeding",
    "open wounds",
    "fractures or broken bones",
    "serious burns",
    "animal bite",
    "poisonous plant",
    "poisonous mushroom",
    "crush injuries",
    "improvised care with no supplies"
]

# Extreme emergency situations for realistic scenario generation
SITUATIONS = [
    "war zones",
    "remote rural areas",
    "low-income or disaster-struck regions",
    "places without cell coverage, clean water, or medical infrastructure",
    "a refugee camp with limited medical supplies",
    "a disaster zone after an earthquake",
    "a flooded village cut off from emergency services",
    "a remote island with no pharmacy or hospital",
    "a collapsed building with people trapped inside",
    "a jungle expedition far from civilization",
    "a desert crossing with no access to water",
    "a mountain pass during a snowstorm",
    "a conflict area with active fighting nearby",
    "a shipwreck survivor stranded on the coast",
    "a remote mining camp with no communication",
    "a rural school with no nurse or doctor",
    "a nomadic community moving through harsh terrain",
    "a remote outpost in the Arctic",
    "a village under quarantine with no outside help",
    "a long-distance hiking trail with no cell signal",
    "a remote oil rig or construction site",
    "a remote forest during a wildfire",
    "a remote farm during a power outage"
]

SYSTEM_PROMPT_QUESTION_TEMPLATE = '''
You are a seasoned expert in emergency medicine and humanitarian crises. Generate one realistic, non-repetitive, concise, and practical question in English that someone might ask a chatbot about first aid in the following situation: 
{situation}

The question must be feasible in such conditions and relevant to real-life emergencies involving: 
{topic}.

Avoid general knowledge, disclaimers, or repeated questions.

Generate only one question at a time, highly specific and practical.
'''

SYSTEM_PROMPT_ANSWER = (
    "You are a medical professional. Answer ONLY using the provided context below. "
    "If you cannot answer with the context, or the question does not make sense (for example a snake bite in the middle of the sea), respond with NULL. Do not invent or hallucinate."
)

# Load embeddings from file
with open(EMBED_JSON, 'r') as f:
    data = json.load(f)

# Convert embeddings to numpy array for FAISS indexing
embeddings = np.array([d['embedding'] for d in data]).astype('float32')
texts = [d['text'] for d in data]

# Load existing output or create new
if os.path.exists(OUT_JSON):
    with open(OUT_JSON, 'r') as f:
        out = json.load(f)
else:
    out = []
existing_questions = set(entry['input'] for entry in out)

# Initialize FAISS index for similarity search
dim = embeddings.shape[1]
index = faiss.IndexFlatL2(dim)  # L2 distance for embedding similarity
index.add(embeddings)

for _ in tqdm(range(GENERATIONS)):
    topic = random.choice(TOPICS)
    situation = random.choice(SITUATIONS)
    system_prompt_question = SYSTEM_PROMPT_QUESTION_TEMPLATE.format(topic=topic, situation=situation)
    # Generate question using model
    question = run_ollama(
        model=MODEL,
        system_prompt=system_prompt_question,
        user_input="Generate a new question.",
        temperature=TEMPERATURE,
        max_tokens=MAX_TOKENS
    ).strip()
    if not question or question in existing_questions:
        continue
    # Generate embedding for the question using Cohere
    emb = co.embed(texts=[question], model='embed-english-v3.0', input_type='search_query').embeddings[0]
    emb = np.array(emb).astype('float32').reshape(1, -1)
    # Search for top N_CONTEXT similar chunks
    D, I = index.search(emb, N_CONTEXT)
    context_chunks = [texts[i] for i in I[0]]
    # Generate answer using only the retrieved context
    context_str = '\n'.join(context_chunks)
    user_prompt = f"Context:\n{context_str}\nQ: {question}\nA:"
    answer = run_ollama(
        model=MODEL,
        system_prompt=SYSTEM_PROMPT_ANSWER,
        user_input=user_prompt,
        temperature=0.2,
        max_tokens=MAX_TOKENS
    ).strip()
    if answer.upper() == 'NULL' or answer == '' or 'NULL' in answer:
        continue
    
    out.append({
        'input': question,
        'context': context_str,
        'output': answer
    })
    existing_questions.add(question)
    with open(OUT_JSON, 'w') as f:
        json.dump(out, f, indent=2, ensure_ascii=False)
    print(f"Saved Q&A: {question}") 