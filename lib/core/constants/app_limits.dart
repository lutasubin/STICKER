/// App limits and constraints
class AppLimits {
  AppLimits._();

  // Sticker pack limits (WhatsApp requirements)
  static const int minStickersPerPack = 3;
  static const int maxStickersPerPack = 30;
  static const int maxStickerSizeKB = 100;
  static const int stickerDimension = 512;

  // Animated sticker limits
  static const int animatedStickerMinSeconds = 1;
  static const int animatedStickerMaxSeconds = 5;

  // Tray icon limits
  static const int maxTrayIconSizeKB = 50;
  static const int minTrayIconSize = 24;
  static const int maxTrayIconSize = 512;

  // Asset loading
  static const int maxAssetsPerPage = 200;
  static const int thumbnailSize = 300;
}
