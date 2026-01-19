import 'dart:io';

/// Path utility functions
class PathUtils {
  PathUtils._();

  /// Join path segments
  static String join(String part1, String part2, [String? part3, String? part4]) {
    var path = '$part1${Platform.pathSeparator}$part2';
    if (part3 != null) {
      path = '$path${Platform.pathSeparator}$part3';
    }
    if (part4 != null) {
      path = '$path${Platform.pathSeparator}$part4';
    }
    return path;
  }

  /// Get directory path from file path
  static String getDirectoryPath(String filePath) {
    return filePath.substring(0, filePath.lastIndexOf(Platform.pathSeparator));
  }

  /// Get parent directory path
  static String getParentDirectory(String path) {
    final parts = path.split(Platform.pathSeparator);
    if (parts.length <= 1) return path;
    parts.removeLast();
    return parts.join(Platform.pathSeparator);
  }

  /// Normalize path (remove trailing separators)
  static String normalizePath(String path) {
    return path.replaceAll(RegExp(r'[/\\]+$'), '');
  }

  /// Check if path is absolute
  static bool isAbsolutePath(String path) {
    if (Platform.isWindows) {
      return path.contains(':') || path.startsWith('\\\\');
    }
    return path.startsWith('/');
  }
}
