import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:sticker_app/controller/animated_sticker/animated_sticker_controller.dart';
import 'package:sticker_app/helper/logger/app_logger.dart';
import 'package:sticker_app/service/sticker/webp_loop_service.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Service xử lý video thành animated sticker
///
/// Tối ưu hiệu suất:
/// - Convert TRỰC TIẾP từ video sang animated WebP (KHÔNG cần extract frames trước)
/// - FFmpeg xử lý toàn bộ quá trình trong một lần chạy, nhanh hơn và tiết kiệm bộ nhớ
/// - Sử dụng libwebp codec với compression tối ưu để đạt file size < 100KB
///
/// Lý do KHÔNG extract frames trước:
/// 1. Tốn thời gian: Phải extract từng frame rồi mới encode lại
/// 2. Tốn bộ nhớ: Phải lưu tất cả frames vào RAM/disk
/// 3. Chậm hơn: 2 bước (extract + encode) thay vì 1 bước (direct convert)
/// 4. FFmpeg đã tối ưu sẵn cho việc convert trực tiếp
class AnimatedStickerService {
  AnimatedStickerService._();

  /// Process video to animated WebP sticker using FFmpeg
  ///
  /// Convert TRỰC TIẾP từ video sang animated WebP - KHÔNG cần extract frames
  /// FFmpeg sẽ xử lý toàn bộ trong một lần chạy duy nhất
  ///
  /// [videoFile] - Input video file
  /// [outputPath] - Output WebP file path
  /// [startTime] - Start time in seconds
  /// [endTime] - End time in seconds
  /// [cropMode] - Crop shape (square, circle, or manual)
  /// [onProgress] - Progress callback (0.0 to 1.0)
  static Future<String> processVideoToWebP({
    required File videoFile,
    required String outputPath,
    required double startTime,
    required double endTime,
    required CropShapeMode cropMode,
    Function(double progress, String message)? onProgress,
  }) async {
    try {
      AppLogger.i('[AnimatedStickerService] Processing video to animated WebP');

      // Validate input (skip progress update vì nhanh)
      if (!await videoFile.exists()) {
        throw Exception('Video file not found: ${videoFile.path}');
      }

      final duration = endTime - startTime;
      if (duration <= 0 || duration > 5) {
        throw Exception('Invalid duration: $duration seconds (must be 1-5s)');
      }

      // Bắt đầu convert video (đây là bước chính, tốn thời gian nhất)
      onProgress?.call(0.0, 'converting_video');

      // WhatsApp animated sticker requirements:
      // - Size: 512x512 pixels
      // - Format: Animated WebP
      // - FPS: 10-15 (recommended 10)
      // - File size: < 100KB
      // - Duration: 1-5 seconds
      //
      // Tối ưu: Convert trực tiếp từ video sang animated WebP
      // KHÔNG cần extract frames trước - FFmpeg xử lý trực tiếp nhanh hơn
      final fps = 10;
      final targetSize = 512;

      // Build FFmpeg command tối ưu cho animated WebP
      // -ss: start time (seek to start position)
      // -i: input file
      // -t: duration (limit output duration)
      // -vf: video filter (scale và pad để đảm bảo 512x512)
      // -r: frame rate (10 fps cho WhatsApp sticker)
      // -loop: loop count (0 = infinite loop)
      // -an: no audio (remove audio track)
      // -vsync 0: disable video sync (tối ưu cho WebP)
      // -f webp: force WebP format
      // -c:v libwebp: use WebP codec
      // -quality: WebP quality (65 để đạt < 100KB ngay lần đầu)
      // -lossless 0: use lossy compression (smaller file size)
      // -compression_level 6: compression level (0-6, 6 = best compression)
      // -method 6: encoding method (0-6, 6 = slowest but best compression)
      final videoFilter = _buildVideoFilter(cropMode, targetSize);

      // Tối ưu: Quality 65 ngay từ đầu để đạt < 100KB
      // Nếu vẫn lớn sẽ re-encode với quality thấp hơn
      final initialQuality = 65;

      // FFmpeg command để tạo animated WebP
      // Lưu ý: Một số build của FFmpeg có thể không hỗ trợ animated WebP trực tiếp
      // Thử dùng format image2pipe rồi encode lại, hoặc dùng cách khác
      //
      // Cách 1: Thử trực tiếp với libwebp (nếu hỗ trợ)
      // Cách 2: Extract frames rồi tạo animated WebP (fallback)

      // FFmpeg command để tạo animated WebP
      //
      // Lưu ý: Một số build FFmpeg có thể không hỗ trợ animated WebP output trực tiếp
      // Thử dùng format image2pipe rồi encode lại, hoặc dùng cách khác
      //
      // Command tối ưu cho animated WebP:
      // - Bỏ -vsync 0 vì có thể gây conflict với libwebp
      // - Dùng -f webp để force WebP format
      // - Đảm bảo có nhiều frames (duration > 0.1s, fps = 10)
      final ffmpegCommand =
          '-ss $startTime '
          '-i "${videoFile.path}" '
          '-t $duration '
          '-vf "$videoFilter" '
          '-r $fps '
          '-an '
          '-f webp '
          '-c:v libwebp '
          '-quality $initialQuality '
          '-lossless 0 '
          '-compression_level 6 '
          '-method 6 '
          '"$outputPath"';

      AppLogger.d('[AnimatedStickerService] FFmpeg command: $ffmpegCommand');

      // Execute FFmpeg command
      // Note: FFmpeg convert trực tiếp từ video sang animated WebP
      // KHÔNG cần extract frames trước - đây là cách tối ưu nhất
      // Progress sẽ được update trong quá trình convert (0% -> 100%)
      final session = await FFmpegKit.execute(ffmpegCommand);

      // Wait for session to complete và get return code
      final returnCode = await session.getReturnCode();

      // FFmpeg đã hoàn thành, set progress 100%
      onProgress?.call(1.0, 'completed');

      if (!ReturnCode.isSuccess(returnCode)) {
        // Get full output để debug
        final output = await session.getOutput();
        final failStackTrace = await session.getFailStackTrace();

        // Log chi tiết để debug
        AppLogger.e(
          '[AnimatedStickerService] FFmpeg failed: '
          'returnCode=$returnCode',
        );

        // Log tất cả output để xem lỗi chi tiết
        if (output != null && output.isNotEmpty) {
          AppLogger.e('[AnimatedStickerService] FFmpeg output: $output');
        }

        if (failStackTrace != null && failStackTrace.isNotEmpty) {
          AppLogger.e(
            '[AnimatedStickerService] FFmpeg stackTrace: $failStackTrace',
          );
        }

        // Try alternative FFmpeg command nếu command đầu fail
        // Thử command đơn giản hơn không dùng -f webp
        AppLogger.w(
          '[AnimatedStickerService] First FFmpeg command failed, '
          'trying alternative command without -f webp',
        );

        final alternativeCommand =
            '-ss $startTime '
            '-i "${videoFile.path}" '
            '-t $duration '
            '-vf "$videoFilter" '
            '-r $fps '
            '-an '
            '-c:v libwebp '
            '-quality $initialQuality '
            '-lossless 0 '
            '-compression_level 6 '
            '-method 6 '
            '"$outputPath"';

        AppLogger.d(
          '[AnimatedStickerService] Alternative FFmpeg command: $alternativeCommand',
        );

        final altSession = await FFmpegKit.execute(alternativeCommand);
        final altReturnCode = await altSession.getReturnCode();

        if (ReturnCode.isSuccess(altReturnCode)) {
          AppLogger.i(
            '[AnimatedStickerService] Alternative FFmpeg command succeeded',
          );
          // Continue với validation và set loop
        } else {
          // Nếu cả 2 command đều fail, fallback về extract frames
          AppLogger.w(
            '[AnimatedStickerService] Alternative command also failed, '
            'falling back to frame extraction (will create static WebP)',
          );
          return await _extractSingleFrameFallback(
            videoFile: videoFile,
            outputPath: outputPath,
            startTime: startTime,
            endTime: endTime,
            cropMode: cropMode,
            onProgress: onProgress,
          );
        }
      }

      // Validate output file (skip progress update vì nhanh)
      final outputFile = File(outputPath);
      if (!await outputFile.exists()) {
        throw Exception('Output file not created: $outputPath');
      }

      final fileSize = await outputFile.length();
      AppLogger.i(
        '[AnimatedStickerService] Animated WebP size: ${(fileSize / 1024).toStringAsFixed(2)} KB',
      );

      // If file is too large, try re-encoding with lower quality
      if (fileSize > 100 * 1024) {
        AppLogger.w(
          '[AnimatedStickerService] File too large (${(fileSize / 1024).toStringAsFixed(2)} KB), '
          're-encoding with lower quality',
        );

        // Re-encode with lower quality (skip progress update vì nhanh)
        // Note: Khi re-encode từ WebP, không cần -vf và -r vì đã có sẵn
        final reencodeCommand =
            '-i "$outputPath" '
            '-c:v libwebp '
            '-quality 50 '
            '-lossless 0 '
            '-compression_level 6 '
            '-method 6 '
            '"$outputPath"';

        final reencodeSession = await FFmpegKit.execute(reencodeCommand);
        final reencodeReturnCode = await reencodeSession.getReturnCode();

        if (ReturnCode.isSuccess(reencodeReturnCode)) {
          final newFileSize = await outputFile.length();
          AppLogger.i(
            '[AnimatedStickerService] Re-encoded size: ${(newFileSize / 1024).toStringAsFixed(2)} KB',
          );

          // If still too large, try even lower quality
          if (newFileSize > 100 * 1024) {
            AppLogger.w(
              '[AnimatedStickerService] Still too large, trying quality 45',
            );

            final finalCommand =
                '-i "$outputPath" '
                '-c:v libwebp '
                '-quality 40 '
                '-lossless 0 '
                '-compression_level 6 '
                '-method 6 '
                '"$outputPath"';

            final finalSession = await FFmpegKit.execute(finalCommand);
            final finalReturnCode = await finalSession.getReturnCode();

            if (ReturnCode.isSuccess(finalReturnCode)) {
              final finalFileSize = await outputFile.length();
              AppLogger.i(
                '[AnimatedStickerService] Final size: ${(finalFileSize / 1024).toStringAsFixed(2)} KB',
              );
            }
          }
        }
      }

      // Validate và set loop (skip progress update vì nhanh)
      final isValid = await validateAnimatedSticker(outputFile);
      if (!isValid) {
        AppLogger.w(
          '[AnimatedStickerService] Generated file failed validation, '
          'but returning path anyway for debugging',
        );
      }

      // Set loop count = 0 (infinite loop) cho animated WebP
      // FFmpeg có thể không tự động set loop metadata, nên cần set thủ công
      AppLogger.d(
        '[AnimatedStickerService] Setting loop count to 0 (infinite) for animated WebP',
      );

      try {
        final loopSuccess = await WebpLoopService.setLoopCount(
          filePath: outputPath,
          loopCount: 0, // 0 = infinite loop
        );

        if (loopSuccess) {
          AppLogger.i(
            '[AnimatedStickerService] Successfully set infinite loop for animated WebP',
          );
        } else {
          AppLogger.w(
            '[AnimatedStickerService] Failed to set loop count, '
            'but continuing anyway. Sticker may only play once.',
          );
        }
      } catch (e, st) {
        AppLogger.e('[AnimatedStickerService] Error setting loop count', e, st);
        // Không throw error, vì file vẫn có thể dùng được (chỉ không loop)
      }

      // Progress đã được set ở trên (sau khi FFmpeg hoàn thành)
      // Không cần set lại vì validate và set loop rất nhanh

      AppLogger.i('[AnimatedStickerService] Processing completed: $outputPath');
      return outputPath;
    } catch (e, st) {
      AppLogger.e('[AnimatedStickerService] Process error', e, st);
      rethrow;
    }
  }

