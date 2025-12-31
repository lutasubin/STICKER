## Sticker App – WhatsApp Sticker Packs (Flutter)

Ứng dụng Flutter hiển thị các bộ sticker (Animal, Memes, Baby, Anime, …) và cho phép **gửi từng gói sticker sang WhatsApp** thông qua native plugin Android và `ContentProvider`.

---

### 1. Kiến trúc & các phần chính

- **Flutter UI**
  - `lib/model/sticker_pack.dart`: model `StickerPack` (id, title, subtitle, category, folderPath, itemCount, getter tạo list asset `.webp`).
  - `lib/service/sticker/sticker_service.dart`: khai báo **danh sách tất cả gói sticker** dùng trong app (mapping sang đúng thư mục `assets/sticker_maker/...` và số lượng ảnh).
  - `lib/service/sticker/whatsapp_sticker_service.dart`: bridge `MethodChannel('whatsapp_stickers')` để:
    - Kiểm tra WhatsApp đã cài hay chưa (`isWhatsAppInstalled`).
    - Build payload và gọi native method `sendToWhatsApp` kèm:
      - `identifier`, `name`, `publisher`, `trayImageFileName`.
      - Map `stickers: { 'assets://<path/to.webp>': [emoji...] }`.
  - `lib/view/home/sticker_pack_detail_screen.dart`:
    - Hiển thị grid sticker trong pack.
    - Nút **“Add to whatsapp”**:
      - Disable khi đang gửi (`_isSending`).
      - Chờ `300ms` rồi:
        - Kiểm tra WhatsApp đã cài.
        - Gọi `WhatsappStickerService.addPack`.
        - Hiển thị `SnackBar` với kết quả (`success`, `already_added`, lỗi PlatformException…).

- **Native Android (Kotlin/Java)**
  - `android/app/src/main/AndroidManifest.xml`:
    - Khai báo `MainActivity`, `FileProvider file_paths.xml`.
    - Khai báo `provider`:
      - `android:name="com.mobileai.stickerapp.StickerContentProvider"`.
      - `android:authorities="${applicationId}.stickercontentprovider"`.
      - `android:exported="true"`, `android:grantUriPermissions="true"`.
      - Quyền `android:readPermission="com.whatsapp.sticker.READ"`, `android:writePermission="com.whatsapp.sticker.WRITE"`.
      - Meta-data `com.whatsapp.sticker.CONTENT_PROVIDER`.
  - `android/app/src/main/kotlin/com/mobileai/stickerapp/MainActivity.kt`:
    - Kế thừa `FlutterActivity`.
    - Trong `configureFlutterEngine` đăng ký plugin: `flutterEngine.plugins.add(WhatsappStickersPlugin())`.
  - `WhatsappStickersPlugin.kt`:
    - Implement `FlutterPlugin`, `MethodCallHandler`, `ActivityAware`, `ActivityResultListener`.
    - Expose các method cho Dart:
      - `isWhatsAppInstalled`, `isWhatsAppConsumerAppInstalled`, `isWhatsAppSmbAppInstalled`, `isStickerPackInstalled`.
      - `sendToWhatsApp`:
        - Nhận dữ liệu từ Dart (`identifier`, `trayImageFileName`, `stickers`).
        - Dùng `ConfigFileManager.addNewPack` để cập nhật file `sticker_packs.json`.
        - Gọi `StickerPackValidator.verifyStickerPackValidity`.
        - Tạo `Intent("com.whatsapp.intent.action.ENABLE_STICKER_PACK")` với extra:
          - `sticker_pack_id`, `sticker_pack_authority`, `sticker_pack_name`.
        - `startActivityForResult` để WhatsApp xử lý việc thêm pack.
    - Trong `onActivityResult`:
      - Đọc kết quả (`add_successful`, `already_added`, `validation_error`, …) và trả lại cho Flutter qua `MethodChannel.Result`.
  - `StickerContentProvider.java`:
    - ContentProvider mà WhatsApp gọi để:
      - Lấy metadata pack (`METADATA`).
      - Lấy danh sách sticker cho một pack (`STICKERS`).
      - Lấy `AssetFileDescriptor` ảnh sticker/tray (`STICKERS_ASSET`).
    - Đọc file `sticker_packs.json` thông qua `ConfigFileManager`, parse bằng `ContentFileParser`.
  - `ConfigFileManager.java`, `ContentFileParser.java`, `StickerPack.java`, `Sticker.java`, `StickerPackLoader.java`, `StickerPackValidator.java`, `WhitelistCheck.java`, `InvalidPackException.java`:
    - Bộ mã gốc từ plugin WhatsApp, đã được chỉnh namespace sang `com.mobileai.stickerapp`.
    - Chịu trách nhiệm:
      - Tạo/cập nhật file `sticker_packs.json` trong thư mục dữ liệu app.
      - Parse JSON thành các `StickerPack` + `Sticker`.
      - Validate theo rule WhatsApp:
        - Tên pack/publisher/tray không rỗng, kí tự hợp lệ.
        - Số lượng sticker trong pack: **3–30**.
        - Kích thước mỗi sticker: `<=100KB` (trong code, check byte length).
        - Tray icon: `<=50KB`, kích thước từ `24x24` đến `512x512`.
        - Mỗi sticker phải có **ít nhất 1 emoji**, tối đa 3 emoji.

