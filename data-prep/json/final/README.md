---
license: cc-by-4.0
task_categories:
- question-answering
- text-generation
language:
- en
tags:
- medical
- healthcare
- emergency-medicine
- first-aid
- medical-qa
- symptom-diagnosis
- treatment
- medication
- disaster-response
- clinical-reasoning
size_categories:
- 10K<n<100K
---

# Medical Training Dataset

A comprehensive medical Q&A dataset for training AI models on healthcare knowledge, emergency medicine, and clinical reasoning.

## Dataset Summary

This dataset contains **80,000+** high-quality medical question-answer pairs compiled from multiple authoritative sources. It's designed for training language models to assist with medical education, emergency response guidance, and clinical knowledge dissemination.

**⚠️ IMPORTANT DISCLAIMER: This dataset is for educational and research purposes only. AI models trained on this data should never replace professional medical advice. Always consult qualified healthcare professionals for medical decisions.**

## Dataset Structure

Each example contains:
- `input`: Medical question or scenario
- `context`: Additional context when available (often empty)
- `output`: Detailed medical response or answer
- `source`: Original data source identifier

```json
{
  "input": "What are the first aid steps for treating severe burns?",
  "context": "",
  "output": "For severe burns: 1) Remove person from heat source safely, 2) Cool the burn with lukewarm water for 10-20 minutes, 3) Remove loose clothing/jewelry, 4) Cover with sterile gauze, 5) Do NOT apply ice, butter, or oils, 6) Seek immediate medical attention for burns larger than palm size, electrical burns, or burns on face/hands/joints",
  "source": "extreme_firstaid_qa_dataset"
}
```

## Data Sources

The dataset is compiled from 11 distinct medical data sources:

| Source                        | Count   | Task Type                                      |
|-------------------------------|---------|------------------------------------------------|
| medical_o1_verifiable_problem | 40316   | Verifiable medical problems                    |
| medical_o1_reasoning_sft      | 19704   | Clinical reasoning (SFT style)                 |
| medqa                         | 10177   | General medical exam-style questions           |
| wiki_medical_terms            | 9528    | Medical term definitions from Wikipedia        |
| first_aid_qa_dataset          | 2181    | First aid QA (question-answer format)          |
| synthetic_disaster_reports    | 1000    | Synthetic disaster incident reports            |
| symptom_to_diagnosis          | 849     | Symptoms to possible diagnosis                 |
| medicationqa                  | 690     | Medication-related questions                   |
| diseases_symptoms             | 394     | Symptom ↔ Disease mapping                      |
| rescue_qa_dataset             | 161     | Emergency rescue QA                            |
| first_aid_dataset             | 26      | Basic first aid information                    |


## Dataset Creation Process

This comprehensive dataset was created through a sophisticated 4-phase pipeline that combines multiple authoritative medical datasets with AI-generated synthetic data using advanced RAG techniques.

**🔗 Complete Implementation**: The full pipeline, scripts, and detailed documentation for reproducing this dataset are available at: https://github.com/ericrisco/gemma3n-impact-challenge

### Phase 1: Raw Data Collection (Automated Download Pipeline)

**📥 11 HuggingFace Datasets Automatically Downloaded:**
- `FreedomIntelligence/medical-o1-reasoning-SFT` (19,704 examples) - Clinical reasoning chains
- `FreedomIntelligence/medical-o1-verifiable-problem` (40,316 examples) - Evidence-based medical problems  
- `gamino/wiki_medical_terms` (9,528 examples) - Medical terminology from Wikipedia
- `truehealth/medqa` (10,177 examples) - Medical licensing exam questions
- `truehealth/medicationqa` (690 examples) - Medication information and interactions
- `gretelai/symptom_to_diagnosis` (849 examples) - Symptom analysis and diagnosis
- `QuyenAnhDE/Diseases_Symptoms` (394 examples) - Disease symptomatology
- `badri55/First_aid__dataset` (26 examples) - Basic first aid procedures
- `paulelliotco/synthetic-disaster-reports` (1,000 examples) - Emergency response scenarios

**📄 14 Official Medical PDFs Automatically Downloaded:**

