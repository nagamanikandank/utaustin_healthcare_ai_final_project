medAIcal schedulAIr

A Windows desktop app (Flutter) that combines clinic scheduling, audio recording → transcription (AWS Transcribe), keyword visualization (t-SNE), and lightweight analytics (logistic classifier + LLM summaries).

    Platform: Flutter (Windows desktop)

    Back end: Local Postgres (patients, notes, keyword maps)

    Python tools:

        aws-transcribe-2.py → speech-to-text (Amazon Transcribe Streaming)

        tsne_and_analysis.py → Word2Vec + t-SNE keyword map (+ brief term analysis)

        analyze_transcript_with_llm.py → OpenAI JSON summary/entities/follow-up

        ml_insurance_classifier.py → logistic regression on patient keywords (per-insurer features)

Features

    Login (demo): any username/password is accepted.

    Schedule (Home): weekly view (Mon–Fri, 8:00–17:00, 30-min slots, 12–13 break).
    Click an appointment → Appointment Details (Summary + Current Visit tabs).

    Current Visit:

        Record/Stop audio (WAV).

        On stop → spinner → run Python tools in sequence:

            Transcribe audio (AWS Transcribe) → transcript JSON

            t-SNE keyword map (Word2Vec + TSNE) → normalized 2D points

            LLM analysis → JSON { summary, entities, follow_up }

        Renders Transcript, t-SNE scatter, and AI analysis side-by-side.

    Analysis page:

        Runs ml_insurance_classifier.py over DB data.

        Shows accuracy and a bar chart of top features per insurer (LR coefficients).

Quick Start (Windows)
1) Prerequisites

    Flutter (Windows desktop enabled):
    https://docs.flutter.dev/get-started/install/windows

    flutter config --enable-windows-desktop
    flutter doctor

    PostgreSQL (local): https://www.postgresql.org/download/

    Python 3.10+ (64-bit) + pip

    AWS credentials (for Transcribe) — or skip if you won’t use ASR yet

    OpenAI API key (for LLM analysis) — or skip that step

    (Optional) FFmpeg for post-processing audio

        Install & add to PATH (e.g., C:\ffmpeg\bin)

2) Clone & install Flutter deps

flutter pub get

3) Configure assets (logo)

    SVGs in assets/brand/ (e.g., medaical_wordmark.svg, medaical_mark.svg)

    Ensure pubspec.yaml has:

    flutter:
      assets:
        - assets/brand/medaical_wordmark.svg
        - assets/brand/medaical_mark.svg
    dependencies:
      flutter_svg: ^2.0.9

4) Postgres: schema & sample data

Create the database and run:

-- Tables
CREATE TABLE IF NOT EXISTS patients (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  insurance_provider TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS patient_notes (
  id SERIAL PRIMARY KEY,
  patient_id TEXT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  note TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS patient_keywords (
  id SERIAL PRIMARY KEY,
  patient_id TEXT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  x DOUBLE PRECISION NOT NULL,
  y DOUBLE PRECISION NOT NULL
);

-- Optionally, create a patient_full view for convenience
CREATE OR REPLACE VIEW patient_full AS
SELECT
  p.id,
  p.name,
  p.insurance_provider,
  COALESCE(ARRAY(
    SELECT note FROM patient_notes pn WHERE pn.patient_id = p.id ORDER BY pn.id
  ), '{}') AS past_notes,
  COALESCE(ARRAY(
    SELECT json_build_object('label', pk.label, 'x', pk.x, 'y', pk.y)
    FROM patient_keywords pk WHERE pk.patient_id = p.id ORDER BY pk.id
  ), '{}') AS keyword_map
FROM patients p;

    Seed a few patients, notes, and keywords as you like. The app can also fall back to mock data while you’re wiring this up.

5) Python environment

Create a venv and install dependencies:

py -3 -m venv .venv
.\.venv\Scripts\activate
pip install -U pip
pip install amazon-transcribe-streaming-sdk aiofile spacy gensim scikit-learn numpy psycopg2-binary
python -m spacy download en_core_web_sm
:: (Optional) SciSpaCy model if you have it:
:: pip install scispacy && python -m spacy download en_core_sci_sm

Set credentials (PowerShell):

setx AWS_ACCESS_KEY_ID "YOUR_AWS_KEY"
setx AWS_SECRET_ACCESS_KEY "YOUR_AWS_SECRET"
setx AWS_REGION "us-east-1"

setx OPENAI_API_KEY "sk-..."

(Open a new terminal after setx so env vars are visible.)
6) Point the app at your Python scripts

