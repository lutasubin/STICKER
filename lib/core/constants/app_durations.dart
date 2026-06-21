/// App duration constants
class AppDurations {
  AppDurations._();

  // Navigation transitions
  static const Duration navigationTransition = Duration(milliseconds: 250);
  static const Duration splashAnimation = Duration(milliseconds: 2500);
  static const Duration fadeTransition = Duration(milliseconds: 500);

  // UI delays
  static const Duration debounceDelay = Duration(milliseconds: 300);
  static const Duration shortDelay = Duration(milliseconds: 100);
  static const Duration mediumDelay = Duration(milliseconds: 200);
  static const Duration longDelay = Duration(milliseconds: 500);

  // Video processing
  static const Duration videoListenerThrottle = Duration(milliseconds: 100);
  static const Duration videoLoopDelay = Duration(milliseconds: 200);

  // Sticker limits
  static const Duration animatedStickerMinDuration = Duration(seconds: 1);
  static const Duration animatedStickerMaxDuration = Duration(seconds: 5);
}
