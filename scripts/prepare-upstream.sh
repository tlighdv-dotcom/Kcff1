#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$ROOT/work"

rm -rf "$WORK"
mkdir -p "$WORK"

git clone --recurse-submodules https://github.com/jqssun/android-titanium-browser.git "$WORK/android-titanium-browser"
git clone https://github.com/jqssun/android-titanium-extension.git "$WORK/android-titanium-extension"

bash "$ROOT/scripts/apply-branding.sh" "$WORK/android-titanium-browser"

echo "Prepared upstream sources in $WORK"
