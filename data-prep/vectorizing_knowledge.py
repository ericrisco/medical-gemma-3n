"""
Extract text from PDFs, split into chunks, and generate embeddings using Cohere
"""
import os
import glob
import PyPDF2
import cohere
import numpy as np
from tqdm import tqdm
import json
import dotenv
dotenv.load_dotenv()
from langchain.text_splitter import RecursiveCharacterTextSplitter

COHERE_API_KEY = os.getenv('COHERE_API_KEY')
assert COHERE_API_KEY, 'Set COHERE_API_KEY env variable'
co = cohere.Client(COHERE_API_KEY)

# Configuration
PDF_DIRS = [
    'data/basic_emergency_care',
    'data/ifrc_first_aid_guidelines',
]
CHUNK_SIZE = 512  # Size of text chunks for embeddings
CHUNK_OVERLAP = 128  # Overlap between chunks to preserve context
OUTPUT_PATH = 'data-prep/json/pdf_embeddings.json'

# Load existing embeddings
if os.path.exists(OUTPUT_PATH):
    with open(OUTPUT_PATH, 'r') as f:
        out = json.load(f)
else:
    out = []

# Track existing entries to avoid duplicates
existing = set((entry['pdf'], entry['chunk_id']) for entry in out)

pdf_files = []
for d in PDF_DIRS:
    pdf_files.extend(glob.glob(os.path.join(d, '*.pdf')))

splitter = RecursiveCharacterTextSplitter(
    chunk_size=CHUNK_SIZE,
    chunk_overlap=CHUNK_OVERLAP,
    separators=["\n\n", "\n", ".", " ", ""]
)

all_chunks = []
meta = []
for pdf_path in pdf_files:
    with open(pdf_path, 'rb') as f:
        reader = PyPDF2.PdfReader(f)
        text = ''
        for page in reader.pages:
            text += page.extract_text() or ''
    # Split text into chunks using LangChain
    chunks = splitter.split_text(text)
    pdf_name = os.path.basename(pdf_path)
    for chunk_id, chunk in enumerate(chunks):
        if (pdf_name, chunk_id) in existing:
            continue
        all_chunks.append(chunk)
        meta.append({'pdf': pdf_name, 'chunk_id': chunk_id})

print(f'Generating embeddings for {len(all_chunks)} new chunks...')
embeddings = []
BATCH = 32  # Process embeddings in batches to avoid API rate limits
for i in tqdm(range(0, len(all_chunks), BATCH)):
    batch = all_chunks[i:i+BATCH]
    batch_meta = meta[i:i+BATCH]
    resp = co.embed(texts=batch, model='embed-english-v3.0', input_type='search_document')
    for j, emb in enumerate(resp.embeddings):
        entry = {
            'text': batch[j],
            'embedding': emb,
            'pdf': batch_meta[j]['pdf'],
            'chunk_id': batch_meta[j]['chunk_id']
        }
        out.append(entry)
        existing.add((batch_meta[j]['pdf'], batch_meta[j]['chunk_id']))
    # Save incrementally after each batch to prevent data loss
    with open(OUTPUT_PATH, 'w') as f:
        json.dump(out, f, indent=2, ensure_ascii=False)
    
print(f"Incremental save to {OUTPUT_PATH}. Total: {len(out)} chunks.") 