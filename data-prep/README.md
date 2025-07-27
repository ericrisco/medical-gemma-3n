# Medical Data Preparation Pipeline

This directory contains scripts to prepare medical datasets for training specialized language models. The pipeline processes both structured medical datasets and emergency care PDFs to create a comprehensive training dataset.

## 📋 Overview

The pipeline processes:
- **11 Medical Datasets** from Hugging Face (Q&A, reasoning, symptoms, medications)
- **14 Official Emergency/Medical PDFs** (WHO, ICRC, government agencies)
- **RAG-Generated Data** from PDF knowledge using Ollama
- **Final Merged Dataset** with 80K+ medical examples

## 🚀 Quick Start

### Prerequisites

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Set up environment variables:**
   ```bash
   # Create .env file in project root
   COHERE_API_KEY=your_cohere_api_key
   ```

3. **Install and configure Ollama:**
   ```bash
   # Install Ollama (https://ollama.ai)
   curl -fsSL https://ollama.ai/install.sh | sh
   
   # Start Ollama service
   ollama serve
   
   # Pull required model
   ollama pull gemma3n
   ```

4. **Download raw data** (if not already done):
   ```bash
   cd ../data
   python download_all.py
   ```

## 📊 Dataset Processing Scripts

### Phase 1: Individual Dataset Processing

These scripts process HuggingFace datasets independently:

#### 1. Medical O1 Reasoning SFT (19,704 examples)
```bash
python prepare_medical_o1_reasoning_sft.py
```
- **Source**: `FreedomIntelligence/medical-o1-reasoning-SFT`
- **Output**: `json/medical_o1_reasoning_sft.json`
- **Content**: Clinical reasoning chains for supervised fine-tuning
- **Processing**: Combines `Complex_CoT` (reasoning) and `Response` fields into structured format
- **Format**: `{"input": "Question", "context": "", "output": "<reasoning>...</reasoning>\nResponse"}`
- **Purpose**: Teaches the model to show clinical reasoning before giving answers

#### 2. Medical O1 Verifiable Problems (40,316 examples)
```bash
python prepare_medical_o1_verifiable_problem.py
```
- **Source**: `FreedomIntelligence/medical-o1-verifiable-problem`
- **Output**: `json/medical_o1_verifiable_problem.json`
- **Content**: Evidence-based medical problems with verifiable answers
- **Processing**: Maps open-ended questions to ground-truth answers with deduplication
- **Features**: Incremental saving, duplicate detection, progress tracking
- **Purpose**: Provides evidence-based medical Q&A with verifiable sources

#### 3. Medical QA Dataset (10,177 examples)
```bash
python prepare_medqa.py
```
- **Source**: `truehealth/medqa`
- **Output**: `json/medqa.json`
- **Content**: Medical licensing exam questions with explanations
- **AI Enhancement**: Uses Ollama Gemma3n to generate detailed explanations for each answer
- **Processing**: Takes multiple-choice questions and creates comprehensive explanations
- **Features**: Professional medical tone, evidence-based reasoning, incremental saving
- **Purpose**: Enhances basic Q&A with detailed clinical explanations

#### 4. Wiki Medical Terms (9,528 examples)
```bash
python prepare_wiki_medical_terms.py
```
- **Source**: `gamino/wiki_medical_terms`
- **Output**: `json/wiki_medical_terms.json`
- **Content**: Medical terminology definitions and explanations
- **AI Enhancement**: Generates specific medical questions and answers using context
- **Processing**: Creates Q&A pairs from medical terminology definitions
- **Features**: Medical-specific filtering, concise questions (max 20 words), duplicate prevention
- **Purpose**: Provides medical terminology Q&A for professional medical knowledge

#### 5. Synthetic Disaster Reports (1,000 examples)
```bash
python prepare_synthetic_disaster_reports.py
```
- **Source**: `paulelliotco/synthetic-disaster-reports`
- **Output**: `json/synthetic_disaster_reports.json`
- **Content**: Emergency response scenarios and resource planning
- **Processing**: Maps disaster situations to required resources and response protocols
- **Features**: Combines disaster type, severity, responder notes, and resource needs
- **Format**: Creates structured emergency scenarios with resource requirements
- **Purpose**: Provides emergency response training data for disaster situations

#### 6. Symptom to Diagnosis (849 examples)
```bash
python prepare_symptom_to_diagnosis.py
```
- **Source**: `gretelai/symptom_to_diagnosis`
- **Output**: `json/symptom_to_diagnosis.json`
- **Content**: Symptom analysis and differential diagnosis
- **AI Enhancement**: Uses Ollama to generate professional medical responses
- **Processing**: Converts symptom-diagnosis pairs into natural medical language
- **Features**: Professional medical tone, clinical reasoning, incremental saving
- **Purpose**: Provides symptom-based diagnostic training data

