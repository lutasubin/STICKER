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
        AppLogger.e(
          '[AnimatedStickerController] Processing returned empty path',
        );
        return null;
      }

      // Validate file sau khi process
      final outputFile = File(result);
      if (!await outputFile.exists()) {
        AppLogger.e(
          '[AnimatedStickerController] Output file does not exist: $result',
        );
        return null;
      }

      final isValid = await AnimatedStickerService.validateAnimatedSticker(
        outputFile,
      );
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

  /// Overlay text image (PNG) onto animated sticker (WebP)
  ///
  /// Pipeline: Render text → PNG → Overlay vào animated WebP → Export
  /// Text sẽ trở thành pixel và được ghép vào từng frame của animation
  ///
  /// [baseStickerFile] - Animated WebP sticker gốc (đã có sẵn)
  /// [textImageFile] - PNG trong suốt chứa text/emoji/sticker đã render
  /// [outputPath] - Output WebP file path sau khi overlay
  /// [position] - Vị trí overlay: 'center' | 'top' | 'bottom'
  Future<String?> overlayTextOnAnimatedSticker({
    required File baseStickerFile,
    required File textImageFile,
    required String outputPath,
    String position = 'center',
  }) async {
    try {
      isProcessing.value = true;
      processingProgress.value = 0.0;
      processingMessage.value = 'overlaying_text'.tr;

      AppLogger.i(
        '[AnimatedStickerController] Overlaying text image onto animated sticker: '
        'base=${baseStickerFile.path}, text=${textImageFile.path}, position=$position',
      );

      // Progress callback để update UI
      void onProgress(double progress, String message) {
        processingProgress.value = progress;
        processingMessage.value = message;
        debugPrint('[AnimatedSticker] Overlay progress: $progress - $message');
      }

      // Gọi service để overlay text image
      final result =
          await AnimatedStickerService.overlayTextImageOnAnimatedSticker(
            baseStickerFile: baseStickerFile,
            textImageFile: textImageFile,
            outputPath: outputPath,
            position: position,
            onProgress: onProgress,
          );

      if (result.isEmpty) {
        AppLogger.e('[AnimatedStickerController] Overlay returned empty path');
        return null;
      }

      // Validate file sau khi overlay
      final outputFile = File(result);
      if (!await outputFile.exists()) {
        AppLogger.e(
          '[AnimatedStickerController] Output file does not exist: $result',
        );
        return null;
      }

      final isValid = await AnimatedStickerService.validateAnimatedSticker(
        outputFile,
      );
      if (!isValid) {
        AppLogger.w(
          '[AnimatedStickerController] Overlayed file failed validation: $result',
        );
        // Vẫn return file để user có thể thử, nhưng log warning
      }

      AppLogger.i('[AnimatedStickerController] Overlay completed: $result');
      return result;
    } catch (e, st) {
      AppLogger.e('[AnimatedStickerController] Overlay text error', e, st);
      Get.snackbar(
        'error_generic_title'.tr,
        'error_overlay_text'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      isProcessing.value = false;
      processingProgress.value = 0.0;
      processingMessage.value = '';
    }
  }

  /// Process video to animated WebP WITH text overlay
  ///
  /// Overlay text PNG lên VIDEO trước khi convert sang WebP (cách ổn định nhất)
  ///
  /// [videoFile] - Input video file
  /// [outputPath] - Output WebP file path
  /// [startTime] - Start time in seconds
  /// [endTime] - End time in seconds
  /// [cropMode] - Crop shape (square, circle, or manual)
  /// [textImageFile] - PNG trong suốt chứa text đã render
  /// [position] - Vị trí overlay: 'center' | 'top' | 'bottom'
  Future<String?> processVideoToAnimatedStickerWithOverlay({
    required File videoFile,
    required String outputPath,
    required double startTime,
    required double endTime,
    required CropShapeMode cropMode,
    required File textImageFile,
    String position = 'center',
  }) async {
    try {
      isProcessing.value = true;
      processingProgress.value = 0.0;
      processingMessage.value = 'processing_video_with_text'.tr;

      AppLogger.i(
        '[AnimatedStickerController] Processing video with text overlay: '
        'video=${videoFile.path}, duration: ${endTime - startTime}s, '
        'mode=$cropMode, position=$position',
      );

      // Progress callback để update UI
      void onProgress(double progress, String message) {
        processingProgress.value = progress;
        processingMessage.value = message;
        debugPrint(
          '[AnimatedSticker] Process with overlay progress: $progress - $message',
        );
      }

      // Gọi service để process video với text overlay
      final result = await AnimatedStickerService.processVideoToWebPWithOverlay(
        videoFile: videoFile,
        outputPath: outputPath,
        startTime: startTime,
        endTime: endTime,
        cropMode: cropMode,
        textImageFile: textImageFile,
        position: position,
        onProgress: onProgress,
      );

      if (result.isEmpty) {
        AppLogger.e(
          '[AnimatedStickerController] Processing with overlay returned empty path',
        );
        return null;
      }

      // Validate file sau khi process
      final outputFile = File(result);
      if (!await outputFile.exists()) {
        AppLogger.e(
          '[AnimatedStickerController] Output file does not exist: $result',
        );
        return null;
      }

      final isValid = await AnimatedStickerService.validateAnimatedSticker(
        outputFile,
      );
      if (!isValid) {
        AppLogger.w(
          '[AnimatedStickerController] Generated file failed validation: $result',
        );
        // Vẫn return file để user có thể thử, nhưng log warning
      }

      AppLogger.i(
        '[AnimatedStickerController] Processing with overlay completed: $result',
      );
      return result;
    } catch (e, st) {
      AppLogger.e(
        '[AnimatedStickerController] Process with overlay error',
        e,
        st,
      );
      Get.snackbar(
        'error_generic_title'.tr,
        'error_process_video_with_text'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      isProcessing.value = false;
      processingProgress.value = 0.0;
      processingMessage.value = '';
    }
  }

  @override
  void onClose() {
    // Cleanup nếu cần
    super.onClose();
  }
}
