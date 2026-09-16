# Trình Duyệt Light Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an installable Android arm64 APK named **Trình Duyệt Light** from Titanium Browser, retaining Chromium extension support and bundling a local-only Light Device Profiles feature for privacy and website compatibility testing.

**Architecture:** `Kcff1` remains a small customization/build wrapper. CI clones `jqssun/android-titanium-browser` and `jqssun/android-titanium-extension`, patches the extension into Light Device Profiles, builds a CRX, replaces Titanium's bundled-extension hook with the local CRX, applies conservative branding patches to Chromium string resources, creates an ephemeral Android signing key, then runs Titanium's existing Chromium build script and uploads the signed arm64 APK.

**Tech Stack:** GitHub Actions, Bash, Chromium/Titanium Browser, Chrome Extension Manifest V3, JavaScript, CRX3 packaging via the upstream extension's Node build script, Android APK signing.

**Spec:** `docs/superpowers/specs/2026-09-16-trinh-duyet-light-design.md`

## Global Constraints

- Visible application name: **Trình Duyệt Light**.
- Primary output: `arm64-v8a` APK compatible with modern Android, including Android 14.
- Keep GPLv2 license and upstream attribution.
- Preserve Titanium's Chrome Web Store, `chrome://extensions`, unpacked extension, and inherited MV2 support.
- No backend/server.
- Device profiles are local-only and intended for privacy, responsive testing, and compatibility testing.
- Do not add CAPTCHA, anti-fraud, device-ban, account-security, identity-verification bypass, automated identity rotation, or mass-account features.
- Initial APK uses a CI-generated ephemeral signing key.

---

### Task 1: Add deterministic upstream preparation and branding scripts

**Files:**
- Create: `scripts/prepare-upstream.sh`
- Create: `scripts/apply-branding.sh`
- Create: `scripts/test-scripts.sh`

**Interfaces:**
- Consumes: repository root path and network access to public GitHub upstream repositories.
- Produces: `work/android-titanium-browser/` and `work/android-titanium-extension/`; patched upstream browser tree ready for Titanium's `build.sh`.

- [ ] **Step 1: Add shell syntax verification**

`scripts/test-scripts.sh` must execute:

```bash
#!/usr/bin/env bash
set -euo pipefail
for f in scripts/*.sh; do
  bash -n "$f"
done
```

- [ ] **Step 2: Verify the test fails before scripts exist**

Run:

```bash
bash scripts/test-scripts.sh
```

Expected before implementation: failure because target scripts are not all present.

- [ ] **Step 3: Implement upstream preparation**

`prepare-upstream.sh` must use `set -euo pipefail`, remove/recreate `work/`, and clone with submodules:

```bash
git clone --recurse-submodules https://github.com/jqssun/android-titanium-browser.git work/android-titanium-browser
git clone https://github.com/jqssun/android-titanium-extension.git work/android-titanium-extension
```

It must then call `scripts/apply-branding.sh work/android-titanium-browser`.

- [ ] **Step 4: Implement conservative branding patch**

`apply-branding.sh` must accept the browser tree as `$1`, fail if `build.sh` or `patch.sh` is missing, then append a Light-specific post-patch hook to upstream `patch.sh`. The hook must only edit resource/text files and must not replace C++ identifiers. It must replace user-facing `Titanium Browser` and standalone `Titanium` strings in `*.grd`, `*.grdp`, `*.xml`, and Android `strings.xml` files under `chrome/` after Chromium sources have been synchronized. It must leave license/credit files untouched.

- [ ] **Step 5: Verify shell syntax**

Run:

```bash
bash scripts/test-scripts.sh
```

Expected: exit 0.

- [ ] **Step 6: Commit**

```bash
git add scripts/
git commit -m "build: add upstream preparation and Light branding"
```

### Task 2: Build Light Device Profiles into the bundled Titanium extension

**Files:**
- Create: `extension-patches/light-device-profiles.js`
- Create: `extension-patches/light-profile-page.js`
- Create: `extension-patches/light-profile-page.html`
- Create: `extension-patches/light-profile.css`
- Create: `scripts/patch-extension.sh`
- Create: `tests/device-profile.test.mjs`

**Interfaces:**
- Consumes: `work/android-titanium-extension/src/`.
- Produces: patched extension source and `work/android-titanium-extension/dist/titanium.crx`.
- Storage key: `lightDeviceProfile` in `chrome.storage.local`.
- Preset IDs: `default`, `android`, `windows`, `custom`.

