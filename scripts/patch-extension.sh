#!/usr/bin/env bash
set -euo pipefail

EXT_DIR="${1:?usage: patch-extension.sh <extension-dir>}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$EXT_DIR/src"

[[ -f "$SRC/manifest.json" ]] || { echo "Missing extension manifest" >&2; exit 1; }
[[ -f "$SRC/background.js" ]] || { echo "Missing extension background.js" >&2; exit 1; }

cp "$ROOT/extension-patches/light-device-profiles.js" "$SRC/light-device-profiles.js"
cp "$ROOT/extension-patches/light-profile-page.html" "$SRC/light-profile-page.html"
cp "$ROOT/extension-patches/light-profile-page.js" "$SRC/light-profile-page.js"
cp "$ROOT/extension-patches/light-profile.css" "$SRC/light-profile.css"

python3 - "$SRC" <<'PY'
import json, pathlib, sys
src = pathlib.Path(sys.argv[1])
manifest_path = src / "manifest.json"
manifest = json.loads(manifest_path.read_text())
manifest["name"] = "Light Device Profiles"
manifest["description"] = "Local privacy and website compatibility profiles for Trình Duyệt Light."
manifest.setdefault("permissions", [])
for perm in ["storage", "declarativeNetRequestWithHostAccess"]:
    if perm not in manifest["permissions"]:
        manifest["permissions"].append(perm)
manifest.setdefault("host_permissions", ["<all_urls>"])
manifest.setdefault("action", {})["default_title"] = "Light Device Profiles"
manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")

bg_path = src / "background.js"
bg = bg_path.read_text()
if 'importScripts("light-device-profiles.js")' not in bg:
    bg = bg.replace('importScripts("common.js");', 'importScripts("common.js");\nimportScripts("light-device-profiles.js");')

block = r'''

const LIGHT_PROFILE_RULE_ID = 92001;

async function syncLightDeviceProfile() {
  try {
    const profile = await LightProfiles.getActiveProfile();
    const addRules = [];
    if (profile.userAgent || profile.language) {
      const requestHeaders = [];
      if (profile.userAgent) requestHeaders.push({ header: "user-agent", operation: "set", value: profile.userAgent });
      if (profile.language) requestHeaders.push({ header: "accept-language", operation: "set", value: profile.language });
      addRules.push({
        id: LIGHT_PROFILE_RULE_ID,
        priority: 1,
        action: { type: "modifyHeaders", requestHeaders },
        condition: { urlFilter: "|http", resourceTypes: ["main_frame", "sub_frame", "xmlhttprequest", "script", "stylesheet", "image", "font", "media", "other"] }
      });
    }
    await chrome.declarativeNetRequest.updateDynamicRules({ removeRuleIds: [LIGHT_PROFILE_RULE_ID], addRules });
    logEvent(`Light Device Profile applied: ${profile.id}`);
  } catch (e) {
    logEvent(`Light Device Profile failed: ${e.message}`);
  }
}
'''
if 'const LIGHT_PROFILE_RULE_ID = 92001;' not in bg:
    bg += block

bg = bg.replace('chrome.runtime.onInstalled.addListener(() => {', 'chrome.runtime.onInstalled.addListener(() => {\n  syncLightDeviceProfile();')
bg = bg.replace('chrome.runtime.onStartup.addListener(() => {', 'chrome.runtime.onStartup.addListener(() => {\n  syncLightDeviceProfile();')
old = 'if (changes.patchEdge || changes.patchOpera) syncMarketplacePatches();'
new = old + '\n  if (changes.lightDeviceProfile) syncLightDeviceProfile();'
if new not in bg:
    bg = bg.replace(old, new)
bg_path.write_text(bg)

popup_path = src / "popup.html"
if popup_path.exists():
    popup = popup_path.read_text()
    link = '<p><a href="light-profile-page.html" target="_blank">Light Device Profiles</a></p>'
    if 'light-profile-page.html' not in popup:
        popup = popup.replace('</body>', link + '\n</body>')
        popup_path.write_text(popup)
PY

echo "Patched Titanium extension with Light Device Profiles"