#### 7. Medication QA (690 examples)
```bash
python prepare_medicationqa.py
```
- **Source**: `truehealth/medicationqa`
- **Output**: `json/medicationqa.json`
- **Content**: Medication information and drug interactions
- **Processing**: Direct Q&A format for medication-related questions
- **Features**: Simple mapping from question to answer fields
- **Purpose**: Provides medication and drug interaction knowledge

#### 8. Diseases and Symptoms (394 examples)
```bash
python prepare_diseases_symptoms.py
```
- **Source**: `QuyenAnhDE/Diseases_Symptoms`
- **Output**: `json/diseases_symptoms.json`
- **Content**: Disease symptomatology and diagnostic criteria
- **Processing**: Maps symptoms to disease names and treatment recommendations
- **Features**: Combines symptoms, disease name, and treatments into structured format
- **Format**: Creates treatment recommendations based on symptoms
- **Purpose**: Provides disease symptomatology and treatment guidance

#### 9. First Aid Dataset (26 examples)
```bash
python prepare_first_aid_dataset.py
```
- **Source**: `badri55/First_aid__dataset`
- **Output**: `json/first_aid_dataset.json`
- **Content**: Basic first aid procedures
- **Processing**: Pattern-response pairs for emergency first aid guidance
- **Features**: Maps patterns to responses for first aid scenarios
- **Purpose**: Provides basic first aid procedure training data

### Phase 2: PDF Knowledge Vectorization

#### 10. Vectorize Medical Knowledge (CRITICAL)
```bash
python vectorizing_medical_knowledge.py --type combined
```

**🔧 Usage Options:**
- `--type firstaid`: Process only first aid PDFs → `first_aid_embeddings.json`
- `--type rescue`: Process only rescue PDFs → `rescue_embeddings.json`
- `--type combined`: Process all PDFs → `medical_knowledge_embeddings.json`

**📄 Processes 14 Official PDFs:**
| Source | Documents | Purpose |
|--------|-----------|---------|
| **WHO** | Basic Emergency Care, EMS Guidelines, Surgical Care | Medical protocols |
| **ICRC** | First Aid Guidelines, GFARC Guidelines | International standards |
| **US Military** | Tactical Combat Casualty Care | Combat medical procedures |
| **US FEMA** | CERT Basic Manual | Community emergency response |
| **Canada** | Mine Rescue Operations | Industrial emergencies |
| **BC Government** | 6x Emergency Guides | Natural disaster preparedness |

**🔍 Processing Features:**
- **Robust PDF Extraction**: Handles encrypted, corrupted, or complex PDFs
- **Comprehensive Error Reporting**: Detailed statistics on processing success/failure
- **Smart Text Chunking**: LangChain RecursiveCharacterTextSplitter (512 tokens, 128 overlap)
- **Cohere Embeddings**: Uses embed-v4.0 model for high-quality vectors
- **Incremental Saving**: Saves progress after each batch to prevent data loss

**⚠️ CRITICAL**: Must complete before Phase 3 RAG generation

## 📄 PDF Knowledge Vectorization - Deep Dive

### 🎯 Purpose & Overview

The PDF vectorization process transforms official medical documents into searchable knowledge embeddings. This is the **foundation** for the RAG pipeline that generates synthetic medical Q&A.

### 📚 Source Documents

**14 Official Medical PDFs from authoritative sources:**

| Organization | Documents | Medical Domain |
|--------------|-----------|----------------|
| **WHO (World Health Organization)** | Basic Emergency Care, EMS Guidelines, Surgical Care | International medical protocols |
| **ICRC (International Red Cross)** | First Aid Guidelines, GFARC Guidelines | Emergency response standards |
| **US Military** | Tactical Combat Casualty Care Handbook | Combat medical procedures |
| **US FEMA** | CERT Basic Manual | Community emergency response |
| **Canadian Government** | Mine Rescue Operations Handbook | Industrial emergency protocols |
| **BC Government** | 6x Emergency Preparedness Guides | Natural disaster response |

### 🔧 Technical Implementation

#### **Script: `vectorizing_medical_knowledge.py`**

**Core Function:**
```python
def process_pdfs_to_embeddings(pdf_directory, output_file, pdf_type="combined"):
    """
    Process medical PDFs into searchable embeddings
    - Extracts text from PDFs (handles encrypted/corrupted files)
    - Chunks text into semantic units
    - Generates embeddings using Cohere API
    - Saves incrementally to prevent data loss
    """
```

#### **Processing Pipeline:**

1. **📄 PDF Text Extraction**
   - **Tool**: LangChain PDF loaders with PyPDF2 fallback
   - **Features**: Handles encrypted, corrupted, and complex PDFs
   - **Error Handling**: Comprehensive reporting on extraction success/failure
   - **Output**: Raw text from all medical documents

