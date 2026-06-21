/// App string constants
class AppStrings {
  AppStrings._();

  // App info
  static const String appName = 'Sticker Maker';
  static const String appPackageName = 'com.mobileai.stickerapp';
  static const String appStoreLink =
      'https://play.google.com/store/apps/details?id=com.mobileai.stickerapp';

  // URLs
  static const String privacyPolicyUrl =
      'https://sites.google.com/view/policystickermaker';

  // Share messages
  static const String shareAppMessage = 'Check out Our app: $appStoreLink';
  static const String shareAppSubject = 'Share App';

  // File extensions
  static const String webpExtension = '.webp';
  static const String pngExtension = '.png';
  static const String mp4Extension = '.mp4';

  // File prefixes
  static const String tempFilePrefix = 'temp_';
  static const String nobgFileSuffix = '_nobg.png';

  // Storage keys
  static const String storageKeySelectedLanguage = 'selected_language';
  static const String storageKeyFirstOpen = 'isFirstOpen';
}
