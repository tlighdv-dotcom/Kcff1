#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$ROOT/work"

# Titanium/Vanadium applies a large patch series with `git am` while building
# Chromium. GitHub hosted runners do not have a committer identity by default,
# so configure an ephemeral CI identity before the upstream build starts.
git config --global user.name "github-actions[bot]"
git config --global user.email "github-actions[bot]@users.noreply.github.com"

rm -rf "$WORK"
mkdir -p "$WORK"

git clone --recurse-submodules https://github.com/jqssun/android-titanium-browser.git "$WORK/android-titanium-browser"
git clone https://github.com/jqssun/android-titanium-extension.git "$WORK/android-titanium-extension"

bash "$ROOT/scripts/apply-branding.sh" "$WORK/android-titanium-browser"

echo "Prepared upstream sources in $WORK"
