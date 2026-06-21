import 'dart:io';

/// Validation utility functions
class ValidationUtils {
  ValidationUtils._();

  /// Validate sticker pack size (3-30 stickers)
  static bool isValidStickerPackSize(int count) {
    return count >= 3 && count <= 30;
  }

  /// Validate sticker file size (< 100KB)
  static bool isValidStickerSize(int bytes) {
    const maxSizeBytes = 100 * 1024; // 100KB
    return bytes <= maxSizeBytes;
  }

  /// Validate animated sticker duration (1-5 seconds)
  static bool isValidAnimatedStickerDuration(Duration duration) {
    final seconds = duration.inSeconds;
    return seconds >= 1 && seconds <= 5;
  }

  /// Validate animated sticker duration in seconds
  static bool isValidAnimatedStickerDurationSeconds(double seconds) {
    return seconds >= 1.0 && seconds <= 5.0;
  }

  /// Validate sticker dimension (must be 512x512)
  static bool isValidStickerDimension(int width, int height) {
    return width == 512 && height == 512;
  }

  /// Validate pack name (not empty, reasonable length)
  static bool isValidPackName(String? name) {
    if (name == null || name.trim().isEmpty) return false;
    return name.trim().length <= 128; // Reasonable max length
  }

  /// Validate file exists
  static bool fileExists(String? filePath) {
    if (filePath == null || filePath.isEmpty) return false;
    try {
      return File(filePath).existsSync();
    } catch (e) {
      return false;
    }
  }
}
