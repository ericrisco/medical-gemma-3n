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
- gguf
- llama-cpp
- ollama
- quantized
language:
- en
datasets:
- ericrisco/medrescue
---

# Medical Gemma-3N GGUF: Offline Medical Assistant 🏥🚀

**GGUF quantized version** of Medical Gemma-3N for **ultra-fast local inference** with **Ollama**. Optimized for offline emergency medical assistance on consumer hardware without requiring Python dependencies.
**Base Model**: [unsloth/gemma-3n-E4B-it](https://huggingface.co/unsloth/gemma-3n-E4B-it)


## 📦 Model File

| File | Size | Description | Quality |
|------|------|-------------|---------|
| `medical-gemma-3n-4b.gguf` | **13.7GB** | Full precision GGUF | Maximum |

*Note: This is a high-precision GGUF conversion. For smaller sizes, you can quantize further using llama.cpp tools.*

## 🚀 Quick Start with Ollama

### ✅ 1. Download the GGUF model from Hugging Face

Download it:

```bash
wget https://huggingface.co/ericrisco/medical-gemma-3n-4b-gguf/resolve/main/medical-gemma-3n-4b.gguf
```

### 🗂️ 2. Create a Modelfile for Ollama

Create a new directory:

```bash
mkdir -p ~/ollama/models/medical-gemma-3n-4b
cd ~/ollama/models/medical-gemma-3n-4b
```

And add a file called Modelfile with this content:

```dockerfile
FROM ./medical-gemma-3n-4b.gguf

# You can adjust these parameters if needed
PARAMETER temperature 0.7
PARAMETER top_k 40
PARAMETER top_p 0.9
PARAMETER repeat_penalty 1.1
```

### 🏗️ 3. Create the model with ollama

Now build the model:

```bash
ollama create medical-gemma-3n-4b -f Modelfile
```

### 🧠 4. Run the model

Once created, simply run:

```bash
ollama run medical-gemma-3n-4b
```

This will give you an interactive interface to talk to your model.

### Interactive Medical Consultation

```bash
# Start interactive session
ollama run medical-gemma-3n-4b

# Example conversation:
>>> What are the signs of a stroke?
The main signs of a stroke can be ...
```

## ⚠️ Important Disclaimers

- **🚨 NOT A SUBSTITUTE for professional medical advice**
- **🏥 ALWAYS consult qualified healthcare professionals**
- **📞 CALL EMERGENCY SERVICES (911/112) for life-threatening situations**
- **🔬 FOR EDUCATIONAL AND RESEARCH PURPOSES ONLY**
- **⚖️ Users assume FULL RESPONSIBILITY for model usage**
- **🔒 Ensure compliance with medical privacy regulations (HIPAA, GDPR)**

## 📖 Citation

```bibtex
@misc{medical_gemma_gguf,
  title={Medical Gemma-3N GGUF: Quantized Emergency Medical Assistant},
  author={Eric Risco},
  year={2025},
  url={https://huggingface.co/ericrisco/medical-gemma-3n-lora-gguf},
  note={GGUF quantized model for offline medical assistance}
}
```

## 🔗 Related Models

- **[ericrisco/medical-gemma-3n-4b](https://huggingface.co/ericrisco/medical-gemma-3n-4b)** - Full merged model
- **[ericrisco/medical-gemma-3n-lora](https://huggingface.co/ericrisco/medical-gemma-3n-lora)** - LoRA adapters
- **[ericrisco/medrescue](https://huggingface.co/datasets/ericrisco/medrescue)** - Training dataset

## 📜 License

This model is released under the Gemma License. See LICENSE for details.

---

**🚀 Ultra-fast offline medical assistance - Deploy anywhere with zero dependencies**