import os
import json
import numpy as np
import faiss
import argparse
from tqdm import tqdm
from run_ollama import run_ollama
from pathlib import Path

def load_embeddings(embeddings_file):
    """Load embeddings from JSON file"""
    print(f"INFO: Loading embeddings from {embeddings_file}")
    
    if not os.path.exists(embeddings_file):
        raise FileNotFoundError(f"Embeddings file not found: {embeddings_file}")
    
    with open(embeddings_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"SUCCESS: Loaded {len(data)} embeddings")
    return data

def create_faiss_index(embeddings_data):
    """Create FAISS index from embeddings data"""
    print("INFO: Creating FAISS vectorstore...")
    
    # Extract embeddings and metadata
    embeddings = []
    texts = []
    
    for item in embeddings_data:
        if 'embedding' in item and 'text' in item:
            embeddings.append(item['embedding'])
            texts.append(item['text'])
    
    if not embeddings:
        raise ValueError("No valid embeddings found in data")
    
    # Convert to numpy array
    embeddings_matrix = np.array(embeddings, dtype=np.float32)
    
    # Create FAISS index
    dimension = embeddings_matrix.shape[1]
    index = faiss.IndexFlatIP(dimension)  # Inner product for similarity
    
    # Normalize embeddings for cosine similarity
    faiss.normalize_L2(embeddings_matrix)
    index.add(embeddings_matrix)
    
    print(f"SUCCESS: Created FAISS index with {len(embeddings)} vectors (dimension: {dimension})")
    return index, texts

def search_similar_chunks(query_embedding, index, texts, k=5):
    """Search for similar chunks using FAISS"""
    # Normalize query embedding
    query_embedding = np.array([query_embedding], dtype=np.float32)
    faiss.normalize_L2(query_embedding)
    
    # Search
    scores, indices = index.search(query_embedding, k)
    
    # Return results
    results = []
    for i, (score, idx) in enumerate(zip(scores[0], indices[0])):
        if idx < len(texts):  # Valid index
            results.append({
                'text': texts[idx],
                'score': float(score),
                'rank': i + 1
            })
    
    return results

