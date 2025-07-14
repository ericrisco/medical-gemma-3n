# Data Preparation Scripts

This directory contains scripts to prepare various medical datasets for training. Each script processes different types of medical data and converts them into a standardized JSON format for training.

## Prerequisites

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Set up environment variables:**
   - Create a `.env` file in the project root
   - Add your Cohere API key: `COHERE_API_KEY=your_api_key_here`

3. **Ensure Ollama is running:**
   - Install Ollama: https://ollama.ai
   - Start Ollama service
   - Pull required models: `ollama pull gemma3n`

## Dataset Sources

The scripts automatically download and process the following datasets:

### HuggingFace Datasets (Auto-downloaded):
- `FreedomIntelligence/medical-o1-reasoning-SFT` (19,704 examples)
- `FreedomIntelligence/medical-o1-verifiable-problem` (40,316 examples)  
- `gamino/wiki_medical_terms` (9,528 examples)
- `truehealth/medqa` (10,177 examples)
- `truehealth/medicationqa` (690 examples)
- `gretelai/symptom_to_diagnosis` (849 examples)
- `QuyenAnhDE/Diseases_Symptoms` (394 examples)
- `badri55/First_aid__dataset` (26 examples)
- `paulelliotco/synthetic-disaster-reports` (1,000 examples)

### Direct PDF Downloads:
- WHO Basic Emergency Care Guidelines
- IFRC First Aid Guidelines

### Generated Data:
- Extreme First Aid Q&A using RAG (1,641 examples)

**Total Combined: 84,325 medical Q&A examples**

## Execution Order

Follow this **exact order** to execute the scripts:

### Phase 1: Individual Dataset Processing (No Dependencies)

These scripts download HuggingFace datasets and process them. Can be run in parallel:

1. **Medical O1 Reasoning SFT** (19,704 examples)
   ```bash
   python prepare_medical_o1_reasoning_sft.py
   ```
   - **Downloads**: `FreedomIntelligence/medical-o1-reasoning-SFT`
   - **Output**: `json/medical_o1_reasoning_sft.json`
   - **Processing**: Clinical reasoning chains for supervised fine-tuning

2. **Medical O1 Verifiable Problems** (40,316 examples)
   ```bash
   python prepare_medical_o1_verifiable_problem.py
   ```
   - **Downloads**: `FreedomIntelligence/medical-o1-verifiable-problem`
   - **Output**: `json/medical_o1_verifiable_problem.json`
   - **Processing**: Evidence-based medical problems with verifiable answers

3. **Medical QA Dataset** (10,177 examples)
   ```bash
   python prepare_medqa.py
   ```
   - **Downloads**: `truehealth/medqa`
   - **Output**: `json/medqa.json`
   - **Uses**: Ollama to generate explanations for multiple-choice questions

4. **Wiki Medical Terms** (9,528 examples)
   ```bash
   python prepare_wiki_medical_terms.py
   ```
   - **Downloads**: `gamino/wiki_medical_terms`
   - **Output**: `json/wiki_medical_terms.json`
   - **Uses**: Ollama to generate Q&A from medical terminology

5. **Synthetic Disaster Reports** (1,000 examples)
   ```bash
   python prepare_synthetic_disaster_reports.py
   ```
   - **Downloads**: `paulelliotco/synthetic-disaster-reports`
   - **Output**: `json/synthetic_disaster_reports.json`
   - **Processing**: Emergency response scenarios and resource planning

6. **Symptom to Diagnosis** (849 examples)
   ```bash
   python prepare_symptom_to_diagnosis.py
   ```
   - **Downloads**: `gretelai/symptom_to_diagnosis`
   - **Output**: `json/symptom_to_diagnosis.json`
   - **Uses**: Ollama to enhance diagnostic explanations

7. **Medication QA** (690 examples)
   ```bash
   python prepare_medicationqa.py
   ```
   - **Downloads**: `truehealth/medicationqa`
   - **Output**: `json/medicationqa.json`
   - **Processing**: Medication information and drug interactions

8. **Diseases and Symptoms** (394 examples)
   ```bash
   python prepare_diseases_symptoms.py
   ```
   - **Downloads**: `QuyenAnhDE/Diseases_Symptoms`
   - **Output**: `json/diseases_symptoms.json`
   - **Processing**: Disease symptomatology and diagnostic criteria

9. **First Aid Dataset** (26 examples)
   ```bash
   python prepare_first_aid_dataset.py
   ```
   - **Downloads**: `badri55/First_aid__dataset`
   - **Output**: `json/first_aid_dataset.json`
   - **Processing**: Basic first aid procedures

