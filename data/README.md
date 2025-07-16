# Emergency Medical Data Pipeline

This directory contains the automated data download pipeline for the Emergency Medical Assistant project. It downloads medical datasets from Hugging Face and official emergency/medical PDFs for training a specialized medical language model.

## 📋 Overview

The pipeline automatically downloads:
- **11 Medical Datasets** from Hugging Face (Q&A, reasoning, symptoms, medications)
- **14 Official Emergency/Medical PDFs** from WHO, ICRC, government agencies, and military sources
- All data is processed and prepared for medical language model training

## 🚀 Quick Start

### 1. Environment Setup

```bash
# Clone and navigate to the project
cd /path/to/gemma3n-impact-challenge/data

# Create virtual environment (recommended)
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Credentials Setup

**Hugging Face:**
- Public datasets: No token needed
- Private datasets: Run `huggingface-cli login`

### 3. Download All Data

```bash
# Download everything (HuggingFace datasets + PDFs)
python download_all.py
```

The script will:
- Download all datasets in parallel
- Show progress bars and detailed status
- Retry failed downloads with exponential backoff
- Save everything to organized folders

## 📊 Downloaded Datasets

### Medical Q&A and Reasoning Datasets (Hugging Face)

| Dataset | Description | Size | Config |
|---------|-------------|------|--------|
| `FreedomIntelligence/medical-o1-reasoning-SFT` | Medical reasoning with chain-of-thought | ~50K examples | `en` |
| `gamino/wiki_medical_terms` | Medical terminology from Wikipedia | ~100K terms | default |
| `FreedomIntelligence/medical-o1-verifiable-problem` | Verifiable medical problems | ~20K examples | default |
| `Intelligent-Internet/II-Medical-Reasoning-SFT` | Medical reasoning for fine-tuning | ~80K examples | default |
| `amu-cai/CAMEO` | Clinical emotion recognition | ~15K examples | default |
| `badri55/First_aid__dataset` | First aid procedures and responses | ~5K examples | default |
| `gretelai/symptom_to_diagnosis` | Symptom-diagnosis mapping | ~10K examples | default |
| `QuyenAnhDE/Diseases_Symptoms` | Disease-symptom relationships | ~8K examples | default |
| `truehealth/medicationqa` | Medication Q&A pairs | ~12K examples | default |
| `truehealth/medqa` | Medical licensing exam questions | ~15K examples | default |
| `paulelliotco/synthetic-disaster-reports` | Synthetic disaster scenarios | ~3K examples | default |

### Official Emergency/Medical PDFs (Direct Download)

| Source | Document | Purpose |
|--------|----------|---------|
| **WHO** | Basic Emergency Care Guidelines | Emergency medical protocols |
| **WHO** | Emergency Medical Services Guidelines | EMS operational guidance |
| **WHO** | Emergency Surgical Care in Disaster Situations | Surgical procedures in emergencies |
| **ICRC** | First Aid Guidelines | International first aid standards |
| **ICRC** | Global First Aid Reference Centre Guidelines | Advanced first aid protocols |
| **US Army** | Tactical Combat Casualty Care Handbook | Military medical procedures |
| **US FEMA** | CERT Basic Participant Manual | Community emergency response |
| **Canada WorkSafeBC** | Mine Rescue and Recovery Operations | Industrial emergency procedures |
| **BC Government** | Earthquake and Tsunami Guide | Natural disaster preparedness |
| **BC Government** | Flood Preparedness Guide | Flood response procedures |
| **BC Government** | Extreme Heat Guide | Heat emergency protocols |
| **BC Government** | Pandemic Guide | Pandemic response procedures |
| **BC Government** | Winter Emergency Guide | Cold weather emergencies |
| **BC Government** | Neighbourhood Emergency Guide | Community response planning |

## 📁 Data Structure

After download, your `/data` directory will look like:

```
data/
├── download_all.py                    # Main download script
├── datasets_to_download.json          # Dataset configuration
├── requirements.txt                   # Python dependencies
├── README.md                          # This file
│
├── medical_o1_reasoning_sft/          # Medical reasoning dataset
├── wiki_medical_terms/                # Medical terminology
├── medicationqa/                      # Medication Q&A
├── first_aid_dataset/                 # First aid procedures
├── symptom_to_diagnosis/              # Symptom-diagnosis mapping
├── synthetic_disaster_reports/        # Disaster scenarios
│
├── basic_emergency_care/              # WHO emergency care PDFs
├── ifrc_first_aid_guidelines/         # ICRC first aid PDFs
├── tactical_casualty_combat_care_handbook/  # Military medical PDFs
├── earthquake_and_tsunami_guide/      # Natural disaster PDFs
├── preparedbc_flood_preparedness_guide/
├── preparedbc_extreme_heat_guide/
├── preparedbc_pandemic_guide/
├── preparedbc_winter_guide/
└── preparedbc_neighbourhood_guide/
```

## 🔧 Configuration

### Adding New Datasets

Edit `datasets_to_download.json`:

```json
{
  "type": "huggingface",          # or "direct"
  "name": "username/dataset-name", # For Hugging Face
  "folder": "local_folder_name",   # Where to save
  "config": "en",                  # Optional: dataset config
  "split": "train"                 # Optional: specific split
}
```

### Direct PDF Download Example

```json
{
  "type": "direct",
  "url": "https://example.com/document.pdf",
  "folder": "document_folder",
  "filename": "document.pdf"
}
```

## 🔍 Download Features

- **Parallel Downloads**: All datasets download simultaneously
- **Smart Retry**: Exponential backoff for failed downloads
- **Progress Tracking**: Real-time progress bars
- **Error Handling**: Detailed error reporting
- **Incremental**: Skips already downloaded files
- **Robust Headers**: Avoids being blocked by servers

## 📈 Usage Statistics

After download completes, you'll see:
```
All downloads finished. Summary:

--- FreedomIntelligence/medical-o1-reasoning-SFT ---
Success

--- https://iris.who.int/bitstream/handle/10665/275635/9789241513081-eng.pdf ---
Success

--- Error Example ---
Error after 3 attempts: Connection timeout
```

## 🛠️ Troubleshooting

### Common Issues

1. **Connection Errors**: Script automatically retries with exponential backoff
2. **Disk Space**: Ensure ~5GB free space for all downloads
3. **Firewall**: Some PDFs may be blocked by corporate firewalls

### Debug Mode

```bash
# Run with verbose output
python download_all.py --verbose
```

## 📋 Next Steps

After downloading:

1. **Process PDFs**: Use `../data-prep/vectorizing_medical_knowledge.py` to extract and vectorize PDF content
2. **Prepare Training Data**: Use scripts in `../data-prep/` to format datasets for training
3. **Train Model**: Use scripts in `../training/` to fine-tune Gemma3N on medical data

## 📄 Citation

If you use this data pipeline or the downloaded datasets, please cite:

```bibtex
@misc{emergency_medical_data_pipeline,
  title={Emergency Medical Data Pipeline},
  author={Eric Risco},
  year={2025},
  url={https://github.com/ericrisco/gemma3n-impact-challenge}
}
```

And cite the original dataset sources as listed in the download summary.

---

**Total Downloads**: 11 datasets + 14 PDFs = ~2GB medical training data 