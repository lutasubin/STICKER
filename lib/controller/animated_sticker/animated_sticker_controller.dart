import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sticker_app/helper/logger/app_logger.dart';
import 'package:sticker_app/service/sticker/animated_sticker_service.dart';

/// Crop shape modes for animated stickers
enum CropShapeMode {
  manual, // Không có shape, giữ nguyên hình dạng
  square,
  circle,
}

/// GetX Controller for Animated Sticker creation
class AnimatedStickerController extends GetxController {
  final isProcessing = false.obs;
  final processingProgress = 0.0.obs;
  final processingMessage = ''.obs;

  /// Process video to animated WebP sticker
  /// 
  /// [videoFile] - Input video file
  /// [outputPath] - Output WebP file path
  /// [startTime] - Start time in seconds
  /// [endTime] - End time in seconds
  /// [cropMode] - Crop shape (square or circle)
  Future<String?> processVideoToAnimatedSticker({
    required File videoFile,
    required String outputPath,
    required double startTime,
    required double endTime,
    required CropShapeMode cropMode,
  }) async {
    try {
      isProcessing.value = true;
      processingProgress.value = 0.0;
      processingMessage.value = 'processing_video'.tr;

      AppLogger.i(
        '[AnimatedStickerController] Processing video: ${videoFile.path}, duration: ${endTime - startTime}s, mode: $cropMode',
      );

      // Progress callback để update UI
      void onProgress(double progress, String message) {
        processingProgress.value = progress;
        processingMessage.value = message;
        debugPrint('[AnimatedSticker] Progress: $progress - $message');
      }

      // Gọi service để process video
      final result = await AnimatedStickerService.processVideoToWebP(
        videoFile: videoFile,
        outputPath: outputPath,
        startTime: startTime,
        endTime: endTime,
        cropMode: cropMode,
        onProgress: onProgress,
      );

      if (result.isEmpty) {
        AppLogger.e('[AnimatedStickerController] Processing returned empty path');
        return null;
      }

      // Validate file sau khi process
      final outputFile = File(result);
      if (!await outputFile.exists()) {
        AppLogger.e('[AnimatedStickerController] Output file does not exist: $result');
        return null;
      }

      final isValid = await AnimatedStickerService.validateAnimatedSticker(outputFile);
      if (!isValid) {
        AppLogger.w(
          '[AnimatedStickerController] Generated file failed validation: $result',
        );
        // Vẫn return file để user có thể thử, nhưng log warning
      }

      AppLogger.i('[AnimatedStickerController] Processing completed: $result');
      return result;
    } catch (e, st) {
      AppLogger.e('[AnimatedStickerController] Processing error', e, st);
      Get.snackbar(
        'error_generic_title'.tr,
        'error_process_video'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      isProcessing.value = false;
      processingProgress.value = 0.0;
      processingMessage.value = '';
    }
  }

  /// Extract video thumbnail for preview
  Future<File?> extractThumbnail({
    required File videoFile,
    required String outputPath,
    double timeInSeconds = 0.0,
  }) async {
    try {
      AppLogger.d(
        '[AnimatedStickerController] Extracting thumbnail at ${timeInSeconds}s',
      );

      final result = await AnimatedStickerService.extractThumbnail(
        videoFile: videoFile,
        outputPath: outputPath,
        timeInSeconds: timeInSeconds,
      );

      return result;
    } catch (e, st) {
      AppLogger.e('[AnimatedStickerController] Extract thumbnail error', e, st);
      return null;
    }
  }

  @override
  void onClose() {
    // Cleanup nếu cần
    super.onClose();
  }
}
