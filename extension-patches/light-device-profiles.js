"use strict";

(function (root, factory) {
  const api = factory();
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  root.LightProfiles = api;
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
  const PRESETS = Object.freeze({
    default: Object.freeze({ id: "default", name: "Mặc định Android", userAgent: "", language: "" }),
    android: Object.freeze({
      id: "android",
      name: "Android chung",
      userAgent: "Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36",
      language: "vi-VN"
    }),
    windows: Object.freeze({
      id: "windows",
      name: "Desktop Windows",
      userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36",
      language: "vi-VN"
    }),
    custom: Object.freeze({ id: "custom", name: "Tùy chỉnh", userAgent: "", language: "vi-VN" })
  });

  const STORAGE_KEY = "lightDeviceProfile";
  const LOCALE_RE = /^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$/;

  function validateProfile(profile) {
    if (!profile || typeof profile !== "object") throw new TypeError("Profile không hợp lệ");
    const id = String(profile.id || "custom");
    const userAgent = String(profile.userAgent || "").trim();
    const language = String(profile.language || "").trim();
    const width = profile.width === "" || profile.width == null ? null : Number(profile.width);
    const height = profile.height === "" || profile.height == null ? null : Number(profile.height);

    if (id !== "default" && userAgent.length > 512) throw new RangeError("User-Agent quá dài");
    if (id === "custom" && userAgent.length < 1) throw new RangeError("Custom User-Agent không được để trống");
    if (language && !LOCALE_RE.test(language)) throw new RangeError("Ngôn ngữ/locale không hợp lệ");
    for (const [label, value] of [["width", width], ["height", height]]) {
      if (value != null && (!Number.isInteger(value) || value < 320 || value > 7680)) {
        throw new RangeError(`${label} phải nằm trong 320-7680`);
      }
    }

    return { id, name: String(profile.name || PRESETS[id]?.name || "Tùy chỉnh"), userAgent, language, width, height };
  }

  async function getActiveProfile(storage = chrome.storage.local) {
    const data = await storage.get(STORAGE_KEY);
    return validateProfile(data[STORAGE_KEY] || PRESETS.default);
  }

  async function setActiveProfile(profile, storage = chrome.storage.local) {
    const clean = validateProfile(profile);
    await storage.set({ [STORAGE_KEY]: clean });
    return clean;
  }

  return { PRESETS, STORAGE_KEY, validateProfile, getActiveProfile, setActiveProfile };
});