2. **✂️ Smart Text Chunking**
   - **Tool**: LangChain RecursiveCharacterTextSplitter
   - **Chunk Size**: 512 tokens per chunk
   - **Overlap**: 128 tokens between chunks
   - **Rationale**: Medical concepts often span multiple sentences
   - **Output**: Semantic chunks preserving medical context

3. **🧠 Embedding Generation**
   - **Model**: Cohere embed-v4.0 (high-quality embeddings)
   - **Dimensions**: 1024-dimensional vectors
   - **Quality**: Optimized for semantic similarity search
   - **Rate Limiting**: Respects API limits with intelligent batching

4. **💾 Incremental Storage**
   - **Format**: JSON with text-embedding pairs
   - **Structure**: `{"text": "medical content", "embedding": [0.1, 0.2, ...]}`
   - **Safety**: Saves after each batch to prevent data loss
   - **Output**: `medical_knowledge_embeddings.json`

### 📊 Processing Statistics

**Typical Output:**
- **Total Chunks**: 15,000-25,000 medical text chunks
- **File Size**: 50-100 MB of embeddings
- **Processing Time**: 2-4 hours (depending on PDF complexity)
- **Success Rate**: 95%+ text extraction success

### 🚀 Usage Options

```bash
# Process all PDFs (recommended)
python vectorizing_medical_knowledge.py --type combined

# Process only first aid PDFs
python vectorizing_medical_knowledge.py --type firstaid

# Process only rescue/emergency PDFs  
python vectorizing_medical_knowledge.py --type rescue
```

### 🔍 Quality Control Features

- **Robust PDF Handling**: Manages various PDF formats and corruption
- **Semantic Chunking**: Preserves medical context across chunk boundaries
- **Error Reporting**: Detailed statistics on processing success/failure
- **Incremental Saving**: Prevents data loss during long processing
- **Memory Management**: Efficient handling of large PDF collections

### 📈 Output Format

```json
[
  {
    "text": "In cases of severe bleeding, apply direct pressure to the wound...",
    "embedding": [0.123, -0.456, 0.789, ...]
  },
  {
    "text": "Vital signs assessment includes blood pressure, heart rate...",
    "embedding": [0.234, -0.567, 0.890, ...]
  }
]
```

### 🔗 Integration with RAG Pipeline

The vectorized knowledge serves as the **knowledge base** for:
- **Question Generation**: Provides medical context for AI question creation
- **Answer Retrieval**: Enables similarity search for relevant medical information
- **Context Enhancement**: Supplies evidence-based medical protocols for answers

### ⚠️ Critical Dependencies

- **Cohere API Key**: Required for embedding generation
- **Sufficient Storage**: 100MB+ for embeddings file
- **Internet Connection**: Required for API calls
- **Processing Time**: 2-4 hours for complete dataset

### 🔧 Script Processing Features

**Common Features Across All Scripts:**
- **🔄 Incremental Processing**: All scripts save progress after each example to prevent data loss
- **📋 Deduplication**: Prevents duplicate entries using input text comparison
- **📊 Progress Tracking**: Real-time progress indicators and statistics
- **⚡ Error Resilience**: Comprehensive error handling and graceful failure recovery
- **🌍 Unicode Support**: Proper handling of international medical content
- **📁 Output Standardization**: All scripts produce consistent JSON format

**AI-Enhanced Scripts:**
- **`prepare_medqa.py`**: Uses Ollama Gemma3n for detailed answer explanations
- **`prepare_wiki_medical_terms.py`**: Generates medical Q&A from terminology definitions
- **`prepare_symptom_to_diagnosis.py`**: Converts symptom-diagnosis pairs to natural language
- **`generate_advanced_firstaid_qa.py`**: Full RAG pipeline with FAISS and Ollama

**Simple Processing Scripts:**
- **`prepare_medical_o1_reasoning_sft.py`**: Direct field mapping with reasoning combination
- **`prepare_medical_o1_verifiable_problem.py`**: Question-answer mapping with deduplication
- **`prepare_medicationqa.py`**: Simple Q&A field mapping
- **`prepare_diseases_symptoms.py`**: Symptom-treatment mapping
- **`prepare_first_aid_dataset.py`**: Pattern-response mapping
- **`prepare_synthetic_disaster_reports.py`**: Disaster scenario to resource mapping

### Phase 3: RAG-Based Synthetic Data Generation

#### 11. Generate Advanced First Aid Q&A
```bash
python generate_advanced_firstaid_qa.py data-prep/json/embeddings/medical_knowledge_embeddings.json
```

**🧠 RAG Pipeline Features:**
- **FAISS Vectorstore**: Fast similarity search on medical knowledge
- **Ollama Integration**: Uses Gemma3n for question generation and answers
- **Medical Content Filtering**: Strict filtering to avoid non-medical questions
- **Duplicate Detection**: Prevents duplicate questions in final dataset
- **Context-Aware Answers**: Uses vector similarity for comprehensive responses

