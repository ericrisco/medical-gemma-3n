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

#### 2. Medical O1 Verifiable Problems (40,316 examples)
```bash
python prepare_medical_o1_verifiable_problem.py
```
- **Source**: `FreedomIntelligence/medical-o1-verifiable-problem`
- **Output**: `json/medical_o1_verifiable_problem.json`
- **Content**: Evidence-based medical problems with verifiable answers

#### 3. Medical QA Dataset (10,177 examples)
```bash
python prepare_medqa.py
```
- **Source**: `truehealth/medqa`
- **Output**: `json/medqa.json`
- **Content**: Medical licensing exam questions with explanations

#### 4. Wiki Medical Terms (9,528 examples)
```bash
python prepare_wiki_medical_terms.py
```
- **Source**: `gamino/wiki_medical_terms`
- **Output**: `json/wiki_medical_terms.json`
- **Content**: Medical terminology definitions and explanations

#### 5. Synthetic Disaster Reports (1,000 examples)
```bash
python prepare_synthetic_disaster_reports.py
```
- **Source**: `paulelliotco/synthetic-disaster-reports`
- **Output**: `json/synthetic_disaster_reports.json`
- **Content**: Emergency response scenarios and resource planning

#### 6. Symptom to Diagnosis (849 examples)
```bash
python prepare_symptom_to_diagnosis.py
```
- **Source**: `gretelai/symptom_to_diagnosis`
- **Output**: `json/symptom_to_diagnosis.json`
- **Content**: Symptom analysis and differential diagnosis

#### 7. Medication QA (690 examples)
```bash
python prepare_medicationqa.py
```
- **Source**: `truehealth/medicationqa`
- **Output**: `json/medicationqa.json`
- **Content**: Medication information and drug interactions

#### 8. Diseases and Symptoms (394 examples)
```bash
python prepare_diseases_symptoms.py
```
- **Source**: `QuyenAnhDE/Diseases_Symptoms`
- **Output**: `json/diseases_symptoms.json`
- **Content**: Disease symptomatology and diagnostic criteria

#### 9. First Aid Dataset (26 examples)
```bash
python prepare_first_aid_dataset.py
```
- **Source**: `badri55/First_aid__dataset`
- **Output**: `json/first_aid_dataset.json`
- **Content**: Basic first aid procedures

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