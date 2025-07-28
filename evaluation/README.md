# Model Evaluation Pipeline

This directory contains the evaluation framework for testing medical AI models against standardized datasets. The pipeline uses a judge-based evaluation system with Ollama for model inference and OpenRouter for judgment scoring.

## 📋 Overview

The evaluation system compares:
- **Base Gemma3N Model** (standard performance baseline)
- **Medical-Tuned Gemma3N-4B** (fine-tuned on medical data)
- **Standardized Medical Datasets** (First Aid Instructions)
- **AI Judge Evaluation** (Gemini 2.5 Flash for consistent scoring)

## 🚀 Quick Start

### Prerequisites

1. **Install dependencies:**
   ```bash
   pip install datasets tqdm ollama openai python-dotenv
   ```

2. **Set up environment variables:**
   ```bash
   # Create .env file in project root
   OPENROUTER_API_KEY=your_openrouter_api_key
   ```

3. **Install and configure Ollama:**
   ```bash
   # Install Ollama (https://ollama.ai)
   curl -fsSL https://ollama.ai/install.sh | sh
   
   # Start Ollama service
   ollama serve
   
   # Pull required models
   ollama pull gemma3n
   ollama pull medical-gemma-3n-4b
   ```

## 📊 Evaluation Framework

### Core Script: `evaluation.py`

The main evaluation script implements a comprehensive testing pipeline:

#### **Judge-Based Evaluation System**

```python
def openrouter_judge(client, model, question, gold, prediction):
    """
    AI judge evaluates prediction against ground truth
    - Uses Gemini 2.5 Flash Lite for consistent judgment
    - Returns CORRECT/INCORRECT based on clinical accuracy
    - Considers medical relevance and completeness
    """
```

#### **Medical System Prompt**

```python
MEDICAL_SYSTEM = (
    "You are a precise, trustworthy medical assistant for students and professionals. "
    "Provide accurate, concise, clinically relevant information based on established medical knowledge. "
    "Explain mechanisms, causes, and consequences when appropriate. "
    "Clarify misconceptions, note uncertainty when relevant, never invent facts, and never give medical advice or diagnoses. "
    "Respond in English only."
)
```

### 🔧 Evaluation Pipeline

1. **Dataset Loading**
   - **Source**: `lextale/FirstAidInstructionsDataset`
   - **Processing**: Loads and samples from HuggingFace datasets
   - **Format**: Question-answer pairs for first aid scenarios

2. **Model Inference**
   - **Tool**: Ollama client with configurable parameters
   - **Temperature**: 0.15 (low randomness for consistent results)
   - **Max Tokens**: 512 (adequate for medical responses)
   - **System**: Medical assistant prompt for clinical accuracy

3. **AI Judge Scoring**
   - **Judge Model**: Google Gemini 2.5 Flash Lite (via OpenRouter)
   - **Evaluation Criteria**: Clinical accuracy, completeness, safety
   - **Output**: Binary CORRECT/INCORRECT judgment
   - **Consistency**: Same judge for all evaluations

4. **Results Tracking**
   - **Format**: Markdown with timestamp and parameters
   - **Metrics**: Accuracy percentage and raw counts
   - **Storage**: Incremental results in `results/results.md`

## 📈 Usage Options

### Basic Evaluation
```bash
python evaluation.py --gen-model gemma3n --limit 20
```

### Advanced Configuration
```bash
python evaluation.py \
    --dataset lextale/FirstAidInstructionsDataset \
    --gen-model medical-gemma-3n-4b \
    --limit 50 \
    --gen-temperature 0.15 \
    --gen-max-new-tokens 512 \
    --openrouter-model google/gemini-2.5-flash-lite-preview-06-17 \
    --print-samples \
    --progress
```

