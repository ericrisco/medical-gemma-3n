import ollama

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
    return response['message']['content'] 