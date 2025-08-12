# ml_insurance_classifier.py
import os, sys, json, argparse
import psycopg2
import numpy as np
from collections import Counter, defaultdict
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MultiLabelBinarizer
from sklearn.metrics import accuracy_score

def fetch(conn):
    with conn.cursor() as cur:
        cur.execute("""
        SELECT p.id,
               p.insurance_provider,
               COALESCE(ARRAY_AGG(pk.label ORDER BY pk.id)
                        FILTER (WHERE pk.id IS NOT NULL), '{}') AS labels
        FROM patients p
        LEFT JOIN patient_keywords pk ON pk.patient_id = p.id
        GROUP BY p.id, p.insurance_provider
        ORDER BY p.id;
        """)
        rows = cur.fetchall()
    # rows: [(id, insurer, [labels...]), ...]
    return rows

def top_features_per_class(clf, vocab):
    # clf.coef_.shape = (n_classes, n_features) for multinomial/ovr
    n_classes, n_features = clf.coef_.shape
    tops = defaultdict(list)
    for c in range(n_classes):
        coefs = clf.coef_[c]
        idxs = np.argsort(np.abs(coefs))[::-1][:10]  # top-10 by magnitude
        for i in idxs:
            tops[c].append({"label": vocab[i], "weight": float(coefs[i])})
    return tops

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="localhost")
    ap.add_argument("--port", type=int, default=5432)
    ap.add_argument("--db", default="postgres")
    ap.add_argument("--user", default="postgres")
    ap.add_argument("--password", default="password")
    args = ap.parse_args()

    try:
        conn = psycopg2.connect(
            host=args.host, port=args.port, dbname=args.db,
            user=args.user, password=args.password
        )
    except Exception as e:
        print(json.dumps({"error": f"DB connection failed: {e}"}))
        sys.exit(1)

    rows = fetch(conn)
    conn.close()

    if not rows:
        print(json.dumps({"accuracy": 0.0, "classes": [], "features": {}, "note": "No data"}))
        return

    patient_ids = [r[0] for r in rows]
    insurers = [r[1] for r in rows]
    labels = [r[2] for r in rows]  # list of lists

    # Binarize bag-of-words on labels
    mlb = MultiLabelBinarizer()
    X = mlb.fit_transform(labels)  # shape: (n_patients, n_vocab)
    y_classes = sorted(list(set(insurers)))
    y_map = {c:i for i,c in enumerate(y_classes)}
    y = np.array([y_map[c] for c in insurers])

    # If very tiny dataset, avoid split
    if len(rows) >= 8 and len(set(insurers)) > 1:
        X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.3, stratify=y, random_state=42)
    else:
        X_tr, X_te, y_tr, y_te = X, X, y, y

    # Train simple LR (multinomial handles multi-class nicely)
    clf = LogisticRegression(max_iter=1000, multi_class="auto", solver="lbfgs")
    clf.fit(X_tr, y_tr)
    acc = float(accuracy_score(y_te, clf.predict(X_te)))

    tops = top_features_per_class(clf, mlb.classes_)
    # map class index to class label
    features_by_class = {
        y_classes[c]: tops[c] for c in range(len(y_classes))
    }

    out = {
        "accuracy": acc,
        "classes": y_classes,
        "features": features_by_class   # { "Aetna": [ {label, weight}, ... ], ... }
    }
    print(json.dumps(out))
    sys.exit(0)

if __name__ == "__main__":
    main()
