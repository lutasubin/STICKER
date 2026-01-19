/// String utility functions
class StringUtils {
  StringUtils._();

  /// Capitalize first letter of string
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Capitalize first letter of each word
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Truncate string with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Remove whitespace from string
  static String removeWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), '');
  }

  /// Check if string is empty or null
  static bool isEmptyOrNull(String? text) {
    return text == null || text.trim().isEmpty;
  }

  /// Check if string is not empty and not null
  static bool isNotEmpty(String? text) {
    return !isEmptyOrNull(text);
  }

  /// Format sticker count text
  static String formatStickerCount(int count) {
    return '$count sticker${count != 1 ? 's' : ''}';
  }

  /// Parse integer from string with fallback
  static int parseInt(String? text, {int fallback = 0}) {
    if (text == null || text.isEmpty) return fallback;
    return int.tryParse(text) ?? fallback;
  }

  /// Parse double from string with fallback
  static double parseDouble(String? text, {double fallback = 0.0}) {
    if (text == null || text.isEmpty) return fallback;
    return double.tryParse(text) ?? fallback;
  }
}
