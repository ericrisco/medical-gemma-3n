import os
import json
import random
from huggingface_hub import HfApi
from dotenv import load_dotenv

load_dotenv()

DIR_PATH = 'json'
OUT_PATH = 'json/final/medical_training_dataset.json'
EXCLUDE = {'pdf_embeddings.json'}
HUGGING_FACE_TOKEN = os.getenv("HUGGING_FACE_TOKEN")

all_data = []

for fname in os.listdir(DIR_PATH):
    if not fname.endswith('.json') or fname in EXCLUDE:
        continue
    fpath = os.path.join(DIR_PATH, fname)
    with open(fpath, 'r') as f:
        try:
            data = json.load(f)
        except Exception as e:
            print(f"Error loading {fname}: {e}")
            continue

    # If the file contains a list of records, add each with its source
    if isinstance(data, list):
        for entry in data:
            entry['source'] = os.path.splitext(fname)[0]
            all_data.append(entry)

    # If the file contains a single record (dict), add it with its source
    elif isinstance(data, dict):
        data['source'] = os.path.splitext(fname)[0]
        all_data.append(data)

# Shuffle the dataset to randomize the 'source' order
random.shuffle(all_data)

# Ensure output directory exists
os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)

with open(OUT_PATH, 'w') as f:
    json.dump(all_data, f, indent=2, ensure_ascii=False)

print(f"Saved {len(all_data)} records to {OUT_PATH}")

print(f"Uploading to Hugging Face Hub: " + HUGGING_FACE_TOKEN)

api = HfApi(token=HUGGING_FACE_TOKEN)

api.create_repo(
    repo_id="ericrisco/medical-training-dataset",
    repo_type="dataset",
    exist_ok=True,
    private=False
)
api.upload_folder(
    folder_path=os.path.dirname(OUT_PATH),
    repo_id="ericrisco/medical-training-dataset",
    repo_type="dataset",
) 