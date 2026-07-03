#!/bin/bash
# One-shot: run on iPhone if already connected, else open Simulator.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER="${FLUTTER_ROOT:-$HOME/Downloads/flutter}/bin/flutter"
cd "$PROJECT_DIR"

DEVICE="$("$FLUTTER" devices 2>/dev/null | awk '/iPhone|iPad/ && !/Simulator/ {print $NF; exit}' | tr -d '()')"

if [[ -n "$DEVICE" ]]; then
  echo "Running on device $DEVICE"
  exec "$FLUTTER" run -d "$DEVICE"
fi

echo "No physical iPhone found — opening Simulator…"
open -a Simulator
sleep 3
exec "$FLUTTER" run -d "$( "$FLUTTER" devices 2>/dev/null | awk '/Simulator/ && /iPhone/ {print $NF; exit}' | tr -d '()' )"
