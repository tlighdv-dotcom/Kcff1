# Trình Duyệt Light

Trình Duyệt Light là bản tùy biến Android browser được build từ [Titanium Browser for Android](https://github.com/jqssun/android-titanium-browser), dựa trên Chromium/Vanadium và giữ khả năng cài, quản lý tiện ích trình duyệt mà Titanium cung cấp.

## Tính năng của bản đầu

- Tên hiển thị: **Trình Duyệt Light**.
- Chromium-based browser cho Android.
- Giữ luồng cài extension từ Chrome Web Store ở chế độ desktop site, `chrome://extensions`, load unpacked và các khả năng extension hiện có của Titanium.
- Bundled **Light Device Profiles** lưu hoàn toàn trên máy.
- Preset: Mặc định Android, Android chung, Desktop Windows, Tùy chỉnh.
- Device Profiles có thể đổi request `User-Agent` và `Accept-Language` cho mục đích riêng tư, tương thích và kiểm thử website.
- Không cần máy chủ/backend riêng.

## Giới hạn Device Profiles

Bản đầu không cố giả lập toàn bộ fingerprint thiết bị. Các giá trị nhạy cảm/anti-detect sâu như IMEI, Android ID, serial phần cứng, canvas fingerprint, WebGL GPU fingerprint hoặc cơ chế xoay danh tính tự động không được triển khai. Một số website vẫn có thể nhận ra engine/thiết bị thực thông qua các API khác của Chromium.

## Build APK

Workflow: `.github/workflows/build-light.yml`

Mỗi lần push vào branch `feat/trinh-duyet-light` hoặc chạy thủ công workflow, CI sẽ:

1. Clone Titanium Browser và Titanium Extension.
2. Áp branding Trình Duyệt Light.
3. Patch và build Light Device Profiles thành CRX.
4. Bundle CRX vào browser.
5. Tạo keystore thử nghiệm tạm thời.
6. Compile Chromium/Titanium cho Android.
7. Upload artifact `Trinh-Duyet-Light-arm64-v8a`.

APK dự kiến có tên:

`Trinh-Duyet-Light-arm64-v8a.apk`

## Chữ ký thử nghiệm

Bản CI đầu tiên dùng keystore được tạo mới trong mỗi workflow run. Vì vậy APK từ hai lần build khác nhau có thể không cập nhật đè lên nhau; có thể cần gỡ bản cũ trước khi cài bản mới. Khi cần cập nhật ổn định lâu dài, nên chuyển sang keystore cố định được lưu bằng GitHub Actions Secrets.

## License và credits

Phần wrapper/customization này tiếp tục tuân theo các nghĩa vụ license của upstream. Titanium Browser và Titanium Extension công bố theo GPL-2.0; Chromium và Vanadium có các license thành phần tương ứng. Không xóa attribution hoặc license của upstream khi phân phối bản build.

Upstream chính:

- https://github.com/jqssun/android-titanium-browser
- https://github.com/jqssun/android-titanium-extension
- https://github.com/GrapheneOS/Vanadium
- https://chromium.googlesource.com/chromium/src.git