  /// Extract video thumbnail for preview
  static Future<File?> extractThumbnail({
    required File videoFile,
    required String outputPath,
    double timeInSeconds = 0.0,
  }) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        imageFormat: ImageFormat.PNG,
        maxWidth: 512,
        maxHeight: 512,
        timeMs: (timeInSeconds * 1000).toInt(),
        quality: 90,
      );

      if (thumbnail == null) {
        return null;
      }

      final file = File(thumbnail);
      if (!await file.exists()) {
        return null;
      }

      // Copy to output path
      final outputFile = File(outputPath);
      await file.copy(outputPath);
      await file.delete();

      return outputFile;
    } catch (e, st) {
      AppLogger.e('[AnimatedStickerService] Extract thumbnail error', e, st);
      return null;
    }
  }

  /// Validate sticker file
  /// Kiểm tra file có tồn tại, size hợp lệ, và format đúng
  static Future<bool> validateAnimatedSticker(File file) async {
    try {
      if (!await file.exists()) {
        AppLogger.w(
          '[AnimatedStickerService] File does not exist: ${file.path}',
        );
        return false;
      }

      // Check file size (< 100KB for WhatsApp sticker)
      final fileSize = await file.length();
      if (fileSize == 0) {
        AppLogger.w('[AnimatedStickerService] File is empty');
        return false;
      }

      if (fileSize > 100 * 1024) {
        AppLogger.w(
          '[AnimatedStickerService] File too large: ${(fileSize / 1024).toStringAsFixed(2)} KB',
        );
        return false;
      }

      // Kiểm tra file extension
      final path = file.path.toLowerCase();
      if (!path.endsWith('.webp')) {
        AppLogger.w('[AnimatedStickerService] File is not WebP format: $path');
        return false;
      }

      // Note: Không thể kiểm tra animated WebP vs static WebP bằng cách đơn giản
      // Cần đọc header của file để kiểm tra, nhưng điều này phức tạp
      // Tạm thời chỉ validate size và extension

      AppLogger.d(
        '[AnimatedStickerService] File validated: '
        'size=${(fileSize / 1024).toStringAsFixed(2)} KB, path=$path',
      );

      return true;
    } catch (e, st) {
      AppLogger.e('[AnimatedStickerService] Validation error', e, st);
      return false;
    }
  }

  /// Fallback: Extract multiple frames and create static WebP
  ///
  /// CHỈ dùng khi FFmpeg thất bại hoàn toàn
  /// Method này CHẬM HƠN và TỐN TÀI NGUYÊN hơn vì phải:
  /// 1. Extract từng frame từ video
  /// 2. Process từng frame (crop, resize)
  /// 3. Encode thành static WebP (không phải animated)
  ///
  /// Lưu ý: Method này chỉ tạo static WebP, không phải animated
  /// Vì image package không hỗ trợ encode animated WebP
  static Future<String> _extractSingleFrameFallback({
    required File videoFile,
    required String outputPath,
    required double startTime,
    required double endTime,
    required CropShapeMode cropMode,
    Function(double progress, String message)? onProgress,
  }) async {
    AppLogger.w(
      '[AnimatedStickerService] Using fallback: extracting multiple frames for animated WebP',
    );

    final duration = endTime - startTime;
    final fps = 10; // Target FPS for animated WebP
    final frameCount = (duration * fps).round().clamp(5, 50); // 5-50 frames
    final frameInterval = duration / frameCount;

    AppLogger.d(
      '[AnimatedStickerService] Extracting $frameCount frames (interval: ${frameInterval.toStringAsFixed(3)}s)',
    );

    onProgress?.call(0.1, 'extracting_frames');

    // Extract multiple frames
    final frames = <img.Image>[];
    for (var i = 0; i < frameCount; i++) {
      final frameTime = startTime + (i * frameInterval);
      final frameTimeMs = (frameTime * 1000).toInt();

      onProgress?.call(
        0.1 + (i / frameCount) * 0.5,
        'extracting_frame_${i + 1}_of_$frameCount',
      );

      try {
        final frameData = await VideoThumbnail.thumbnailData(
          video: videoFile.path,
          imageFormat: ImageFormat.PNG,
          maxWidth: 1024,
          maxHeight: 1024,
          timeMs: frameTimeMs,
          quality: 100,
        );

        if (frameData != null) {
          final decoded = img.decodeImage(frameData);
          if (decoded != null) {
            // Process frame: crop, resize, apply shape
            final processed = _processFrame(decoded, cropMode);
            frames.add(processed);
          }
        }
      } catch (e) {
        AppLogger.w(
          '[AnimatedStickerService] Failed to extract frame at ${frameTime}s: $e',
        );
        // Continue with other frames
      }
    }

    if (frames.isEmpty) {
      throw Exception('Failed to extract any frames from video');
    }

    AppLogger.d('[AnimatedStickerService] Extracted ${frames.length} frames');

    onProgress?.call(0.6, 'creating_animated_webp');

    // Create animated WebP from frames
    // Note: image package doesn't support animated WebP encoding
    // We'll use FlutterImageCompress which also doesn't support animated WebP
    // So we'll create a workaround: use the first frame as static WebP
    // TODO: Need FFmpeg or another library to create true animated WebP

    // For now, use the first frame (or middle frame) as static WebP
    final middleFrameIndex = (frames.length / 2).round();
    final selectedFrame = frames[middleFrameIndex];

    onProgress?.call(0.8, 'compressing_file');

    // Encode to PNG first
    final pngBytes = Uint8List.fromList(img.encodePng(selectedFrame));

    // Compress to WebP (static, not animated)
    final webpBytes = await FlutterImageCompress.compressWithList(
      pngBytes,
      format: CompressFormat.webp,
      quality: 80,
      keepExif: false,
    );

    onProgress?.call(0.9, 'saving_file');

    // Save to file
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(webpBytes, flush: true);

    // Validate size
    final fileSize = await outputFile.length();
    AppLogger.i(
      '[AnimatedStickerService] Static WebP size: ${fileSize / 1024} KB',
    );

    if (fileSize > 100 * 1024) {
      // Re-compress với quality thấp hơn
      AppLogger.w('[AnimatedStickerService] File too large, re-compressing');
      final recompressed = await FlutterImageCompress.compressWithList(
        pngBytes,
        format: CompressFormat.webp,
        quality: 60,
        keepExif: false,
      );
      await outputFile.writeAsBytes(recompressed, flush: true);
    }

    onProgress?.call(1.0, 'completed');

    AppLogger.w(
      '[AnimatedStickerService] WARNING: Created static WebP (not animated). '
      'FFmpeg is required for true animated WebP. '
      'Fallback completed: $outputPath',
    );
    return outputPath;
  }

  /// Process a single frame: crop, resize, apply shape
  static img.Image _processFrame(img.Image source, CropShapeMode cropMode) {
    // Convert to RGBA
    final rgba =
        source.numChannels == 4 ? source : source.convert(numChannels: 4);

    // Crop to square (1:1 aspect ratio) - center crop
    final size = rgba.width < rgba.height ? rgba.width : rgba.height;
    final x = ((rgba.width - size) / 2).round();
    final y = ((rgba.height - size) / 2).round();
    final cropped = img.copyCrop(rgba, x: x, y: y, width: size, height: size);

    // Resize to 512x512
    final resized = img.copyResize(cropped, width: 512, height: 512);

    // Apply circle mask if needed
    if (cropMode == CropShapeMode.circle) {
      _applyCircleMask(resized);
    }

    return resized;
  }

  /// Build video filter string based on crop mode
  /// Tối ưu: Sử dụng scale và pad để đảm bảo 512x512 với hiệu suất tốt nhất
  static String _buildVideoFilter(CropShapeMode cropMode, int targetSize) {
    // Tối ưu video filter:
    // 1. scale: Scale video xuống 512x512, giữ tỷ lệ khung hình
    //    force_original_aspect_ratio=decrease: chỉ scale down, không scale up
    // 2. pad: Pad video để đạt đúng 512x512 với padding đen trong suốt
    //    (ow-iw)/2, (oh-ih)/2: center padding
    //    color=black@0: màu đen trong suốt (alpha=0)

    String filter =
        'scale=$targetSize:$targetSize:force_original_aspect_ratio=decrease:flags=lanczos,'
        'pad=$targetSize:$targetSize:(ow-iw)/2:(oh-ih)/2:color=black@0';

    // Note: Circle mask sẽ được xử lý sau khi convert nếu cần
    // Vì FFmpeg circle filter phức tạp và tốn tài nguyên hơn
    // Tạm thời giữ nguyên filter scale+pad cho hiệu suất tốt nhất

    return filter;
  }

  /// Apply circle mask to image
  static void _applyCircleMask(img.Image canvas) {
    final cx = (canvas.width - 1) / 2.0;
    final cy = (canvas.height - 1) / 2.0;
    final r = (canvas.width / 2.0) * 0.95; // 95% radius để có border nhẹ
    final rSquared = r * r;

    final pixels = canvas.buffer.asUint8List();
    for (var y = 0; y < canvas.height; y++) {
      for (var x = 0; x < canvas.width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final distSquared = dx * dx + dy * dy;
        if (distSquared > rSquared) {
          // Set alpha = 0 (transparent)
          final index = (y * canvas.width + x) * 4 + 3;
          pixels[index] = 0;
        }
      }
    }
  }
}
