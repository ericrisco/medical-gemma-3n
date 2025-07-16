"""
Extract text from PDFs, split into chunks, and generate embeddings using Cohere
Combines first aid and rescue knowledge processing
"""
import os
import glob
import PyPDF2
import cohere
import numpy as np
from tqdm import tqdm
import json
import dotenv
import argparse
dotenv.load_dotenv()
from langchain.text_splitter import RecursiveCharacterTextSplitter

COHERE_API_KEY = os.getenv('COHERE_API_KEY')
assert COHERE_API_KEY, 'Set COHERE_API_KEY env variable'
co = cohere.Client(COHERE_API_KEY)

# Configuration - combining both sets of directories
FIRST_AID_DIRS = [
    'data/basic_emergency_care',
    'data/ifrc_first_aid_guidelines',
    "data/emergency_surgical_care_in_disaster_situations",
    "data/tactical_casualty_combat_care_handbook",
    "data/gfarc_guidelines",
    "data/emergency_medical_services_guidelines",
    "data/cert_basic_pm"
]

RESCUE_DIRS = [
    'data/earthquake_and_tsunami_guide',
    "data/preparedbc_flood_preparedness_guide",
    "data/preparedbc_extreme_heat_guide",
    "data/preparedbc_pandemic_guide",
    "data/preparedbc_winter_guide",
    "data/preparedbc_neighbourhood_guide",
]

def process_pdfs(pdf_dirs, output_path, description=""):
    """Process PDFs from given directories and generate embeddings"""
    
    print(f"INFO: Processing {description}")
    print(f"INFO: Output file: {output_path}")
    
    # Configuration
    CHUNK_SIZE = 512  # Size of text chunks for embeddings
    CHUNK_OVERLAP = 128  # Overlap between chunks to preserve context
    
    # Load existing embeddings
    if os.path.exists(output_path):
        with open(output_path, 'r') as f:
            out = json.load(f)
    else:
        out = []

    # Track existing entries to avoid duplicates
    existing = set((entry['pdf'], entry['chunk_id']) for entry in out)

    pdf_files = []
    for d in pdf_dirs:
        pdf_files.extend(glob.glob(os.path.join(d, '*.pdf')))

    splitter = RecursiveCharacterTextSplitter(
        chunk_size=CHUNK_SIZE,
        chunk_overlap=CHUNK_OVERLAP,
        separators=["\n\n", "\n", ".", " ", ""]
    )

    all_chunks = []
    meta = []
    pdf_stats = {
        'total_found': len(pdf_files),
        'successfully_processed': 0,
        'failed_to_read': 0,
        'failed_files': []
    }

    print(f"INFO: Found {len(pdf_files)} PDF files to process")

    for pdf_path in pdf_files:
        pdf_name = os.path.basename(pdf_path)
        
        try:
            print(f"INFO: Processing {pdf_name}...")
            
            # Check if file exists and is readable
            if not os.path.exists(pdf_path):
                raise FileNotFoundError(f"PDF file not found: {pdf_path}")
            
            if os.path.getsize(pdf_path) == 0:
                raise ValueError(f"PDF file is empty: {pdf_path}")
            
            with open(pdf_path, 'rb') as f:
                try:
                    reader = PyPDF2.PdfReader(f)
                    
                    # Check if PDF is encrypted
                    if reader.is_encrypted:
                        print(f"WARNING: PDF {pdf_name} is encrypted, attempting to decrypt...")
                        # Try to decrypt with empty password
                        if not reader.decrypt(''):
                            raise ValueError(f"Could not decrypt encrypted PDF: {pdf_name}")
                    
                    # Check if PDF has pages
                    if len(reader.pages) == 0:
                        raise ValueError(f"PDF has no pages: {pdf_name}")
                    
                    text = ''
                    pages_processed = 0
                    
                    for page_num, page in enumerate(reader.pages):
                        try:
                            page_text = page.extract_text()
                            if page_text:
                                text += page_text
                                pages_processed += 1
                        except Exception as page_error:
                            print(f"WARNING: Failed to extract text from page {page_num + 1} of {pdf_name}: {page_error}")
                            continue
                    
                    if not text.strip():
                        raise ValueError(f"No extractable text found in PDF: {pdf_name}")
                    
                    print(f"SUCCESS: Extracted text from {pages_processed}/{len(reader.pages)} pages of {pdf_name}")
                    
                except PyPDF2.errors.PdfReadError as pdf_error:
                    raise ValueError(f"PyPDF2 could not read PDF {pdf_name}: {pdf_error}")
                
            # Split text into chunks using LangChain
            chunks = splitter.split_text(text)
            
            if not chunks:
                raise ValueError(f"No text chunks generated from {pdf_name}")
            
            chunks_added = 0
            for chunk_id, chunk in enumerate(chunks):
                if (pdf_name, chunk_id) in existing:
                    continue
                
                # Only add chunks with meaningful content
                if len(chunk.strip()) > 50:  # Minimum chunk size
                    all_chunks.append(chunk)
                    meta.append({'pdf': pdf_name, 'chunk_id': chunk_id})
                    chunks_added += 1
            
            pdf_stats['successfully_processed'] += 1
            print(f"SUCCESS: Added {chunks_added} new chunks from {pdf_name}")
            
        except Exception as e:
            pdf_stats['failed_to_read'] += 1
            pdf_stats['failed_files'].append({'file': pdf_name, 'error': str(e)})
            print(f"ERROR: Failed to process {pdf_name}: {e}")
            continue

    print(f'Generating embeddings for {len(all_chunks)} new chunks...')
    embeddings = []
    BATCH = 32  # Process embeddings in batches to avoid API rate limits
    for i in tqdm(range(0, len(all_chunks), BATCH)):
        batch = all_chunks[i:i+BATCH]
        batch_meta = meta[i:i+BATCH]
        resp = co.embed(texts=batch, model='embed-v4.0', input_type='search_document')
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
        with open(output_path, 'w') as f:
            json.dump(out, f, indent=2, ensure_ascii=False)
        
    print(f"Incremental save to {output_path}. Total: {len(out)} chunks.")
    
    # Print final statistics
    print(f"\n=== PDF Processing Statistics for {description} ===")
    print(f"Total PDFs found: {pdf_stats['total_found']}")
    print(f"Successfully processed: {pdf_stats['successfully_processed']}")
    print(f"Failed to read: {pdf_stats['failed_to_read']}")
    
    if pdf_stats['failed_files']:
        print(f"\nFailed files:")
        for failed in pdf_stats['failed_files']:
            print(f"  - {failed['file']}: {failed['error']}")
    
    return len(out)

