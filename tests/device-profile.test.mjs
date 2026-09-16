import assert from "node:assert/strict";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { PRESETS, validateProfile } = require("../extension-patches/light-device-profiles.js");

assert.equal(PRESETS.default.userAgent, "");
assert.match(PRESETS.android.userAgent, /Android/);
assert.match(PRESETS.windows.userAgent, /Windows NT/);
assert.equal(validateProfile({ id: "custom", userAgent: "x", language: "vi-VN" }).language, "vi-VN");
assert.throws(() => validateProfile({ id: "custom", userAgent: "x", language: "bad language!" }));
console.log("device-profile tests passed");