---

### 2. Cấu hình assets & mapping

- `pubspec.yaml` (section `flutter/assets`):
  - Khai báo đầy đủ thư mục:
    - `assets/images/`, `assets/svg/`, `assets/icons/`, `assets/flags/`.
    - Sticker:
      - Animal: `Kermit_the_Frog/`, `Moka_the_dog/`, `Penguin/`, `Pocky/`.
      - Anime: `Anya_Forger/`, `Demon_Slayer/`, `Zenitsu_Agatsuma/`, `Zoro_Roronoa/`.
      - Baby: `Baby_cute/`, `Children/`, `Ullzangbaby/`.
      - Memes: `Face_funny/`, `Face_meme/`, `Face_reaction/`, `Feed_funny/`, `Pepe/`, `Rage_Comics/`.
- `StickerService.getAllPacks()` chỉ sử dụng **một phần trong số đó**, bảo đảm:
  - Các pack đang active:
    - Animal: `Kermit_the_Frog` (30), `Moka_the_dog` (30), `Penguin` (24), `Pocky` (22).
    - Memes: `Face_funny` (29), `Face_meme` (30 – 1 file dư không dùng), `Face_reaction` (22), `Pepe` (30).
    - Baby: `Children` (20), `Ullzangbaby` (21).
    - Anime: `Zenitsu_Agatsuma` (26), `Zoro_Roronoa` (24).
  - Các pack tạm ẩn do **không đạt chuẩn 512x512 hoặc file quá nặng** (nhưng assets vẫn còn trong dự án):
    - `Memes/Feed_funny` (nhiều file ~400–500KB).
    - `Memes/Rage_Comics` (nhiều sticker không đúng 512x512).
    - `Anime/Anya_Forger`, `Anime/Demon_Slayer` (nhiều ảnh không 512x512).

---

### 3. Các kiểm tra & chỉnh sửa kỹ thuật đã thực hiện

- **Class & namespace Android**
  - Sửa toàn bộ import từ `dev.applicazza.flutter.plugins.whatsapp_stickers.*` sang `com.mobileai.stickerapp.*`.
  - Đảm bảo `StickerContentProvider`, `ConfigFileManager`, `StickerPackLoader`… đều nằm trong cùng package, không lỗi `ClassNotFoundException`.
  - Thêm `sourceSets["main"].java.srcDirs("src/main/java", "src/main/kotlin")` vào `android/app/build.gradle.kts` để Gradle biên dịch cả Java nằm trong `src/main/kotlin`.

- **FileProvider**
  - Thêm `android/app/src/main/res/xml/file_paths.xml`:
    - Cho phép chia sẻ file từ `cache-path` và `files-path`.
  - Khai báo trong manifest với authority `${applicationId}.fileprovider`.

- **Tích hợp plugin Flutter embedding v2**
  - Loại bỏ API `Registrar` cũ, dùng `onAttachedToEngine` + `ActivityAware`.
  - Đăng ký `ActivityResultListener` để nhận kết quả từ WhatsApp.

