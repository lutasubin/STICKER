import 'dart:io';
import 'dart:typed_data';
import 'package:sticker_app/helper/logger/app_logger.dart';
import 'package:sticker_app/service/u2net_background_remover.dart';

class RemoveBgService {
  static Future<Uint8List> removeBackground(File imageFile) async {
    AppLogger.i(
      '[RemoveBgService] Starting background removal from file: ${imageFile.path}',
    );
    try {
      final bytes = await imageFile.readAsBytes();
      AppLogger.d(
        '[RemoveBgService] File loaded: ${bytes.length} bytes',
      );
      final result = await U2NetBackgroundRemover.removeBackgroundFromBytes(bytes);
      AppLogger.i(
        '[RemoveBgService] Background removal completed: output size=${result.length} bytes',
      );
      return result;
    } catch (e, stackTrace) {
      AppLogger.e(
        '[RemoveBgService] Failed to remove background from file: ${imageFile.path}',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  static Future<Uint8List> removeBackgroundFromBytes(Uint8List imageBytes) async {
    AppLogger.i(
      '[RemoveBgService] Starting background removal from bytes: ${imageBytes.length} bytes',
    );
    try {
      final result = await U2NetBackgroundRemover.removeBackgroundFromBytes(imageBytes);
      AppLogger.i(
        '[RemoveBgService] Background removal completed: output size=${result.length} bytes',
      );
      return result;
    } catch (e, stackTrace) {
      AppLogger.e(
        '[RemoveBgService] Failed to remove background from bytes',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
