import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sticker_app/helper/logger/app_logger.dart';

/// Service để set loop count cho animated WebP qua native code
class WebpLoopService {
  static const MethodChannel _channel = MethodChannel('whatsapp_stickers');

  /// Set loop count cho animated WebP file
  /// 
  /// [filePath] Đường dẫn đến file WebP
  /// [loopCount] Số lần loop (0 = infinite loop)
  /// 
  /// Returns true nếu thành công, false nếu thất bại
  static Future<bool> setLoopCount({
    required String filePath,
    int loopCount = 0,
  }) async {
    try {
      AppLogger.d(
        '[WebpLoopService] Setting loop count to $loopCount for: $filePath',
      );

      // Kiểm tra file tồn tại
      final file = File(filePath);
      if (!await file.exists()) {
        AppLogger.e('[WebpLoopService] File does not exist: $filePath');
        return false;
      }

      // Gọi native code để set loop count
      final result = await _channel.invokeMethod<bool>(
        'setWebpLoopCount',
        {
          'filePath': filePath,
          'loopCount': loopCount,
        },
      );

      if (result == true) {
        AppLogger.i(
          '[WebpLoopService] Successfully set loop count to $loopCount',
        );
        return true;
      } else {
        AppLogger.w('[WebpLoopService] Failed to set loop count');
        return false;
      }
    } on PlatformException catch (e) {
      AppLogger.e(
        '[WebpLoopService] Platform exception: ${e.code} - ${e.message}',
      );
      return false;
    } catch (e, st) {
      AppLogger.e('[WebpLoopService] Error setting loop count', e, st);
      return false;
    }
  }
}