In CurrentVisitTab (or your config), verify absolute paths:

static const String _pythonExe = 'python'; // or full path to python.exe in your venv
static const String _pythonScriptPath = r'C:\path\to\aws-transcribe-2.py';
static const String _tsneScriptPath   = r'C:\path\to\tsne_and_analysis.py';
static const String _analysisScriptPath = r'C:\path\to\analyze_transcript_with_llm.py';

7) Run the app

flutter run -d windows

Project Structure (key files)

lib/
  main.dart
  screens/
    login/login_page.dart
    home/home_page.dart
    analysis/analysis_page.dart
    appointment/appointment_detail_page.dart
  widgets/
    app_logo.dart
    schedule_day_view.dart
    simple_bar_chart.dart
    tsne_scatter.dart (if present)
  core/
    data/mock_data.dart
    db/db_service.dart
    models/ (Patient, Appointment, KeywordPoint, etc.)
  util/
    date_utils.dart
assets/
  brand/
    medaical_wordmark.svg
    medaical_mark.svg
python/
  aws-transcribe-2.py
  tsne_and_analysis.py
  analyze_transcript_with_llm.py
  ml_insurance_classifier.py

    Paths may differ; just ensure the Dart code points to your real script locations.

How it works (flow)

    Record → Stop (Current Visit tab)

        Saves WAV (PCM).

        (Optional) Post-process with FFmpeg then hand off the final WAV.

    Transcribe (AWS)

        aws-transcribe-2.py streams audio & returns:

    {"transcript": "..."}

Visualize (t-SNE)

    tsne_and_analysis.py returns:

    {"points":[{"label":"pain","x":0.2,"y":-0.4},...], "analysis":"Top terms: ..."}

LLM Analysis

    analyze_transcript_with_llm.py returns:

        {"summary":"...","entities":{"symptom":"..."},"follow_up":"..."}

    Analysis Page (DB-driven ML)

        ml_insurance_classifier.py connects to Postgres, trains LR, outputs accuracy and top features per insurer.

Configuration

    DB connection: in DbService (Flutter) and ml_insurance_classifier.py (Python).

    Script paths: absolute paths in CurrentVisitTab (Flutter).

    FFmpeg (optional): either add ffmpeg to PATH or call with full path (C:\ffmpeg\bin\ffmpeg.exe).

Replace the Windows app icon

    Create app_icon.ico (with 256/128/64/32 inside).

    Replace windows/runner/resources/app_icon.ico.

    Rebuild:

    flutter clean
    flutter build windows

Troubleshooting

    LateInitializationError / empty schedule: initialize lists to [] and show a loader until async loads finish.

    Process.run can’t find python: use the full path to your venv’s python.exe and set runInShell: true.

    ffmpeg not recognized: add C:\ffmpeg\bin to PATH or use absolute path in code.

    ASR errors: verify AWS creds, region, and that the WAV is PCM 16-bit mono (16kHz if you downsample).

    LLM JSON parsing fails: ensure the script uses response_format={"type":"json_object"} or strip code fences before json.loads.

    t-SNE not visible: ensure coordinates are normalized (the Python script already scales to [-1,1]) or auto-scale in the painter.

Security & Compliance

    This is a prototype. If handling PHI, ensure encryption, access controls, and retention policies that comply with your jurisdiction (e.g., HIPAA).

    Store secrets in environment variables or a secrets manager—never hardcode.

    Limit IAM permissions for AWS Transcribe to the minimum necessary.