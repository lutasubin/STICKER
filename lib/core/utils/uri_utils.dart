import 'dart:io';

/// URI utility functions
class UriUtils {
  UriUtils._();

  /// Convert file path to URI string
  static String filePathToUri(String filePath) {
    return Uri.file(filePath).toString();
  }

  /// Convert URI string to File
  static File uriToFile(String uri) {
    return File.fromUri(Uri.parse(uri));
  }

  /// Get file path from URI string
  static String uriToFilePath(String uri) {
    final parsedUri = Uri.parse(uri);
    if (parsedUri.scheme == 'file') {
      return parsedUri.toFilePath();
    }
    return uri.replaceFirst('file://', '');
  }

  /// Check if URI is a file URI
  static bool isFileUri(String uri) {
    try {
      final parsedUri = Uri.parse(uri);
      return parsedUri.scheme == 'file' || uri.startsWith('file://');
    } catch (e) {
      return false;
    }
  }

  /// Normalize URI (remove file:// prefix if present)
  static String normalizeUri(String uri) {
    if (uri.startsWith('file://')) {
      return uri.replaceFirst('file://', '');
    }
    return uri;
  }
}
