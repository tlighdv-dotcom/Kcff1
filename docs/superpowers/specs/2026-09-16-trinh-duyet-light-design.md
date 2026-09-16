# Trình Duyệt Light — Design Spec

## Goal
Build an Android browser named **Trình Duyệt Light** from the public Titanium Browser for Android codebase, keeping Chromium-based extension support while adding privacy/testing-oriented device profile controls. The app must be buildable through GitHub Actions and produce installable Android APK artifacts.

## Source and licensing
- Upstream base: `jqssun/android-titanium-browser`.
- Keep GPLv2 license and upstream attribution/credits.
- Preserve extension support from Titanium, including Chrome Web Store installation and `chrome://extensions`/unpacked extension flows already provided upstream.
- Do not claim compatibility beyond what the upstream engine currently supports.

## Repository strategy
`tlighdv-dotcom/Kcff1` is the customization/build repository. Because the available GitHub integration cannot invoke GitHub's fork endpoint directly, the repository will use an upstream-sync build strategy:
1. GitHub Actions checks out `Kcff1`.
2. The workflow clones the Titanium Browser upstream source and its required submodules.
3. Light-specific patches/resources/scripts from `Kcff1` are copied/applied to the upstream working tree.
4. The upstream build script compiles Chromium/Titanium into APK outputs.

This keeps the user's repository small and makes upstream updates easier to pull into future builds.

## Branding
- Visible application name: **Trình Duyệt Light**.
- Replace user-facing Titanium branding where practical through build-time patches/resources.
- Keep third-party license and project-credit text where required.
- Use a Light-specific Android package/application identifier where the Chromium build setup permits it without breaking the upstream patch set.
- Initial build may reuse upstream-compatible package plumbing if changing the identifier would require broad Chromium changes; user-facing name must still be Trình Duyệt Light.

## Device Profiles
Add a privacy/testing-oriented Device Profile feature. Profiles may control browser-visible values that are reasonably exposed through browser configuration/Chromium patches:
- User-Agent string.
- User-Agent Client Hints where supported by Chromium's existing override plumbing.
- Preferred language/locale.
- Timezone override where technically supported by the engine.
- Viewport/device emulation values used for responsive testing, including width, height and device scale factor when practical.

### Profile presets
Initial presets:
- Default Android.
- Generic Android Phone.
- Desktop Windows.
- Custom.

### Profile behavior
- Default profile leaves Chromium defaults unchanged.
- Profile state is stored locally on the device.
- Profile switching should take effect for newly loaded pages; if Chromium internals require a tab reload or new tab, the UI must communicate that behavior.
- Custom values must be validated before applying.

### Safety boundary
The feature is for privacy controls and website compatibility/testing. It must not implement functionality specifically designed to bypass account security, anti-fraud systems, CAPTCHA, device bans, or identity-verification controls. No automation for rotating spoofed identities, mass-account operation, or evading enforcement is included.

## Extensions
Retain upstream extension behavior:
- Chrome Web Store access in desktop-site mode.
- `chrome://extensions` management.
- Load unpacked extensions using the Android Storage Access Framework.
- Existing Manifest V2 support inherited from Titanium where present.

No separate backend/server is required for extension management.

## Local data
All browser-specific settings introduced by Light are local-only for the initial release:
- Device profile selection.
- Custom profile values.
- Existing Chromium/Titanium bookmarks/history/extensions remain handled by the browser engine.

No Light-owned cloud account or synchronization server is introduced.

## Build and signing
### CI target
- GitHub Actions on `ubuntu-latest`.
- Primary APK target: `arm64-v8a` for modern Android devices, including Android 14.
- If upstream build naturally produces `armeabi-v7a`, it may be retained as an additional artifact, but arm64 is the required output.

### Initial signing strategy
The first build uses a CI-generated test keystore so an installable APK can be produced without asking the user to configure repository secrets first.
- The workflow generates the keystore during the build.
- The APK is signed and uploaded as a GitHub Actions artifact and/or GitHub Release asset.
- Because the generated key is not stable between builds, future builds may require uninstalling the previous test build before installation.

### Stable updates later
A follow-up can switch to a fixed user-controlled signing key stored in GitHub Actions Secrets. This is outside the first-build requirement.

## CI workflow
Create a workflow that:
1. Checks out `Kcff1`.
2. Installs required packages.
3. Clones `jqssun/android-titanium-browser` with submodules.
4. Applies Light branding/device-profile patches from this repo.
5. Generates an ephemeral Android keystore and `local.properties` compatible with Titanium's signing helpers.
6. Runs the upstream build on `ubuntu-latest`.
7. Locates the signed arm64 APK.
8. Renames it to a clear filename such as `Trinh-Duyet-Light-arm64-v8a.apk`.
9. Uploads it as a workflow artifact.
10. Optionally creates a GitHub Release for manual-dispatch builds when permissions allow.

## Error handling
The workflow should fail clearly when:
- Upstream clone/submodule checkout fails.
- A Light patch no longer applies after an upstream change.
- Chromium build fails.
- APK signing fails.
- The expected APK cannot be found.

Each failure should stop the workflow with a non-zero exit code and a descriptive step name.

## Testing and verification
Before calling the build complete:
- Verify the workflow file parses and references existing local scripts.
- Verify Light patch scripts run in a shell without syntax errors.
- Verify the upstream version/build invocation remains compatible with Titanium's documented build process.
- Run the GitHub Actions build.
- Inspect job logs for errors.
- Confirm an arm64 APK artifact is present and downloadable.
- Report the exact artifact/release that contains the APK.

Functional checks expected after installation:
- App launches with visible name **Trình Duyệt Light**.
- Normal web browsing works.
- `chrome://extensions` opens.
- Extension install/management flow remains available.
- Device Profile settings can be opened and a preset can be selected.
- Default profile preserves Chromium defaults.

## Non-goals for first build
- Cloud sync or accounts.
- Remote backend/API.
- Automated anti-detect profile rotation.
- CAPTCHA/anti-fraud bypass.
- Desktop-class full fingerprint virtualization across every Web API.
- Play Store publishing.
- Stable production signing key.
