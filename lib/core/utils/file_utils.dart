import 'dart:io';

/// File utility functions
class FileUtils {
  FileUtils._();

  /// Get file extension from path
  static String getFileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }

  /// Get file name without extension
  static String getFileNameWithoutExtension(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1) return fileName;
    return fileName.substring(0, dotIndex);
  }

  /// Get file name with extension
  static String getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  /// Format file size in bytes to human readable string
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Check if file is image
  static bool isImageFile(String path) {
    final ext = getFileExtension(path);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  /// Check if file is video
  static bool isVideoFile(String path) {
    final ext = getFileExtension(path);
    return ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(ext);
  }

  /// Check if file is WebP
  static bool isWebPFile(String path) {
    return getFileExtension(path) == 'webp';
  }

  /// Generate unique file name with timestamp
  static String generateUniqueFileName({
    required String extension,
    String? prefix,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final prefixStr = prefix != null ? '${prefix}_' : '';
    return '${prefixStr}$timestamp.$extension';
  }
}
