import 'package:logger/logger.dart';

/// Centralized logger service với format giống backend
/// 
/// Sử dụng logger để log các service và lỗi một cách rõ ràng
/// với timestamp, level, và stack trace cho errors
class AppLogger {
  static Logger? _instance;

  /// Get singleton logger instance
  static Logger get instance {
    _instance ??= Logger(
      printer: _CustomLogPrinter(),
      level: _getLogLevel(),
    );
    return _instance!;
  }

  /// Get log level based on environment
  static Level _getLogLevel() {
    // Trong production có thể set Level.warning hoặc Level.error
    // Trong development dùng Level.debug để xem tất cả
    return Level.debug;
  }

  /// Log debug message
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null && stackTrace != null) {
      instance.d(message, error: error, stackTrace: stackTrace);
    } else if (error != null) {
      instance.d(message, error: error);
    } else {
      instance.d(message);
    }
  }

  /// Log info message
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null && stackTrace != null) {
      instance.i(message, error: error, stackTrace: stackTrace);
    } else if (error != null) {
      instance.i(message, error: error);
    } else {
      instance.i(message);
    }
  }

  /// Log warning message
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null && stackTrace != null) {
      instance.w(message, error: error, stackTrace: stackTrace);
    } else if (error != null) {
      instance.w(message, error: error);
    } else {
      instance.w(message);
    }
  }

  /// Log error message
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null && stackTrace != null) {
      instance.e(message, error: error, stackTrace: stackTrace);
    } else if (error != null) {
      instance.e(message, error: error);
    } else {
      instance.e(message);
    }
  }

  /// Log fatal error
  static void f(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null && stackTrace != null) {
      instance.f(message, error: error, stackTrace: stackTrace);
    } else if (error != null) {
      instance.f(message, error: error);
    } else {
      instance.f(message);
    }
  }
}

/// Custom log printer với format giống backend
class _CustomLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final color = _getColorForLevel(event.level);
    final emoji = _getEmojiForLevel(event.level);
    final level = event.level.name.toUpperCase().padRight(5);
    final time = DateTime.now().toIso8601String();
    final message = event.message;

    final buffer = StringBuffer();
    buffer.writeln('$color$emoji [$time] [$level] $message');

    // Log error object nếu có
    if (event.error != null) {
      buffer.writeln('$color  └─ Error: ${event.error}');
    }

    // Log stack trace nếu có
    if (event.stackTrace != null) {
      buffer.writeln('$color  └─ StackTrace:');
      final lines = event.stackTrace.toString().split('\n');
      for (var i = 0; i < lines.length && i < 10; i++) {
        buffer.writeln('$color    ${lines[i]}');
      }
      if (lines.length > 10) {
        buffer.writeln('$color    ... (${lines.length - 10} more lines)');
      }
    }

    return [buffer.toString()];
  }

  String _getColorForLevel(Level level) {
    switch (level) {
      case Level.trace:
        return '\x1B[37m'; // White
      case Level.debug:
        return '\x1B[36m'; // Cyan
      case Level.info:
        return '\x1B[32m'; // Green
      case Level.warning:
        return '\x1B[33m'; // Yellow
      case Level.error:
        return '\x1B[31m'; // Red
      case Level.fatal:
        return '\x1B[35m'; // Magenta
      default:
        return '\x1B[0m'; // Reset
    }
  }

  String _getEmojiForLevel(Level level) {
    switch (level) {
      case Level.trace:
        return '🔍';
      case Level.debug:
        return '🐛';
      case Level.info:
        return 'ℹ️';
      case Level.warning:
        return '⚠️';
      case Level.error:
        return '❌';
      case Level.fatal:
        return '💀';
      default:
        return '📝';
    }
  }
}
