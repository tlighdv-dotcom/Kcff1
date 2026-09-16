#!/usr/bin/env bash
set -euo pipefail

BROWSER_DIR="${1:?usage: apply-branding.sh <browser-dir>}"
PATCH_FILE="$BROWSER_DIR/patch.sh"

[[ -f "$BROWSER_DIR/build.sh" ]] || { echo "Missing upstream build.sh" >&2; exit 1; }
[[ -f "$PATCH_FILE" ]] || { echo "Missing upstream patch.sh" >&2; exit 1; }

MARKER="# LIGHT_BROWSER_BRANDING_PATCH"
if grep -qF "$MARKER" "$PATCH_FILE"; then
  echo "Branding hook already present"
  exit 0
fi

cat >> "$PATCH_FILE" <<'EOF'

# LIGHT_BROWSER_BRANDING_PATCH
# Keep code identifiers untouched; only rewrite user-facing resource text.
while IFS= read -r -d '' f; do
  sed -i \
    -e 's/Titanium Browser/Trình Duyệt Light/g' \
    -e 's/>Titanium</>Trình Duyệt Light</g' \
    -e 's/"Titanium"/"Trình Duyệt Light"/g' \
    "$f" || true
done < <(find chrome -type f \( -name '*.grd' -o -name '*.grdp' -o -name 'strings.xml' -o -name '*.xml' \) -print0)
EOF

echo "Applied Light branding hook"
