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

The scripts expect raw datasets to be downloaded in the `data/` directory with the following structure:

```
data/
├── symptom_to_diagnosis/
├── diseases_symptoms/
├── first_aid_dataset/
├── medical_o1_reasoning_sft/
├── medical_o1_verifiable_problem/
├── medicationqa/
├── medqa/
├── synthetic_disaster_reports/
├── wiki_medical_terms/
├── basic_emergency_care/        # PDF files
└── ifrc_first_aid_guidelines/   # PDF files
```

## Execution Order

Follow this **exact order** to execute the scripts:

### Phase 1: Basic Dataset Preparation (No Dependencies)

These scripts can be run in parallel as they have no dependencies on each other:

1. **Symptom to Diagnosis Dataset**
   ```bash
   python prepare_symptom_to_diagnosis.py
   ```
   - **Purpose**: Converts symptom-diagnosis pairs using Ollama to generate doctor-like responses
   - **Input**: `data/symptom_to_diagnosis/*/symptom_to_diagnosis-train.arrow`
   - **Output**: `json/symptom_to_diagnosis.json`
   - **Uses**: Ollama model to reformat responses in medical professional language

2. **Diseases and Symptoms Dataset**
   ```bash
   python prepare_diseases_symptoms.py
   ```
   - **Purpose**: Creates simple symptom-to-treatment mappings
   - **Input**: `data/diseases_symptoms/*/diseases_symptoms-train.arrow`
   - **Output**: `json/diseases_symptoms.json`
   - **Processing**: Direct mapping without AI generation

3. **First Aid Dataset**
   ```bash
   python prepare_first_aid_dataset.py
   ```
   - **Purpose**: Processes first aid patterns and responses
   - **Input**: `data/first_aid_dataset/*/first_aid__dataset-train.arrow`
   - **Output**: `json/first_aid_dataset.json`
   - **Processing**: Direct conversion of patterns to Q&A format

4. **Medical O1 Reasoning Dataset**
   ```bash
   python prepare_medical_o1_reasoning_sft.py
   ```
   - **Purpose**: Combines complex medical reasoning with responses
   - **Input**: `data/medical_o1_reasoning_sft/*/medical-o1-reasoning-sft-train.arrow`
   - **Output**: `json/medical_o1_reasoning_sft.json`
   - **Processing**: Merges reasoning and response into structured format

5. **Medical O1 Verifiable Problems**
   ```bash
   python prepare_medical_o1_verifiable_problem.py
   ```
   - **Purpose**: Processes verifiable medical questions and answers
   - **Input**: `data/medical_o1_verifiable_problem/*/medical-o1-verifiable-problem-train.arrow`
   - **Output**: `json/medical_o1_verifiable_problem.json`
   - **Processing**: Direct Q&A conversion with duplicate checking

6. **Medication QA Dataset**
   ```bash
   python prepare_medicationqa.py
   ```
   - **Purpose**: Processes medication-related questions and answers
   - **Input**: `data/medicationqa/*/medicationqa-train.arrow`
   - **Output**: `json/medicationqa.json`
   - **Processing**: Direct Q&A conversion

7. **Medical QA Dataset**
   ```bash
   python prepare_medqa.py
   ```
   - **Purpose**: Processes multiple-choice medical questions with explanations
   - **Input**: `data/medqa/*/medqa-train.arrow`
   - **Output**: `json/medqa.json`
   - **Uses**: Ollama to generate explanations for correct answers

8. **Synthetic Disaster Reports**
   ```bash
   python prepare_synthetic_disaster_reports.py
   ```
   - **Purpose**: Creates emergency response scenarios with resource needs
   - **Input**: `data/synthetic_disaster_reports/*/synthetic-disaster-reports-train.arrow`
   - **Output**: `json/synthetic_disaster_reports.json`
   - **Processing**: Formats disaster scenarios with resource requirements

9. **Wiki Medical Terms**
   ```bash
   python prepare_wiki_medical_terms.py
   ```
   - **Purpose**: Generates medical terminology Q&A from Wikipedia content
   - **Input**: `data/wiki_medical_terms/*/wiki_medical_terms-train.arrow`
   - **Output**: `json/wiki_medical_terms.json`
   - **Uses**: Ollama to generate questions and answers from medical contexts

### Phase 2: Knowledge Vectorization (Required for Phase 3)

10. **Vectorize PDF Knowledge**
    ```bash
    python vectorizing_knowledge.py
    ```
    - **Purpose**: Extracts text from PDFs and creates embeddings for RAG
    - **Input**: PDF files in `data/basic_emergency_care/` and `data/ifrc_first_aid_guidelines/`
    - **Output**: `json/pdf_embeddings.json`
    - **Requirements**: Cohere API key for embeddings
    - **Processing**: 
      - Extracts text from PDFs using PyPDF2
      - Splits text into chunks using LangChain
      - Generates embeddings using Cohere's embed-english-v3.0 model
    - **⚠️ IMPORTANT**: This must complete before running `generate_firstaid_qa_dataset.py`

### Phase 3: RAG-Based Dataset Generation (Depends on Phase 2)

11. **Generate First Aid QA Dataset**
    ```bash
    python generate_firstaid_qa_dataset.py
    ```
    - **Purpose**: Generates extreme first aid scenarios using RAG with PDF embeddings
    - **Input**: `json/pdf_embeddings.json` (from vectorizing_knowledge.py)
    - **Output**: `json/extreme_firstaid_qa_dataset.json`
    - **Requirements**: 
      - Completed `vectorizing_knowledge.py`
      - Cohere API key for query embeddings
      - Ollama with gemma3n model
    - **Processing**:
      - Uses FAISS index for similarity search
      - Generates realistic emergency scenarios
      - Creates context-aware Q&A pairs using RAG

### Phase 4: Final Merge

12. **Merge All Datasets**
    ```bash
    python merge_json_datasets.py
    ```
    - **Purpose**: Combines all individual JSON datasets into a single training file
    - **Input**: All JSON files in `json/` directory (except `pdf_embeddings.json`)
    - **Output**: `json/medical_training_dataset.json`
    - **Processing**: Adds source tracking to each entry and combines all datasets
    - **⚠️ IMPORTANT**: Run this LAST after all other scripts have completed

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

## Troubleshooting

1. **Ollama Connection Issues**: Ensure Ollama service is running and the model is available
2. **Cohere API Issues**: Verify your API key is set correctly in the `.env` file
3. **Missing Data Files**: Ensure all required `.arrow` files are downloaded to the correct paths
4. **Memory Issues**: For large datasets, the scripts process data incrementally to manage memory
5. **PDF Processing Issues**: Ensure PDF files are not corrupted and are readable

## Resource Requirements

- **RAM**: 8GB+ recommended for large datasets
- **Storage**: Several GB for processed datasets
- **API Credits**: Cohere API usage for embeddings (costs vary by dataset size)
- **Processing Time**: Can take hours for complete processing depending on dataset sizes

## Output Statistics

After running all scripts, you'll have approximately:
- Individual datasets in `json/` directory
- Combined training dataset with thousands of medical Q&A pairs
- PDF embeddings for RAG-based question answering
- Comprehensive medical knowledge spanning multiple domains