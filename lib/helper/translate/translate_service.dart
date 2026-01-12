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
      'warning_pack_already_in_whatsapp':
          'Этот пакет стикеров уже существует в WhatsApp.',
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
      'warning_pack_already_in_whatsapp':
          'Dieses Sticker-Paket existiert bereits in WhatsApp.',
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
      'warning_pack_already_in_whatsapp':
          'Цей пакет стікерів вже існує в WhatsApp.',
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
      'warning_pack_already_in_whatsapp': '此贴纸包已存在于 WhatsApp 中。',
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
      'warning_pack_already_in_whatsapp':
          'Este pacote de stickers já existe no WhatsApp.',
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
      'warning_pack_already_in_whatsapp':
          'حزمة الملصقات هذه موجودة بالفعل في واتساب.',
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
      'warning_pack_already_in_whatsapp':
          'Paket stiker ini sudah ada di WhatsApp.',
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
      'warning_pack_already_in_whatsapp':
          'यह स्टिकर पैक पहले से WhatsApp में मौजूद है।',
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
      'warning_pack_already_in_whatsapp': '이 스티커 팩은 이미 WhatsApp에 존재합니다.',
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
      'warning_pack_already_in_whatsapp': 'このステッカーパックは既にWhatsAppに存在します。',
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
      'warning_pack_already_in_whatsapp':
          'Ce pack d\'autocollants existe déjà dans WhatsApp.',
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
      'warning_pack_already_in_whatsapp':
          'Bu çıkartma paketi WhatsApp\'ta zaten mevcut.',
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
      'warning_pack_already_in_whatsapp':
          'Este paquete de stickers ya existe en WhatsApp.',
    },
  };
}
