import ollama

def clean_markdown_response(response):
    if not response:
        return response
    
    cleaned = response.strip()
    
    if cleaned.startswith('```json'):
        cleaned = cleaned[7:] 
    elif cleaned.startswith('```'):
        cleaned = cleaned[3:]
    
    if cleaned.endswith('```'):
        cleaned = cleaned[:-3]
    
    cleaned = cleaned.strip()
    
    return cleaned

def run_ollama(model, system_prompt, user_input, temperature=0.7, top_p=1.0, max_tokens=512):
    response = ollama.chat(
        model=model,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_input}
        ],
        options={
            "temperature": temperature,
            "top_p": top_p,
            "num_predict": max_tokens
        }
    )

    raw_content = response['message']['content']
    cleaned_content = clean_markdown_response(raw_content)
    return cleaned_content