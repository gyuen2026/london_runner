# London Runner (Flutter)

Mobile and web client for **GEENGREEN London Runner** — route studio, live run navigation, QR handoff to phone, and experimental crossing-signal UI.

| | |
|---|---|
| **Live web (deployed via backend)** | [https://london-runner-api.onrender.com/app/](https://london-runner-api.onrender.com/app/) |
| **Backend + docs** | [gyuen2026/P1_2026](https://github.com/gyuen2026/P1_2026) |
| **Handoff doc** | [PROJECT_HANDOFF.md](https://github.com/gyuen2026/P1_2026/blob/main/files/docs/PROJECT_HANDOFF.md) |

Default API base: `https://london-runner-api.onrender.com` (`lib/config/api_config.dart`).

## Project layout

```
lib/
  config/           API base URL
  core/utils/       Signal countdown helpers
  features/
    maps/           Google Places search, route maps
    navigate/       Run screen, crossing tracker, AR overlays
    studio/         Route studio, mobile QR dialog
scripts/
  sync_web_to_backend.sh   Build web → copy to P1_2026/files/app/static/web/
```

## Run locally

```bash
flutter pub get
flutter run                    # iOS / Android / desktop
flutter run -d chrome          # web dev
```

Optional API override:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Permissions

- **iOS:** Location, HealthKit (`Info.plist`)
- **Android:** Location, activity recognition (`AndroidManifest.xml`)

## Deploy web to Render

Web is served from the **backend repo**, not this repo directly:

```bash
./scripts/sync_web_to_backend.sh /path/to/P12606/files
# Then commit + push P1_2026; Render redeploys static assets
```

## Signal UI disclaimer

Pedestrian phase in the app is **experimental** (bus-delay proxy, JamCam vehicle lane, or synthetic countdown). See backend handoff for honest limits before treating AR/voice alerts as ground truth.

## Git

```bash
git add .
git commit -m "Describe your change"
git push origin main
```

Do not commit secrets; use `--dart-define` or local env for keys.