- [ ] **Step 1: Write profile-model tests**

`tests/device-profile.test.mjs` must import the profile helpers and assert:

```js
assert.equal(PRESETS.default.userAgent, "");
assert.match(PRESETS.android.userAgent, /Android/);
assert.match(PRESETS.windows.userAgent, /Windows NT/);
assert.equal(validateProfile({ id: "custom", userAgent: "x", language: "vi-VN" }).language, "vi-VN");
assert.throws(() => validateProfile({ id: "custom", userAgent: "x", language: "bad language!" }));
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
node tests/device-profile.test.mjs
```

Expected: module-not-found or missing export failure.

- [ ] **Step 3: Implement profile model and page**

`light-device-profiles.js` must export `PRESETS`, `validateProfile`, `getActiveProfile`, and `setActiveProfile`. Presets:

```js
default: { id: "default", name: "Mặc định Android", userAgent: "", language: "" }
android: { id: "android", name: "Android chung", userAgent: "Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36", language: "vi-VN" }
windows: { id: "windows", name: "Desktop Windows", userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36", language: "vi-VN" }
```

Custom profile validation must allow UA length 1-512, locale matching `^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$`, and optional viewport width/height in 320-7680. No randomization or profile rotation is permitted.

`light-profile-page.html/js/css` must provide a simple mobile-friendly page for selecting the four profiles, editing custom UA/language/viewport, saving to local storage, and explaining that a page reload may be required.

- [ ] **Step 4: Patch extension manifest/background**

`patch-extension.sh` must copy Light files into `work/android-titanium-extension/src/`, change extension display name/action title to `Light Device Profiles`, add `webRequest`/`webRequestBlocking` only if supported by the current Titanium extension environment, otherwise use `declarativeNetRequest` dynamic rules for the `User-Agent` header, add a content script on `<all_urls>` to apply safe page-visible overrides for `navigator.userAgent`, `navigator.language`, `navigator.languages`, `navigator.platform`, and optional viewport emulation CSS metadata. It must not spoof hardware serials, IMEI, Android ID, WebGL GPU strings, canvas output, or other high-risk anti-detect surfaces.

The extension popup/options page must link to `light-profile-page.html`.

- [ ] **Step 5: Make background apply the selected UA**

On startup and `chrome.storage.onChanged`, build/update a dynamic declarativeNetRequest rule for request header `User-Agent` when the selected profile has a non-empty UA. Default profile removes the rule.

- [ ] **Step 6: Run model tests**

Run:

```bash
node tests/device-profile.test.mjs
```

Expected: PASS.

- [ ] **Step 7: Build CRX using upstream extension tooling**

Run:

```bash
bash scripts/prepare-upstream.sh
bash scripts/patch-extension.sh work/android-titanium-extension
(cd work/android-titanium-extension && bash build.sh)
test -s work/android-titanium-extension/dist/titanium.crx
```

Expected: non-empty CRX file.

- [ ] **Step 8: Commit**

```bash
git add extension-patches scripts/patch-extension.sh tests/
git commit -m "feat: add local Light device profiles"
```

### Task 3: Wire local CRX into Titanium and generate a test signing key

**Files:**
- Create: `scripts/wire-extension.sh`
- Create: `scripts/generate-test-signing.sh`

**Interfaces:**
- Consumes: browser and extension work trees from Tasks 1-2.
- Produces: browser `.gclient` configured to bundle the locally-built CRX; environment variables `LOCAL_TEST_JKS` and `STORE_TEST_JKS` compatible with Titanium's `common.sh`.

- [ ] **Step 1: Implement local extension wiring**

`wire-extension.sh <browser-dir> <extension-crx>` must copy the CRX into a stable path under the browser wrapper tree and rewrite Titanium's `.gclient` hook URL from its GitHub release URL to an absolute `file://` URI for the copied CRX. It must verify `.gclient` contains `extensions/bundle.py` before changing it and fail otherwise.

- [ ] **Step 2: Implement ephemeral signing key generation**

`generate-test-signing.sh` must call `keytool -genkeypair` with alias `light`, RSA 2048, validity 3650 days, and CI-only password `light-ci-test`. It must write a `local.properties` file with:

```properties
keyAlias=light
keyPassword=light-ci-test
storePassword=light-ci-test
```

Then it must export GitHub Actions environment values compatible with Titanium's reversed variable naming:

```bash
LOCAL_TEST_JKS=$(base64 -w0 local.properties)
STORE_TEST_JKS=$(base64 -w0 test.jks)
```

