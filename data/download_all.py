import os
import json
import threading
import subprocess
import requests
from tqdm import tqdm
from datasets import load_dataset
from kaggle.api.kaggle_api_extended import KaggleApi

with open(os.path.join(os.path.dirname(__file__), 'datasets_to_download.json')) as f:
    DATASETS = json.load(f)

results = {}
threads = []

# Setup Kaggle API only if needed
api = None
for d in DATASETS:
    if d['type'] == 'kaggle':
        os.environ['KAGGLE_CONFIG_DIR'] = os.path.abspath('credentials')
        api = KaggleApi()
        api.authenticate()
        break

def download_huggingface(dataset_name, folder, key, config=None, split=None):
    dest = os.path.join('data', folder)
    os.makedirs(dest, exist_ok=True)
    try:
        print(f"[HF] Downloading {dataset_name} to {dest} ...")
        kwargs = {'cache_dir': dest}
        if config:
            kwargs['name'] = config
        if split:
            kwargs['split'] = split
        load_dataset(dataset_name, **kwargs)
        results[key] = 'Success'
    except Exception as e:
        results[key] = f'Error: {e}'

def download_kaggle(dataset_name, folder, key):
    dest = os.path.join('data', folder)
    os.makedirs(dest, exist_ok=True)
    try:
        print(f"[Kaggle] Downloading {dataset_name} to {dest} ...")
        api.dataset_download_files(dataset_name, path=dest, unzip=True)
        results[key] = 'Success'
    except Exception as e:
        results[key] = f'Error: {e}'

def download_direct(url, folder, filename, key):
    dest_dir = os.path.join('data', folder)
    os.makedirs(dest_dir, exist_ok=True)
    dest_file = os.path.join(dest_dir, filename)
    try:
        print(f"[Direct] Downloading {url} to {dest_file} ...")
        with requests.get(url, stream=True) as r:
            r.raise_for_status()
            total = int(r.headers.get('content-length', 0))
            with open(dest_file, 'wb') as f, tqdm(total=total, unit='B', unit_scale=True) as bar:
                for chunk in r.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        bar.update(len(chunk))
        results[key] = 'Success'
    except Exception as e:
        results[key] = f'Error: {e}'

def dispatch_download(d, key):
    if d['type'] == 'huggingface':
        # Support optional config and split
        config = d.get('config')
        split = d.get('split')
        download_huggingface(d['name'], d['folder'], key, config, split)
    elif d['type'] == 'kaggle':
        download_kaggle(d['name'], d['folder'], key)
    elif d['type'] == 'direct':
        download_direct(d['url'], d['folder'], d['filename'], key)
    else:
        results[key] = f"Unknown type: {d['type']}"

for i, d in enumerate(DATASETS):
    key = d.get('name') or d.get('url')
    t = threading.Thread(target=dispatch_download, args=(d, key))
    t.start()
    threads.append(t)

for t in threads:
    t.join()

print("\nAll downloads finished. Summary:")
for key, output in results.items():
    print(f"\n--- {key} ---\n{output}") 