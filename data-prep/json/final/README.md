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

This dataset contains **84,325** high-quality medical question-answer pairs compiled from multiple authoritative sources. It's designed for training language models to assist with medical education, emergency response guidance, and clinical knowledge dissemination.

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

The dataset is compiled from 10 distinct medical data sources:

| Source | Count | Description |
|--------|-------|-------------|
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

## Dataset Creation Process

This dataset was created by combining multiple high-quality medical datasets from HuggingFace Hub and generating additional synthetic data using AI models.

### 1. Source Data Collection

**HuggingFace Datasets Used:**
- `FreedomIntelligence/medical-o1-reasoning-SFT` - Clinical reasoning processes
- `FreedomIntelligence/medical-o1-verifiable-problem` - Evidence-based medical problems  
- `gamino/wiki_medical_terms` - Medical terminology from Wikipedia
- `truehealth/medqa` - General medical Q&A with multiple choice
- `truehealth/medicationqa` - Medication information and interactions
- `gretelai/symptom_to_diagnosis` - Symptom analysis and diagnosis
- `QuyenAnhDE/Diseases_Symptoms` - Disease symptomatology
- `badri55/First_aid__dataset` - Basic first aid procedures
- `paulelliotco/synthetic-disaster-reports` - Emergency response scenarios
- `Intelligent-Internet/II-Medical-Reasoning-SFT` - Additional medical reasoning
- `amu-cai/CAMEO` - Clinical case studies

**Direct PDF Sources:**
- WHO Basic Emergency Care Guidelines (9789241513081-eng.pdf)
- IFRC First Aid Guidelines (ifrc_first_aid_guidelines.pdf)

### 2. Synthetic Data Generation

**AI-Generated Content Using Ollama + Gemma3N:**
- **Emergency First Aid Scenarios**: Generated 1,641 extreme emergency scenarios using RAG (Retrieval-Augmented Generation) with PDF knowledge base
- **Medical Terminology Q&A**: Enhanced Wikipedia medical terms with AI-generated questions and comprehensive answers
- **Diagnostic Explanations**: Added detailed explanations to multiple-choice medical questions
- **Symptom Analysis**: Generated detailed diagnostic reasoning for symptom-to-diagnosis mappings

**RAG Pipeline for Emergency Data:**
1. **PDF Processing**: Extracted text from WHO and IFRC emergency care PDFs
2. **Embedding Creation**: Used Cohere's embed-english-v3.0 to create vector embeddings
3. **Similarity Search**: FAISS index for finding relevant emergency procedures
4. **Context-Aware Generation**: Gemma3N model generates realistic emergency scenarios with proper medical context

### 3. Data Standardization
- All sources converted to uniform `{input, context, output, source}` format
- Inconsistent schemas normalized across 11 different source formats
- Empty context fields standardized
- Source attribution maintained for traceability

### 4. Quality Control
- Removed duplicate entries across all sources
- Filtered out incomplete or malformed examples
- Length constraints applied (10-1500 characters for input/output)
- AI-generated content reviewed for medical appropriateness

### 5. Final Processing
- Dataset shuffled to randomize source distribution
- Combined 84,325 high-quality medical Q&A pairs
- Exported in standardized JSON format
- Automatically uploaded to HuggingFace Hub

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
@dataset{medical_training_dataset_2024,
  title={Medical Training Dataset: Comprehensive Medical Q&A for AI Training},
  author={Eric Risco},
  year={2024},
  url={https://huggingface.co/datasets/ericrisco/medical-training-dataset},
  note={Compiled from multiple medical data sources for educational AI training}
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
- **Ollama + Gemma3N**: Synthetic data generation using RAG
- **Cohere**: Embeddings for similarity search
- **Custom Pipeline**: Emergency scenario generation and medical Q&A enhancement

## Related Resources

- **Data Preparation Scripts**: Available in the source repository
- **Model Training Code**: Gemma3N fine-tuning scripts for Apple Silicon
- **Documentation**: Comprehensive guides for dataset creation and model training

---

**Remember**: This is an AI training dataset for educational purposes. Always consult healthcare professionals for medical advice. In emergencies, contact your local emergency services immediately.