import 'dart:ui';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class TranslationService extends Translations {
  static final GetStorage _storage = GetStorage();
  static final locale = const Locale('en', 'US');
  static final fallbackLocale = const Locale('en', 'US');

  // Danh sách ngôn ngữ hỗ trợ
  static final supportedLocales = [
    const Locale('en', 'US'),
    const Locale('vi', 'VN'),
    const Locale('ru', 'RU'),
    const Locale('de', 'DE'),
    const Locale('uk', 'UA'),
    const Locale('en', 'SG'),
    const Locale('zh', 'CN'),
    const Locale('pt', 'BR'),
    const Locale('ar', 'SA'),
    const Locale('id', 'ID'),
    const Locale('hi', 'IN'),
    const Locale('ko', 'KR'),
    const Locale('ja', 'JP'),
    const Locale('fr', 'FR'),
    const Locale('tr', 'TR'),
    const Locale('es', 'ES'),
  ];

  // Map tên ngôn ngữ -> Locale tương ứng
  static final Map<String, Locale> languageLocales = {
    "English": const Locale('en', 'US'),
    "Hindi": const Locale('hi', 'IN'),
    "Arabic": const Locale('ar', 'SA'),
    "Japanese": const Locale('ja', 'JP'),
    "Brazil": const Locale('pt', 'BR'),
    "Vietnamese": const Locale('vi', 'VN'),
    "Singapore": const Locale('en', 'SG'),
    "France": const Locale('fr', 'FR'),
    "Turkey": const Locale('tr', 'TR'),
    "Indonesia": const Locale('id', 'ID'),
    "Korea": const Locale('ko', 'KR'),
    "Russia": const Locale('ru', 'RU'),
    "Germany": const Locale('de', 'DE'),
    "Ukraine": const Locale('uk', 'UA'),
    "China": const Locale('zh', 'CN'),
    "Spain": const Locale('es', 'ES'),
  };

  // Khởi tạo GetStorage và load ngôn ngữ đã lưu
  static Future<void> init() async {
    await GetStorage.init();
  }

  // Lấy ngôn ngữ đã lưu
  static Locale getSavedLocale() {
    String? savedLanguage = _storage.read('selected_language');
    if (savedLanguage != null && languageLocales.containsKey(savedLanguage)) {
      return languageLocales[savedLanguage]!;
    }
    return locale;
  }

  // Lưu ngôn ngữ
  static void saveLanguage(String language) {
    _storage.write('selected_language', language);
  }

  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      // lang
      'language_setting': 'LANGUAGE SETTING',

      // Setting
      'setting': 'SETTING',
      'rate_app': 'Rate App',
      'share': 'Share',
      'privacy': 'Privacy Policy',
      'language': 'Language',

      // Common
      'confirm_ok': 'OK',
      'confirm_cancel': 'Cancel',
      'success_title': 'Success',
      'error_title': 'Error',
      'coming_soon_title': 'Coming soon',

      // Select image
      'select_image_title': 'Select image',
      'permission_photos_required':
          'Photo access permission is required to pick an image.',
      'grant_permission': 'Grant permission',
      'open_settings': 'Open settings',

      // Crop / create sticker
      'crop_mode_auto': 'Auto cutout',
      'crop_mode_manual': 'Manual',
      'crop_mode_square': 'Square',
      'crop_mode_circle': 'Circle',
      'crop_mode_heart': 'Heart',
      'coming_soon_ai_cutout':
          'On-device AI cutout will be implemented in the next step.',
      'coming_soon_animated_stickers':
          'Animated stickers will be implemented in the next step.',
      'error_cannot_read_image': 'Cannot read image.',
      'error_cannot_encode_webp': 'Cannot encode WebP.',
      'error_sticker_too_large':
          'Sticker is too large (@sizeKbKB). Please crop smaller or choose a simpler image.',
      'success_saved_to_pack': 'Sticker created and saved to pack "@title".',

      // Snackbars / dialogs
      'snackbar_success_title': 'Success',
      'snackbar_error_title': 'Error',
      'snackbar_warning_title': 'Warning',
      'snackbar_info_title': 'Info',
      'error_whatsapp_not_installed':
          'WhatsApp is not installed on this device.',
      'success_sent_to_whatsapp': 'Sticker pack has been sent to WhatsApp.',
      'success_sticker_updated': 'Sticker pack has been updated in WhatsApp.',
      'warning_pack_already_in_whatsapp':
          'This sticker pack already exists in WhatsApp.',

      // Edit Sticker
      'edit_sticker_title': 'Edit Sticker',
      'create_button': 'Create',

      // Text Edit
      'text_edit_title': 'Text',
      'text_color_label': 'Text Color',
      'font_label': 'Font',
      'opacity_label': 'Opacity',

      // Background Picker
      'background_title': 'Background',
      'no_sticker_preview': 'No sticker to preview',

      // My Sticker
      'sticker_maker_title': 'Sticker Maker',
      'create_sticker_title': 'Create Sticker',
      'sticker_type_regular': 'Regular',
      'sticker_type_animated': 'Animated',
      'default_pack_name': 'New Pack',
      'updating_button': 'Updating...',
      'update_to_whatsapp_button': 'Update to WhatsApp',
      'export_package_button': 'Export Package Sticker',

      // Dialogs
      'delete_package_title': 'Delete Package',
      'delete_package_message': 'Do you want to delete this sticker pack?',
      'cancel_button': 'CANCEL',
      'ok_button': 'OK',

      // Errors
      'error_generic_title': 'Error',
      'error_load_photos': 'Load photos failed',
      'error_crop_title': 'Crop Error',

      // Bottom Navigation
      'bottom_nav_home': 'Home',
      'bottom_nav_my_sticker': 'My Sticker',

      // Sticker Pack Actions
      'add_button': 'Add',
      'add_to_whatsapp_button': 'Add to WhatsApp',
      'adding_button_short': 'Adding...',
      'checking_status': 'Checking...',
      'has_been_added_status': 'Has been added',

      // Crop Screen
      'crop_title': 'Crop',
      'next_button': 'Next',
      'processing_ai': 'Processing AI...',
      'compressing_image': 'Compressing image...',
      'removing_background_ai': 'Removing background with AI...',
      'processing_image': 'Processing image...',
      'cleaning_image': 'Cleaning image...',
      'creating_sticker': 'Creating sticker...',
      'error_crop_loading': 'An error occurred while loading the crop screen.',
      'error_label': 'Error:',
      'go_back_button': 'Go Back',

      // Select Image Screen
      'select_from_library': 'Select from library',
      'load_failed_message':
          'Could not load the list of images on this device. You can select an image from the library to continue.',
      'try_reload_button': 'Try reload',
    },

    'vi_VN': {
      // lang
      'language_setting': 'CÀI ĐẶT NGÔN NGỮ',

      // Setting
      'setting': 'CÀI ĐẶT',
      'rate_app': 'Đánh Giá Ứng Dụng',
      'share': 'Chia Sẻ',
      'privacy': 'Chính Sách Bảo Mật',
      'language': 'Ngôn Ngữ',

      // Common
      'confirm_ok': 'OK',
      'confirm_cancel': 'Hủy',
      'success_title': 'Thành công',
      'error_title': 'Lỗi',
      'coming_soon_title': 'Sắp có',

      // Select image
      'select_image_title': 'Chọn ảnh',
      'permission_photos_required': 'Cần quyền truy cập ảnh để chọn hình.',
      'grant_permission': 'Cấp quyền',
      'open_settings': 'Mở cài đặt',

      // Crop / create sticker
      'crop_mode_auto': 'Cắt tự động',
      'crop_mode_manual': 'Cắt thủ công',
      'crop_mode_square': 'Hình vuông',
      'crop_mode_circle': 'Hình tròn',
      'crop_mode_heart': 'Trái tim',
      'coming_soon_ai_cutout':
          'AI cutout on-device sẽ được làm ở bước tiếp theo.',
      'coming_soon_animated_stickers':
          'Animated stickers sẽ được làm ở bước tiếp theo.',
      'error_cannot_read_image': 'Không đọc được ảnh.',
      'error_cannot_encode_webp': 'Không encode được WebP.',
      'error_sticker_too_large':
          'Sticker quá lớn (@sizeKbKB). Vui lòng crop nhỏ hơn hoặc chọn ảnh đơn giản hơn.',
      'success_saved_to_pack': 'Đã tạo sticker và lưu vào pack "@title".',

      // Snackbars / dialogs
      'snackbar_success_title': 'Thành công',
      'snackbar_error_title': 'Lỗi',
      'snackbar_warning_title': 'Cảnh báo',
      'snackbar_info_title': 'Thông báo',
      'error_whatsapp_not_installed':
          'WhatsApp chưa được cài đặt trên thiết bị.',
      'success_sent_to_whatsapp': 'Đã gửi gói sticker sang WhatsApp.',
      'success_sticker_updated': 'Đã cập nhật gói sticker trong WhatsApp.',
      'warning_pack_already_in_whatsapp':
          'Gói sticker đã tồn tại trong WhatsApp.',

      // Edit Sticker
      'edit_sticker_title': 'Chỉnh Sửa Sticker',
      'create_button': 'Tạo',

      // Text Edit
      'text_edit_title': 'Văn Bản',
      'text_color_label': 'Màu Chữ',
      'font_label': 'Phông Chữ',
      'opacity_label': 'Độ Mờ',

      // Background Picker
      'background_title': 'Nền',
      'no_sticker_preview': 'Không có sticker để xem trước',

      // My Sticker
      'sticker_maker_title': 'Tạo Sticker',
      'create_sticker_title': 'Tạo Sticker',
      'sticker_type_regular': 'Thường',
      'sticker_type_animated': 'Động',
      'default_pack_name': 'Gói Mới',
      'updating_button': 'Đang cập nhật...',
      'update_to_whatsapp_button': 'Cập Nhật lên WhatsApp',
      'export_package_button': 'Xuất Gói Sticker',

      // Dialogs
      'delete_package_title': 'Xóa Gói',
      'delete_package_message': 'Bạn có muốn xóa gói sticker này không?',
      'cancel_button': 'HỦY',
      'ok_button': 'OK',

      // Errors
      'error_generic_title': 'Lỗi',
      'error_load_photos': 'Tải ảnh thất bại',
      'error_crop_title': 'Lỗi Cắt Ảnh',

      // Bottom Navigation
      'bottom_nav_home': 'Trang Chủ',
      'bottom_nav_my_sticker': 'Sticker Của Tôi',

      // Sticker Pack Actions
      'add_button': 'Thêm',
      'add_to_whatsapp_button': 'Thêm vào WhatsApp',
      'adding_button_short': 'Đang thêm...',
      'checking_status': 'Đang kiểm tra...',
      'has_been_added_status': 'Đã được thêm',

      // Crop Screen
      'crop_title': 'Cắt Ảnh',
      'next_button': 'Tiếp',
      'processing_ai': 'Đang xử lý AI...',
      'compressing_image': 'Đang nén ảnh...',
      'removing_background_ai': 'Đang xóa nền bằng AI...',
      'processing_image': 'Đang xử lý ảnh...',
      'cleaning_image': 'Đang làm sạch ảnh...',
      'creating_sticker': 'Đang tạo sticker...',
      'error_crop_loading': 'Đã xảy ra lỗi khi tải màn hình cắt ảnh.',
      'error_label': 'Lỗi:',
      'go_back_button': 'Quay Lại',

      // Select Image Screen
      'select_from_library': 'Chọn ảnh từ thư viện',
      'load_failed_message':
          'Không load được danh sách ảnh trên thiết bị này. Bạn có thể chọn ảnh từ thư viện để tiếp tục.',
      'try_reload_button': 'Thử tải lại',
    },

    'ru_RU': {
      // lang
      'language_setting': 'НАСТРОЙКА ЯЗЫКА',

      // Setting
      'setting': 'НАСТРОЙКИ',
      'rate_app': 'Оценить Приложение',
      'share': 'Поделиться',
      'privacy': 'Политика Конфиденциальности',
      'language': 'Язык',

      // Common
      'confirm_ok': 'ОК',
      'confirm_cancel': 'Отмена',
      'success_title': 'Успешно',
      'error_title': 'Ошибка',
      'coming_soon_title': 'Скоро',

      // Select image
      'select_image_title': 'Выбрать изображение',
      'permission_photos_required':
          'Требуется разрешение на доступ к фотографиям.',
      'grant_permission': 'Предоставить разрешение',
      'open_settings': 'Открыть настройки',

      // Crop / create sticker
      'crop_mode_auto': 'Автоматическая обрезка',
      'crop_mode_manual': 'Вручную',
      'crop_mode_square': 'Квадрат',
      'crop_mode_circle': 'Круг',
      'crop_mode_heart': 'Сердце',
      'coming_soon_ai_cutout':
          'ИИ-обрезка на устройстве будет реализована на следующем этапе.',
      'coming_soon_animated_stickers':
          'Анимированные стикеры будут реализованы на следующем этапе.',
      'error_cannot_read_image': 'Не удалось прочитать изображение.',
      'error_cannot_encode_webp': 'Не удалось закодировать WebP.',
      'error_sticker_too_large':
          'Стикер слишком большой (@sizeKbКБ). Пожалуйста, обрежьте меньше или выберите более простое изображение.',
      'success_saved_to_pack': 'Стикер создан и сохранен в пакет "@title".',

      // Snackbars / dialogs
      'snackbar_success_title': 'Успешно',
      'snackbar_error_title': 'Ошибка',
      'snackbar_warning_title': 'Предупреждение',
      'snackbar_info_title': 'Информация',
      'error_whatsapp_not_installed':
          'WhatsApp не установлен на этом устройстве.',
      'success_sent_to_whatsapp': 'Пакет стикеров отправлен в WhatsApp.',
      'success_sticker_updated': 'Пакет стикеров обновлен в WhatsApp.',
      'warning_pack_already_in_whatsapp':
          'Этот пакет стикеров уже существует в WhatsApp.',

      // Edit Sticker
      'edit_sticker_title': 'Редактировать стикер',
      'create_button': 'Создать',

      // Text Edit
      'text_edit_title': 'Текст',
      'text_color_label': 'Цвет текста',
      'font_label': 'Шрифт',
      'opacity_label': 'Прозрачность',

      // Background Picker
      'background_title': 'Фон',
      'no_sticker_preview': 'Нет стикера для предпросмотра',

      // My Sticker
      'sticker_maker_title': 'Создание стикеров',
      'create_sticker_title': 'Создать стикер',
      'sticker_type_regular': 'Обычный',
      'sticker_type_animated': 'Анимированный',
      'default_pack_name': 'Новый пакет',
      'updating_button': 'Обновление...',
      'update_to_whatsapp_button': 'Обновить в WhatsApp',
      'export_package_button': 'Экспортировать пакет стикеров',

      // Dialogs
      'delete_package_title': 'Удалить пакет',
      'delete_package_message': 'Вы хотите удалить этот пакет стикеров?',
      'cancel_button': 'ОТМЕНА',
      'ok_button': 'ОК',

      // Errors
      'error_generic_title': 'Ошибка',
      'error_load_photos': 'Не удалось загрузить фотографии',
      'error_crop_title': 'Ошибка обрезки',

      // Bottom Navigation
      'bottom_nav_home': 'Главная',
      'bottom_nav_my_sticker': 'Мои стикеры',

      // Sticker Pack Actions
      'add_button': 'Добавить',
      'add_to_whatsapp_button': 'Добавить в WhatsApp',
      'adding_button_short': 'Добавление...',
      'checking_status': 'Проверка...',
      'has_been_added_status': 'Уже добавлено',

      // Crop Screen
      'crop_title': 'Обрезка',
      'next_button': 'Далее',
      'processing_ai': 'Обработка AI...',
      'compressing_image': 'Сжатие изображения...',
      'removing_background_ai': 'Удаление фона с помощью AI...',
      'processing_image': 'Обработка изображения...',
      'cleaning_image': 'Очистка изображения...',
      'creating_sticker': 'Создание стикера...',
      'error_crop_loading': 'Произошла ошибка при загрузке экрана обрезки.',
      'error_label': 'Ошибка:',
      'go_back_button': 'Назад',
      'select_from_library': 'Выбрать из библиотеки',
      'load_failed_message':
          'Не удалось загрузить список изображений на этом устройстве. Вы можете выбрать изображение из библиотеки, чтобы продолжить.',
      'try_reload_button': 'Попробовать перезагрузить',
    },

    'de_DE': {
      // lang
      'language_setting': 'SPRACHEINSTELLUNGEN',

      // Setting
      'setting': 'EINSTELLUNGEN',
      'rate_app': 'App Bewerten',
      'share': 'Teilen',
      'privacy': 'Datenschutzrichtlinie',
      'language': 'Sprache',

      // Common
      'confirm_ok': 'OK',
      'confirm_cancel': 'Abbrechen',
      'success_title': 'Erfolg',
      'error_title': 'Fehler',
      'coming_soon_title': 'Demnächst',

      // Select image
      'select_image_title': 'Bild auswählen',
      'permission_photos_required':
          'Fotoberechtigung ist erforderlich, um ein Bild auszuwählen.',
      'grant_permission': 'Berechtigung erteilen',
      'open_settings': 'Einstellungen öffnen',

      // Crop / create sticker
      'crop_mode_auto': 'Automatischer Zuschnitt',
      'crop_mode_manual': 'Manuell',
      'crop_mode_square': 'Quadrat',
      'crop_mode_circle': 'Kreis',
      'crop_mode_heart': 'Herz',
      'coming_soon_ai_cutout':
          'KI-Ausschnitt auf dem Gerät wird im nächsten Schritt implementiert.',
      'coming_soon_animated_stickers':
          'Animierte Sticker werden im nächsten Schritt implementiert.',
      'error_cannot_read_image': 'Bild kann nicht gelesen werden.',
      'error_cannot_encode_webp': 'WebP kann nicht kodiert werden.',
      'error_sticker_too_large':
          'Sticker ist zu groß (@sizeKbKB). Bitte kleiner zuschneiden oder ein einfacheres Bild wählen.',
      'success_saved_to_pack':
          'Sticker erstellt und in Paket "@title" gespeichert.',

      // Snackbars / dialogs
      'snackbar_success_title': 'Erfolg',
      'snackbar_error_title': 'Fehler',
      'snackbar_warning_title': 'Warnung',
      'snackbar_info_title': 'Info',
      'error_whatsapp_not_installed':
          'WhatsApp ist auf diesem Gerät nicht installiert.',
      'success_sent_to_whatsapp': 'Sticker-Paket wurde an WhatsApp gesendet.',
      'success_sticker_updated':
          'Sticker-Paket wurde in WhatsApp aktualisiert.',
      'warning_pack_already_in_whatsapp':
          'Dieses Sticker-Paket existiert bereits in WhatsApp.',

      // Edit Sticker
      'edit_sticker_title': 'Sticker bearbeiten',
      'create_button': 'Erstellen',

      // Text Edit
      'text_edit_title': 'Text',
      'text_color_label': 'Textfarbe',
      'font_label': 'Schriftart',
      'opacity_label': 'Deckkraft',

      // Background Picker
      'background_title': 'Hintergrund',
      'no_sticker_preview': 'Kein Sticker zur Vorschau',

      // My Sticker
      'sticker_maker_title': 'Sticker-Ersteller',
      'create_sticker_title': 'Sticker erstellen',
      'sticker_type_regular': 'Normal',
      'sticker_type_animated': 'Animiert',
      'default_pack_name': 'Neues Paket',
      'updating_button': 'Wird aktualisiert...',
      'update_to_whatsapp_button': 'In WhatsApp aktualisieren',
      'export_package_button': 'Sticker-Paket exportieren',

      // Dialogs
      'delete_package_title': 'Paket löschen',
      'delete_package_message': 'Möchten Sie dieses Sticker-Paket löschen?',
      'cancel_button': 'ABBRECHEN',
      'ok_button': 'OK',

      // Errors
      'error_generic_title': 'Fehler',
      'error_load_photos': 'Fotos konnten nicht geladen werden',
      'error_crop_title': 'Zuschneidefehler',

      // Bottom Navigation
      'bottom_nav_home': 'Startseite',
      'bottom_nav_my_sticker': 'Meine Sticker',

      // Sticker Pack Actions
      'add_button': 'Hinzufügen',
      'add_to_whatsapp_button': 'Zu WhatsApp hinzufügen',
      'adding_button_short': 'Wird hinzugefügt...',
      'checking_status': 'Wird überprüft...',
      'has_been_added_status': 'Wurde hinzugefügt',

      // Crop Screen
      'crop_title': 'Zuschneiden',
      'next_button': 'Weiter',
      'processing_ai': 'KI-Verarbeitung...',
      'compressing_image': 'Bild wird komprimiert...',
      'removing_background_ai': 'Hintergrund wird mit KI entfernt...',
      'processing_image': 'Bild wird verarbeitet...',
      'cleaning_image': 'Bild wird bereinigt...',
      'creating_sticker': 'Sticker wird erstellt...',
      'error_crop_loading':
          'Beim Laden des Zuschneidebildschirms ist ein Fehler aufgetreten.',
      'error_label': 'Fehler:',
      'go_back_button': 'Zurück',
      'select_from_library': 'Aus Bibliothek auswählen',
      'load_failed_message':
          'Die Bildliste auf diesem Gerät konnte nicht geladen werden. Sie können ein Bild aus der Bibliothek auswählen, um fortzufahren.',
      'try_reload_button': 'Erneut versuchen',
    },

    'uk_UA': {
      // lang
      'language_setting': 'НАЛАШТУВАННЯ МОВИ',

      // Setting
      'setting': 'НАЛАШТУВАННЯ',
      'rate_app': 'Оцінити Додаток',
      'share': 'Поділитися',
      'privacy': 'Політика Конфіденційності',
      'language': 'Мова',

      // Common
      'confirm_ok': 'OK',
      'confirm_cancel': 'Скасувати',
      'success_title': 'Успішно',
      'error_title': 'Помилка',
      'coming_soon_title': 'Незабаром',

      // Select image
      'select_image_title': 'Вибрати зображення',
      'permission_photos_required': 'Потрібен дозвіл на доступ до фотографій.',
      'grant_permission': 'Надати дозвіл',
      'open_settings': 'Відкрити налаштування',

      // Crop / create sticker
      'crop_mode_auto': 'Автоматичне обрізання',
      'crop_mode_manual': 'Вручну',
      'crop_mode_square': 'Квадрат',
      'crop_mode_circle': 'Коло',
      'crop_mode_heart': 'Серце',
      'coming_soon_ai_cutout':
          'ШІ-обрізка на пристрої буде реалізована на наступному кроці.',
      'coming_soon_animated_stickers':
          'Анімовані стікери будуть реалізовані на наступному кроці.',
      'error_cannot_read_image': 'Не вдалося прочитати зображення.',
      'error_cannot_encode_webp': 'Не вдалося закодувати WebP.',
      'error_sticker_too_large':
          'Стікер занадто великий (@sizeKbКБ). Будь ласка, обріжте менше або виберіть простіше зображення.',
      'success_saved_to_pack': 'Стікер створено і збережено в пакет "@title".',

      // Snackbars / dialogs
      'snackbar_success_title': 'Успішно',
      'snackbar_error_title': 'Помилка',
      'snackbar_warning_title': 'Попередження',
      'snackbar_info_title': 'Інформація',
      'error_whatsapp_not_installed':
          'WhatsApp не встановлено на цьому пристрої.',
      'success_sent_to_whatsapp': 'Пакет стікерів надіслано в WhatsApp.',
      'success_sticker_updated': 'Пакет стікерів оновлено в WhatsApp.',
      'warning_pack_already_in_whatsapp':
          'Цей пакет стікерів вже існує в WhatsApp.',

      // Edit Sticker
      'edit_sticker_title': 'Редагувати стікер',
      'create_button': 'Створити',

      // Text Edit
      'text_edit_title': 'Текст',
      'text_color_label': 'Колір тексту',
      'font_label': 'Шрифт',
      'opacity_label': 'Прозорість',

      // Background Picker
      'background_title': 'Фон',
      'no_sticker_preview': 'Немає стікера для попереднього перегляду',

      // My Sticker
      'sticker_maker_title': 'Створення стікерів',
      'create_sticker_title': 'Створити стікер',
      'sticker_type_regular': 'Звичайний',
      'sticker_type_animated': 'Анімований',
      'default_pack_name': 'Новий пакет',
      'updating_button': 'Оновлення...',
      'update_to_whatsapp_button': 'Оновити в WhatsApp',
      'export_package_button': 'Експортувати пакет стікерів',

      // Dialogs
      'delete_package_title': 'Видалити пакет',
      'delete_package_message': 'Ви хочете видалити цей пакет стікерів?',
      'cancel_button': 'СКАСУВАТИ',
      'ok_button': 'ОК',

      // Errors
      'error_generic_title': 'Помилка',
      'error_load_photos': 'Не вдалося завантажити фотографії',
      'error_crop_title': 'Помилка обрізання',

      // Bottom Navigation
      'bottom_nav_home': 'Головна',
      'bottom_nav_my_sticker': 'Мої стікери',

      // Sticker Pack Actions
      'add_button': 'Додати',
      'add_to_whatsapp_button': 'Додати в WhatsApp',
      'adding_button_short': 'Додавання...',
      'checking_status': 'Перевірка...',
      'has_been_added_status': 'Вже додано',

      // Crop Screen
      'crop_title': 'Обрізання',
      'next_button': 'Далі',
      'processing_ai': 'Обробка AI...',
      'compressing_image': 'Стиснення зображення...',
      'removing_background_ai': 'Видалення фону за допомогою AI...',
      'processing_image': 'Обробка зображення...',
      'cleaning_image': 'Очищення зображення...',
      'creating_sticker': 'Створення стікера...',
      'error_crop_loading':
          'Сталася помилка при завантаженні екрана обрізання.',
      'error_label': 'Помилка:',
      'go_back_button': 'Назад',
      'select_from_library': 'Вибрати з бібліотеки',
      'load_failed_message':
          'Не вдалося завантажити список зображень на цьому пристрої. Ви можете вибрати зображення з бібліотеки, щоб продовжити.',
      'try_reload_button': 'Спробувати перезавантажити',
    },

    'en_SG': {
      // lang
      'language_setting': 'LANGUAGE SETTING',

      // Setting
      'setting': 'Setting',
      'rate_app': 'Rate App',
      'share': 'Share',
      'privacy': 'Privacy Policy',
      'language': 'Language',

      // Common
      'confirm_ok': 'OK',
      'confirm_cancel': 'Cancel',
      'success_title': 'Success',
      'error_title': 'Error',
      'coming_soon_title': 'Coming soon',

      // Select image
      'select_image_title': 'Select image',
      'permission_photos_required':
          'Photo access permission is required to pick an image.',
      'grant_permission': 'Grant permission',
      'open_settings': 'Open settings',

      // Crop / create sticker
      'crop_mode_auto': 'Auto cutout',
      'crop_mode_manual': 'Manual',
      'crop_mode_square': 'Square',
      'crop_mode_circle': 'Circle',
      'crop_mode_heart': 'Heart',
      'coming_soon_ai_cutout':
          'On-device AI cutout will be implemented in the next step.',
      'coming_soon_animated_stickers':
          'Animated stickers will be implemented in the next step.',
      'error_cannot_read_image': 'Cannot read image.',
      'error_cannot_encode_webp': 'Cannot encode WebP.',
      'error_sticker_too_large':
          'Sticker is too large (@sizeKbKB). Please crop smaller or choose a simpler image.',
      'success_saved_to_pack': 'Sticker created and saved to pack "@title".',

      // Snackbars / dialogs
      'snackbar_success_title': 'Success',
      'snackbar_error_title': 'Error',
      'snackbar_warning_title': 'Warning',
      'snackbar_info_title': 'Info',
      'error_whatsapp_not_installed':
          'WhatsApp is not installed on this device.',
      'success_sent_to_whatsapp': 'Sticker pack has been sent to WhatsApp.',
      'success_sticker_updated': 'Sticker pack has been updated in WhatsApp.',
      'warning_pack_already_in_whatsapp':
          'This sticker pack already exists in WhatsApp.',

      // Edit Sticker
      'edit_sticker_title': 'Edit Sticker',
      'create_button': 'Create',

      // Text Edit
      'text_edit_title': 'Text',
      'text_color_label': 'Text Color',
      'font_label': 'Font',
      'opacity_label': 'Opacity',

      // Background Picker
      'background_title': 'Background',
      'no_sticker_preview': 'No sticker to preview',

      // My Sticker
      'sticker_maker_title': 'Sticker Maker',
      'create_sticker_title': 'Create Sticker',
      'sticker_type_regular': 'Regular',
      'sticker_type_animated': 'Animated',
      'default_pack_name': 'New Pack',
      'updating_button': 'Updating...',
      'update_to_whatsapp_button': 'Update to WhatsApp',
      'export_package_button': 'Export Package Sticker',

      // Dialogs
      'delete_package_title': 'Delete Package',
      'delete_package_message': 'Do you want to delete this sticker pack?',
      'cancel_button': 'CANCEL',
      'ok_button': 'OK',

      // Errors
      'error_generic_title': 'Error',
      'error_load_photos': 'Load photos failed',
      'error_crop_title': 'Crop Error',

      // Bottom Navigation
      'bottom_nav_home': 'Home',
      'bottom_nav_my_sticker': 'My Sticker',

      // Sticker Pack Actions
      'add_button': 'Add',
      'add_to_whatsapp_button': 'Add to WhatsApp',
      'adding_button_short': 'Adding...',
      'checking_status': 'Checking...',
      'has_been_added_status': 'Has been added',

      // Crop Screen
      'crop_title': 'Crop',
      'next_button': 'Next',
      'processing_ai': 'Processing AI...',
      'compressing_image': 'Compressing image...',
      'removing_background_ai': 'Removing background with AI...',
      'processing_image': 'Processing image...',
      'cleaning_image': 'Cleaning image...',
      'creating_sticker': 'Creating sticker...',
      'error_crop_loading': 'An error occurred while loading the crop screen.',
      'error_label': 'Error:',
      'go_back_button': 'Go Back',
      'select_from_library': 'Select from library',
      'load_failed_message':
          'Could not load the list of images on this device. You can select an image from the library to continue.',
      'try_reload_button': 'Try reload',
    },

    'zh_CN': {
      // lang
      'language_setting': '语言设置',

      // Setting
      'setting': '设置',
      'rate_app': '评价应用',
      'share': '分享',
      'privacy': '隐私政策',
      'language': '语言',

      // Common
      'confirm_ok': '确定',
      'confirm_cancel': '取消',
      'success_title': '成功',
      'error_title': '错误',
      'coming_soon_title': '即将推出',

      // Select image
      'select_image_title': '选择图片',
      'permission_photos_required': '需要照片访问权限才能选择图片。',
      'grant_permission': '授予权限',
      'open_settings': '打开设置',

      // Crop / create sticker
      'crop_mode_auto': '自动裁剪',
      'crop_mode_manual': '手动',
      'crop_mode_square': '正方形',
      'crop_mode_circle': '圆形',
      'crop_mode_heart': '心形',
      'coming_soon_ai_cutout': '设备端 AI 裁剪将在下一步实现。',
      'coming_soon_animated_stickers': '动态贴纸将在下一步实现。',
      'error_cannot_read_image': '无法读取图片。',
      'error_cannot_encode_webp': '无法编码 WebP。',
      'error_sticker_too_large': '贴纸太大（@sizeKbKB）。请裁剪小一点或选择更简单的图片。',
      'success_saved_to_pack': '已创建贴纸并保存到贴纸包"@title"。',

      // Snackbars / dialogs
      'snackbar_success_title': '成功',
      'snackbar_error_title': '错误',
      'snackbar_warning_title': '警告',
      'snackbar_info_title': '信息',
      'error_whatsapp_not_installed': '此设备未安装 WhatsApp。',
      'success_sent_to_whatsapp': '贴纸包已发送到 WhatsApp。',
      'success_sticker_updated': '贴纸包已在 WhatsApp 中更新。',
      'warning_pack_already_in_whatsapp': '此贴纸包已存在于 WhatsApp 中。',

      // Edit Sticker
      'edit_sticker_title': '编辑贴纸',
      'create_button': '创建',

      // Text Edit
      'text_edit_title': '文本',
      'text_color_label': '文本颜色',
      'font_label': '字体',
      'opacity_label': '不透明度',

      // Background Picker
      'background_title': '背景',
      'no_sticker_preview': '没有贴纸可预览',

      // My Sticker
      'sticker_maker_title': '贴纸制作',
      'create_sticker_title': '创建贴纸',
      'sticker_type_regular': '普通',
      'sticker_type_animated': '动态',
      'default_pack_name': '新包',
      'updating_button': '更新中...',
      'update_to_whatsapp_button': '更新到 WhatsApp',
      'export_package_button': '导出贴纸包',

      // Dialogs
      'delete_package_title': '删除包',
      'delete_package_message': '您想删除这个贴纸包吗？',
      'cancel_button': '取消',
      'ok_button': '确定',

      // Errors
      'error_generic_title': '错误',
      'error_load_photos': '加载照片失败',
      'error_crop_title': '裁剪错误',

      // Bottom Navigation
      'bottom_nav_home': '首页',
      'bottom_nav_my_sticker': '我的贴纸',

      // Sticker Pack Actions
      'add_button': '添加',
      'add_to_whatsapp_button': '添加到 WhatsApp',
      'adding_button_short': '添加中...',
      'checking_status': '检查中...',
      'has_been_added_status': '已添加',

      // Crop Screen
      'crop_title': '裁剪',
      'next_button': '下一步',
      'processing_ai': 'AI处理中...',
      'compressing_image': '压缩图片中...',
      'removing_background_ai': '使用AI移除背景中...',
      'processing_image': '处理图片中...',
      'cleaning_image': '清理图片中...',
      'creating_sticker': '创建贴纸中...',
      'error_crop_loading': '加载裁剪屏幕时发生错误。',
      'error_label': '错误：',
      'go_back_button': '返回',
      'select_from_library': '从图库选择',
      'load_failed_message': '无法加载此设备上的图片列表。您可以从图库选择图片以继续。',
      'try_reload_button': '尝试重新加载',
    },

    'pt_BR': {
      // lang
      'language_setting': 'CONFIGURAÇÃO DE IDIOMA',

      // Setting
      'setting': 'CONFIGURAÇÕES',
      'rate_app': 'Avaliar App',
      'share': 'Compartilhar',
      'privacy': 'Política de Privacidade',
      'language': 'Idioma',

      // Common
      'confirm_ok': 'OK',
      'confirm_cancel': 'Cancelar',
      'success_title': 'Sucesso',
      'error_title': 'Erro',
      'coming_soon_title': 'Em breve',

      // Select image
      'select_image_title': 'Selecionar imagem',
      'permission_photos_required':
          'É necessária permissão de acesso às fotos para escolher uma imagem.',
      'grant_permission': 'Conceder permissão',
      'open_settings': 'Abrir configurações',

      // Crop / create sticker
      'crop_mode_auto': 'Recorte automático',
      'crop_mode_manual': 'Manual',
      'crop_mode_square': 'Quadrado',
      'crop_mode_circle': 'Círculo',
      'crop_mode_heart': 'Coração',
      'coming_soon_ai_cutout':
          'O recorte de IA no dispositivo será implementado na próxima etapa.',
      'coming_soon_animated_stickers':
          'Stickers animados serão implementados na próxima etapa.',
      'error_cannot_read_image': 'Não foi possível ler a imagem.',
      'error_cannot_encode_webp': 'Não foi possível codificar WebP.',
      'error_sticker_too_large':
          'O sticker é muito grande (@sizeKbKB). Por favor, recorte menor ou escolha uma imagem mais simples.',
      'success_saved_to_pack': 'Sticker criado e salvo no pacote "@title".',

      // Snackbars / dialogs
      'snackbar_success_title': 'Sucesso',
      'snackbar_error_title': 'Erro',
      'snackbar_warning_title': 'Aviso',
      'snackbar_info_title': 'Informação',
      'error_whatsapp_not_installed':
          'O WhatsApp não está instalado neste dispositivo.',
      'success_sent_to_whatsapp':
          'Pacote de stickers foi enviado para o WhatsApp.',
      'success_sticker_updated':
          'Pacote de stickers foi atualizado no WhatsApp.',
      'warning_pack_already_in_whatsapp':
          'Este pacote de stickers já existe no WhatsApp.',

      // Edit Sticker
      'edit_sticker_title': 'Editar Sticker',
      'create_button': 'Criar',

      // Text Edit
      'text_edit_title': 'Texto',
      'text_color_label': 'Cor do Texto',
      'font_label': 'Fonte',
      'opacity_label': 'Opacidade',

      // Background Picker
      'background_title': 'Fundo',
      'no_sticker_preview': 'Nenhum sticker para visualizar',

      // My Sticker
      'sticker_maker_title': 'Criador de Stickers',
      'create_sticker_title': 'Criar Sticker',
      'sticker_type_regular': 'Regular',
      'sticker_type_animated': 'Animado',
      'default_pack_name': 'Novo Pacote',
      'updating_button': 'Atualizando...',
      'update_to_whatsapp_button': 'Atualizar no WhatsApp',
      'export_package_button': 'Exportar Pacote de Stickers',

      // Dialogs
      'delete_package_title': 'Excluir Pacote',
      'delete_package_message': 'Você deseja excluir este pacote de stickers?',
      'cancel_button': 'CANCELAR',
      'ok_button': 'OK',

      // Errors
      'error_generic_title': 'Erro',
      'error_load_photos': 'Falha ao carregar fotos',
      'error_crop_title': 'Erro ao Recortar',

      // Bottom Navigation
      'bottom_nav_home': 'Início',
      'bottom_nav_my_sticker': 'Meus Stickers',

      // Sticker Pack Actions
      'add_button': 'Adicionar',
      'add_to_whatsapp_button': 'Adicionar ao WhatsApp',
      'adding_button_short': 'Adicionando...',
      'checking_status': 'Verificando...',
      'has_been_added_status': 'Já foi adicionado',

      // Crop Screen
      'crop_title': 'Recortar',
      'next_button': 'Próximo',
      'processing_ai': 'Processando AI...',
      'compressing_image': 'Comprimindo imagem...',
      'removing_background_ai': 'Removendo fundo com AI...',
      'processing_image': 'Processando imagem...',
      'cleaning_image': 'Limpando imagem...',
      'creating_sticker': 'Criando sticker...',
      'error_crop_loading': 'Ocorreu um erro ao carregar a tela de recorte.',
      'error_label': 'Erro:',
      'go_back_button': 'Voltar',
      'select_from_library': 'Selecionar da biblioteca',
      'load_failed_message':
          'Não foi possível carregar a lista de imagens neste dispositivo. Você pode selecionar uma imagem da biblioteca para continuar.',
      'try_reload_button': 'Tentar recarregar',
    },

    'ar_SA': {
      // lang
      'language_setting': 'إعدادات اللغة',

      // Setting
      'setting': 'الإعدادات',
      'rate_app': 'تقييم التطبيق',
      'share': 'مشاركة',
      'privacy': 'سياسة الخصوصية',
      'language': 'اللغة',

      // Common
      'confirm_ok': 'موافق',
      'confirm_cancel': 'إلغاء',
      'success_title': 'نجح',
      'error_title': 'خطأ',
      'coming_soon_title': 'قريباً',

      // Select image
      'select_image_title': 'اختر صورة',
      'permission_photos_required': 'مطلوب إذن الوصول إلى الصور لاختيار صورة.',
      'grant_permission': 'منح الإذن',
      'open_settings': 'فتح الإعدادات',

      // Crop / create sticker
      'crop_mode_auto': 'قص تلقائي',
      'crop_mode_manual': 'يدوي',
      'crop_mode_square': 'مربع',
      'crop_mode_circle': 'دائرة',
      'crop_mode_heart': 'قلب',
      'coming_soon_ai_cutout':
          'سيتم تطبيق القص بالذكاء الاصطناعي على الجهاز في الخطوة التالية.',
      'coming_soon_animated_stickers':
          'سيتم تطبيق الملصقات المتحركة في الخطوة التالية.',
      'error_cannot_read_image': 'لا يمكن قراءة الصورة.',
      'error_cannot_encode_webp': 'لا يمكن ترميز WebP.',
      'error_sticker_too_large':
          'الملصق كبير جداً (@sizeKbكيلوبايت). يرجى قصه بشكل أصغر أو اختيار صورة أبسط.',
      'success_saved_to_pack': 'تم إنشاء الملصق وحفظه في الحزمة "@title".',

      // Snackbars / dialogs
      'snackbar_success_title': 'نجح',
      'snackbar_error_title': 'خطأ',
      'snackbar_warning_title': 'تحذير',
      'snackbar_info_title': 'معلومات',
      'error_whatsapp_not_installed': 'واتساب غير مثبت على هذا الجهاز.',
      'success_sent_to_whatsapp': 'تم إرسال حزمة الملصقات إلى واتساب.',
      'success_sticker_updated': 'تم تحديث حزمة الملصقات في واتساب.',
      'warning_pack_already_in_whatsapp':
          'حزمة الملصقات هذه موجودة بالفعل في واتساب.',

      // Edit Sticker
      'edit_sticker_title': 'تحرير الملصق',
      'create_button': 'إنشاء',

      // Text Edit
      'text_edit_title': 'نص',
      'text_color_label': 'لون النص',
      'font_label': 'الخط',
      'opacity_label': 'الشفافية',

      // Background Picker
      'background_title': 'الخلفية',
      'no_sticker_preview': 'لا يوجد ملصق للمعاينة',

      // My Sticker
      'sticker_maker_title': 'صانع الملصقات',
      'create_sticker_title': 'إنشاء ملصق',
      'sticker_type_regular': 'عادي',
      'sticker_type_animated': 'متحرك',
      'default_pack_name': 'حزمة جديدة',
      'updating_button': 'جاري التحديث...',
      'update_to_whatsapp_button': 'تحديث إلى واتساب',
      'export_package_button': 'تصدير حزمة الملصقات',

      // Dialogs
      'delete_package_title': 'حذف الحزمة',
      'delete_package_message': 'هل تريد حذف حزمة الملصقات هذه؟',
      'cancel_button': 'إلغاء',
      'ok_button': 'موافق',

      // Errors
      'error_generic_title': 'خطأ',
      'error_load_photos': 'فشل تحميل الصور',
      'error_crop_title': 'خطأ في القص',

      // Bottom Navigation
      'bottom_nav_home': 'الرئيسية',
      'bottom_nav_my_sticker': 'ملصقاتي',

      // Sticker Pack Actions
      'add_button': 'إضافة',
      'add_to_whatsapp_button': 'إضافة إلى واتساب',
      'adding_button_short': 'جاري الإضافة...',
      'checking_status': 'جاري التحقق...',
      'has_been_added_status': 'تم الإضافة',

      // Crop Screen
      'crop_title': 'قص',
      'next_button': 'التالي',
      'processing_ai': 'معالجة الذكاء الاصطناعي...',
      'compressing_image': 'ضغط الصورة...',
      'removing_background_ai': 'إزالة الخلفية بالذكاء الاصطناعي...',
      'processing_image': 'معالجة الصورة...',
      'cleaning_image': 'تنظيف الصورة...',
      'creating_sticker': 'إنشاء الملصق...',
      'error_crop_loading': 'حدث خطأ أثناء تحميل شاشة القص.',
      'error_label': 'خطأ:',
      'go_back_button': 'العودة',
      'select_from_library': 'اختر من المكتبة',
      'load_failed_message':
          'تعذر تحميل قائمة الصور على هذا الجهاز. يمكنك اختيار صورة من المكتبة للمتابعة.',
      'try_reload_button': 'حاول إعادة التحميل',
    },

    'id_ID': {
      // lang
      'language_setting': 'PENGATURAN BAHASA',

      // Setting
      'setting': 'PENGATURAN',
      'rate_app': 'Beri Rating Aplikasi',
      'share': 'Bagikan',
      'privacy': 'Kebijakan Privasi',
      'language': 'Bahasa',

      // Common
      'confirm_ok': 'OK',
      'confirm_cancel': 'Batal',
      'success_title': 'Berhasil',
      'error_title': 'Error',
      'coming_soon_title': 'Segera hadir',

      // Select image
      'select_image_title': 'Pilih gambar',
      'permission_photos_required':
          'Izin akses foto diperlukan untuk memilih gambar.',
      'grant_permission': 'Berikan izin',
      'open_settings': 'Buka pengaturan',

      // Crop / create sticker
      'crop_mode_auto': 'Potong otomatis',
      'crop_mode_manual': 'Manual',
      'crop_mode_square': 'Persegi',
      'crop_mode_circle': 'Lingkaran',
      'crop_mode_heart': 'Hati',
      'coming_soon_ai_cutout':
          'Pemotongan AI di perangkat akan diterapkan pada langkah berikutnya.',
      'coming_soon_animated_stickers':
          'Stiker animasi akan diterapkan pada langkah berikutnya.',
      'error_cannot_read_image': 'Tidak dapat membaca gambar.',
      'error_cannot_encode_webp': 'Tidak dapat mengkodekan WebP.',
      'error_sticker_too_large':
          'Stiker terlalu besar (@sizeKbKB). Silakan potong lebih kecil atau pilih gambar yang lebih sederhana.',
      'success_saved_to_pack': 'Stiker dibuat dan disimpan ke paket "@title".',

      // Snackbars / dialogs
      'snackbar_success_title': 'Berhasil',
      'snackbar_error_title': 'Error',
      'snackbar_warning_title': 'Peringatan',
      'snackbar_info_title': 'Info',
      'error_whatsapp_not_installed':
          'WhatsApp tidak terinstal di perangkat ini.',
      'success_sent_to_whatsapp': 'Paket stiker telah dikirim ke WhatsApp.',
      'success_sticker_updated': 'Paket stiker telah diperbarui di WhatsApp.',
      'warning_pack_already_in_whatsapp':
          'Paket stiker ini sudah ada di WhatsApp.',

      // Edit Sticker
      'edit_sticker_title': 'Edit Stiker',
      'create_button': 'Buat',

      // Text Edit
      'text_edit_title': 'Teks',
      'text_color_label': 'Warna Teks',
      'font_label': 'Font',
      'opacity_label': 'Opacity',

      // Background Picker
      'background_title': 'Latar Belakang',
      'no_sticker_preview': 'Tidak ada stiker untuk pratinjau',

      // My Sticker
      'sticker_maker_title': 'Pembuat Stiker',
      'create_sticker_title': 'Buat Stiker',
      'sticker_type_regular': 'Reguler',
      'sticker_type_animated': 'Animasi',
      'default_pack_name': 'Paket Baru',
      'updating_button': 'Memperbarui...',
      'update_to_whatsapp_button': 'Perbarui ke WhatsApp',
      'export_package_button': 'Ekspor Paket Stiker',

      // Dialogs
      'delete_package_title': 'Hapus Paket',
      'delete_package_message': 'Apakah Anda ingin menghapus paket stiker ini?',
      'cancel_button': 'BATAL',
      'ok_button': 'OK',

      // Errors
      'error_generic_title': 'Error',
      'error_load_photos': 'Gagal memuat foto',
      'error_crop_title': 'Error Potong',

      // Bottom Navigation
      'bottom_nav_home': 'Beranda',
      'bottom_nav_my_sticker': 'Stiker Saya',

      // Sticker Pack Actions
      'add_button': 'Tambah',
      'add_to_whatsapp_button': 'Tambahkan ke WhatsApp',
      'adding_button_short': 'Menambahkan...',
      'checking_status': 'Memeriksa...',
      'has_been_added_status': 'Telah ditambahkan',

      // Crop Screen
      'crop_title': 'Potong',
      'next_button': 'Berikutnya',
      'processing_ai': 'Memproses AI...',
      'compressing_image': 'Mengompresi gambar...',
      'removing_background_ai': 'Menghapus latar belakang dengan AI...',
      'processing_image': 'Memproses gambar...',
      'cleaning_image': 'Membersihkan gambar...',
      'creating_sticker': 'Membuat stiker...',
      'error_crop_loading': 'Terjadi kesalahan saat memuat layar pemotongan.',
      'error_label': 'Error:',
      'go_back_button': 'Kembali',
      'select_from_library': 'Pilih dari perpustakaan',
      'load_failed_message':
          'Tidak dapat memuat daftar gambar di perangkat ini. Anda dapat memilih gambar dari perpustakaan untuk melanjutkan.',
      'try_reload_button': 'Coba muat ulang',
    },

    'hi_IN': {
      // lang
      'language_setting': 'भाषा सेटिंग',

      // Setting
      'setting': 'सेटिंग',
      'rate_app': 'ऐप को रेट करें',
      'share': 'साझा करें',
      'privacy': 'गोपनीयता नीति',
      'language': 'भाषा',

      // Common
      'confirm_ok': 'ठीक है',
      'confirm_cancel': 'रद्द करें',
      'success_title': 'सफल',
      'error_title': 'त्रुटि',
      'coming_soon_title': 'जल्द आ रहा है',

      // Select image
      'select_image_title': 'छवि चुनें',
      'permission_photos_required':
          'छवि चुनने के लिए फोटो एक्सेस अनुमति आवश्यक है।',
      'grant_permission': 'अनुमति दें',
      'open_settings': 'सेटिंग खोलें',

      // Crop / create sticker
      'crop_mode_auto': 'ऑटो कटआउट',
      'crop_mode_manual': 'मैनुअल',
      'crop_mode_square': 'वर्ग',
      'crop_mode_circle': 'वृत्त',
      'crop_mode_heart': 'दिल',
      'coming_soon_ai_cutout':
          'ऑन-डिवाइस AI कटआउट अगले चरण में लागू किया जाएगा।',
      'coming_soon_animated_stickers':
          'एनिमेटेड स्टिकर अगले चरण में लागू किए जाएंगे।',
      'error_cannot_read_image': 'छवि नहीं पढ़ सकते।',
      'error_cannot_encode_webp': 'WebP एनकोड नहीं कर सकते।',
      'error_sticker_too_large':
          'स्टिकर बहुत बड़ा है (@sizeKbKB)। कृपया छोटा क्रॉप करें या सरल छवि चुनें।',
      'success_saved_to_pack':
          'स्टिकर बनाया गया और "@title" पैक में सहेजा गया।',

      // Snackbars / dialogs
      'snackbar_success_title': 'सफल',
      'snackbar_error_title': 'त्रुटि',
      'snackbar_warning_title': 'चेतावनी',
      'snackbar_info_title': 'जानकारी',
      'error_whatsapp_not_installed': 'WhatsApp इस डिवाइस पर इंस्टॉल नहीं है।',
      'success_sent_to_whatsapp': 'स्टिकर पैक WhatsApp को भेजा गया है।',
      'success_sticker_updated': 'स्टिकर पैक WhatsApp में अपडेट किया गया है।',
      'warning_pack_already_in_whatsapp':
          'यह स्टिकर पैक पहले से WhatsApp में मौजूद है।',

      // Edit Sticker
      'edit_sticker_title': 'स्टिकर संपादित करें',
      'create_button': 'बनाएं',

      // Text Edit
      'text_edit_title': 'टेक्स्ट',
      'text_color_label': 'टेक्स्ट रंग',
      'font_label': 'फ़ॉन्ट',
      'opacity_label': 'पारदर्शिता',

      // Background Picker
      'background_title': 'पृष्ठभूमि',
      'no_sticker_preview': 'पूर्वावलोकन के लिए कोई स्टिकर नहीं',

      // My Sticker
      'sticker_maker_title': 'स्टिकर निर्माता',
      'create_sticker_title': 'स्टिकर बनाएं',
      'sticker_type_regular': 'नियमित',
      'sticker_type_animated': 'एनिमेटेड',
      'default_pack_name': 'नया पैक',
      'updating_button': 'अपडेट हो रहा है...',
      'update_to_whatsapp_button': 'WhatsApp में अपडेट करें',
      'export_package_button': 'स्टिकर पैक निर्यात करें',

      // Dialogs
      'delete_package_title': 'पैक हटाएं',
      'delete_package_message': 'क्या आप इस स्टिकर पैक को हटाना चाहते हैं?',
      'cancel_button': 'रद्द करें',
      'ok_button': 'ठीक है',

      // Errors
      'error_generic_title': 'त्रुटि',
      'error_load_photos': 'फ़ोटो लोड करने में विफल',
      'error_crop_title': 'क्रॉप त्रुटि',

      // Bottom Navigation
      'bottom_nav_home': 'होम',
      'bottom_nav_my_sticker': 'मेरे स्टिकर',

      // Sticker Pack Actions
      'add_button': 'जोड़ें',
      'add_to_whatsapp_button': 'WhatsApp में जोड़ें',
      'adding_button_short': 'जोड़ा जा रहा है...',
      'checking_status': 'जाँच हो रही है...',
      'has_been_added_status': 'जोड़ दिया गया है',

      // Crop Screen
      'crop_title': 'क्रॉप',
      'next_button': 'अगला',
      'processing_ai': 'AI प्रोसेस हो रहा है...',
      'compressing_image': 'छवि संपीड़ित हो रही है...',
      'removing_background_ai': 'AI से पृष्ठभूमि हटाई जा रही है...',
      'processing_image': 'छवि प्रोसेस हो रही है...',
      'cleaning_image': 'छवि साफ़ हो रही है...',
      'creating_sticker': 'स्टिकर बनाया जा रहा है...',
      'error_crop_loading': 'क्रॉप स्क्रीन लोड करते समय एक त्रुटि हुई।',
      'error_label': 'त्रुटि:',
      'go_back_button': 'वापस जाएं',
      'select_from_library': 'लाइब्रेरी से चुनें',
      'load_failed_message':
          'इस डिवाइस पर छवियों की सूची लोड नहीं हो सकी। आप जारी रखने के लिए लाइब्रेरी से एक छवि चुन सकते हैं।',
      'try_reload_button': 'पुनः लोड करने का प्रयास करें',
    },

    'ko_KR': {
      // lang
      'language_setting': '언어 설정',

      // Setting
      'setting': '설정',
      'rate_app': '앱 평가',
      'share': '공유',
      'privacy': '개인정보 보호정책',
      'language': '언어',

      // Common
      'confirm_ok': '확인',
      'confirm_cancel': '취소',
      'success_title': '성공',
      'error_title': '오류',
      'coming_soon_title': '곧 출시',

      // Select image
      'select_image_title': '이미지 선택',
      'permission_photos_required': '이미지를 선택하려면 사진 접근 권한이 필요합니다.',
      'grant_permission': '권한 허용',
      'open_settings': '설정 열기',

      // Crop / create sticker
      'crop_mode_auto': '자동 자르기',
      'crop_mode_manual': '수동',
      'crop_mode_square': '정사각형',
      'crop_mode_circle': '원',
      'crop_mode_heart': '하트',
      'coming_soon_ai_cutout': '온디바이스 AI 자르기는 다음 단계에서 구현됩니다.',
      'coming_soon_animated_stickers': '애니메이션 스티커는 다음 단계에서 구현됩니다.',
      'error_cannot_read_image': '이미지를 읽을 수 없습니다.',
      'error_cannot_encode_webp': 'WebP를 인코딩할 수 없습니다.',
      'error_sticker_too_large':
          '스티커가 너무 큽니다(@sizeKbKB). 더 작게 자르거나 더 간단한 이미지를 선택하세요.',
      'success_saved_to_pack': '스티커가 생성되어 "@title" 팩에 저장되었습니다.',

      // Snackbars / dialogs
      'snackbar_success_title': '성공',
      'snackbar_error_title': '오류',
      'snackbar_warning_title': '경고',
      'snackbar_info_title': '정보',
      'error_whatsapp_not_installed': 'WhatsApp이 이 기기에 설치되어 있지 않습니다.',
      'success_sent_to_whatsapp': '스티커 팩이 WhatsApp으로 전송되었습니다.',
      'success_sticker_updated': '스티커 팩이 WhatsApp에서 업데이트되었습니다.',
      'warning_pack_already_in_whatsapp': '이 스티커 팩은 이미 WhatsApp에 존재합니다.',

      // Edit Sticker
      'edit_sticker_title': '스티커 편집',
      'create_button': '생성',

      // Text Edit
      'text_edit_title': '텍스트',
      'text_color_label': '텍스트 색상',
      'font_label': '글꼴',
      'opacity_label': '불투명도',

      // Background Picker
      'background_title': '배경',
      'no_sticker_preview': '미리보기할 스티커가 없습니다',

      // My Sticker
      'sticker_maker_title': '스티커 제작',
      'create_sticker_title': '스티커 생성',
      'sticker_type_regular': '일반',
      'sticker_type_animated': '애니메이션',
      'default_pack_name': '새 팩',
      'updating_button': '업데이트 중...',
      'update_to_whatsapp_button': 'WhatsApp에 업데이트',
      'export_package_button': '스티커 팩 내보내기',

      // Dialogs
      'delete_package_title': '팩 삭제',
      'delete_package_message': '이 스티커 팩을 삭제하시겠습니까?',
      'cancel_button': '취소',
      'ok_button': '확인',

      // Errors
      'error_generic_title': '오류',
      'error_load_photos': '사진 로드 실패',
      'error_crop_title': '자르기 오류',

      // Bottom Navigation
      'bottom_nav_home': '홈',
      'bottom_nav_my_sticker': '내 스티커',

      // Sticker Pack Actions
      'add_button': '추가',
      'add_to_whatsapp_button': 'WhatsApp에 추가',
      'adding_button_short': '추가 중...',
      'checking_status': '확인 중...',
      'has_been_added_status': '이미 추가됨',

      // Crop Screen
      'crop_title': '자르기',
      'next_button': '다음',
      'processing_ai': 'AI 처리 중...',
      'compressing_image': '이미지 압축 중...',
      'removing_background_ai': 'AI로 배경 제거 중...',
      'processing_image': '이미지 처리 중...',
      'cleaning_image': '이미지 정리 중...',
      'creating_sticker': '스티커 생성 중...',
      'error_crop_loading': '자르기 화면을 로드하는 중 오류가 발생했습니다.',
      'error_label': '오류:',
      'go_back_button': '뒤로 가기',
      'select_from_library': '라이브러리에서 선택',
      'load_failed_message':
          '이 장치에서 이미지 목록을 로드할 수 없습니다. 라이브러리에서 이미지를 선택하여 계속할 수 있습니다.',
      'try_reload_button': '다시 로드 시도',
    },

    'ja_JP': {
      // lang
      'language_setting': '言語設定',

      // Setting
      'setting': '設定',
      'rate_app': 'アプリを評価',
      'share': '共有',
      'privacy': 'プライバシーポリシー',
      'language': '言語',

      // Common
      'confirm_ok': 'OK',
      'confirm_cancel': 'キャンセル',
      'success_title': '成功',
      'error_title': 'エラー',
      'coming_soon_title': '近日公開',

      // Select image
      'select_image_title': '画像を選択',
      'permission_photos_required': '画像を選択するには写真アクセス許可が必要です。',
      'grant_permission': '許可を付与',
      'open_settings': '設定を開く',

      // Crop / create sticker
      'crop_mode_auto': '自動切り抜き',
      'crop_mode_manual': '手動',
      'crop_mode_square': '正方形',
      'crop_mode_circle': '円',
      'crop_mode_heart': 'ハート',
      'coming_soon_ai_cutout': 'オンデバイスAI切り抜きは次のステップで実装されます。',
      'coming_soon_animated_stickers': 'アニメーションステッカーは次のステップで実装されます。',
      'error_cannot_read_image': '画像を読み込めません。',
      'error_cannot_encode_webp': 'WebPをエンコードできません。',
      'error_sticker_too_large':
          'ステッカーが大きすぎます（@sizeKbKB）。小さくトリミングするか、よりシンプルな画像を選択してください。',
      'success_saved_to_pack': 'ステッカーが作成され、「@title」パックに保存されました。',

      // Snackbars / dialogs
      'snackbar_success_title': '成功',
      'snackbar_error_title': 'エラー',
      'snackbar_warning_title': '警告',
      'snackbar_info_title': '情報',
      'error_whatsapp_not_installed': 'このデバイスにWhatsAppがインストールされていません。',
      'success_sent_to_whatsapp': 'ステッカーパックがWhatsAppに送信されました。',
      'success_sticker_updated': 'ステッカーパックがWhatsAppで更新されました。',
      'warning_pack_already_in_whatsapp': 'このステッカーパックは既にWhatsAppに存在します。',

      // Edit Sticker
      'edit_sticker_title': 'ステッカーを編集',
      'create_button': '作成',

      // Text Edit
      'text_edit_title': 'テキスト',
      'text_color_label': 'テキストの色',
      'font_label': 'フォント',
      'opacity_label': '不透明度',

      // Background Picker
      'background_title': '背景',
      'no_sticker_preview': 'プレビューするステッカーがありません',

      // My Sticker
      'sticker_maker_title': 'ステッカー作成',
      'create_sticker_title': 'ステッカーを作成',
      'sticker_type_regular': '通常',
      'sticker_type_animated': 'アニメーション',
      'default_pack_name': '新しいパック',
      'updating_button': '更新中...',
      'update_to_whatsapp_button': 'WhatsAppに更新',
      'export_package_button': 'ステッカーパックをエクスポート',

      // Dialogs
      'delete_package_title': 'パックを削除',
      'delete_package_message': 'このステッカーパックを削除しますか？',
      'cancel_button': 'キャンセル',
      'ok_button': 'OK',

      // Errors
      'error_generic_title': 'エラー',
      'error_load_photos': '写真の読み込みに失敗しました',
      'error_crop_title': 'トリミングエラー',

      // Bottom Navigation
      'bottom_nav_home': 'ホーム',
      'bottom_nav_my_sticker': 'マイステッカー',

      // Sticker Pack Actions
      'add_button': '追加',
      'add_to_whatsapp_button': 'WhatsAppに追加',
      'adding_button_short': '追加中...',
      'checking_status': '確認中...',
      'has_been_added_status': '追加済み',

      // Crop Screen
      'crop_title': 'トリミング',
      'next_button': '次へ',
      'processing_ai': 'AI処理中...',
      'compressing_image': '画像を圧縮中...',
      'removing_background_ai': 'AIで背景を削除中...',
      'processing_image': '画像を処理中...',
      'cleaning_image': '画像をクリーニング中...',
      'creating_sticker': 'ステッカーを作成中...',
      'error_crop_loading': 'トリミング画面の読み込み中にエラーが発生しました。',
      'error_label': 'エラー：',
      'go_back_button': '戻る',
      'select_from_library': 'ライブラリから選択',
      'load_failed_message': 'このデバイスで画像リストを読み込めませんでした。ライブラリから画像を選択して続行できます。',
      'try_reload_button': '再読み込みを試す',
    },

    'fr_FR': {
      // lang
      'language_setting': 'PARAMÈTRES DE LANGUE',

      // Setting
      'setting': 'PARAMÈTRES',
      'rate_app': 'Évaluer l\'Application',
      'share': 'Partager',
      'privacy': 'Politique de Confidentialité',
      'language': 'Langue',

      // Common
      'confirm_ok': 'OK',
      'confirm_cancel': 'Annuler',
      'success_title': 'Succès',
      'error_title': 'Erreur',
      'coming_soon_title': 'Bientôt disponible',

      // Select image
      'select_image_title': 'Sélectionner une image',
      'permission_photos_required':
          'L\'autorisation d\'accès aux photos est requise pour choisir une image.',
      'grant_permission': 'Accorder l\'autorisation',
      'open_settings': 'Ouvrir les paramètres',

      // Crop / create sticker
      'crop_mode_auto': 'Découpe automatique',
      'crop_mode_manual': 'Manuel',
      'crop_mode_square': 'Carré',
      'crop_mode_circle': 'Cercle',
      'crop_mode_heart': 'Cœur',
      'coming_soon_ai_cutout':
          'La découpe IA sur appareil sera implémentée à la prochaine étape.',
      'coming_soon_animated_stickers':
          'Les autocollants animés seront implémentés à la prochaine étape.',
      'error_cannot_read_image': 'Impossible de lire l\'image.',
      'error_cannot_encode_webp': 'Impossible d\'encoder WebP.',
      'error_sticker_too_large':
          'L\'autocollant est trop grand (@sizeKbKo). Veuillez recadrer plus petit ou choisir une image plus simple.',
      'success_saved_to_pack':
          'Autocollant créé et enregistré dans le pack "@title".',

      // Snackbars / dialogs
      'snackbar_success_title': 'Succès',
      'snackbar_error_title': 'Erreur',
      'snackbar_warning_title': 'Avertissement',
      'snackbar_info_title': 'Information',
      'error_whatsapp_not_installed':
          'WhatsApp n\'est pas installé sur cet appareil.',
      'success_sent_to_whatsapp':
          'Le pack d\'autocollants a été envoyé à WhatsApp.',
      'success_sticker_updated':
          'Le pack d\'autocollants a été mis à jour dans WhatsApp.',
      'warning_pack_already_in_whatsapp':
          'Ce pack d\'autocollants existe déjà dans WhatsApp.',

      // Edit Sticker
      'edit_sticker_title': 'Modifier l\'Autocollant',
      'create_button': 'Créer',

      // Text Edit
      'text_edit_title': 'Texte',
      'text_color_label': 'Couleur du Texte',
      'font_label': 'Police',
      'opacity_label': 'Opacité',

      // Background Picker
      'background_title': 'Arrière-plan',
      'no_sticker_preview': 'Aucun autocollant à prévisualiser',

      // My Sticker
      'sticker_maker_title': 'Créateur d\'Autocollants',
      'create_sticker_title': 'Créer un Autocollant',
      'sticker_type_regular': 'Normal',
      'sticker_type_animated': 'Animé',
      'default_pack_name': 'Nouveau Pack',
      'updating_button': 'Mise à jour...',
      'update_to_whatsapp_button': 'Mettre à jour sur WhatsApp',
      'export_package_button': 'Exporter le Pack d\'Autocollants',

      // Dialogs
      'delete_package_title': 'Supprimer le Pack',
      'delete_package_message':
          'Voulez-vous supprimer ce pack d\'autocollants?',
      'cancel_button': 'ANNULER',
      'ok_button': 'OK',

      // Errors
      'error_generic_title': 'Erreur',
      'error_load_photos': 'Échec du chargement des photos',
      'error_crop_title': 'Erreur de Recadrage',

      // Bottom Navigation
      'bottom_nav_home': 'Accueil',
      'bottom_nav_my_sticker': 'Mes Autocollants',

      // Sticker Pack Actions
      'add_button': 'Ajouter',
      'add_to_whatsapp_button': 'Ajouter à WhatsApp',
      'adding_button_short': 'Ajout...',
      'checking_status': 'Vérification...',
      'has_been_added_status': 'Déjà ajouté',

      // Crop Screen
      'crop_title': 'Recadrer',
      'next_button': 'Suivant',
      'processing_ai': 'Traitement IA...',
      'compressing_image': 'Compression de l\'image...',
      'removing_background_ai': 'Suppression de l\'arrière-plan avec IA...',
      'processing_image': 'Traitement de l\'image...',
      'cleaning_image': 'Nettoyage de l\'image...',
      'creating_sticker': 'Création de l\'autocollant...',
      'error_crop_loading':
          'Une erreur s\'est produite lors du chargement de l\'écran de recadrage.',
      'error_label': 'Erreur :',
      'go_back_button': 'Retour',
      'select_from_library': 'Sélectionner dans la bibliothèque',
      'load_failed_message':
          'Impossible de charger la liste d\'images sur cet appareil. Vous pouvez sélectionner une image dans la bibliothèque pour continuer.',
      'try_reload_button': 'Essayer de recharger',
    },

    'tr_TR': {
      // lang
      'language_setting': 'DİL AYARLARI',

      // Setting
      'setting': 'AYARLAR',
      'rate_app': 'Uygulamayı Değerlendir',
      'share': 'Paylaş',
      'privacy': 'Gizlilik Politikası',
      'language': 'Dil',

      // Common
      'confirm_ok': 'Tamam',
      'confirm_cancel': 'İptal',
      'success_title': 'Başarılı',
      'error_title': 'Hata',
      'coming_soon_title': 'Yakında',

      // Select image
      'select_image_title': 'Resim seç',
      'permission_photos_required':
          'Resim seçmek için fotoğraf erişim izni gereklidir.',
      'grant_permission': 'İzin ver',
      'open_settings': 'Ayarları aç',

      // Crop / create sticker
      'crop_mode_auto': 'Otomatik kesim',
      'crop_mode_manual': 'Manuel',
      'crop_mode_square': 'Kare',
      'crop_mode_circle': 'Daire',
      'crop_mode_heart': 'Kalp',
      'coming_soon_ai_cutout':
          'Cihaz üzerinde AI kesimi bir sonraki adımda uygulanacaktır.',
      'coming_soon_animated_stickers':
          'Animasyonlu çıkartmalar bir sonraki adımda uygulanacaktır.',
      'error_cannot_read_image': 'Resim okunamıyor.',
      'error_cannot_encode_webp': 'WebP kodlanamıyor.',
      'error_sticker_too_large':
          'Çıkartma çok büyük (@sizeKbKB). Lütfen daha küçük kırpın veya daha basit bir resim seçin.',
      'success_saved_to_pack':
          'Çıkartma oluşturuldu ve "@title" paketine kaydedildi.',

      // Snackbars / dialogs
      'snackbar_success_title': 'Başarılı',
      'snackbar_error_title': 'Hata',
      'snackbar_warning_title': 'Uyarı',
      'snackbar_info_title': 'Bilgi',
      'error_whatsapp_not_installed': 'WhatsApp bu cihazda yüklü değil.',
      'success_sent_to_whatsapp': 'Çıkartma paketi WhatsApp\'a gönderildi.',
      'success_sticker_updated': 'Çıkartma paketi WhatsApp\'ta güncellendi.',
      'warning_pack_already_in_whatsapp':
          'Bu çıkartma paketi WhatsApp\'ta zaten mevcut.',

      // Edit Sticker
      'edit_sticker_title': 'Çıkartmayı Düzenle',
      'create_button': 'Oluştur',

      // Text Edit
      'text_edit_title': 'Metin',
      'text_color_label': 'Metin Rengi',
      'font_label': 'Yazı Tipi',
      'opacity_label': 'Opaklık',

      // Background Picker
      'background_title': 'Arka Plan',
      'no_sticker_preview': 'Önizlenecek çıkartma yok',

      // My Sticker
      'sticker_maker_title': 'Çıkartma Oluşturucu',
      'create_sticker_title': 'Çıkartma Oluştur',
      'sticker_type_regular': 'Normal',
      'sticker_type_animated': 'Animasyonlu',
      'default_pack_name': 'Yeni Paket',
      'updating_button': 'Güncelleniyor...',
      'update_to_whatsapp_button': 'WhatsApp\'ta Güncelle',
      'export_package_button': 'Çıkartma Paketini Dışa Aktar',

      // Dialogs
      'delete_package_title': 'Paketi Sil',
      'delete_package_message': 'Bu çıkartma paketini silmek istiyor musunuz?',
      'cancel_button': 'İPTAL',
      'ok_button': 'TAMAM',

      // Errors
      'error_generic_title': 'Hata',
      'error_load_photos': 'Fotoğraflar yüklenemedi',
      'error_crop_title': 'Kırpma Hatası',

      // Bottom Navigation
      'bottom_nav_home': 'Ana Sayfa',
      'bottom_nav_my_sticker': 'Çıkartmalarım',

      // Sticker Pack Actions
      'add_button': 'Ekle',
      'add_to_whatsapp_button': 'WhatsApp\'a Ekle',
      'adding_button_short': 'Ekleniyor...',
      'checking_status': 'Kontrol ediliyor...',
      'has_been_added_status': 'Eklendi',

      // Crop Screen
      'crop_title': 'Kırp',
      'next_button': 'İleri',
      'processing_ai': 'AI işleniyor...',
      'compressing_image': 'Görsel sıkıştırılıyor...',
      'removing_background_ai': 'AI ile arka plan kaldırılıyor...',
      'processing_image': 'Görsel işleniyor...',
      'cleaning_image': 'Görsel temizleniyor...',
      'creating_sticker': 'Çıkartma oluşturuluyor...',
      'error_crop_loading': 'Kırpma ekranı yüklenirken bir hata oluştu.',
      'error_label': 'Hata:',
      'go_back_button': 'Geri Dön',
      'select_from_library': 'Kütüphaneden seç',
      'load_failed_message':
          'Bu cihazda resim listesi yüklenemedi. Devam etmek için kütüphaneden bir resim seçebilirsiniz.',
      'try_reload_button': 'Yeniden yüklemeyi dene',
    },

    'es_ES': {
      // lang
      'language_setting': 'CONFIGURACIÓN DE IDIOMA',

      // Setting
      'setting': 'CONFIGURACIÓN',
      'rate_app': 'Calificar Aplicación',
      'share': 'Compartir',
      'privacy': 'Política de Privacidad',
      'language': 'Idioma',

      // Common
      'confirm_ok': 'OK',
      'confirm_cancel': 'Cancelar',
      'success_title': 'Éxito',
      'error_title': 'Error',
      'coming_soon_title': 'Próximamente',

      // Select image
      'select_image_title': 'Seleccionar imagen',
      'permission_photos_required':
          'Se requiere permiso de acceso a fotos para elegir una imagen.',
      'grant_permission': 'Otorgar permiso',
      'open_settings': 'Abrir configuración',

      // Crop / create sticker
      'crop_mode_auto': 'Recorte automático',
      'crop_mode_manual': 'Manual',
      'crop_mode_square': 'Cuadrado',
      'crop_mode_circle': 'Círculo',
      'crop_mode_heart': 'Corazón',
      'coming_soon_ai_cutout':
          'El recorte con IA en el dispositivo se implementará en el siguiente paso.',
      'coming_soon_animated_stickers':
          'Los stickers animados se implementarán en el siguiente paso.',
      'error_cannot_read_image': 'No se puede leer la imagen.',
      'error_cannot_encode_webp': 'No se puede codificar WebP.',
      'error_sticker_too_large':
          'El sticker es demasiado grande (@sizeKbKB). Por favor, recorta más pequeño o elige una imagen más simple.',
      'success_saved_to_pack':
          'Sticker creado y guardado en el paquete "@title".',

      // Snackbars / dialogs
      'snackbar_success_title': 'Éxito',
      'snackbar_error_title': 'Error',
      'snackbar_warning_title': 'Advertencia',
      'snackbar_info_title': 'Información',
      'error_whatsapp_not_installed':
          'WhatsApp no está instalado en este dispositivo.',
      'success_sent_to_whatsapp':
          'El paquete de stickers se ha enviado a WhatsApp.',
      'success_sticker_updated':
          'El paquete de stickers se ha actualizado en WhatsApp.',
      'warning_pack_already_in_whatsapp':
          'Este paquete de stickers ya existe en WhatsApp.',

      // Edit Sticker
      'edit_sticker_title': 'Editar Sticker',
      'create_button': 'Crear',

      // Text Edit
      'text_edit_title': 'Texto',
      'text_color_label': 'Color del Texto',
      'font_label': 'Fuente',
      'opacity_label': 'Opacidad',

      // Background Picker
      'background_title': 'Fondo',
      'no_sticker_preview': 'No hay sticker para previsualizar',

      // My Sticker
      'sticker_maker_title': 'Creador de Stickers',
      'create_sticker_title': 'Crear Sticker',
      'sticker_type_regular': 'Normal',
      'sticker_type_animated': 'Animado',
      'default_pack_name': 'Nuevo Paquete',
      'updating_button': 'Actualizando...',
      'update_to_whatsapp_button': 'Actualizar en WhatsApp',
      'export_package_button': 'Exportar Paquete de Stickers',

      // Dialogs
      'delete_package_title': 'Eliminar Paquete',
      'delete_package_message': '¿Deseas eliminar este paquete de stickers?',
      'cancel_button': 'CANCELAR',
      'ok_button': 'OK',

      // Errors
      'error_generic_title': 'Error',
      'error_load_photos': 'Error al cargar fotos',
      'error_crop_title': 'Error de Recorte',

      // Bottom Navigation
      'bottom_nav_home': 'Inicio',
      'bottom_nav_my_sticker': 'Mis Stickers',

      // Sticker Pack Actions
      'add_button': 'Agregar',
      'add_to_whatsapp_button': 'Agregar a WhatsApp',
      'adding_button_short': 'Agregando...',
      'checking_status': 'Verificando...',
      'has_been_added_status': 'Ya agregado',

      // Crop Screen
      'crop_title': 'Recortar',
      'next_button': 'Siguiente',
      'processing_ai': 'Procesando IA...',
      'compressing_image': 'Comprimiendo imagen...',
      'removing_background_ai': 'Eliminando fondo con IA...',
      'processing_image': 'Procesando imagen...',
      'cleaning_image': 'Limpiando imagen...',
      'creating_sticker': 'Creando sticker...',
      'error_crop_loading':
          'Ocurrió un error al cargar la pantalla de recorte.',
      'error_label': 'Error:',
      'go_back_button': 'Volver',
      'select_from_library': 'Seleccionar de la biblioteca',
      'load_failed_message':
          'No se pudo cargar la lista de imágenes en este dispositivo. Puedes seleccionar una imagen de la biblioteca para continuar.',
      'try_reload_button': 'Intentar recargar',
    },
  };
}
