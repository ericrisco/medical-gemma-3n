# Emergency Assistant Data Pipeline

This directory contains the automated, reproducible data download pipeline for the Emergency Assistant project. It supports batch downloading from Hugging Face, Kaggle, Zenodo, and direct URLs, with robust handling for dataset configs and splits.

## 1. Environment Setup

1. **Install Python 3.8+**
2. (Recommended) Create a virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```
3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

## 2. Credentials

- **Kaggle:**
  1. Create a `kaggle.json` API token from your Kaggle account settings.
  2. Place it in `credentials/kaggle.json` (create the `credentials` folder if needed).

- **Hugging Face:**
  - Public datasets require no token. For private datasets, run `huggingface-cli login` before downloading.

## 3. Download All Datasets

Run:
```bash
python data/download_all.py
```
- Downloads all datasets in parallel as specified in `datasets_to_download.json`.
- Supports Hugging Face (with optional config/split), Kaggle, and direct URLs.
- Progress and errors are shown in the terminal.

## 4. Adding or Editing Datasets

Edit `datasets_to_download.json`. Each entry must have:
- `type`: `huggingface`, `kaggle`, or `direct`
- `name` (for Hugging Face/Kaggle) or `url` (for direct)
- `folder`: where to store the dataset
- For Hugging Face, optional: `config`, `split`
- For direct, required: `filename`

**Example:**
```json
{
  "type": "huggingface",
  "name": "some/dataset",
  "folder": "some_folder",
  "config": "default",
  "split": "train"
}
```

## 5. Citing Downloaded Datasets

The following datasets are included in the current pipeline:

### Hugging Face
- FreedomIntelligence/medical-o1-reasoning-SFT: https://huggingface.co/datasets/FreedomIntelligence/medical-o1-reasoning-SFT
- gamino/wiki_medical_terms: https://huggingface.co/datasets/gamino/wiki_medical_terms
- FreedomIntelligence/medical-o1-verifiable-problem: https://huggingface.co/datasets/FreedomIntelligence/medical-o1-verifiable-problem
- Intelligent-Internet/II-Medical-Reasoning-SFT: https://huggingface.co/datasets/Intelligent-Internet/II-Medical-Reasoning-SFT
- amu-cai/CAMEO: https://huggingface.co/datasets/amu-cai/CAMEO
- badri55/First_aid__dataset: https://huggingface.co/datasets/badri55/First_aid__dataset
- gretelai/symptom_to_diagnosis: https://huggingface.co/datasets/gretelai/symptom_to_diagnosis
- QuyenAnhDE/Diseases_Symptoms: https://huggingface.co/datasets/QuyenAnhDE/Diseases_Symptoms
- forwins/Drug-Review-Dataset: https://huggingface.co/datasets/forwins/Drug-Review-Dataset
- truehealth/medicationqa: https://huggingface.co/datasets/truehealth/medicationqa
- QCRI/HumAID-all: https://huggingface.co/datasets/QCRI/HumAID-all
- QCRI/MEDIC: https://huggingface.co/datasets/QCRI/MEDIC
- paulelliotco/synthetic-disaster-reports: https://huggingface.co/datasets/paulelliotco/synthetic-disaster-reports

### Kaggle
- louisteitelbaum/911-recordings: https://www.kaggle.com/datasets/louisteitelbaum/911-recordings

### Direct/Zenodo/WHO/ICRC
- UrbanSound8K: https://zenodo.org/record/1203745/files/UrbanSound8K.tar.gz
- WHO Basic Emergency Care: https://www.who.int/publications/i/item/9789241513081
- IFRC First Aid Guidelines: https://www.icrc.org/en/publication/basic-emergency-care-approach-acutely-ill-and-injured
- WHO BEC Protocol: https://www.who.int/teams/integrated-health-services/clinical-services-and-systems/emergency-and-critical-care/bec

Please cite the original sources in any publications or derivative works.

## 6. Troubleshooting
- Errors and summaries are printed after each run.
- For Hugging Face datasets requiring a config or split, add the `config` and/or `split` fields in the JSON.
- For private datasets, ensure you are authenticated with the appropriate service.

---

For questions or improvements, open an issue or contact the maintainers. 