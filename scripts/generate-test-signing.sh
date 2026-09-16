#!/usr/bin/env bash
set -euo pipefail

OUT="${1:?usage: generate-test-signing.sh <output-dir>}"
mkdir -p "$OUT"
KEYSTORE="$OUT/test.jks"
PROPS="$OUT/local.properties"
PASS="light-ci-test"

rm -f "$KEYSTORE" "$PROPS" "$OUT/local.properties.b64" "$OUT/test.jks.b64"

keytool -genkeypair \
  -alias light \
  -keyalg RSA \
  -keysize 2048 \
  -validity 3650 \
  -keystore "$KEYSTORE" \
  -storepass "$PASS" \
  -keypass "$PASS" \
  -dname "CN=Trinh Duyet Light CI, OU=Test Build, O=Light, L=Ho Chi Minh City, C=VN" \
  -noprompt

cat > "$PROPS" <<EOF
keyAlias=light
keyPassword=$PASS
storePassword=$PASS
EOF

base64 -w0 "$PROPS" > "$OUT/local.properties.b64"
base64 -w0 "$KEYSTORE" > "$OUT/test.jks.b64"

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "LOCAL_TEST_JKS=$(cat "$OUT/local.properties.b64")" >> "$GITHUB_ENV"
  echo "STORE_TEST_JKS=$(cat "$OUT/test.jks.b64")" >> "$GITHUB_ENV"
fi

echo "Generated ephemeral CI signing key in $OUT"
