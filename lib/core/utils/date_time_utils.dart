/// Date and time utility functions
class DateTimeUtils {
  DateTimeUtils._();

  /// Format duration to MM:SS or SS format
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }

  /// Format duration in seconds to MM:SS or SS format
  static String formatDurationSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${remainingSeconds}s';
  }

  /// Format timestamp to readable date string
  static String formatTimestamp(int millisecondsSinceEpoch) {
    final date = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get current timestamp in milliseconds
  static int getCurrentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch;
  }
}
