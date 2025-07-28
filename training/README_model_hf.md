---
license: gemma
base_model: unsloth/gemma-3n-E4B-it
tags:
- medical
- emergency
- first-aid
- healthcare
- offline
- gemma3n
- unsloth
- medical-ai
language:
- en
datasets:
- ericrisco/medrescue
pipeline_tag: text-generation
---

# Medical Gemma-3N: Emergency Medical Assistant 🏥

**Medical Gemma-3N** is a specialized version of Google's Gemma-3N-4B model, fine-tuned specifically for **emergency medical assistance** and **offline healthcare applications**. This model is designed to provide accurate medical guidance in emergency scenarios where internet connectivity may be limited or unavailable.

## 🎯 Model Overview

- **Base Model**: [unsloth/gemma-3n-E4B-it](https://huggingface.co/unsloth/gemma-3n-E4B-it)
- **Training Dataset**: [ericrisco/medrescue](https://huggingface.co/datasets/ericrisco/medrescue) (86,667 medical Q&A pairs)
- **Training Method**: LoRA (Low-Rank Adaptation) fine-tuning
- **Optimization**: Unsloth framework for 2x faster training
- **Model Size**: 7.8B parameters + 76.9MB LoRA adapters
- **Training Loss**: 0.002 (excellent convergence)

## 🚀 Key Features

- **🏥 Medical Expertise**: Trained on 80K+ medical Q&A pairs from authoritative sources
- **🚨 Emergency Focus**: Specialized in first aid, emergency care, and rescue procedures  
- **📱 Offline Capable**: Optimized for deployment without internet connectivity
- **⚡ Edge Optimized**: Efficient inference on local devices and mobile platforms
- **🎯 Clinical Accuracy**: 72% accuracy on medical benchmarks (vs 36% baseline)
- **🔒 Privacy First**: No data leaves your device during inference

## 📊 Performance Benchmarks

| Metric | Base Gemma-3N | Medical Gemma-3N | Improvement |
|--------|---------------|------------------|-------------|
| **First Aid Accuracy** | 36.15% | 71.54% | **+35.39%** |
| **Medical Terminology** | Limited | Comprehensive | Clinical-grade |
| **Emergency Response** | Generic | Specialized | Professional |
| **Offline Performance** | Standard | Optimized | Edge-ready |

*Evaluated on [lextale/FirstAidInstructionsDataset](https://huggingface.co/datasets/lextale/FirstAidInstructionsDataset)*

## 💻 Quick Start

### Installation

```bash
pip install torch transformers accelerate
```

### Basic Usage

```python
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

# Load model and tokenizer
model_name = "ericrisco/medical-gemma-3n-4b"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    torch_dtype=torch.float16,
    device_map="auto"
)

# Medical consultation example
def ask_medical_question(question):
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
    return response.split("<start_of_turn>model\n")[-1]

# Example usage
question = "What should I do if someone is having a heart attack?"
response = ask_medical_question(question)
print(response)
```

### Advanced Usage with Streaming

```python
from transformers import TextIteratorStreamer
from threading import Thread

def stream_medical_response(question):
    prompt = f"<start_of_turn>user\n{question}<end_of_turn>\n<start_of_turn>model\n"
    inputs = tokenizer.encode(prompt, return_tensors="pt")
    
    streamer = TextIteratorStreamer(tokenizer, skip_special_tokens=True)
    
    generation_kwargs = dict(
        inputs=inputs,
        streamer=streamer,
        max_new_tokens=512,
        temperature=0.7,
        do_sample=True,
        pad_token_id=tokenizer.eos_token_id
    )
    
    thread = Thread(target=model.generate, kwargs=generation_kwargs)
    thread.start()
    
    generated_text = ""
    for new_text in streamer:
        generated_text += new_text
        print(new_text, end="", flush=True)
    
    return generated_text

# Stream response
question = "How do I treat severe bleeding?"
stream_medical_response(question)
```

## 🎯 Use Cases

### 🚨 Emergency Scenarios
- **First Aid Guidance**: Step-by-step emergency procedures
- **Symptom Assessment**: Initial triage and severity evaluation  
- **Drug Information**: Medication guidance and contraindications
- **Disaster Response**: Medical care in resource-limited settings

### 🏥 Healthcare Applications  
- **Medical Education**: Training support for healthcare students
- **Rural Healthcare**: Medical assistance in underserved areas
- **Telemedicine**: Offline medical consultation capabilities
- **Clinical Decision Support**: Evidence-based medical recommendations

### 📱 Mobile & Edge Deployment
- **Emergency Apps**: Offline medical guidance applications
- **Wearable Devices**: Health monitoring and emergency response  
- **Remote Areas**: Medical assistance without connectivity
- **Privacy-Focused**: Local processing without data transmission

## 📚 Training Dataset

The model was trained on **[ericrisco/medrescue](https://huggingface.co/datasets/ericrisco/medrescue)**, a comprehensive medical dataset containing:

- **86,667 medical Q&A pairs** from multiple authoritative sources
- **11 specialized medical datasets** covering clinical reasoning, symptoms, medications
- **14 official medical PDFs** from WHO, ICRC, military, and government sources  
- **RAG-enhanced content** using vector search and AI generation
- **Quality validation** with strict medical accuracy filtering

### Dataset Sources Include:
- Medical licensing exam questions with detailed explanations
- Clinical reasoning chains for diagnostic procedures  
- Emergency medicine protocols and first aid instructions
- Medication information and drug interaction guidance
- Symptom analysis and differential diagnosis training
- Disaster response and rescue operation procedures

## ⚙️ Technical Details

### Training Configuration
- **Base Model**: Gemma-3N-E4B-it (7.8B parameters)
- **Fine-tuning Method**: LoRA (r=8, alpha=8, dropout=0)
- **Training Framework**: Unsloth (2x speed optimization)
- **Quantization**: 4-bit loading for memory efficiency
- **Sequence Length**: 1024 tokens
- **Batch Size**: 16 effective (4×4 gradient accumulation)
- **Learning Rate**: 2e-5 with linear scheduling
- **Training Time**: ~4.5 hours on Tesla T4

### Model Architecture
- **Parameters Trained**: 19.2M out of 7.8B (0.24% efficient adaptation)
- **Target Modules**: Attention and MLP layers
- **Optimization**: AdamW 8-bit with gradient checkpointing
- **Memory Usage**: Fits on 16GB GPU with 4-bit quantization
- **Inference Speed**: 317 samples/second during training

## 🔄 Model Variants

This model is available in multiple formats for different deployment scenarios:

1. **[ericrisco/medical-gemma-3n-lora](https://huggingface.co/ericrisco/medical-gemma-3n-lora)** - LoRA adapters (76.9MB)
2. **[ericrisco/medical-gemma-3n-lora-gguf](https://huggingface.co/ericrisco/medical-gemma-3n-lora-gguf)** - GGUF quantized for llama.cpp
3. **ericrisco/medical-gemma-3n-4b** - Full merged model (this repository)

## 📋 Evaluation Results

Evaluated on [lextale/FirstAidInstructionsDataset](https://huggingface.co/datasets/lextale/FirstAidInstructionsDataset) using AI judge scoring:

```
Base Gemma-3N:     36.15% accuracy (47/130)
Medical Gemma-3N:  71.54% accuracy (93/130)
Improvement:       +35.39% absolute gain
```

The model shows significant improvement in:
- **Medical terminology** understanding and usage
- **Clinical reasoning** and diagnostic procedures  
- **Emergency response** protocols and first aid
- **Drug information** and medication guidance
- **Safety considerations** in medical recommendations

## ⚠️ Important Disclaimers

- **🚨 Not a substitute for professional medical advice**
- **🏥 Always consult healthcare professionals for medical decisions**  
- **📞 Call emergency services (911/112) for life-threatening situations**
- **🔬 For research and educational purposes only**
- **⚖️ Users assume full responsibility for model usage**

## 🛠️ Hardware Requirements

### Minimum Requirements
- **GPU**: 8GB VRAM (with 4-bit quantization)
- **RAM**: 16GB system memory
- **Storage**: 20GB for model and dependencies

### Recommended Requirements  
- **GPU**: 16GB+ VRAM (RTX 4080/A100)
- **RAM**: 32GB+ system memory
- **Storage**: 50GB+ SSD for optimal performance

## 📖 Citation

If you use this model in your research or applications, please cite:

```bibtex
@misc{medical_gemma_3n,
  title={Medical Gemma-3N: Emergency Medical Assistant for Offline Healthcare},
  author={Eric Risco},
  year={2025},
  url={https://huggingface.co/ericrisco/medical-gemma-3n-4b},
  note={Fine-tuned on 86,667 medical Q&A pairs for emergency assistance}
}
```

## 🤝 Contributing

This model is part of the [Gemma3N Impact Challenge](https://github.com/ericrisco/gemma3n-impact-challenge) project. Contributions, feedback, and improvements are welcome!

## 📜 License

This model is released under the Gemma License. Please review the license terms before use in commercial applications.