def main():
    parser = argparse.ArgumentParser(description="Extract text from medical PDFs and generate embeddings")
    parser.add_argument("--type", choices=["firstaid", "rescue", "combined"], default="combined",
                       help="Type of documents to process")
    parser.add_argument("--output-dir", default="data-prep/json/embeddings",
                       help="Output directory for embeddings")
    
    args = parser.parse_args()
    
    # Ensure output directory exists
    os.makedirs(args.output_dir, exist_ok=True)
    
    if args.type == "firstaid":
        output_path = os.path.join(args.output_dir, "first_aid_embeddings.json")
        total_chunks = process_pdfs(FIRST_AID_DIRS, output_path, "First Aid Documents")
        
    elif args.type == "rescue":
        output_path = os.path.join(args.output_dir, "rescue_embeddings.json")
        total_chunks = process_pdfs(RESCUE_DIRS, output_path, "Rescue Documents")
        
    elif args.type == "combined":
        output_path = os.path.join(args.output_dir, "medical_knowledge_embeddings.json")
        combined_dirs = FIRST_AID_DIRS + RESCUE_DIRS
        total_chunks = process_pdfs(combined_dirs, output_path, "Combined Medical Knowledge")
    
    print(f"\n=== FINAL RESULTS ===")
    print(f"Successfully generated embeddings for {total_chunks} total chunks")
    print(f"Output saved to: {output_path}")

if __name__ == "__main__":
    main()