| Source | Document | URL |
|--------|----------|-----|
| **WHO** | Basic Emergency Care Guidelines | https://iris.who.int/bitstream/handle/10665/275635/9789241513081-eng.pdf |
| **WHO** | Emergency Medical Services Guidelines | https://iris.who.int/bitstream/handle/10665/326106/9789241516181-eng.pdf |
| **WHO** | Emergency Surgical Care in Disaster Situations | https://cdn.who.int/media/docs/default-source/integrated-health-services-(ihs)/csy/surgical-care/emergencysurgicalcareindisastersituations.pdf |
| **ICRC** | First Aid Guidelines | https://shop.icrc.org/download/ebook?sku=BEC/002-Ebook |
| **ICRC** | Global First Aid Reference Centre Guidelines | https://www.ifrc.org/sites/default/files/2022-02/EN_GFARC_GUIDELINES_2020.pdf |
| **US Military** | Tactical Combat Casualty Care Handbook | https://api.army.mil/e2/c/downloads/2023/01/19/31e03488/17-13-tactical-casualty-combat-care-handbook-v5-may-17-distro-a.pdf |
| **US FEMA** | CERT Basic Participant Manual | https://www.ready.gov/sites/default/files/2019.CERT_.Basic_.PM_FINAL_508c.pdf |
| **Canada WorkSafeBC** | Mine Rescue and Recovery Operations | https://www.workplacesafetynorth.ca/sites/default/files/uploads/Handbook-of-Training-in-Mine-Rescue-and-Recovery-Operations-2021.pdf |
| **BC Government** | Earthquake and Tsunami Guide | https://www2.gov.bc.ca/assets/gov/public-safety-and-emergency-services/emergency-preparedness-response-recovery/embc/preparedbc/preparedbc-guides/earthquake_and_tsunami_guide.pdf |
| **BC Government** | Flood Preparedness Guide | https://www2.gov.bc.ca/assets/gov/public-safety-and-emergency-services/emergency-preparedness-response-recovery/embc/preparedbc/preparedbc-guides/preparedbc_flood_preparedness_guide_fillable.pdf |
| **BC Government** | Extreme Heat Guide | https://www2.gov.bc.ca/assets/gov/public-safety-and-emergency-services/emergency-preparedness-response-recovery/embc/preparedbc/preparedbc-guides/preparedbc_extreme_heat_guide.pdf |
| **BC Government** | Pandemic Guide | https://www2.gov.bc.ca/assets/gov/public-safety-and-emergency-services/emergency-preparedness-response-recovery/embc/preparedbc/preparedbc-guides/preparedbc_pandemic_guide.pdf |
| **BC Government** | Winter Guide | https://www2.gov.bc.ca/assets/gov/public-safety-and-emergency-services/emergency-preparedness-response-recovery/embc/preparedbc/preparedbc-guides/preparedbc_winter_guide.pdf |
| **BC Government** | Neighbourhood Emergency Guide | https://www2.gov.bc.ca/assets/gov/public-safety-and-emergency-services/emergency-preparedness-response-recovery/embc/preparedbc/preparedbc-guides/preparedbc_neighbourhood_guide.pdf |

These PDFs contain authoritative medical and emergency response information that forms the knowledge base for our RAG-generated synthetic data.

### Phase 2: Medical Knowledge Vectorization (PDF Processing)

This phase transforms authoritative medical PDFs into a searchable knowledge base using advanced NLP techniques.

**🔍 Detailed PDF Processing Pipeline:**

**Step 1: PDF Text Extraction**
- **Tool**: PyPDF2 with comprehensive error handling
- **Process**: Each PDF is processed page by page with robust error recovery
- **Challenges Handled**: Encrypted PDFs, corrupted files, complex layouts, scanned documents
- **Success Rate**: 99%+ with detailed error reporting for any failures

**Step 2: Intelligent Text Chunking**
- **Tool**: LangChain RecursiveCharacterTextSplitter
- **Configuration**: 512 tokens per chunk, 128 token overlap
- **Strategy**: Preserves context by splitting on paragraphs, sentences, then characters
- **Result**: Coherent medical knowledge chunks that maintain semantic meaning

**Step 3: Vector Embedding Generation**
- **API**: Cohere embed-v4.0 (state-of-the-art multilingual embeddings)
- **Process**: Batch processing of 32 chunks at a time to avoid rate limits
- **Output**: High-dimensional vectors capturing semantic meaning of medical concepts
- **Storage**: FAISS-compatible format for fast similarity search

**Step 4: Quality Assurance**
- **Validation**: Each chunk validated for minimum content length (50+ characters)
- **Deduplication**: Removes duplicate chunks based on PDF name and chunk ID
- **Incremental Saving**: Progress saved after each batch to prevent data loss
- **Error Tracking**: Comprehensive statistics on processing success/failure rates

**📊 Processing Results:**
- **14 official medical PDFs** successfully processed
- **Thousands of medical knowledge chunks** created with semantic embeddings
- **Vector embeddings** stored in FAISS-compatible JSON format
- **Full traceability** from original PDF source to final chunks
- **Processing time**: ~30-45 minutes depending on PDF complexity

### Phase 3: RAG-Based Synthetic Data Generation

This is the most innovative phase where we create factual first aid and rescue Q&A pairs from the processed PDF knowledge using advanced AI techniques.

**🧠 Advanced RAG Pipeline with `generate_advanced_firstaid_qa.py`:**

