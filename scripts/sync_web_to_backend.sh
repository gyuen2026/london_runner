#!/usr/bin/env bash
# Build Flutter web and copy to Render backend static (/app).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND="${BACKEND_ROOT:-$(cd "$ROOT/../P12606/files" 2>/dev/null && pwd || echo "")}"
FLUTTER="${FLUTTER_BIN:-/Users/mollang/Downloads/flutter/bin/flutter}"

if [[ -z "$BACKEND" || ! -d "$BACKEND/app" ]]; then
  echo "Set BACKEND_ROOT to P12606/files (e.g. ../P12606/files)"
  exit 1
fi

DEST="$BACKEND/app/static/web"
echo "→ flutter build web --base-href=/app/"
cd "$ROOT"
"$FLUTTER" build web --release --base-href=/app/

echo "→ sync to $DEST"
rm -rf "$DEST"
mkdir -p "$DEST"
cp -R build/web/* "$DEST/"

echo "Done. Deploy backend to Render — QR: https://london-runner-api.onrender.com/app/"
echo "Poster: https://london-runner-api.onrender.com/go"
