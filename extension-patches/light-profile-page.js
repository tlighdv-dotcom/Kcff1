"use strict";

const preset = document.getElementById("preset");
const customFields = document.getElementById("customFields");
const ua = document.getElementById("ua");
const language = document.getElementById("language");
const width = document.getElementById("width");
const height = document.getElementById("height");
const save = document.getElementById("save");
const status = document.getElementById("status");

function syncFields(profile) {
  preset.value = profile.id in LightProfiles.PRESETS ? profile.id : "custom";
  customFields.hidden = preset.value !== "custom";
  ua.value = profile.userAgent || "";
  language.value = profile.language || "";
  width.value = profile.width || "";
  height.value = profile.height || "";
}

preset.addEventListener("change", () => {
  const p = LightProfiles.PRESETS[preset.value];
  customFields.hidden = preset.value !== "custom";
  if (p && preset.value !== "custom") syncFields(p);
});

save.addEventListener("click", async () => {
  status.textContent = "";
  try {
    const p = preset.value === "custom"
      ? { id: "custom", name: "Tùy chỉnh", userAgent: ua.value, language: language.value, width: width.value, height: height.value }
      : LightProfiles.PRESETS[preset.value];
    await LightProfiles.setActiveProfile(p);
    status.textContent = "Đã lưu. Hãy tải lại tab đang mở để áp dụng đầy đủ.";
  } catch (e) {
    status.textContent = e.message;
  }
});

LightProfiles.getActiveProfile().then(syncFields).catch((e) => { status.textContent = e.message; });
