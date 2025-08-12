# medAIcal schedulAIr (Flutter Windows Desktop)

A simple desktop app for doctors and nurses with:
- Login screen (no auth, always succeeds)
- Weekly schedule (Mon–Fri, 8:00–17:00, 30-minute intervals, break 12:00–13:00)
- Appointment details (patient info + 2 tabs)
  - Summary tab: past notes and a labeled t‑SNE-like scatter of keywords (mocked)
  - Current visit tab: giant record button + transcript text area (mocked)

## Quick Start (Windows Desktop)

1. **Enable Flutter desktop** (only once):
   ```bash
   flutter config --enable-windows-desktop
   flutter doctor
   ```

2. **Create a new Flutter project** (if you plan to integrate these sources into a newly created project):
   ```bash
   flutter create medAIcal_schedulAIr
   ```
   Then overwrite the `lib/` and `pubspec.yaml` with the ones provided here.

   **OR** simply unzip this folder and run from it (Flutter will generate the `windows/` folder on first build if missing).

3. **Install packages**:
   ```bash
   flutter pub get
   ```

4. **Run**:
   ```bash
   flutter run -d windows
   ```

5. **Build**:
   ```bash
   flutter build windows
   ```

> Note: Audio transcription and t‑SNE are mocked for demo. Replace stubs with your services later.