### Command Line Arguments

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--dataset` | `lextale/FirstAidInstructionsDataset` | HuggingFace dataset to evaluate |
| `--gen-model` | `gemma3n` | Ollama model to test |
| `--limit` | `20` | Number of examples per dataset split |
| `--gen-temperature` | `0.2` | Temperature for model generation |
| `--gen-max-new-tokens` | `512` | Maximum tokens for model response |
| `--openrouter-model` | `google/gemini-2.5-flash-lite-preview-06-17` | Judge model |
| `--print-samples` | `False` | Print individual Q&A samples |
| `--progress` | `False` | Show progress with running accuracy |
| `--output-dir` | `results` | Output directory for results |
| `--md-file` | `results.md` | Markdown file for results |

## 📊 Evaluation Results

### Current Performance Benchmarks

Based on `results/results.md`:

#### Base Gemma3N Model
- **Dataset**: First Aid Instructions (130 examples)
- **Accuracy**: **36.15%** (47/130)
- **Performance**: Baseline medical knowledge
- **Strengths**: General reasoning ability
- **Weaknesses**: Limited medical-specific training

#### Medical-Tuned Gemma3N-4B
- **Dataset**: First Aid Instructions (130 examples)
- **Accuracy**: **71.54%** (93/130)
- **Performance**: Significantly improved medical accuracy
- **Improvement**: **35.39%** absolute gain over base model
- **Strengths**: Medical terminology, clinical reasoning, emergency procedures

### Performance Analysis

**Key Findings:**
- **2x Performance Gain**: Medical fine-tuning nearly doubles accuracy
- **Clinical Relevance**: Specialized model shows better understanding of medical context
- **Emergency Scenarios**: Significant improvement in first aid instruction accuracy
- **Judge Consistency**: AI judge provides reliable evaluation metrics

## 🛠️ Technical Architecture

### Core Components

1. **Ollama Client**: Local model inference with medical system prompt
2. **OpenRouter Integration**: Cloud-based AI judge for consistent evaluation
3. **Dataset Processing**: HuggingFace dataset loading and sampling
4. **Results Management**: Automated markdown generation with timestamps

### Key Features

- **Reproducible Evaluation**: Consistent parameters and random seeds
- **Scalable Testing**: Configurable dataset sizes and model parameters
- **Real-time Monitoring**: Progress tracking and sample inspection
- **Automated Reporting**: Markdown generation with run summaries
- **Error Resilience**: Robust handling of API failures and timeouts

### Judge Evaluation Criteria

The AI judge evaluates predictions based on:
- **Clinical Accuracy**: Medically correct information
- **Completeness**: Coverage of essential medical points
- **Safety**: No harmful or dangerous recommendations
- **Professional Standards**: Appropriate for medical professionals
- **Context Relevance**: Appropriate response to the specific question

### Output Format

Results are stored in markdown format:
```markdown
## Run — 2025-07-27 00:45:10

**Parameters**:
{
  "dataset": "lextale/FirstAidInstructionsDataset",
  "gen_model": "medical-gemma-3n-4b",
  "limit": 10,
  "gen_temperature": 0.15,
  "gen_max_new_tokens": 512,
  "openrouter_model": "google/gemini-2.5-flash-lite-preview-06-17"
}

**Summary**:
- Accuracy: **71.54%** (93/130)
```

## 🔧 Configuration

### Environment Variables
```bash
OPENROUTER_API_KEY=your_openrouter_api_key_here
```

### Required Services
- **Ollama**: Must be running with target models installed
- **OpenRouter**: API key for judge model access
- **Internet**: Required for dataset loading and judge API calls

### Model Requirements
- **Base Model**: `gemma3n` (Ollama)
- **Medical Model**: `medical-gemma-3n-4b` (Ollama)
- **Judge Model**: `google/gemini-2.5-flash-lite-preview-06-17` (OpenRouter)

## 🚀 Execution Workflow

### Single Model Evaluation
```bash
# Evaluate base model
python evaluation.py --gen-model gemma3n --limit 50 --progress

# Evaluate medical-tuned model
python evaluation.py --gen-model medical-gemma-3n-4b --limit 50 --progress
```

### Comprehensive Benchmark
```bash
# Compare both models with detailed output
python evaluation.py --gen-model gemma3n --limit 100 --print-samples
python evaluation.py --gen-model medical-gemma-3n-4b --limit 100 --print-samples
```

### Custom Dataset Evaluation
```bash
# Evaluate on different medical dataset
python evaluation.py \
    --dataset your/medical/dataset \
    --gen-model medical-gemma-3n-4b \
    --limit 200 \
    --gen-temperature 0.1
```

## 📈 Performance Metrics

### Accuracy Calculation
- **Formula**: `(Correct Predictions / Total Predictions) × 100`
- **Judge**: AI-based binary classification (CORRECT/INCORRECT)
- **Consistency**: Same judge model for all evaluations
- **Threshold**: Clinical accuracy and completeness standards

### Benchmark Datasets
- **Primary**: `lextale/FirstAidInstructionsDataset` - First aid procedures
- **Future**: Additional medical Q&A datasets for comprehensive evaluation
- **Scalability**: Configurable dataset sizes for different testing needs

## 📄 Citation

If you use this evaluation pipeline, please cite:

```bibtex
@misc{medical_model_evaluation,
  title={Medical AI Model Evaluation Pipeline with Judge-Based Scoring},
  author={Eric Risco},
  year={2025},
  url={https://github.com/ericrisco/gemma3n-impact-challenge}
}
```

---

**Evaluation Results**: Medical fine-tuning provides **71.54% accuracy** vs **36.15% baseline** - a **35.39%** improvement in medical AI performance.