**Core Technology Stack:**
- **FAISS Vectorstore**: Lightning-fast cosine similarity search on medical knowledge embeddings
- **Ollama + Gemma3N**: Local deployment of Google's Gemma3N model for controlled, privacy-preserving generation
- **Medical Content Filtering**: Multi-layer validation to ensure medical relevance and accuracy
- **Duplicate Detection**: Sophisticated deduplication to prevent repeated questions

**🔄 Detailed Processing Pipeline:**

**Step 1: Knowledge Base Preparation**
- **Input**: Vectorized medical PDF embeddings from Phase 2
- **Process**: Load thousands of medical knowledge chunks with their embeddings
- **Index Creation**: Build FAISS index with cosine similarity for fast semantic search
- **Validation**: Ensure all embeddings are properly formatted and accessible

**Step 2: Context-Aware Question Generation**
- **Batch Processing**: Process embeddings in groups of 5 for diverse context
- **Semantic Clustering**: Group related medical concepts for comprehensive coverage
- **Prompt Engineering**: Specialized prompts designed for medical question generation
- **AI Generation**: Use Ollama (Gemma3N) to create 3 medical questions per chunk group

**Step 3: Strict Medical Validation**
- **Forbidden Content Filter**: Removes administrative, licensing, or documentation questions
- **Medical Terminology Validation**: Ensures questions contain required medical indicators:
  - Patient care terms: "patient", "treatment", "procedure", "emergency"
  - Clinical terms: "vital signs", "medication", "diagnosis", "symptoms"
  - Emergency terms: "first aid", "rescue", "bleeding", "fracture", "airway"
- **Length Constraints**: Validates appropriate question length (10-200 characters)
- **Relevance Scoring**: Questions must score >80% on medical relevance metrics

**Step 4: Context Retrieval for Answers**
- **Similarity Search**: For each validated question, find 5 most relevant PDF chunks
- **Context Ranking**: Rank retrieved chunks by semantic similarity score
- **Context Aggregation**: Combine multiple knowledge sources for comprehensive answers
- **Source Attribution**: Maintain traceability to original PDF sources

**Step 5: Comprehensive Answer Generation**
- **Prompt Engineering**: Specialized prompts for medical answer generation
- **Context Integration**: Combine question with retrieved PDF context
- **AI Generation**: Use Ollama (Gemma3N) to create detailed, factual medical answers
- **Answer Validation**: Ensure answers are clinically appropriate and complete

**Step 6: Quality Assurance**
- **Medical Appropriateness**: Answers reviewed for clinical accuracy
- **Completeness Check**: Ensure answers fully address the question
- **Duplicate Prevention**: Exact string matching to avoid duplicate Q&A pairs
- **Length Validation**: Answers must be 50-1000 characters for optimal training

**Step 7: Incremental Processing**
- **Batch Saving**: Save progress every 10 successful Q&A generations
- **Error Handling**: Comprehensive error recovery and logging
- **Progress Tracking**: Real-time monitoring of generation success rates
- **Final Validation**: Complete dataset review before export

**✅ Advanced Medical Content Validation:**

**Forbidden Topics (Automatically Filtered):**
- Document structure, licensing, copyrights
- Training program organization or curriculum  
- Administrative or educational metadata
- General advice not based on clinical context

**Required Medical Indicators (Must Be Present):**
- Patient assessment and vital signs
- Treatment protocols and procedures
- Emergency interventions and medications
- Equipment usage and safety precautions
- Clinical decision-making criteria

**📊 Generation Results:**
- **Input**: ~2,000 medical knowledge chunks from 14 official PDFs
- **Output**: ~2,000 high-quality first aid and rescue Q&A pairs
- **Success Rate**: 95%+ medical relevance after filtering
- **Processing Time**: ~2-3 hours depending on system performance
- **Quality Metrics**: All outputs validated for medical appropriateness and factual accuracy

### Phase 4: Data Standardization and Consolidation

**🔧 Comprehensive Data Processing:**
- **Schema Normalization**: Converted 11 different source formats to unified `{input, context, output, source}` structure
- **Quality Filtering**: Removed incomplete, malformed, or duplicate entries
- **Source Attribution**: Maintained traceability to original datasets
- **Medical Validation**: Applied consistent medical appropriateness criteria
- **Character Encoding**: Proper Unicode handling for international medical content

**📈 Final Processing:**
- **Dataset Shuffling**: Randomized source distribution to prevent overfitting
- **Comprehensive Validation**: Final quality checks across all examples
- **Automated Upload**: Direct integration with HuggingFace Hub
- **Documentation Generation**: Automatic README and dataset card creation

## Technical Architecture

### Core Technologies Used

