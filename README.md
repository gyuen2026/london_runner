# London Runner (Flutter)

Connects to Render API: `https://london-runner-api.onrender.com`

## 1~5 setup (what goes where)

| Step | What | Where |
|------|------|--------|
| 1 | Packages (`http`, `geolocator`, `health`, …) | `pubspec.yaml` |
| 2 | API URL | `lib/config/api_config.dart` |
| 3 | Routes recommend | `lib/screens/setup_screen.dart` → `routes_screen.dart` |
| 4 | Live GPS + HR | `lib/screens/run_screen.dart` |
| 5 | Signal report | GREEN/RED buttons in `run_screen.dart` |

**Deploy:** Flutter app runs on **phone/simulator** (`flutter run`).  
**Not** deployed to Render — only the Python API is on Render.

## Run

```bash
cd ~/Desktop/london_runner
flutter pub get
flutter run
```

## Permissions

- **iOS:** Location + HealthKit (Info.plist)
- **Android:** Location + Activity recognition (AndroidManifest)

## Git push (after changes)

```bash
git add .
git commit -m "Flutter MVP: API routes, live coaching, signal report"
git branch -M main
git push -u origin main
```