- **Kiểm tra & chuẩn hoá sticker**
  - Viết script Python + Pillow để:
    - Quét toàn bộ `assets/sticker_maker/**/**/*.webp`.
    - Kiểm tra kích thước ảnh, dung lượng file, số lượng image trong từng folder.
  - Kết quả:
    - Tất cả pack đang dùng (`Kermit`, `Moka`, `Penguin`, `Pocky`, `Face_funny`, `Face_meme`, `Face_reaction`, `Pepe`, `Children`, `Ullzangbaby`, `Zenitsu`, `Zoro`) **đều 512x512, <100KB, tray <50KB, số lượng ảnh khớp với `itemCount`**.
    - Các pack không đạt chuẩn (đã ẩn khỏi `StickerService`) nằm ở:
      - `Memes/Feed_funny` – nhiều file ~400–500KB.
      - `Memes/Rage_Comics` – nhiều ảnh lệch kích thước.
      - `Anime/Anya_Forger`, `Anime/Demon_Slayer` – nhiều ảnh không 512x512.

- **UI/UX nút Add to WhatsApp**
  - Thêm trạng thái `_isSending` để tránh double tap.
  - Thêm `Future.delayed(const Duration(milliseconds: 300))` trước khi gọi native để tránh gửi intent quá nhanh liên tiếp.
  - Hiển thị `SnackBar` với thông báo rõ ràng cho các trạng thái:
    - WhatsApp chưa cài.
    - Gói đã tồn tại.
    - Gửi thành công.
    - Báo lỗi từ `PlatformException`.

---

### 4. Hạn chế hiện tại & ghi chú quan trọng

- **Phụ thuộc vào WhatsApp & ROM (MIUI, Android 14)**:
  - Dù dữ liệu & ContentProvider đã chuẩn, một số máy vẫn báo:
    - `There's a problem with the sticker pack. Unable to add to WhatsApp.`
    - `PlatformException(error, Third party pack cannot be found likely because the corresponding app is restricted, sdk: 35, ...)`
  - Đây là thông báo từ chính WhatsApp, thường do:
    - Giới hạn app bên thứ ba trên Android 14 / MIUI (battery optimization, app restriction).
    - Bug hoặc giới hạn mới của WhatsApp với content provider.
  - Trên một số thiết bị, có thể chỉ thêm được một vài pack (ví dụ: `Kermit`, `Moka`, `Zenitsu`) dù các pack khác cũng đạt chuẩn.

- **Cách test/khắc phục gợi ý**
  - Tắt chế độ **battery saver / app optimization / app restriction** cho app sticker và WhatsApp.
  - Sử dụng **WhatsApp chính thức**, không dùng bản clone/dual app/mod.
  - Gỡ cả app sticker và WhatsApp, khởi động lại thiết bị, cài lại bản WhatsApp mới nhất từ Play Store, sau đó cài lại app.
  - Nếu có thể, test thêm trên:
    - Máy khác (Samsung/Pixel…).
    - Android version thấp hơn (Android 12/13).

---

### 5. Hướng dẫn build & chạy

- **Yêu cầu**
  - Flutter SDK (theo version trong `pubspec.yaml`, hiện tại: `sdk: ^3.7.2`).
  - Android SDK, JDK 17.

- **Cài dependency**
  ```bash
  flutter pub get
  ```

- **Chạy debug trên thiết bị thật / emulator**
  ```bash
  flutter run
  ```

- **Build APK release**
  ```bash
  flutter build apk --release
  # file output: build/app/outputs/flutter-apk/app-release.apk
  ```

---

### 6. Công việc đã thực hiện (tóm tắt)

- Tích hợp đầy đủ plugin WhatsApp sticker native (Kotlin/Java) vào app Flutter:
  - Sửa manifest, ContentProvider, MainActivity, plugin registration.
  - Fix nhiều lỗi biên dịch: `ClassNotFoundException`, import sai namespace, API embedding cũ.
- Viết layer Dart (`WhatsappStickerService`) và cập nhật UI chi tiết pack để gửi dữ liệu sang native đúng định dạng mà WhatsApp yêu cầu.
- Phân tích toàn bộ assets sticker:
  - Loại bỏ/ẩn các pack ảnh không đạt chuẩn (kích thước hoặc dung lượng).
  - Xác nhận lại toàn bộ pack còn lại là 512x512, <100KB, số lượng hợp lệ.
- Thêm cải tiến UX (loading state, delay nhỏ trước khi gửi intent, thông báo lỗi rõ ràng).
- Ghi lại các **giới hạn đến từ phía WhatsApp/ROM** để tham khảo khi debug sau này.
