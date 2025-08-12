
import argparse, os, sys, json, re
from openai import OpenAI

def main():
    ap = argparse.ArgumentParser(description="Analyze transcript with ChatGPT and print JSON.")
    ap.add_argument("--text", help="Transcript text")
    ap.add_argument("--input", help="Path to a text file containing transcript")
    ap.add_argument("--model", default="gpt-4o-mini")
    args = ap.parse_args()

    if not args.text and not args.input:
        print("Provide --text or --input", file=sys.stderr)
        sys.exit(1)

    if args.input:
        if not os.path.isfile(args.input):
            print(f"Input file not found: {args.input}", file=sys.stderr)
            sys.exit(1)
        with open(args.input, "r", encoding="utf-8") as f:
            transcript_text = f.read().strip()
    else:
        transcript_text = (args.text or "").strip()

    if not transcript_text:
        print(json.dumps({"summary":"","entities":{},"follow_up":""}))
        return

    client = OpenAI(api_key="")

    prompt = f"""
Analyze the following medical visit transcript and return ONLY raw JSON with:
- "summary": a 1–3 sentence recap,
- "entities": a JSON object of key clinical items (symptoms, meds, body sites, diagnoses) as string values,
- "follow_up": a short, cautious recommendation.

Transcript:
{transcript_text}

Return ONLY JSON (no commentary, no code fences).
"""

    # Prefer forcing JSON if your SDK version supports it
    try:
        resp = client.chat.completions.create(
            model=args.model,
            messages=[
                {"role": "system", "content": "You are a careful medical assistant. Do not include PHI beyond what is provided."},
                {"role": "user", "content": prompt},
            ],
            temperature=0,
            response_format={"type": "json_object"},  # <- ensures pure JSON in many client versions
        )
        raw = resp.choices[0].message.content
        print(raw)  # already JSON
        return
    except Exception:
        # Fallback: clean code fences if the SDK/server ignored response_format
        resp = client.chat.completions.create(
            model=args.model,
            messages=[
                {"role": "system", "content": "You are a careful medical assistant. Do not include PHI beyond what is provided."},
                {"role": "user", "content": prompt},
            ],
            temperature=0,
        )
        raw = resp.choices[0].message.content or ""
        cleaned = re.sub(r"^```(?:json)?|```$", "", raw.strip(), flags=re.MULTILINE).strip()
        print(cleaned)

if __name__ == "__main__":
    main()
