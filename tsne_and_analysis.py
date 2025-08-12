# tsne_and_analysis.py
import argparse, json, os, sys, random
import numpy as np

# Try SciSpaCy first; fallback to small English
try:
    import spacy
    try:
        nlp = spacy.load("en_core_sci_sm")
    except Exception:
        nlp = spacy.load("en_core_web_sm")
except Exception as e:
    print("spaCy missing. Install with: pip install spacy && python -m spacy download en_core_web_sm", file=sys.stderr)
    sys.exit(2)

from gensim.models import Word2Vec
from sklearn.manifold import TSNE

def simple_sent_tokenize(nlp, text):
    doc = nlp(text)
    # Sentences → tokens (keep health-ish words, lemmas)
    sents = []
    for sent in doc.sents:
        toks = []
        for t in sent:
            if t.is_alpha and not t.is_stop:
                toks.append(t.lemma_.lower())
        if toks:
            sents.append(toks)
    # If sentencizer not available, fallback to whole text
    if not sents:
        toks = [t.lemma_.lower() for t in nlp(text) if t.is_alpha and not t.is_stop]
        if toks:
            sents = [toks]
    return sents

def analyze(text):
    doc = nlp(text)
    # Simple heuristics for “analysis”
    keywords = {}
    for t in doc:
        if t.is_alpha and not t.is_stop:
            k = t.lemma_.lower()
            keywords[k] = keywords.get(k, 0) + 1

    top = sorted(keywords.items(), key=lambda x: x[1], reverse=True)[:10]
    parts = [f"{k}×{c}" for k, c in top]
    summary = "Top terms: " + (", ".join(parts) if parts else "N/A")

    # Pull out some entities if available
    ents = [f"{ent.text} ({ent.label_})" for ent in doc.ents[:6]]
    if ents:
        summary += f". Entities: {', '.join(ents)}"
    return summary

def build_tsne_points(text):
    sentences = simple_sent_tokenize(nlp, text)
    if not sentences:
        return []

    w2v = Word2Vec(
        sentences=sentences, vector_size=100, window=5, min_count=1, sg=1, workers=2, epochs=20
    )

    vocab = list(w2v.wv.index_to_key)
    if len(vocab) < 2:  # need at least 2 points for t-SNE to be meaningful
        return []

    import numpy as np
    from sklearn.manifold import TSNE
    vectors = np.array([w2v.wv[w] for w in vocab])

    perplexity = max(2, min(30, len(vectors) - 1))
    tsne = TSNE(n_components=2, perplexity=perplexity, random_state=42, init="random")
    tsne_res = tsne.fit_transform(vectors)

    # --- Normalize each axis to [-1, 1] ---
    eps = 1e-9
    x = tsne_res[:, 0]
    y = tsne_res[:, 1]
    x_norm = 2 * ((x - x.min()) / (x.max() - x.min() + eps)) - 1
    y_norm = 2 * ((y - y.min()) / (y.max() - y.min() + eps)) - 1

    # sample up to 30 for readability
    import random
    idxs = list(range(len(vocab)))
    random.shuffle(idxs)
    idxs = idxs[: min(30, len(idxs))]

    points = []
    for i in idxs:
        points.append({"label": vocab[i], "x": float(x_norm[i]), "y": float(y_norm[i])})
    return points


def main():
    ap = argparse.ArgumentParser(description="t-SNE + analysis for transcript")
    ap.add_argument("--text", help="Transcript text")
    ap.add_argument("--input", help="Path to text file containing transcript")
    args = ap.parse_args()

    if not args.text and not args.input:
        print("Provide --text or --input", file=sys.stderr)
        sys.exit(1)

    if args.input:
        if not os.path.isfile(args.input):
            print(f"Input not found: {args.input}", file=sys.stderr)
            sys.exit(1)
        with open(args.input, "r", encoding="utf-8") as f:
            text = f.read()
    else:
        text = args.text

    text = (text or "").strip()
    if not text:
        print(json.dumps({"points": [], "analysis": "No text provided"}))
        return

    try:
        points = build_tsne_points(text)
        analysis = analyze(text)
        print(json.dumps({"points": points, "analysis": analysis}), flush=True)
    except Exception as e:
        print(json.dumps({"points": [], "analysis": f"TSNE/Analysis error: {e}"}), flush=True)

if __name__ == "__main__":
    main()