def generate_questions_from_chunks(chunks_text):
    """Generate 3 medical questions from concatenated chunks using Gemma 3N"""
    
    system_prompt = """You are a medical emergency instructor creating training questions for doctors, nurses, and paramedics.

CRITICAL REQUIREMENTS:
- Questions MUST be practical medical scenarios that healthcare workers face
- Questions MUST be about patient care, treatment procedures, or emergency response
- Questions MUST be answerable using the provided medical context
- Return ONLY a valid JSON array with exactly 3 questions
- Format: ["Question 1?", "Question 2?", "Question 3?"]
- Do not include ```json or ``` in the response

FORBIDDEN QUESTIONS (DO NOT CREATE):
❌ About licenses, copyrights, or document metadata
❌ About training materials, handbooks, or educational content
❌ About document structure, chapters, or organization
❌ Abstract concepts not related to direct patient care
❌ Questions mentioning "document", "handbook", "manual", "guide", "section", "chapter"

REQUIRED QUESTION TYPES (CREATE THESE):
✅ Patient assessment: "What signs indicate...?"
✅ Treatment procedures: "How should you treat...?"
✅ Emergency protocols: "What is the first step when...?"
✅ Equipment usage: "When using [medical device], what precautions...?"
✅ Clinical decisions: "If a patient presents with X, you should...?"
✅ Rescue techniques: "During a rescue, how do you...?"

EXAMPLES OF GOOD QUESTIONS:
- "What vital signs should be monitored in a patient with severe blood loss?"
- "How do you properly immobilize a suspected spinal injury?"
- "What medication dosage is appropriate for treating severe allergic reactions?"
- "When should you use a tourniquet for bleeding control?"

If the provided text does not contain enough medical information to create 3 practical healthcare questions, return exactly: null

Do not include any explanation, just the JSON array or null."""

    user_prompt = f"""Based on this medical text, create exactly 3 questions:

TEXT:
{chunks_text}

Return only the JSON array of 3 questions."""

    response = run_ollama(
        model="gemma3n",
        user_input=user_prompt,
        system_prompt=system_prompt,
        temperature=0.8,
        max_tokens=300
    )
    
    if not response:
        return None
    
    try:
        cleaned_response = response.strip()
        questions = json.loads(cleaned_response)
        
        if isinstance(questions, list) and len(questions) == 3:
            valid_questions = []
            
            # Filter for medical/rescue questions only
            forbidden_words = [
                'handbook', 'manual', 'guide', 'document', 'section', 'chapter', 
                'license', 'copyright', 'creative commons', 'training material',
                'educational content', 'course', 'curriculum', 'syllabus',
                'topics covered', 'purpose of', 'structure of', 'organized'
            ]
            
            required_medical_indicators = [
                'patient', 'treatment', 'procedure', 'medical', 'emergency', 
                'rescue', 'first aid', 'injury', 'wound', 'bleeding', 'fracture',
                'vital signs', 'medication', 'dose', 'symptom', 'diagnosis',
                'equipment', 'device', 'technique', 'protocol', 'assessment',
                'breathing', 'airway', 'circulation', 'pulse', 'blood pressure'
            ]
            
            for q in questions:
                if isinstance(q, str) and len(q.strip()) > 10:
                    q_lower = q.lower()
                    
                    has_forbidden = any(word in q_lower for word in forbidden_words)
                    
                    has_medical = any(word in q_lower for word in required_medical_indicators)
                    
                    if has_medical and not has_forbidden:
                        valid_questions.append(q)
            
            if len(valid_questions) >= 2:
                return valid_questions[:3]
    except json.JSONDecodeError:
        pass
    
    print(f"WARNING: Failed to parse questions from response: {response[:100]}...")
    return None

def answer_question_with_context(question, original_context, search_results):
    """Answer a question using both original context and search results"""
    
    # Combine contexts
    search_context = "\n\n".join([result['text'] for result in search_results])
    
    system_prompt = """You are an emergency medicine physician providing clinical guidance.

STRICT REQUIREMENTS:
1. Answer ONLY medical questions about patient care, treatment, or emergency procedures
2. Answer ONLY if you can provide a complete clinical answer using the provided context
3. If the question is about documents, training materials, licenses, or administrative topics: return exactly "null"
4. If the question cannot be answered with the medical context provided: return exactly "null"
5. Provide specific, actionable clinical guidance for healthcare professionals
6. Include specific steps, dosages, timings, or measurements when available in context

FORBIDDEN TOPICS (always return "null"):
❌ Document structure, licensing, copyrights
❌ Training program organization or curriculum
❌ Administrative or educational metadata
❌ General advice not based on provided clinical context

REQUIRED TOPICS (provide detailed answers):
✅ Patient assessment and vital signs
✅ Treatment protocols and procedures  
✅ Emergency interventions and medications
✅ Equipment usage and safety precautions
✅ Clinical decision-making criteria

Return either a detailed clinical answer OR exactly "null"."""

    user_prompt = f"""QUESTION: {question}

ORIGINAL CONTEXT:
{original_context}

ADDITIONAL MEDICAL CONTEXT:
{search_context}

Provide a complete medical answer using this context, or return "null" if insufficient information or non-medical question."""

    response = run_ollama(
        model="gemma3n",
        prompt=user_prompt,
        system_prompt=system_prompt,
        temperature=0.3,  # Lower temperature for more accurate answers
        max_tokens=400
    )
    
    if not response or response.strip().lower() == "null":
        return None
    
    return response.strip()

