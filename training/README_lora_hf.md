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
- lora
- peft
- adapter
- unsloth
language:
- en
datasets:
- ericrisco/medrescue
library_name: peft
---

# Medical Gemma-3N LoRA Adapters 🏥⚡

**Efficient LoRA adapters** for fine-tuning Gemma-3N-4B into a specialized **emergency medical assistant**. These lightweight adapters (76.9MB) transform the base model into a medical expert while maintaining the original model's general capabilities.

## 🎯 Overview

- **Base Model**: [unsloth/gemma-3n-E4B-it](https://huggingface.co/unsloth/gemma-3n-E4B-it)
- **Adapter Size**: 76.9MB (vs 7.8GB full model)
- **Training Method**: LoRA (Low-Rank Adaptation)
- **Parameters Adapted**: 19.2M out of 7.8B (0.24% efficiency)
- **Training Dataset**: 86,667 medical Q&A pairs
- **Medical Accuracy**: 71.54% (vs 36.15% baseline)

## 🚀 Quick Start

### Installation

```bash
pip install torch transformers peft accelerate unsloth
```

### Load with PEFT

```python
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel
import torch

# Load base model
base_model_name = "unsloth/gemma-3n-E4B-it"
adapter_name = "ericrisco/medical-gemma-3n-lora"

tokenizer = AutoTokenizer.from_pretrained(base_model_name)
base_model = AutoModelForCausalLM.from_pretrained(
    base_model_name,
    torch_dtype=torch.float16,
    device_map="auto",
    load_in_4bit=True  # Optional: for memory efficiency
)

# Load LoRA adapters
model = PeftModel.from_pretrained(base_model, adapter_name)

# Medical consultation
def medical_consultation(question):
    prompt = f"<start_of_turn>user\n{question}<end_of_turn>\n<start_of_turn>model\n"
    
    inputs = tokenizer.encode(prompt, return_tensors="pt").to(model.device)
    
    with torch.no_grad():
        outputs = model.generate(
            inputs,
            max_new_tokens=512,
            temperature=0.7,
            do_sample=True,
            pad_token_id=tokenizer.eos_token_id,
            eos_token_id=tokenizer.eos_token_id
        )
    
    response = tokenizer.decode(outputs[0], skip_special_tokens=True)
    return response.split("<start_of_turn>model\n")[-1].split("<end_of_turn>")[0]

# Example usage
question = "What are the signs of a heart attack and what should I do?"
answer = medical_consultation(question)
print(answer)
```

### Load with Unsloth (Recommended)

```python
from unsloth import FastModel
from unsloth.chat_templates import get_chat_template

# Load model with Unsloth optimization
model, tokenizer = FastModel.from_pretrained(
    model_name="ericrisco/medical-gemma-3n-lora",
    max_seq_length=1024,
    dtype=None,
    load_in_4bit=True,
)

# Apply chat template
tokenizer = get_chat_template(
    tokenizer,
    chat_template="gemma-3",
)

# Faster inference with Unsloth
def fast_medical_response(question):
    messages = [{"role": "user", "content": question}]
    
    inputs = tokenizer.apply_chat_template(
        messages,
        tokenize=True,
        add_generation_prompt=True,
        return_tensors="pt"
    ).to(model.device)
    
    outputs = model.generate(
        input_ids=inputs,
        max_new_tokens=512,
        temperature=0.7,
        do_sample=True
    )
    
    response = tokenizer.decode(outputs[0][inputs.shape[-1]:], skip_special_tokens=True)
    return response

# Example usage
response = fast_medical_response("How do I treat severe bleeding?")
print(response)
```

## 🔧 Adapter Configuration

### LoRA Parameters
```python
# Training configuration used
LoRAConfig(
    r=8,                    # Rank: balance between efficiency and capacity
    lora_alpha=8,          # Scaling parameter
    lora_dropout=0.0,      # No dropout for stability
    bias="none",           # No bias adaptation
    task_type="CAUSAL_LM", # Causal language modeling
    target_modules=[       # Adapted components
        "q_proj", "k_proj", "v_proj", "o_proj",  # Attention
        "gate_proj", "up_proj", "down_proj"       # MLP
    ]
)
```

## 🎯 Use Cases

### 🚨 Emergency Medical Scenarios
```python
# First aid guidance
question = "Someone is choking, what should I do immediately?"
response = medical_consultation(question)

# Cardiac emergency  
question = "What are the steps for CPR on an adult?"
response = medical_consultation(question)

# Trauma assessment
question = "How do I assess if someone has a spinal injury?"
response = medical_consultation(question)
```

### 🏥 Clinical Applications
```python
# Symptom analysis
question = "What could cause chest pain and shortness of breath?"
response = medical_consultation(question)

# Medication information
question = "What are the contraindications for aspirin?"
response = medical_consultation(question)

# Diagnostic procedures
question = "When should someone seek immediate medical attention for headaches?"
response = medical_consultation(question)
```

## 📊 Performance Comparison

### Benchmark Results

Evaluated on [lextale/FirstAidInstructionsDataset](https://huggingface.co/datasets/lextale/FirstAidInstructionsDataset):

| Model | Accuracy | Parameters | Size |
|-------|----------|------------|------|
| **Base Gemma-3N** | 36.15% | 7.8B | 15GB |
| **+ Medical LoRA** | **71.54%** | +19.2M | **+76.9MB** |
| **Improvement** | **+35.39%** | +0.24% | +0.5% |

## 🔄 Model Management

### Multiple Adapter Support

```python
from peft import PeftModel

# Load base model once
base_model = AutoModelForCausalLM.from_pretrained("unsloth/gemma-3n-E4B-it")

# Switch between different adapters
medical_model = PeftModel.from_pretrained(base_model, "ericrisco/medical-gemma-3n-lora")

# You can load other task-specific adapters on the same base
# legal_model = PeftModel.from_pretrained(base_model, "other/legal-adapters")
# code_model = PeftModel.from_pretrained(base_model, "other/coding-adapters")
```

### Merging Adapters (Optional)

```python
from peft import PeftModel

# Load and merge for standalone deployment
base_model = AutoModelForCausalLM.from_pretrained("unsloth/gemma-3n-E4B-it")
model = PeftModel.from_pretrained(base_model, "ericrisco/medical-gemma-3n-lora")

# Merge adapters into base model
merged_model = model.merge_and_unload()

# Save merged model
merged_model.save_pretrained("./medical-gemma-merged")
tokenizer.save_pretrained("./medical-gemma-merged")

# Push to hub
merged_model.push_to_hub("your-username/medical-gemma-merged")
```

## 📚 Training Details

### Dataset Information
- **Source**: [ericrisco/medrescue](https://huggingface.co/datasets/ericrisco/medrescue)
- **Size**: 86,667 medical Q&A pairs
- **Sources**: 11 medical datasets + 14 official medical PDFs
- **Quality**: AI-enhanced with RAG pipeline and medical validation
- **Format**: Conversational instruction-response pairs

### Training Configuration
```python
# Training parameters used
SFTConfig(
    output_dir="./medical-gemma-lora",
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    warmup_steps=5,
    num_train_epochs=1,
    learning_rate=2e-5,
    logging_steps=10,
    save_steps=500,
    optim="adamw_8bit",
    weight_decay=0.01,
    lr_scheduler_type="linear",
    max_seq_length=1024,
)
```

## ⚠️ Important Disclaimers

- **🚨 Not a substitute for professional medical advice**
- **🏥 Always consult qualified healthcare professionals**
- **📞 Call emergency services (911/112) for life-threatening situations**
- **🔬 For research and educational purposes only**
- **⚖️ Users assume full responsibility for model usage**
- **🔒 Ensure HIPAA compliance in healthcare applications**

## 📖 Citation

```bibtex
@misc{medical_gemma_lora,
  title={Medical Gemma-3N LoRA Adapters: Efficient Medical AI Fine-tuning},
  author={Eric Risco},
  year={2025},
  url={https://huggingface.co/ericrisco/medical-gemma-3n-lora},
  note={LoRA adapters for emergency medical assistance}
}
```

## 🔗 Related Models

- **[ericrisco/medical-gemma-3n-4b](https://huggingface.co/ericrisco/medical-gemma-3n-4b)** - Full merged model
- **[ericrisco/medical-gemma-3n-lora-gguf](https://huggingface.co/ericrisco/medical-gemma-3n-lora-gguf)** - GGUF quantized
- **[ericrisco/medrescue](https://huggingface.co/datasets/ericrisco/medrescue)** - Training dataset

## 📜 License

This model is released under the Gemma License. See LICENSE file for details.