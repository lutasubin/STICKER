/// Number utility functions
class NumberUtils {
  NumberUtils._();

  /// Clamp number between min and max
  static double clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// Clamp integer between min and max
  static int clampInt(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// Round to specified decimal places
  static double roundToDecimalPlaces(double value, int places) {
    final factor = 10.0 * places;
    return (value * factor).round() / factor;
  }

  /// Format number with thousand separator
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// Calculate percentage
  static double calculatePercentage(int part, int total) {
    if (total == 0) return 0.0;
    return (part / total) * 100.0;
  }

  /// Convert bytes to KB
  static double bytesToKB(int bytes) {
    return bytes / 1024.0;
  }

  /// Convert bytes to MB
  static double bytesToMB(int bytes) {
    return bytes / (1024.0 * 1024.0);
  }
}