**🛠️ Data Processing Stack:**
- **Python**: Primary programming language for all processing scripts
- **Cohere API**: High-quality embeddings generation (embed-v4.0)
- **Ollama + Gemma3N**: Local LLM for synthetic data generation
- **FAISS**: Fast similarity search on medical knowledge vectors
- **LangChain**: Advanced text chunking and processing
- **PyPDF2**: Robust PDF text extraction with error handling
- **HuggingFace Hub**: Automated dataset upload and distribution

**🔧 Processing Infrastructure:**
- **Parallel Processing**: Concurrent download and processing of multiple datasets
- **Incremental Saving**: Progress preservation to prevent data loss
- **Error Resilience**: Comprehensive error handling and retry mechanisms
- **Memory Optimization**: Efficient batch processing for large datasets
- **Quality Assurance**: Multi-layer validation and filtering

### Data Pipeline Workflow

```
Raw Data Sources → Download Pipeline → Individual Processing → 
PDF Vectorization → RAG Generation → Quality Filtering → 
Dataset Consolidation → HuggingFace Upload
```

**📊 Pipeline Statistics:**
- **Total Processing Time**: ~4-6 hours for complete pipeline
- **Raw Data Volume**: ~2GB of medical content
- **Final Dataset Size**: 80,000+ high-quality Q&A pairs

## Use Cases

### Training Applications
- **Medical Chatbots**: Train conversational AI for medical education
- **Emergency Response**: Fine-tune models for first aid guidance
- **Clinical Decision Support**: Develop tools for medical professionals
- **Medical Education**: Create interactive learning assistants

### Research Applications
- **Medical NLP**: Benchmark language models on medical knowledge
- **Safety Research**: Study AI safety in healthcare applications
- **Bias Analysis**: Examine potential biases in medical AI systems
- **Evaluation**: Test medical reasoning capabilities

## Citation

If you use this dataset in your research, please cite:

```bibtex
@dataset{medical_training_dataset_2025,
  title={Medical Training Dataset: Comprehensive Medical Q&A for AI Training},
  author={Eric Risco},
  year={2025},
  url={https://huggingface.co/datasets/ericrisco/medical-training-dataset},
  repository={https://github.com/ericrisco/gemma3n-impact-challenge},
  note={Compiled from 11 medical datasets + 14 official PDFs using advanced RAG pipeline}
}
```

## Contributing

This dataset is part of an ongoing effort to improve medical AI safety and education. Contributions, corrections, and feedback are welcome through the HuggingFace Hub discussions.

## License

This dataset is released under **CC-BY-4.0** license, allowing for:
- ✅ Commercial use
- ✅ Distribution
- ✅ Modification
- ✅ Private use

**Attribution Required**: Please cite this dataset in any derived works.

## Source Datasets Attribution

This dataset builds upon the following open-source medical datasets:

### Primary Sources:
- **FreedomIntelligence/medical-o1-reasoning-SFT** - Clinical reasoning processes
- **FreedomIntelligence/medical-o1-verifiable-problem** - Evidence-based medical problems
- **gamino/wiki_medical_terms** - Medical terminology from Wikipedia
- **truehealth/medqa** - General medical Q&A 
- **truehealth/medicationqa** - Medication information
- **gretelai/symptom_to_diagnosis** - Symptom analysis
- **QuyenAnhDE/Diseases_Symptoms** - Disease symptomatology
- **badri55/First_aid__dataset** - Basic first aid procedures
- **paulelliotco/synthetic-disaster-reports** - Emergency scenarios
- **Intelligent-Internet/II-Medical-Reasoning-SFT** - Medical reasoning
- **amu-cai/CAMEO** - Clinical case studies

### Direct Sources:
- **WHO**: Basic Emergency Care Guidelines
- **IFRC**: First Aid Guidelines

### AI Enhancement:
- **Ollama + Gemma3N**: Synthetic data generation using advanced RAG techniques
- **Cohere embed-v4.0**: High-quality embeddings for semantic similarity search
- **FAISS**: Fast vector similarity search for context retrieval
- **Custom RAG Pipeline**: Emergency scenario generation from official medical PDFs
- **Medical Content Filtering**: Strict validation to ensure medical relevance

## Related Resources

- **Complete Dataset Creation Process**: The full pipeline, scripts, and documentation for creating this dataset are available at: https://github.com/ericrisco/gemma3n-impact-challenge
- **Data Preparation Scripts**: All processing scripts are in the `data-prep/` directory
- **Model Training Code**: Gemma3N fine-tuning scripts optimized for Apple Silicon in `training/` directory
- **Documentation**: Comprehensive guides for dataset creation and model training
- **Raw Data Pipeline**: Automated download scripts for all source datasets and PDFs in `data/` directory

---

**Remember**: This is an AI training dataset for educational purposes. Always consult healthcare professionals for medical advice. In emergencies, contact your local emergency services immediately.