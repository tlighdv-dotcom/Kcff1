#!/usr/bin/env bash
set -euo pipefail

BROWSER_DIR="${1:?usage: wire-extension.sh <browser-dir> <extension-crx>}"
CRX="${2:?usage: wire-extension.sh <browser-dir> <extension-crx>}"
GCLIENT="$BROWSER_DIR/.gclient"

[[ -f "$GCLIENT" ]] || { echo "Missing .gclient" >&2; exit 1; }
[[ -s "$CRX" ]] || { echo "Missing or empty CRX: $CRX" >&2; exit 1; }
grep -q 'extensions/bundle.py' "$GCLIENT" || { echo "Unexpected upstream .gclient: bundle hook missing" >&2; exit 1; }

mkdir -p "$BROWSER_DIR/light-assets"
cp "$CRX" "$BROWSER_DIR/light-assets/light-device-profiles.crx"

python3 - "$GCLIENT" "$BROWSER_DIR/light-assets/light-device-profiles.crx" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
crx = Path(sys.argv[2]).resolve().as_uri()
s = p.read_text()
old = 'https://github.com/jqssun/android-titanium-extension/releases/latest/download/titanium.crx'
if old not in s and 'file://' not in s:
    raise SystemExit('Upstream extension URL not found in .gclient')
s = s.replace(old, crx)
p.write_text(s)
print(f'Bundled Light CRX: {crx}')
PY
