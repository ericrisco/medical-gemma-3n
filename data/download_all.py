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
    
    # Skip if file already exists
    if os.path.exists(dest_file) and os.path.getsize(dest_file) > 0:
        print(f"[Direct] File already exists: {dest_file}")
        results[key] = 'Already exists'
        return
    
    max_retries = 3
    for attempt in range(max_retries):
        try:
            print(f"[Direct] Downloading {url} to {dest_file} ... (attempt {attempt + 1}/{max_retries})")
            
            # Enhanced headers to avoid being blocked
            headers = {
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                'Accept': 'application/pdf,application/octet-stream,*/*',
                'Accept-Language': 'en-US,en;q=0.9',
                'Accept-Encoding': 'gzip, deflate, br',
                'DNT': '1',
                'Connection': 'keep-alive',
                'Upgrade-Insecure-Requests': '1',
            }
            
            # Longer timeout and session for better connection handling
            session = requests.Session()
            session.headers.update(headers)
            
            with session.get(url, stream=True, timeout=(30, 60)) as r:
                r.raise_for_status()
                total = int(r.headers.get('content-length', 0))
                
                with open(dest_file, 'wb') as f, tqdm(total=total, unit='B', unit_scale=True, desc=filename) as bar:
                    for chunk in r.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            bar.update(len(chunk))
            
            # Verify file was downloaded correctly
            if os.path.exists(dest_file) and os.path.getsize(dest_file) > 0:
                print(f"[Direct] Successfully downloaded {filename} ({os.path.getsize(dest_file)} bytes)")
                results[key] = 'Success'
                return
            else:
                raise Exception("Downloaded file is empty or doesn't exist")
                
        except Exception as e:
            print(f"[Direct] Attempt {attempt + 1} failed for {url}: {e}")
            
            # Clean up partial download
            if os.path.exists(dest_file):
                os.remove(dest_file)
            
            if attempt == max_retries - 1:
                results[key] = f'Error after {max_retries} attempts: {e}'
                print(f"[Direct] Giving up on {url} after {max_retries} attempts")
            else:
                import time
                time.sleep(5 * (attempt + 1))  # Exponential backoff

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