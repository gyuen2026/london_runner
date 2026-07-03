#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER="$HOME/Downloads/flutter/bin/flutter"
[[ -x "$FLUTTER" ]] || FLUTTER="$(command -v flutter)"
cd "$PROJECT_DIR"

echo "Waiting for iPhone/iPad USB…"
echo "  Unlock phone · Trust this Mac · keep cable connected"
echo "  Ctrl+C to cancel"
echo ""

poll_device() {
  "$FLUTTER" devices --machine 2>/dev/null | python3 -c "
import json, sys
try:
  for d in json.load(sys.stdin):
    if d.get('emulator'):
      continue
    plat = (d.get('targetPlatform') or d.get('platform') or '').lower()
    if plat == 'ios' and d.get('isSupported', True):
      print(d.get('id', ''))
      break
except Exception:
  pass
"
}

n=0
while true; do
  id="$(poll_device || true)"
  if [[ -n "$id" ]]; then
    name="$("$FLUTTER" devices 2>/dev/null | awk -v id="$id" '$0 ~ id {print $1; exit}')"
    echo ""
    echo "✅ Device detected: ${name:-iPhone} ($id)"
    echo "→ flutter run -d $id"
    exec "$FLUTTER" run -d "$id"
  fi
  n=$((n+1))
  (( n % 10 == 0 )) && echo "...${n}s — if Finder shows phone but this waits, open Xcode → Window → Devices"
  sleep 1
done