**📊 Processing Pipeline:**
1. Load medical knowledge embeddings
2. Create FAISS index with cosine similarity
3. Process embeddings in chunks of 5
4. Generate 3 medical questions per chunk using Ollama
5. Filter out non-medical content
6. Use vector search for answer context
7. Generate comprehensive medical answers via Ollama
8. Save incrementally to JSON

### Phase 4: Final Dataset Merge

#### 12. Merge All Datasets
```bash
python merge_json_datasets.py
```
- **Input**: All JSON files in `json/` directory
- **Output**: `json/final/medical_training_dataset.json`
- **Features**: Adds source tracking, deduplication, validation
- **Upload**: Automatically uploads to HuggingFace Hub

## 📈 Final Dataset Results

**📊 Complete Dataset Statistics:**
- **Total Examples**: 80,000+ medical Q&A pairs
- **Format**: Standardized `{input, context, output, source}` structure
- **Location**: `json/final/medical_training_dataset.json`
- **HuggingFace**: `ericrisco/medical-training-dataset`

**📋 Breakdown by Source:**
| Source | Examples | Description |
|--------|----------|-------------|
| medical_o1_verifiable_problem | 40,316 | Evidence-based medical problems |
| medical_o1_reasoning_sft | 19,704 | Clinical reasoning chains |
| medqa | 10,177 | Medical licensing exam Q&A |
| wiki_medical_terms | 9,528 | Medical terminology |
| advanced_firstaid_rag | ~2,000 | RAG-generated emergency scenarios |
| synthetic_disaster_reports | 1,000 | Disaster response scenarios |
| symptom_to_diagnosis | 849 | Symptom analysis |
| medicationqa | 690 | Medication information |
| diseases_symptoms | 394 | Disease symptomatology |
| first_aid_dataset | 26 | Basic first aid procedures |

## 🛠️ Technical Architecture

### Core Components

1. **Data Processors**: Individual scripts for each dataset type
2. **Knowledge Vectorizer**: `vectorizing_medical_knowledge.py` - unified PDF processing
3. **RAG Generator**: `generate_advanced_firstaid_qa.py` - synthetic data creation
4. **Dataset Merger**: `merge_json_datasets.py` - final consolidation

### Key Features

- **Incremental Processing**: All scripts save progress to prevent data loss
- **Error Resilience**: Comprehensive error handling and retry mechanisms
- **Duplicate Prevention**: Multiple layers of deduplication
- **Medical Validation**: Strict filtering for medical relevance
- **Unicode Support**: Proper handling of international medical content

### Output Format

All scripts generate standardized JSON:
```json
[
  {
    "input": "Patient question or medical scenario",
    "context": "Additional context (if applicable)",
    "output": "Comprehensive medical response",
    "source": "dataset_name"
  }
]
```

## 🔧 Configuration

### Environment Variables
```bash
COHERE_API_KEY=your_cohere_api_key_here
```

### Required Services
- **Ollama**: Must be running with gemma3n model
- **Cohere**: API key for embeddings generation

### File Locations
- **Raw Data**: `../data/` (downloaded by data pipeline)
- **Processed Data**: `json/` (individual datasets)
- **Embeddings**: `json/embeddings/` (vector knowledge)
- **Final Dataset**: `json/final/` (merged training data)

## 🚀 Execution Workflow

**Complete Pipeline:**
```bash
# Phase 1: Process individual datasets (can run in parallel)
python prepare_medical_o1_reasoning_sft.py &
python prepare_medical_o1_verifiable_problem.py &
python prepare_medqa.py &
python prepare_wiki_medical_terms.py &
python prepare_synthetic_disaster_reports.py &
python prepare_symptom_to_diagnosis.py &
python prepare_medicationqa.py &
python prepare_diseases_symptoms.py &
python prepare_first_aid_dataset.py &
wait

# Phase 2: Vectorize PDF knowledge (CRITICAL)
python vectorizing_medical_knowledge.py --type combined

# Phase 3: Generate RAG-based synthetic data
python generate_advanced_firstaid_qa.py data-prep/json/embeddings/medical_knowledge_embeddings.json

# Phase 4: Final merge
python merge_json_datasets.py
```

## 📄 Citation

If you use this data preparation pipeline, please cite:

```bibtex
@misc{medical_data_prep_pipeline,
  title={Medical Data Preparation Pipeline for Emergency Assistant Training},
  author={Eric Risco},
  year={2025},
  url={https://github.com/ericrisco/gemma3n-impact-challenge}
}
```

---

**Pipeline Result**: 80K+ medical Q&A examples ready for Gemma3N fine-tuning