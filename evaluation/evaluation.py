import os
import argparse
import json
from datetime import datetime
from pathlib import Path
from datasets import load_dataset, concatenate_datasets
from tqdm import tqdm
import ollama
from openai import OpenAI
import dotenv
dotenv.load_dotenv()

def make_ollama_client():
    host = "http://localhost:11434"
    return ollama.Client(host=host)

def make_openrouter_client(referrer: str = "", title: str = ""):
    api_key = os.getenv('OPENROUTER_API_KEY')
    if not api_key:
        raise RuntimeError("OPENROUTER_API_KEY is not set")
    client = OpenAI(
        base_url="https://openrouter.ai/api/v1",
        api_key=api_key,
    )
    headers = {}
    if referrer:
        headers["HTTP-Referer"] = referrer
    if title:
        headers["X-Title"] = title
    return client, headers

MEDICAL_SYSTEM = (
    "You are a precise, trustworthy medical assistant for students and professionals. "
    "Provide accurate, concise, clinically relevant information based on established medical knowledge. "
    "Explain mechanisms, causes, and consequences when appropriate. "
    "Clarify misconceptions, note uncertainty when relevant, never invent facts, and never give medical advice or diagnoses. "
    "Respond in English only."
)

def ollama_chat(client, model, system, user, temperature=0.2, max_tokens=512):
    resp = client.chat(
        model=model,
        messages=[
            {"role": "system", "content": system or ""},
            {"role": "user", "content": user},
        ],
        options={"temperature": float(temperature), "num_predict": int(max_tokens)},
        stream=False,
    )
    msg = resp.get("message", {})
    return (msg.get("content") or "").strip()

def generate_prediction(ollama_client, gen_model, question, temperature, max_tokens):
    return ollama_chat(
        client=ollama_client,
        model=gen_model,
        system=MEDICAL_SYSTEM,
        user=question,
        temperature=temperature,
        max_tokens=max_tokens,
    )

def openrouter_judge(client, extra_headers, model, question, gold, prediction):
    content = [
        {
            "type": "text",
            "text": (
                "You are an expert medical evaluator. Given a question, the ground-truth answer (gold), "
                "and a prediction from another AI, your job is to provide a one-word judgment: "
                "'CORRECT' if the prediction would be accepted by a medical examiner as a clinically accurate and sufficient answer, "
                "'INCORRECT' if it misses clinically essential information, contains significant errors, or would mislead a healthcare professional. "
                "Minor differences in wording, detail, or additional correct information should not make the answer incorrect as long as the main clinical content is present. "
                "If the prediction covers all clinically important points—even if the style or extra details differ from the gold—it is CORRECT. "
                "Respond in English only. Only give your one-word verdict, nothing else.\n\n"
                f"Question: ***{question}***\n"
                f"Ground truth answer: ***{gold}***\n"
                f"Prediction: ***{prediction}***"
            )
        }
    ]
    completion = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": content}],
        extra_headers=extra_headers,
    )
    verdict = completion.choices[0].message.content.strip().upper()
    if "CORRECT" in verdict and "INCORRECT" not in verdict:
        return "CORRECT"
    if "INCORRECT" in verdict and "CORRECT" not in verdict:
        return "INCORRECT"
    return "INCORRECT"

def build_dataset(name, limit_per_split):
    ds = load_dataset(name)
    parts = []
    for split_name in ds.keys():
        split = ds[split_name]
        n = min(limit_per_split, len(split))
        parts.append(split.select(range(n)))
    return parts[0] if len(parts) == 1 else concatenate_datasets(parts)

def ensure_results_md(md_path: Path):
    if not md_path.exists():
        md_path.parent.mkdir(parents=True, exist_ok=True)
        md_path.write_text("# Evaluations with Ollama + OpenRouter Judge\n\n", encoding="utf-8")

def append_run_summary(md_path: Path, params: dict, accuracy: float, correct: int, total: int):
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    block = []
    block.append(f"## Run — {ts}\n")
    block.append("**Parameters**:\n")
    block.append("```json")
    block.append(json.dumps(params, ensure_ascii=False, indent=2))
    block.append("```\n")
    block.append("**Summary**:\n")
    block.append(f"- Accuracy: **{accuracy:.2%}** ({correct}/{total})\n")
    block.append("---\n\n")
    with md_path.open("a", encoding="utf-8") as f:
        f.write("\n".join(block))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dataset", default="lextale/FirstAidInstructionsDataset")
    ap.add_argument("--gen-model", default="gemma3n")
    ap.add_argument("--limit", type=int, default=20)
    ap.add_argument("--gen-temperature", type=float, default=0.2)
    ap.add_argument("--gen-max-new-tokens", type=int, default=512)
    ap.add_argument("--openrouter-model", default="google/gemini-2.5-flash-lite-preview-06-17")
    ap.add_argument("--openrouter-referrer", default="https://huggingface.co/ericrisco/medical-gemma-3n-4b")
    ap.add_argument("--openrouter-title", default="EVALUATION GEMMA")
    ap.add_argument("--print-samples", action="store_true")
    ap.add_argument("--progress", action="store_true")
    ap.add_argument("--output-dir", default="results")
    ap.add_argument("--md-file", default="results.md")
    args = ap.parse_args()

    ollama_client = make_ollama_client()
    or_client, or_headers = make_openrouter_client(args.openrouter_referrer, args.openrouter_title)
    data = build_dataset(args.dataset, args.limit)

    out_dir = Path(args.output_dir)
    md_path = out_dir / args.md_file
    ensure_results_md(md_path)
    out_dir.mkdir(parents=True, exist_ok=True)

    correct = 0
    total = 0

    for row in tqdm(data, desc="Evaluating"):
        q = row["question"] if "question" in row else row.get("prompt", "")
        gold = row["answer"] if "answer" in row else row.get("gold", "")
        pred = generate_prediction(
            ollama_client=ollama_client,
            gen_model=args.gen_model,
            question=q,
            temperature=args.gen_temperature,
            max_tokens=args.gen_max_new_tokens,
        )
        verdict = openrouter_judge(
            client=or_client,
            extra_headers=or_headers,
            model=args.openrouter_model,
            question=q,
            gold=gold,
            prediction=pred,
        )
        total += 1
        if verdict == "CORRECT":
            correct += 1

        if args.print_samples:
            print("\n---")
            print("Q:", q)
            print("GOLD:", gold)
            print("PRED:", pred)
            print("VERDICT:", verdict)
            print(f"RUN ACCURACY: {correct}/{total} = {correct/total:.2%}")

        elif args.progress:
            print(f"VERDICT: {verdict} | ACC: {correct}/{total} = {correct/total:.2%}")

    accuracy = correct / total if total else 0.0
    print(f"\nFinal Accuracy: {accuracy:.2%}  ({correct}/{total})")

    params = {
        "dataset": args.dataset,
        "gen_model": args.gen_model,
        "limit": args.limit,
        "gen_temperature": args.gen_temperature,
        "gen_max_new_tokens": args.gen_max_new_tokens,
        "openrouter_model": args.openrouter_model,
        "output_dir": str(out_dir),
        "md_file": args.md_file,
    }
    append_run_summary(md_path, params, accuracy, correct, total)

if __name__ == "__main__":
    main()