### Phase 2: PDF Knowledge Vectorization (Required for Phase 3)

10. **Vectorize Emergency Care PDFs**
    ```bash
    python vectorizing_knowledge.py
    ```
    - **Purpose**: Downloads and processes WHO/IFRC PDFs for RAG-based first aid generation
    - **Downloads**: 
      - WHO Basic Emergency Care Guidelines
      - IFRC First Aid Guidelines  
    - **Output**: `json/pdf_embeddings.json`
    - **Requirements**: Cohere API key for embeddings
    - **Processing**: 
      - Downloads PDFs automatically
      - Extracts text using PyPDF2
      - Chunks text using LangChain
      - Creates embeddings with Cohere embed-english-v3.0
    - **⚠️ CRITICAL**: Must complete before running Phase 3

### Phase 3: RAG-Based Synthetic Data Generation (Depends on Phase 2)

11. **Generate Extreme First Aid Scenarios** (1,641 examples)
    ```bash
    python generate_firstaid_qa_dataset.py
    ```
    - **Purpose**: Uses RAG to create realistic emergency scenarios from PDF knowledge
    - **Input**: `json/pdf_embeddings.json` (from Phase 2)
    - **Output**: `json/extreme_firstaid_qa_dataset.json`
    - **Requirements**: 
      - Completed `vectorizing_knowledge.py`
      - Cohere API key for query embeddings
      - Ollama with Gemma3N model
    - **Processing**:
      - FAISS similarity search on PDF embeddings
      - Gemma3N generates realistic emergency Q&A
      - Context-aware responses using WHO/IFRC guidelines

### Phase 4: Final Merge

12. **Merge All Datasets**
    ```bash
    python merge_json_datasets.py
    ```
    - **Purpose**: Combines all individual JSON datasets into a single training file
    - **Input**: All JSON files in `json/` directory (except `pdf_embeddings.json`)
    - **Output**: `json/final/medical_training_dataset.json`
    - **Processing**: Adds source tracking to each entry and combines all datasets
    - **Upload**: Automatically uploads to HuggingFace Hub as `ericrisco/medical-training-dataset`
    - **⚠️ IMPORTANT**: Run this LAST after all other scripts have completed

## Final Dataset Results

After running all scripts, the final consolidated dataset contains:

**📊 Dataset Statistics:**
- **Total Examples**: 84,325 medical Q&A pairs
- **Format**: Standardized `{input, context, output, source}` structure
- **Location**: `json/final/medical_training_dataset.json`
- **HuggingFace**: `ericrisco/medical-training-dataset`

**📈 Breakdown by Source:**
| Source | Examples | Description |
|--------|----------|-------------|
| medical_o1_verifiable_problem | 40,316 | Evidence-based medical problems with verifiable answers |
| medical_o1_reasoning_sft | 19,704 | Clinical reasoning and diagnostic processes |
| medqa | 10,177 | General medical Q&A with multiple choice explanations |
| wiki_medical_terms | 9,528 | Medical terminology definitions and explanations |
| extreme_firstaid_qa_dataset | 1,641 | Emergency first aid procedures using RAG |
| synthetic_disaster_reports | 1,000 | Disaster response scenarios and resource planning |
| symptom_to_diagnosis | 849 | Symptom analysis and differential diagnosis |
| medicationqa | 690 | Medication information and drug interactions |
| diseases_symptoms | 394 | Disease symptomatology and diagnostic criteria |
| first_aid_dataset | 26 | Basic first aid procedures |

This comprehensive dataset covers emergency medicine, clinical reasoning, pharmacology, diagnostics, and medical terminology - ideal for training medical AI assistants.

## Script Details

### Helper Scripts

- **`run_ollama.py`**: Utility function to interact with Ollama API
  - Used by: `prepare_symptom_to_diagnosis.py`, `prepare_medqa.py`, `prepare_wiki_medical_terms.py`, `generate_firstaid_qa_dataset.py`

### Data Processing Features

- **Duplicate Detection**: Most scripts check for existing entries to avoid duplicates
- **Incremental Processing**: Scripts save progress incrementally to prevent data loss
- **Error Handling**: Robust error handling for malformed data
- **Unicode Support**: Proper handling of international characters

### Output Format

All scripts generate JSON files with the following structure:
```json
[
  {
    "input": "Patient question or scenario",
    "context": "Additional context (if applicable)",
    "output": "Medical response or answer",
    "source": "dataset_name" (added by merge script)
  }
]
```