- [ ] **Step 3: Verify wiring and signing inputs**

Run:

```bash
bash scripts/wire-extension.sh work/android-titanium-browser work/android-titanium-extension/dist/titanium.crx
grep -q 'file://' work/android-titanium-browser/.gclient
bash scripts/generate-test-signing.sh .tmp-signing
base64 -d .tmp-signing/local.properties.b64 | grep -q 'keyAlias=light'
```

Expected: exit 0.

- [ ] **Step 4: Commit**

```bash
git add scripts/wire-extension.sh scripts/generate-test-signing.sh
git commit -m "build: bundle Light extension and generate CI signing key"
```

### Task 4: Add GitHub Actions APK build and artifact publication

**Files:**
- Create: `.github/workflows/build-light.yml`
- Create: `README.md`

**Interfaces:**
- Consumes: Tasks 1-3 scripts.
- Produces: GitHub Actions artifact named `Trinh-Duyet-Light-arm64-v8a` containing `Trinh-Duyet-Light-arm64-v8a.apk`.

- [ ] **Step 1: Add workflow validation conditions**

Workflow triggers:

```yaml
on:
  workflow_dispatch:
  push:
    branches:
      - feat/trinh-duyet-light
```

It must use `ubuntu-latest`, `timeout-minutes: 350`, `contents: read`, and `actions: write` only where required.

- [ ] **Step 2: Add disk-space preparation**

Before Chromium checkout/build, remove large preinstalled hosted-runner SDKs that are not needed (for example dotnet, ghc, Android preinstalled images) and print `df -h`. Do not remove system packages Titanium's build script needs.

- [ ] **Step 3: Add prepare/build steps**

The workflow must:

```bash
bash scripts/test-scripts.sh
bash scripts/prepare-upstream.sh
bash scripts/patch-extension.sh work/android-titanium-extension
(cd work/android-titanium-extension && bash build.sh)
bash scripts/wire-extension.sh work/android-titanium-browser work/android-titanium-extension/dist/titanium.crx
bash scripts/generate-test-signing.sh "$RUNNER_TEMP/light-signing"
cd work/android-titanium-browser
./build.sh
```

Signing values generated by the script must be appended to `$GITHUB_ENV` before `./build.sh`.

- [ ] **Step 4: Locate and rename APK**

Workflow must fail if no `*-arm64-v8a.apk` exists under `work/android-titanium-browser/chromium/src/out/release/`. It must copy exactly one expected arm64 APK to:

```text
artifacts/Trinh-Duyet-Light-arm64-v8a.apk
```

- [ ] **Step 5: Upload artifact**

Use `actions/upload-artifact@v4` with:

```yaml
name: Trinh-Duyet-Light-arm64-v8a
path: artifacts/Trinh-Duyet-Light-arm64-v8a.apk
if-no-files-found: error
```

- [ ] **Step 6: Document usage and licensing**

README must explain the upstream Titanium/Vanadium/Chromium relationship, GPLv2 obligations, extension installation flow, Device Profiles scope, ephemeral signing limitation, and where to download the Actions artifact.

- [ ] **Step 7: Commit**

```bash
git add .github/workflows/build-light.yml README.md
git commit -m "ci: build Trình Duyệt Light APK"
```

### Task 5: CI verification and artifact handoff

**Files:**
- Modify only if failures require a targeted fix.

**Interfaces:**
- Consumes: workflow run triggered by branch push.
- Produces: verified arm64 APK artifact or a concrete build blocker with logs.

- [ ] **Step 1: Confirm branch workflow starts**

Inspect GitHub Actions runs for the commit and confirm `build-light.yml` is queued/in progress.

- [ ] **Step 2: Inspect job steps/logs**

If a job fails, identify the first failing step from logs, make the smallest targeted correction, commit, and let the push workflow rerun.

- [ ] **Step 3: Verify artifact exists**

After success, query workflow artifacts and confirm one named `Trinh-Duyet-Light-arm64-v8a` with non-zero size.

- [ ] **Step 4: Download artifact**

Download the artifact ZIP through the GitHub connector, extract the APK into `/mnt/data/Trinh-Duyet-Light-arm64-v8a.apk`, and verify the file exists and has non-zero size.

- [ ] **Step 5: Report exact result**

Provide the user a direct sandbox link to the APK and the GitHub branch/run reference. If CI cannot complete on GitHub-hosted runner because of Chromium resource limits, report the exact failed step/log evidence and leave the repo ready for a self-hosted runner rather than claiming an APK exists.
