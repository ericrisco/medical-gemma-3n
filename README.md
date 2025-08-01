# Medical Emergency Assistant: Complete AI Pipeline

A comprehensive pipeline for training and deploying medical AI models for offline emergency assistance. This project fine-tunes Gemma-3n models on medical datasets and deploys them in a Flutter mobile application for edge computing scenarios.

## 🎯 Project Overview

This pipeline addresses the critical need for **offline medical AI assistance** in emergency situations where internet connectivity is unreliable or unavailable. The system provides:

- **Medical Knowledge**: 86,667+ medical Q&A pairs from authoritative sources
- **Offline Capability**: Complete on-device inference without internet dependency
- **Emergency Focus**: Specialized training for first aid, emergency procedures, and disaster response
- **Privacy-First**: All processing happens locally on user devices
- **Clinical Accuracy**: 71.54% accuracy on medical benchmarks (vs 36.15% baseline)

## 📺 Model Presentation

**[🎥 Watch the Model Presentation](https://youtu.be/mnmY4Yc0Nag)**: Comprehensive overview of the Medical Gemma-3N model, its capabilities, and real-world applications for emergency medical assistance.

## 🏗️ Architecture Overview

The project follows a **6-phase pipeline** designed for maximum efficiency and clinical accuracy:

```
🔍 Baseline Evaluation → 📊 Data Collection → 🛠️ Data Preparation → 🎓 Model Training → 📈 Performance Evaluation → 📱 Mobile Deployment
```

Each phase builds upon the previous, creating a robust medical AI system optimized for emergency scenarios.

## 📋 Pipeline Phases

### Phase 1: Baseline Evaluation (`/evaluation`)
**Purpose**: Establish performance baseline for the base Gemma-3n model

**What it does**:
- Tests base Gemma-3n model on medical benchmarks
- Uses AI judge (Gemini 2.5 Flash) for consistent evaluation
- Establishes 36.15% baseline accuracy on medical tasks

**Why this approach**:
- **Performance Benchmarking**: Quantifies improvement from fine-tuning
- **AI Judge System**: Eliminates human bias in evaluation
- **Standardized Metrics**: Reproducible evaluation methodology

**Key Components**:
- `evaluation.py`: Main evaluation script with configurable parameters
- Judge-based scoring using OpenRouter API
- First Aid Instructions dataset for medical relevance

**📖 [Detailed Evaluation Documentation →](./evaluation/README.md)**

### Phase 2: Data Collection (`/data`)
**Purpose**: Automated download of medical datasets and official emergency documents

**What it does**:
- Downloads 11 medical datasets from Hugging Face (Q&A, reasoning, symptoms, medications)
- Fetches 14 official emergency/medical PDFs from WHO, ICRC, government agencies
- Creates a comprehensive medical knowledge base (~2GB total)

**Why this approach**:
- **Authoritative Sources**: Official medical guidelines ensure clinical accuracy
- **Comprehensive Coverage**: Multiple medical domains (emergency, pharmacology, diagnostics)
- **Automated Pipeline**: Reproducible data collection for consistent training

**Key Components**:
- `download_all.py`: Parallel download with retry logic
- `datasets_to_download.json`: Configuration for all data sources
- Organized folder structure for easy processing

**📖 [Detailed Data Pipeline Documentation →](./data/README.md)**
**Purpose**: Establish performance baseline for the base Gemma-3n model

**What it does**:
- Tests base Gemma-3n model on medical benchmarks
- Uses AI judge (Gemini 2.5 Flash) for consistent evaluation
- Establishes 36.15% baseline accuracy on medical tasks

**Why this approach**:
- **Performance Benchmarking**: Quantifies improvement from fine-tuning
- **AI Judge System**: Eliminates human bias in evaluation
- **Standardized Metrics**: Reproducible evaluation methodology

**Key Components**:
- `evaluation.py`: Main evaluation script with configurable parameters
- Judge-based scoring using OpenRouter API
- First Aid Instructions dataset for medical relevance

**📖 [Detailed Evaluation Documentation →](./evaluation/README.md)**

### Phase 3: Data Preparation (`/data-prep`)
**Purpose**: Transform raw data into training-ready format with RAG-enhanced synthetic data

**What it does**:
- Processes 11 medical datasets into standardized JSON format
- Vectorizes 14 official PDFs using Cohere embeddings
- Generates synthetic medical Q&A using RAG pipeline
- Creates 80,000+ training examples with medical validation

**Why this approach**:
- **RAG Enhancement**: Leverages official medical documents for synthetic data generation
- **Quality Control**: Multiple layers of medical content filtering
- **Standardized Format**: Consistent structure for efficient training
- **Incremental Processing**: Robust error handling and progress tracking

**Key Components**:
- Individual dataset processors (11 scripts)
- `vectorizing_medical_knowledge.py`: PDF vectorization pipeline
- `generate_advanced_firstaid_qa.py`: RAG-based synthetic data generation
- `merge_json_datasets.py`: Final dataset consolidation

**📖 [Detailed Data Preparation Documentation →](./data-prep/README.md)**

### Phase 4: Model Training (`/training`)
**Purpose**: Fine-tune Gemma-3n model on medical datasets using efficient LoRA adaptation

**What it does**:
- Trains Gemma-3n-4B model on 86,667 medical examples
- Uses Unsloth framework for 2x faster training
- Implements LoRA (Low-Rank Adaptation) for parameter efficiency
- Achieves 0.002 training loss with excellent convergence

**Why this approach**:
- **LoRA Efficiency**: Trains only 0.24% of parameters (76.9MB vs 7.8GB)
- **Unsloth Optimization**: 2x faster training with memory efficiency
- **Medical Specialization**: Focuses learning on clinical accuracy
- **Edge Deployment**: Optimized for mobile and offline scenarios

**Key Components**:
- `training_gemma_3n_medrescue.ipynb`: Google Colab training notebook
- Unsloth-optimized training pipeline
- LoRA adapters for efficient parameter updates
- GGUF quantization for local inference

**📖 [Detailed Training Documentation →](./training/README.md)**

### Phase 5: Performance Evaluation (`/evaluation`)
**Purpose**: Evaluate fine-tuned model performance and quantify improvements

**What it does**:
- Tests medical-tuned model on same benchmarks as baseline
- Achieves 71.54% accuracy (35.39% improvement over baseline)
- Validates clinical relevance and safety of responses
- Provides comprehensive performance analysis

**Why this approach**:
- **Comparative Analysis**: Direct comparison with baseline performance
- **Clinical Validation**: Ensures medical accuracy and safety
- **Quantified Improvement**: 2x performance gain demonstrates effectiveness
- **Reproducible Results**: Same evaluation methodology for consistency

**Key Results**:
- **Baseline Model**: 36.15% accuracy (47/130 correct)
- **Medical-Tuned Model**: 71.54% accuracy (93/130 correct)
- **Improvement**: +35.39% absolute gain in medical accuracy

**📖 [Detailed Evaluation Documentation →](./evaluation/README.md)**

### Phase 6: Mobile Deployment (`/app`)
**Purpose**: Deploy fine-tuned model in Flutter mobile application for offline use

**What it does**:
- Creates Flutter app with on-device AI inference
- Uses `flutter_gemma` package for local model execution
- Provides intuitive medical chat interface
- Ensures complete offline capability and privacy

**Why this approach**:
- **Offline First**: No internet dependency after model download
- **Privacy Preserved**: All processing happens on-device
- **Emergency Ready**: Available in disaster scenarios without connectivity
- **User-Friendly**: Intuitive chat interface for medical queries

**Key Components**:
- `gemma_model_service.dart`: On-device model management
- `medical_chat_screen.dart`: Chat interface with markdown support
- Automatic model download and local storage
- Error handling and user feedback

**📖 [Detailed App Documentation →](./app/README.md)**

## 🚀 Quick Start Guide

### Prerequisites

1. **Hardware Requirements**:
   - GPU with 16GB+ VRAM for training (Google Colab Pro recommended)
   - 50GB+ storage for datasets and models
   - Modern mobile device for app deployment

2. **Software Requirements**:
   - Python 3.8+ with pip
   - Flutter SDK for mobile development
   - Ollama for local model inference
   - HuggingFace account for model hosting

3. **API Keys**:
   - Cohere API key for embeddings generation
   - OpenRouter API key for evaluation
   - HuggingFace token for model uploads

### Complete Pipeline Execution

```bash
# 1. Baseline Evaluation
cd evaluation
python evaluation.py --gen-model gemma3n --limit 50

# 2. Data Collection
cd ../data
python download_all.py

# 3. Data Preparation
cd ../data-prep
# Process individual datasets (run in parallel)
python prepare_medical_o1_reasoning_sft.py &
python prepare_medical_o1_verifiable_problem.py &
# ... (other dataset processors)
wait

# Vectorize PDF knowledge (CRITICAL)
python vectorizing_medical_knowledge.py --type combined

# Generate RAG-based synthetic data
python generate_advanced_firstaid_qa.py json/embeddings/medical_knowledge_embeddings.json

# Merge all datasets
python merge_json_datasets.py

# 4. Model Training (Google Colab)
# Open training_gemma_3n_medrescue.ipynb in Google Colab
# Follow notebook instructions for training

# 5. Performance Evaluation
cd ../evaluation
python evaluation.py --gen-model medical-gemma-3n-4b --limit 50

# 6. Mobile Deployment
cd ../app
flutter pub get
flutter run
```

## 📊 Performance Results

### Training Performance
- **Training Loss**: 0.002 (excellent convergence)
- **Training Speed**: 317 samples/second with Unsloth optimization
- **Model Efficiency**: 76.9MB LoRA adapters (0.24% of parameters)
- **Training Time**: ~4.5 hours for complete dataset

### Evaluation Results
- **Baseline Accuracy**: 36.15% (base Gemma-3n)
- **Medical-Tuned Accuracy**: 71.54% (fine-tuned model)
- **Improvement**: +35.39% absolute gain
- **Performance Gain**: 2x improvement in medical accuracy

### Deployment Metrics
- **Model Size**: 76.9MB LoRA adapters + 7.8GB base model
- **Inference Speed**: Real-time responses on modern devices
- **Offline Capability**: Complete functionality without internet
- **Privacy**: Zero data transmission to external servers

## 🚀 Model Access & Testing

### 📦 Available Model Variants

| Model Type | Link | Size | Use Case |
|------------|------|------|----------|
| **Full Model** | [medical-gemma-3n-4b](https://huggingface.co/ericrisco/medical-gemma-3n-4b) | 7.8GB | Server deployment, Python inference |
| **GGUF Quantized** | [medical-gemma-3n-4b-gguf](https://huggingface.co/ericrisco/medical-gemma-3n-4b-gguf) | 13.7GB | Ollama, llama.cpp, mobile deployment |
| **LoRA Adapters** | [medical-gemma-3n-lora](https://huggingface.co/ericrisco/medical-gemma-3n-lora) | 76.9MB | Efficient fine-tuning, parameter updates |
| **Collection** | [medical-gemma-3n](https://huggingface.co/collections/ericrisco/medical-gemma-3n-688a4415f8171d97fb86b14f) | - | All model variants in one place |

### 🧪 Live Testing

- **[HF Spaces Demo](https://huggingface.co/spaces/ericrisco/medical-gemma-3n-4b)**: Test the model directly in your browser with GPU acceleration
- **Interactive Chat**: Real-time medical consultation interface
- **No Setup Required**: Instant access to model capabilities

### 📚 Training Dataset

- **[MedRescue Dataset](https://huggingface.co/datasets/ericrisco/medrescue)**: 86,667 medical Q&A pairs used for training
- **Comprehensive Coverage**: Emergency care, first aid, clinical reasoning
- **Authoritative Sources**: WHO, ICRC, medical licensing exams
- **Open Access**: Available for research and development

### 🔧 Quick Model Usage

#### Python Inference (Full Model)
```python
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

model_name = "ericrisco/medical-gemma-3n-4b"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    torch_dtype=torch.float16,
    device_map="auto"
)

# Medical consultation
question = "What should I do if someone is having a heart attack?"
prompt = f"<start_of_turn>user\n{question}<end_of_turn>\n<start_of_turn>model\n"
inputs = tokenizer.encode(prompt, return_tensors="pt")

with torch.no_grad():
    outputs = model.generate(
        inputs,
        max_new_tokens=512,
        temperature=0.7,
        do_sample=True,
        pad_token_id=tokenizer.eos_token_id
    )

response = tokenizer.decode(outputs[0], skip_special_tokens=True)
print(response.split("<start_of_turn>model\n")[-1])
```

#### Ollama Usage (GGUF Model)

**🚀 Quick Start with Ollama**

**✅ 1. Download the GGUF model from Hugging Face**
```bash
wget https://huggingface.co/ericrisco/medical-gemma-3n-4b-gguf/resolve/main/medical-gemma-3n-4b.gguf
```

**🗂️ 2. Create a Modelfile for Ollama**
```bash
# Create directory
mkdir -p ~/ollama/models/medical-gemma-3n-4b
cd ~/ollama/models/medical-gemma-3n-4b
```

Create a file called `Modelfile` with this content:
```dockerfile
FROM ./medical-gemma-3n-4b.gguf

# Medical assistant parameters
PARAMETER temperature 0.7
PARAMETER top_k 40
PARAMETER top_p 0.9
PARAMETER repeat_penalty 1.1

# System prompt for medical assistance
SYSTEM """You are a precise, trustworthy medical assistant for emergency situations. 
Provide accurate, concise, clinically relevant information based on established medical knowledge. 
Explain mechanisms, causes, and consequences when appropriate. 
Clarify misconceptions, note uncertainty when relevant, never invent facts, and never give medical advice or diagnoses. 
Respond in English only."""
```

**🏗️ 3. Create the model with Ollama**
```bash
ollama create medical-gemma-3n-4b -f Modelfile
```

**🧠 4. Run the model**
```bash
# Interactive chat
ollama run medical-gemma-3n-4b

# Example conversation:
>>> What are the signs of a stroke?
The main signs of a stroke can be remembered with the acronym FAST...
```

**🔌 API Usage**
```bash
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "medical-gemma-3n-4b",
    "prompt": "What are the signs of cardiac arrest?",
    "stream": false
  }'
```

## 🛠️ Technical Architecture

### Data Pipeline Architecture
```
Raw Data Sources → Automated Download → Processing & Validation → Vectorization → RAG Generation → Training Dataset
```

### Training Architecture
```
Base Gemma-3n → LoRA Adaptation → Medical Fine-tuning → Quantization → Edge Deployment
```

### Deployment Architecture
```
Flutter App → Local Model Storage → On-Device Inference → Medical Chat Interface → Offline Operation
```

### Key Technologies
- **Base Model**: Gemma-3n-4B (Google)
- **Training Framework**: Unsloth + LoRA
- **Vector Database**: FAISS for RAG pipeline
- **Embeddings**: Cohere embed-v4.0
- **Evaluation**: AI judge with Gemini 2.5 Flash
- **Mobile Framework**: Flutter with flutter_gemma
- **Local Inference**: Ollama for model serving

## 🔧 Configuration Options

### Training Parameters
- **Learning Rate**: 2e-5 with linear scheduling
- **Batch Size**: 4 per device × 4 gradient accumulation = 16 effective
- **LoRA Rank**: 8 (adaptation capacity)
- **Sequence Length**: 1024 tokens
- **Training Epochs**: 1 full pass through dataset

### Evaluation Parameters
- **Judge Model**: Google Gemini 2.5 Flash Lite
- **Temperature**: 0.15 (low randomness for consistency)
- **Max Tokens**: 512 (adequate for medical responses)
- **Evaluation Criteria**: Clinical accuracy, completeness, safety

### Deployment Parameters
- **Model Format**: GGUF Q8_0 for llama.cpp compatibility
- **Mobile Optimization**: Quantized for efficient inference
- **Storage**: Local device storage with integrity verification
- **Privacy**: Zero external data transmission

## 📈 Quality Assurance

### Data Quality
- **Source Validation**: Official medical documents and datasets
- **Content Filtering**: Medical relevance validation
- **Duplicate Prevention**: Multiple deduplication layers
- **Incremental Processing**: Robust error handling and recovery

### Model Quality
- **Training Monitoring**: Loss tracking and convergence analysis
- **Evaluation Consistency**: Same judge model for all assessments
- **Clinical Validation**: Medical accuracy and safety verification
- **Performance Benchmarking**: Quantified improvement metrics

### Deployment Quality
- **Offline Testing**: Complete functionality without internet
- **Error Handling**: Robust failure recovery and user feedback
- **Performance Optimization**: Efficient inference for mobile devices
- **Security**: Local data processing and model integrity verification

## 🚨 Important Disclaimers

### Medical Disclaimer
⚠️ **This system is for educational and research purposes only. It should never replace professional medical consultation, diagnosis, or treatment. Always contact emergency services for urgent medical care.**

### Technical Limitations
- **AI Responses**: May contain errors or outdated information
- **Emergency Situations**: Always prioritize professional medical care
- **Model Accuracy**: 71.54% accuracy means some responses may be incorrect
- **Liability**: Users assume full responsibility for model usage and outcomes

### Usage Guidelines
- **Educational Use**: Primary use case for medical education and training
- **Emergency Backup**: Secondary use in emergency scenarios without professional access
- **Professional Consultation**: Always consult qualified healthcare professionals
- **Continuous Learning**: Model should be updated with latest medical guidelines

## 📄 Citation

If you use this pipeline or models, please cite:

```bibtex
@misc{medical_emergency_assistant_pipeline,
  title={Medical Emergency Assistant: Complete AI Pipeline for Offline Medical AI},
  author={Eric Risco},
  year={2025},
  url={https://github.com/ericrisco/gemma3n-impact-challenge},
  note={Models: ericrisco/medical-gemma-3n-4b, ericrisco/medical-gemma-3n-lora}
}
```

### Model References

- **Full Model**: [ericrisco/medical-gemma-3n-4b](https://huggingface.co/ericrisco/medical-gemma-3n-4b)
- **LoRA Adapters**: [ericrisco/medical-gemma-3n-lora](https://huggingface.co/ericrisco/medical-gemma-3n-lora)
- **GGUF Quantized**: [ericrisco/medical-gemma-3n-4b-gguf](https://huggingface.co/ericrisco/medical-gemma-3n-4b-gguf)
- **Training Dataset**: [ericrisco/medrescue](https://huggingface.co/datasets/ericrisco/medrescue)
- **Live Demo**: [HF Spaces](https://huggingface.co/spaces/ericrisco/medical-gemma-3n-4b)

## 🤝 Contributing

### Development Areas
- **Additional Medical Datasets**: Expand training data coverage
- **Model Optimization**: Further efficiency improvements
- **Mobile Features**: Enhanced user interface and functionality
- **Evaluation Metrics**: Additional medical benchmarks
- **Documentation**: Improved guides and tutorials

### Contribution Guidelines
1. Fork the repository
2. Create feature branch
3. Implement changes with tests
4. Update documentation
5. Submit pull request

## 📞 Support

### Documentation Navigation
- **[Data Pipeline](./data/README.md)**: Raw data collection and organization
- **[Evaluation Framework](./evaluation/README.md)**: Model performance assessment
- **[Data Preparation](./data-prep/README.md)**: Training data processing and RAG generation
- **[Model Training](./training/README.md)**: Fine-tuning pipeline and optimization
- **[Mobile App](./app/README.md)**: Flutter deployment and user interface

### Common Issues
- **Training Failures**: Check GPU memory and Colab runtime
- **Download Errors**: Verify API keys and internet connectivity
- **Mobile Issues**: Ensure sufficient device storage and RAM
- **Evaluation Problems**: Check OpenRouter API key and model availability

---
## 🏆 Impact Challenge Project

This project was developed as part of the **[Google Gemma 3N Impact Challenge](https://www.kaggle.com/competitions/google-gemma-3n-hackathon/overview)**, a hackathon focused on leveraging Google's Gemma 3N models to create positive social impact through innovative AI applications.

The Medical Emergency Assistant demonstrates how fine-tuned language models can provide critical medical assistance in emergency scenarios where internet connectivity is limited, potentially saving lives in disaster zones, remote areas, and emergency situations.

---

*Built with ❤️ for the Google Gemma 3N Impact Challenge* 