def process_embeddings_in_chunks(embeddings_data, index, texts, output_file, chunk_size=5):
    
    print(f"INFO: Processing embeddings in chunks of {chunk_size}")
    print(f"INFO: Output file: {output_file}")
    
    # Load existing data if file exists
    existing_data = []
    if os.path.exists(output_file):
        try:
            with open(output_file, 'r', encoding='utf-8') as f:
                existing_data = json.load(f)
            print(f"INFO: Loaded {len(existing_data)} existing Q&A pairs")
        except:
            print("INFO: Starting with empty dataset")
    
    total_chunks = len(embeddings_data) // chunk_size
    successful_generations = 0
    
    for i in tqdm(range(0, len(embeddings_data), chunk_size), desc="Processing chunks"):
        chunk = embeddings_data[i:i+chunk_size]
        
        if len(chunk) < chunk_size:
            continue  # Skip incomplete chunks
        
        # Concatenate text from chunk
        chunk_texts = []
        for item in chunk:
            if 'text' in item:
                chunk_texts.append(item['text'])
        
        if len(chunk_texts) < chunk_size:
            continue
        
        concatenated_text = "\n\n".join(chunk_texts)
        
        # Generate questions
        questions = generate_questions_from_chunks(concatenated_text)
        if not questions:
            continue
        
        # Process each question
        for question in questions:
            try:
                # Check if this exact question already exists in the dataset
                question_exists = any(
                    existing_item.get("input", "").strip() == question.strip() 
                    for existing_item in existing_data
                )
                
                if question_exists:
                    print(f"INFO: Skipping duplicate question: {question[:50]}...")
                    continue
                
                # Use first chunk's embedding for similarity search
                query_embedding = chunk[0]['embedding']
                
                # Search for similar chunks
                search_results = search_similar_chunks(query_embedding, index, texts, k=5)
                
                # Generate answer
                answer = answer_question_with_context(question, concatenated_text, search_results)
                
                if answer:  # Only save if we got a valid answer
                    qa_pair = {
                        "input": question,
                        "context": "",  # Keep empty as per original format
                        "output": answer,
                        "source": "advanced_firstaid_rag"
                    }
                    
                    existing_data.append(qa_pair)
                    successful_generations += 1
                    
                    # Save incrementally every 10 successful generations
                    if successful_generations % 10 == 0:
                        with open(output_file, 'w', encoding='utf-8') as f:
                            json.dump(existing_data, f, indent=2, ensure_ascii=False)
                        print(f"INFO: Saved {successful_generations} Q&A pairs")
                
            except Exception as e:
                print(f"WARNING: Error processing question '{question[:50]}...': {e}")
                continue
    
    # Final save
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(existing_data, f, indent=2, ensure_ascii=False)
    
    print(f"SUCCESS: Generated {successful_generations} Q&A pairs")
    print(f"SUCCESS: Total dataset size: {len(existing_data)} examples")
    print(f"SUCCESS: Saved to: {output_file}")

def main():
    parser = argparse.ArgumentParser(description="Generate advanced first aid Q&A using RAG")
    parser.add_argument("embeddings_file", help="Path to embeddings JSON file")
    parser.add_argument("--output", default="/Volumes/EXTERN/DEV/gemma3n-impact-challenge/data-prep/json/advanced_firstaid_qa.json", 
                       help="Output JSON file path")
    parser.add_argument("--chunk_size", type=int, default=5, 
                       help="Number of chunks to process together")
    
    args = parser.parse_args()
    
    print("INFO: === Advanced First Aid Q&A Generation with RAG ===")
    print(f"INFO: Embeddings file: {args.embeddings_file}")
    print(f"INFO: Output file: {args.output}")
    print(f"INFO: Chunk size: {args.chunk_size}")
    print("=" * 60)
    
    try:
        # Load embeddings
        embeddings_data = load_embeddings(args.embeddings_file)
        
        # Create FAISS index
        index, texts = create_faiss_index(embeddings_data)
        
        # Ensure output directory exists
        os.makedirs(os.path.dirname(args.output), exist_ok=True)
        
        # Process embeddings and generate Q&A
        process_embeddings_in_chunks(embeddings_data, index, texts, args.output, args.chunk_size)
        
    except Exception as e:
        print(f"ERROR: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())