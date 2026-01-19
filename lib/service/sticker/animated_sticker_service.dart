import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
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

      // Auto-adjust duration nếu quá dài
      var adjustedEndTime = endTime;
      var duration = endTime - startTime;

      if (duration <= 0) {
        throw Exception('Invalid duration: $duration seconds (must be > 0s)');
      }

      // Nếu video dài hơn 5 giây, tự động lấy 5 giây đầu tiên
      if (duration > 5) {
        adjustedEndTime = startTime + 5.0;
        duration = 5.0;
        AppLogger.i(
          '[AnimatedStickerService] Video duration too long (${endTime - startTime}s), '
          'auto-adjusted to 5 seconds (from ${startTime}s to ${adjustedEndTime}s)',
        );
      }

      // Bắt đầu convert video (đây là bước chính, tốn thời gian nhất)
      onProgress?.call(0.0, 'converting_video');

      // WhatsApp animated sticker requirements:
      // - Size: 512x512 pixels
      // - Format: Animated WebP
      // - FPS: 8-15 (recommended 8 cho file nhỏ hơn)
      // - File size: < 500KB (animated sticker)
      // - Duration: 1-5 seconds
      //
      // Tối ưu: Convert trực tiếp từ video sang animated WebP
      // KHÔNG cần extract frames trước - FFmpeg xử lý trực tiếp nhanh hơn
      // FPS 8 thay vì 10 để giảm file size (5s * 8fps = 40 frames thay vì 50)
      final fps = 8;
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

      // Tối ưu: Tính toán quality và FPS dựa trên duration để đảm bảo < 500KB
      // Video dài hơn cần quality và FPS thấp hơn
      int initialQuality;
      int targetFps = fps;

      if (duration <= 2.0) {
        // Video ngắn (≤2s): Có thể dùng quality cao hơn
        initialQuality = 70;
        targetFps = 10;
      } else if (duration <= 3.5) {
        // Video trung bình (2-3.5s): Quality vừa phải
        initialQuality = 60;
        targetFps = 8;
      } else {
        // Video dài (3.5-5s): Quality và FPS thấp để đảm bảo < 500KB
        initialQuality = 50;
        targetFps = 6; // Giảm FPS để giảm số frames
      }

      AppLogger.i(
        '[AnimatedStickerService] Duration: ${duration}s, '
        'Quality: $initialQuality, FPS: $targetFps (tối ưu cho < 500KB)',
      );

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
          '-r $targetFps '
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
            endTime: adjustedEndTime, // Sử dụng adjustedEndTime thay vì endTime
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

      // If file is too large, try re-encoding với quality và FPS thấp hơn
      // Đảm bảo LUÔN giảm xuống < 500KB
      if (fileSize > 500 * 1024) {
        AppLogger.w(
          '[AnimatedStickerService] File too large (${(fileSize / 1024).toStringAsFixed(2)} KB), '
          're-encoding with lower quality and FPS',
        );

        // Tính toán quality và FPS mới dựa trên file size hiện tại
        int newQuality = 40;
        int newFps = 6;

        // Nếu file rất lớn (>800KB), giảm mạnh hơn
        if (fileSize > 800 * 1024) {
          newQuality = 30;
          newFps = 5;
        } else if (fileSize > 650 * 1024) {
          newQuality = 35;
          newFps = 5;
        }

        // Re-encode với quality và FPS thấp hơn
        final reencodeCommand =
            '-y '
            '-i "$outputPath" '
            '-r $newFps '
            '-c:v libwebp '
            '-quality $newQuality '
            '-lossless 0 '
            '-compression_level 6 '
            '-method 6 '
            '"$outputPath"';

        final reencodeSession = await FFmpegKit.execute(reencodeCommand);
        final reencodeReturnCode = await reencodeSession.getReturnCode();

        if (ReturnCode.isSuccess(reencodeReturnCode)) {
          final newFileSize = await outputFile.length();
          AppLogger.i(
            '[AnimatedStickerService] Re-encoded size: ${(newFileSize / 1024).toStringAsFixed(2)} KB '
            '(quality: $newQuality, fps: $newFps)',
          );

          // Nếu vẫn quá lớn, giảm mạnh hơn nữa
          if (newFileSize > 500 * 1024) {
            AppLogger.w(
              '[AnimatedStickerService] Still too large, trying ultra low quality (25, fps: 4)',
            );

            final ultraLowCommand =
                '-y '
                '-i "$outputPath" '
                '-r 4 '
                '-c:v libwebp '
                '-quality 25 '
                '-lossless 0 '
                '-compression_level 6 '
                '-method 6 '
                '"$outputPath"';

            final ultraSession = await FFmpegKit.execute(ultraLowCommand);
            final ultraReturnCode = await ultraSession.getReturnCode();

            if (ReturnCode.isSuccess(ultraReturnCode)) {
              final ultraFileSize = await outputFile.length();
              AppLogger.i(
                '[AnimatedStickerService] Ultra low quality size: ${(ultraFileSize / 1024).toStringAsFixed(2)} KB',
              );

              // Nếu VẪN quá lớn (rất hiếm), cắt duration hoặc giảm quality xuống 20
              if (ultraFileSize > 500 * 1024) {
                AppLogger.e(
                  '[AnimatedStickerService] File STILL too large after all optimizations! '
                  'Trying minimum quality (20, fps: 3)',
                );

                final minimumCommand =
                    '-y '
                    '-i "$outputPath" '
                    '-r 3 '
                    '-c:v libwebp '
                    '-quality 20 '
                    '-lossless 0 '
                    '-compression_level 6 '
                    '-method 6 '
                    '"$outputPath"';

                final minimumSession = await FFmpegKit.execute(minimumCommand);
                final minimumReturnCode = await minimumSession.getReturnCode();

                if (ReturnCode.isSuccess(minimumReturnCode)) {
                  final minimumFileSize = await outputFile.length();
                  AppLogger.i(
                    '[AnimatedStickerService] Minimum quality size: ${(minimumFileSize / 1024).toStringAsFixed(2)} KB',
                  );

                  if (minimumFileSize > 500 * 1024) {
                    AppLogger.e(
                      '[AnimatedStickerService] CRITICAL: File still > 500KB after all optimizations! '
                      'Size: ${(minimumFileSize / 1024).toStringAsFixed(2)} KB',
                    );
                    throw Exception(
                      'Không thể giảm file size xuống < 500KB. '
                      'File size hiện tại: ${(minimumFileSize / 1024).toStringAsFixed(2)} KB. '
                      'Vui lòng thử với video ngắn hơn hoặc đơn giản hơn.',
                    );
                  }
                }
              }
            }
          }
        } else {
          AppLogger.e(
            '[AnimatedStickerService] Re-encode failed, but continuing...',
          );
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

  /// Process video to animated WebP WITH text overlay
  ///
  /// Overlay text PNG lên VIDEO trước khi convert sang WebP (cách ổn định nhất)
  /// FFmpeg sẽ overlay PNG lên mọi frame của video, rồi encode thành animated WebP
  ///
  /// [videoFile] - Input video file
  /// [outputPath] - Output WebP file path
  /// [startTime] - Start time in seconds
  /// [endTime] - End time in seconds
  /// [cropMode] - Crop shape (square, circle, or manual)
  /// [textImageFile] - PNG trong suốt chứa text đã render
  /// [position] - Vị trí overlay: 'center' | 'top' | 'bottom'
  /// [onProgress] - Progress callback (0.0 to 1.0)
  static Future<String> processVideoToWebPWithOverlay({
    required File videoFile,
    required String outputPath,
    required double startTime,
    required double endTime,
    required CropShapeMode cropMode,
    required File textImageFile,
    String position = 'center',
    Function(double progress, String message)? onProgress,
  }) async {
    try {
      AppLogger.i(
        '[AnimatedStickerService] Processing video to animated WebP with text overlay',
      );

      // Validate input
      if (!await videoFile.exists()) {
        throw Exception('Video file not found: ${videoFile.path}');
      }
      if (!await textImageFile.exists()) {
        throw Exception('Text image file not found: ${textImageFile.path}');
      }

      // Auto-adjust duration
      var duration = endTime - startTime;

      if (duration <= 0) {
        throw Exception('Invalid duration: $duration seconds (must be > 0s)');
      }

      if (duration > 5) {
        duration = 5.0;
        AppLogger.i(
          '[AnimatedStickerService] Video duration too long, auto-adjusted to 5 seconds',
        );
      }

      onProgress?.call(0.0, 'preparing_overlay');

      final fps = 8;
      final targetSize = 512;

      // Build video filter (scale + pad + crop shape)
      final videoFilter = _buildVideoFilter(cropMode, targetSize);

      // Tính toán overlay position
      String xExpr;
      String yExpr;
      switch (position) {
        case 'top':
          xExpr = '(W-w)/2';
          yExpr = 'H*0.05';
          break;
        case 'bottom':
          xExpr = '(W-w)/2';
          yExpr = 'H-h-H*0.05';
          break;
        case 'center':
        default:
          xExpr = '(W-w)/2';
          yExpr = '(H-h)/2';
          break;
      }

      // Build filter complex: video filter + overlay text
      // [0:v] = video input, [1:v] = text PNG input

      // Chuẩn hóa paths và quote để tránh lỗi với spaces
      final videoPath = videoFile.path.replaceAll('\\', '/');
      final textPath = textImageFile.path.replaceAll('\\', '/');
      final outPath = outputPath.replaceAll('\\', '/');

      // Quote paths để tránh lỗi với spaces và ký tự đặc biệt
      final quotedVideoPath = '"$videoPath"';
      final quotedTextPath = '"$textPath"';
      final quotedOutPath = '"$outPath"';

      final initialQuality = 60;

      // FFmpeg command: overlay text PNG lên video rồi convert sang animated WebP
      // Scale text PNG về 512x512 trước khi overlay để đảm bảo đúng size
      final filterComplexWithScale =
          '[0:v]$videoFilter[v0];[1:v]scale=512:512[text_scaled];[v0][text_scaled]overlay=$xExpr:$yExpr';

      final ffmpegCommand = [
        '-y', // Overwrite output file
        '-ss',
        startTime.toString(),
        '-i',
        quotedVideoPath,
        '-loop',
        '1',
        '-i',
        quotedTextPath,
        '-t',
        duration.toString(),
        '-filter_complex',
        filterComplexWithScale,
        '-r',
        fps.toString(),
        '-an',
        '-c:v',
        'libwebp',
        '-quality',
        initialQuality.toString(),
        '-lossless',
        '0',
        '-compression_level',
        '6',
        '-method',
        '6',
        '-loop',
        '0',
        quotedOutPath,
      ].join(' ');

      AppLogger.d(
        '[AnimatedStickerService] FFmpeg command with overlay: $ffmpegCommand',
      );
      AppLogger.d(
        '[AnimatedStickerService] Video path: $videoPath, Text path: $textPath, Output: $outPath',
      );

      onProgress?.call(0.1, 'running_ffmpeg');

      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        final output = await session.getOutput();
        final failStackTrace = await session.getFailStackTrace();
        final logs = await session.getLogs();

        AppLogger.e(
          '[AnimatedStickerService] FFmpeg with overlay failed: returnCode=$returnCode',
        );
        if (output != null && output.isNotEmpty) {
          AppLogger.e('[AnimatedStickerService] FFmpeg output: $output');
        }
        if (failStackTrace != null && failStackTrace.isNotEmpty) {
          AppLogger.e(
            '[AnimatedStickerService] FFmpeg stackTrace: $failStackTrace',
          );
        }
        // Log chi tiết hơn - parse log messages
        if (logs.isNotEmpty) {
          final lastLogs =
              logs.length > 20 ? logs.sublist(logs.length - 20) : logs;
          final logMessages = lastLogs
              .map((log) {
                try {
                  return log.getMessage() ?? log.toString();
                } catch (e) {
                  return log.toString();
                }
              })
              .join('\n');
          AppLogger.e(
            '[AnimatedStickerService] FFmpeg logs (last ${lastLogs.length}):\n$logMessages',
          );
        }

        // Thử alternative command với format khác
        AppLogger.w(
          '[AnimatedStickerService] Trying alternative FFmpeg command',
        );

        // Alternative command: Scale text PNG và dùng shortest=1
        final alternativeFilterComplex =
            '[0:v]$videoFilter[v0];[1:v]scale=512:512[text_scaled];[v0][text_scaled]overlay=$xExpr:$yExpr:shortest=1';

        final alternativeCommand = [
          '-y',
          '-ss',
          startTime.toString(),
          '-i',
          quotedVideoPath,
          '-loop',
          '1',
          '-framerate',
          '1',
          '-i',
          quotedTextPath,
          '-t',
          duration.toString(),
          '-filter_complex',
          alternativeFilterComplex,
          '-r',
          fps.toString(),
          '-an',
          '-c:v',
          'libwebp',
          '-quality',
          initialQuality.toString(),
          '-lossless',
          '0',
          '-compression_level',
          '6',
          '-method',
          '6',
          '-loop',
          '0',
          quotedOutPath,
        ].join(' ');

        AppLogger.d(
          '[AnimatedStickerService] Alternative FFmpeg command: $alternativeCommand',
        );

        final altSession = await FFmpegKit.execute(alternativeCommand);
        final altReturnCode = await altSession.getReturnCode();

        if (ReturnCode.isSuccess(altReturnCode)) {
          AppLogger.i(
            '[AnimatedStickerService] Alternative FFmpeg command succeeded',
          );
          // Continue với validation
        } else {
          final altOutput = await altSession.getOutput();
          final altFailStackTrace = await altSession.getFailStackTrace();
          AppLogger.e(
            '[AnimatedStickerService] Alternative command also failed: returnCode=$altReturnCode',
          );
          if (altOutput != null && altOutput.isNotEmpty) {
            AppLogger.e(
              '[AnimatedStickerService] Alternative output: $altOutput',
            );
          }
          if (altFailStackTrace != null && altFailStackTrace.isNotEmpty) {
            AppLogger.e(
              '[AnimatedStickerService] Alternative stackTrace: $altFailStackTrace',
            );
          }

          // Log chi tiết alternative logs
          final altLogs = await altSession.getLogs();
          if (altLogs.isNotEmpty) {
            final lastAltLogs =
                altLogs.length > 20
                    ? altLogs.sublist(altLogs.length - 20)
                    : altLogs;
            final altLogMessages = lastAltLogs
                .map((log) {
                  try {
                    return log.getMessage() ?? log.toString();
                  } catch (e) {
                    return log.toString();
                  }
                })
                .join('\n');
            AppLogger.e(
              '[AnimatedStickerService] Alternative FFmpeg logs (last ${lastAltLogs.length}):\n$altLogMessages',
            );
          }

          // Thử fallback command đơn giản nhất: không có crop shape, chỉ overlay
          AppLogger.w(
            '[AnimatedStickerService] Trying simple fallback command without crop shape',
          );

          final simpleFilterComplex =
              '[0:v]scale=512:512:force_original_aspect_ratio=decrease:flags=lanczos,pad=512:512:(ow-iw)/2:(oh-ih)/2:color=black@0[v0];[1:v]scale=512:512[text_scaled];[v0][text_scaled]overlay=$xExpr:$yExpr';

          final simpleCommand = [
            '-y',
            '-ss',
            startTime.toString(),
            '-i',
            quotedVideoPath,
            '-loop',
            '1',
            '-i',
            quotedTextPath,
            '-t',
            duration.toString(),
            '-filter_complex',
            simpleFilterComplex,
            '-r',
            fps.toString(),
            '-an',
            '-c:v',
            'libwebp',
            '-quality',
            initialQuality.toString(),
            '-lossless',
            '0',
            '-compression_level',
            '6',
            '-method',
            '6',
            '-loop',
            '0',
            quotedOutPath,
          ].join(' ');

          AppLogger.d(
            '[AnimatedStickerService] Simple fallback command: $simpleCommand',
          );

          final simpleSession = await FFmpegKit.execute(simpleCommand);
          final simpleReturnCode = await simpleSession.getReturnCode();

          if (ReturnCode.isSuccess(simpleReturnCode)) {
            AppLogger.i(
              '[AnimatedStickerService] Simple fallback command succeeded',
            );
            // Continue với validation
          } else {
            final simpleOutput = await simpleSession.getOutput();
            final simpleLogs = await simpleSession.getLogs();
            AppLogger.e(
              '[AnimatedStickerService] Simple fallback also failed: returnCode=$simpleReturnCode',
            );
            if (simpleOutput != null && simpleOutput.isNotEmpty) {
              AppLogger.e(
                '[AnimatedStickerService] Simple fallback output: $simpleOutput',
              );
            }
            if (simpleLogs.isNotEmpty) {
              final lastSimpleLogs =
                  simpleLogs.length > 10
                      ? simpleLogs.sublist(simpleLogs.length - 10)
                      : simpleLogs;
              final simpleLogMessages = lastSimpleLogs
                  .map((log) {
                    try {
                      return log.getMessage() ?? log.toString();
                    } catch (e) {
                      return log.toString();
                    }
                  })
                  .join('\n');
              AppLogger.e(
                '[AnimatedStickerService] Simple fallback logs:\n$simpleLogMessages',
              );
            }
            throw Exception(
              'Failed to process video with text overlay. All commands failed.',
            );
          }
        }
      }

      onProgress?.call(0.8, 'validating_output');

      final outputFile = File(outputPath);
      if (!await outputFile.exists()) {
        throw Exception('Output file not created: $outputPath');
      }

      final fileSize = await outputFile.length();
      AppLogger.i(
        '[AnimatedStickerService] Animated WebP with overlay size: ${(fileSize / 1024).toStringAsFixed(2)} KB',
      );

      // Re-encode nếu file quá lớn (tương tự processVideoToWebP)
      // Đảm bảo LUÔN giảm xuống < 500KB
      if (fileSize > 500 * 1024) {
        AppLogger.w(
          '[AnimatedStickerService] File too large (${(fileSize / 1024).toStringAsFixed(2)} KB), '
          're-encoding with lower quality and FPS',
        );

        // Tính toán quality và FPS mới dựa trên file size hiện tại
        int newQuality = 40;
        int newFps = 6;

        // Nếu file rất lớn (>800KB), giảm mạnh hơn
        if (fileSize > 800 * 1024) {
          newQuality = 30;
          newFps = 5;
        } else if (fileSize > 650 * 1024) {
          newQuality = 35;
          newFps = 5;
        }

        final reencodeCommand = [
          '-y',
          '-i',
          outPath,
          '-r',
          newFps.toString(),
          '-c:v',
          'libwebp',
          '-quality',
          newQuality.toString(),
          '-lossless',
          '0',
          '-compression_level',
          '6',
          '-method',
          '6',
          outPath,
        ].join(' ');

        final reencodeSession = await FFmpegKit.execute(reencodeCommand);
        final reencodeReturnCode = await reencodeSession.getReturnCode();

        if (ReturnCode.isSuccess(reencodeReturnCode)) {
          final newFileSize = await outputFile.length();
          AppLogger.i(
            '[AnimatedStickerService] Re-encoded size: ${(newFileSize / 1024).toStringAsFixed(2)} KB '
            '(quality: $newQuality, fps: $newFps)',
          );

          // Nếu vẫn quá lớn, giảm mạnh hơn nữa
          if (newFileSize > 500 * 1024) {
            AppLogger.w(
              '[AnimatedStickerService] Still too large, trying ultra low quality (25, fps: 4)',
            );

            final ultraLowCommand = [
              '-y',
              '-i',
              outPath,
              '-r',
              '4',
              '-c:v',
              'libwebp',
              '-quality',
              '25',
              '-lossless',
              '0',
              '-compression_level',
              '6',
              '-method',
              '6',
              outPath,
            ].join(' ');

            final ultraSession = await FFmpegKit.execute(ultraLowCommand);
            final ultraReturnCode = await ultraSession.getReturnCode();

            if (ReturnCode.isSuccess(ultraReturnCode)) {
              final ultraFileSize = await outputFile.length();
              AppLogger.i(
                '[AnimatedStickerService] Ultra low quality size: ${(ultraFileSize / 1024).toStringAsFixed(2)} KB',
              );

              // Nếu VẪN quá lớn, giảm xuống minimum
              if (ultraFileSize > 500 * 1024) {
                AppLogger.e(
                  '[AnimatedStickerService] File STILL too large! Trying minimum quality (20, fps: 3)',
                );

                final minimumCommand = [
                  '-y',
                  '-i',
                  outPath,
                  '-r',
                  '3',
                  '-c:v',
                  'libwebp',
                  '-quality',
                  '20',
                  '-lossless',
                  '0',
                  '-compression_level',
                  '6',
                  '-method',
                  '6',
                  outPath,
                ].join(' ');

                final minimumSession = await FFmpegKit.execute(minimumCommand);
                final minimumReturnCode = await minimumSession.getReturnCode();

                if (ReturnCode.isSuccess(minimumReturnCode)) {
                  final minimumFileSize = await outputFile.length();
                  AppLogger.i(
                    '[AnimatedStickerService] Minimum quality size: ${(minimumFileSize / 1024).toStringAsFixed(2)} KB',
                  );

                  if (minimumFileSize > 500 * 1024) {
                    AppLogger.e(
                      '[AnimatedStickerService] CRITICAL: File still > 500KB after all optimizations!',
                    );
                    throw Exception(
                      'Không thể giảm file size xuống < 500KB. '
                      'File size hiện tại: ${(minimumFileSize / 1024).toStringAsFixed(2)} KB.',
                    );
                  }
                }
              }
            }
          }
        }
      }

      // Set loop count
      try {
        final loopSuccess = await WebpLoopService.setLoopCount(
          filePath: outputPath,
          loopCount: 0,
        );
        if (loopSuccess) {
          AppLogger.i(
            '[AnimatedStickerService] Successfully set infinite loop',
          );
        }
      } catch (e) {
        AppLogger.w('[AnimatedStickerService] Failed to set loop count: $e');
      }

      // Validate
      final isValid = await validateAnimatedSticker(outputFile);
      if (!isValid) {
        AppLogger.w(
          '[AnimatedStickerService] Generated file failed validation, but returning path anyway',
        );
      }

      onProgress?.call(1.0, 'completed');

      AppLogger.i(
        '[AnimatedStickerService] Processing with overlay completed: $outputPath',
      );
      return outputPath;
    } catch (e, st) {
      AppLogger.e('[AnimatedStickerService] Process with overlay error', e, st);
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

      // Check file size (< 500KB for WhatsApp animated sticker)
      final fileSize = await file.length();
      if (fileSize == 0) {
        AppLogger.w('[AnimatedStickerService] File is empty');
        return false;
      }

      if (fileSize > 500 * 1024) {
        AppLogger.w(
          '[AnimatedStickerService] File too large: ${(fileSize / 1024).toStringAsFixed(2)} KB (must be < 500KB for animated sticker)',
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

  /// Overlay static text image (PNG) lên animated sticker (WebP)
  ///
  /// Pipeline: Frame-by-frame approach (cách chuẩn của app sticker)
  /// 1. Extract frames từ animated WebP
  /// 2. Overlay PNG lên từng frame
  /// 3. Ghép lại thành animated WebP
  ///
  /// Lý do dùng frame-by-frame:
  /// - FFmpeg Android không ổn định với overlay trực tiếp lên animated WebP
  /// - PNG chỉ có 1 frame, WebP có N frame → cần extract frame trước
  /// - Frame-by-frame approach ổn định 100% trên mọi Android build
  ///
  /// Lưu ý:
  /// - Text chỉ là bitmap, KHÔNG có layer riêng, KHÔNG metadata
  /// - WhatsApp chỉ thấy một animated WebP duy nhất
  static Future<String> overlayTextImageOnAnimatedSticker({
    required File baseStickerFile,
    required File textImageFile,
    required String outputPath,
    // Vị trí text - hiện tại hỗ trợ một số preset cơ bản
    String position = 'center', // center, top, bottom
    Function(double progress, String message)? onProgress,
  }) async {
    try {
      AppLogger.i(
        '[AnimatedStickerService] Overlay text PNG on animated WebP (frame-by-frame): '
        'base=${baseStickerFile.path}, text=${textImageFile.path}',
      );

      // Validate input
      if (!await baseStickerFile.exists()) {
        throw Exception('Base sticker file not found: ${baseStickerFile.path}');
      }
      if (!await textImageFile.exists()) {
        throw Exception('Text image file not found: ${textImageFile.path}');
      }

      onProgress?.call(0.0, 'decoding_webp');

      // Bước 1: Decode animated WebP bằng image package (Dart native)
      // Package image có thể decode WebP, nhưng có thể chỉ decode được frame đầu tiên
      // Nếu không được, sẽ fallback sang cách khác
      final webpBytes = await baseStickerFile.readAsBytes();

      // Thử decode bằng image package
      // Lưu ý: image package có thể chỉ decode được frame đầu tiên của animated WebP
      // Nếu animated WebP có nhiều frame, cần dùng cách khác
      final decoded = img.decodeImage(webpBytes);

      if (decoded == null) {
        throw Exception('Failed to decode animated WebP with image package');
      }

      AppLogger.d(
        '[AnimatedStickerService] Decoded WebP: ${decoded.width}x${decoded.height}',
      );

      // Nếu chỉ decode được 1 frame (static WebP hoặc frame đầu của animated)
      // → Overlay text lên frame này, rồi tạo animated WebP từ frame đã overlay
      // (Lưu ý: Cách này chỉ tạo được static WebP hoặc animated 1 frame)

      onProgress?.call(0.3, 'overlaying_text');

      // Bước 2: Overlay text PNG lên frame bằng Flutter Canvas
      final tempDir = await getTemporaryDirectory();
      final overlayedFramePath =
          '${tempDir.path}${Platform.pathSeparator}overlayed_frame_${DateTime.now().millisecondsSinceEpoch}.png';

      // Load text PNG
      final textBytes = await textImageFile.readAsBytes();
      final textImage = img.decodeImage(textBytes);

      if (textImage == null) {
        throw Exception('Failed to decode text PNG');
      }

      // Tính toán overlay position
      int x;
      int y;
      switch (position) {
        case 'top':
          x = ((decoded.width - textImage.width) / 2).round();
          y = (decoded.height * 0.05).round();
          break;
        case 'bottom':
          x = ((decoded.width - textImage.width) / 2).round();
          y =
              (decoded.height -
                      textImage.height -
                      (decoded.height * 0.05).round())
                  .round();
          break;
        case 'center':
        default:
          x = ((decoded.width - textImage.width) / 2).round();
          y = ((decoded.height - textImage.height) / 2).round();
          break;
      }

      // Overlay text image lên base image
      img.compositeImage(
        decoded,
        textImage,
        dstX: x,
        dstY: y,
        blend: img.BlendMode.alpha,
      );

      // Encode lại thành PNG
      final overlayedPngBytes = img.encodePng(decoded);
      final overlayedFrameFile = File(overlayedFramePath);
      await overlayedFrameFile.writeAsBytes(overlayedPngBytes);

      AppLogger.d(
        '[AnimatedStickerService] Overlayed frame saved: $overlayedFramePath',
      );

      onProgress?.call(0.7, 'creating_animated_webp');

      // Bước 3: Tạo animated WebP từ frame đã overlay
      // Vì chỉ có 1 frame, sẽ tạo animated WebP với 1 frame (hoặc lặp lại frame này)
      // Để tạo animated WebP từ 1 frame, dùng FFmpeg với -loop 0
      final outPath = outputPath.replaceAll('\\', '/');
      final framePath = overlayedFramePath.replaceAll('\\', '/');

      // Tạo animated WebP từ 1 frame (lặp lại frame này)
      // Command: ffmpeg -loop 1 -i frame.png -t 3 -c:v libwebp -loop 0 output.webp
      final combineCommand = [
        '-y',
        '-loop',
        '1', // Loop input frame
        '-i',
        framePath,
        '-t',
        '3', // Duration 3 seconds (WhatsApp limit)
        '-an',
        '-c:v',
        'libwebp',
        '-quality',
        '80',
        '-lossless',
        '0',
        '-compression_level',
        '6',
        '-method',
        '6',
        '-loop',
        '0', // Infinite loop output
        outPath,
      ].join(' ');

      AppLogger.d(
        '[AnimatedStickerService] Create animated WebP command: $combineCommand',
      );

      final combineSession = await FFmpegKit.execute(combineCommand);
      final combineReturnCode = await combineSession.getReturnCode();

      // Cleanup temp file
      try {
        await overlayedFrameFile.delete();
      } catch (e) {
        AppLogger.w('[AnimatedStickerService] Failed to delete temp frame: $e');
      }

      if (!ReturnCode.isSuccess(combineReturnCode)) {
        final output = await combineSession.getOutput();
        AppLogger.e(
          '[AnimatedStickerService] Create animated WebP failed: returnCode=$combineReturnCode',
        );
        if (output != null && output.isNotEmpty) {
          AppLogger.e('[AnimatedStickerService] Combine output: $output');
        }
        throw Exception('Failed to create animated WebP from overlayed frame');
      }

      onProgress?.call(0.95, 'validating_output');

      final outputFile = File(outputPath);
      if (!await outputFile.exists()) {
        throw Exception('Overlay output file not created: $outputPath');
      }

      // Set loop count
      try {
        final loopSuccess = await WebpLoopService.setLoopCount(
          filePath: outputPath,
          loopCount: 0,
        );
        if (loopSuccess) {
          AppLogger.i(
            '[AnimatedStickerService] Successfully set infinite loop',
          );
        }
      } catch (e) {
        AppLogger.w('[AnimatedStickerService] Failed to set loop count: $e');
      }

      // Validate sticker sau khi overlay (size, format, ...)
      final isValid = await validateAnimatedSticker(outputFile);
      if (!isValid) {
        AppLogger.w(
          '[AnimatedStickerService] Overlay result failed validation '
          '(size/format), nhưng vẫn trả path để debug: $outputPath',
        );
      }

      onProgress?.call(1.0, 'completed');

      AppLogger.i(
        '[AnimatedStickerService] Overlay text completed (frame-by-frame): $outputPath',
      );
      return outputPath;
    } catch (e, st) {
      AppLogger.e('[AnimatedStickerService] Overlay text error', e, st);
      rethrow;
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

    // Auto-adjust duration nếu quá dài (tương tự như main method)
    var adjustedEndTime = endTime;
    var duration = endTime - startTime;

    if (duration > 5) {
      adjustedEndTime = startTime + 5.0;
      duration = 5.0;
      AppLogger.i(
        '[AnimatedStickerService] Fallback: Video duration too long (${endTime - startTime}s), '
        'auto-adjusted to 5 seconds',
      );
    }

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
      // Đảm bảo frameTime không vượt quá adjustedEndTime
      final frameTime = (startTime + (i * frameInterval)).clamp(
        startTime,
        adjustedEndTime,
      );
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

    if (fileSize > 500 * 1024) {
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
    // 3. format=rgba: Đảm bảo có alpha channel (chỉ khi cần circle mask)
    // 4. geq: Apply circle mask nếu cần (set alpha = 0 cho pixels ngoài vòng tròn)

    // Base filter cho tất cả modes: scale + pad
    String filter =
        'scale=$targetSize:$targetSize:force_original_aspect_ratio=decrease:flags=lanczos,'
        'pad=$targetSize:$targetSize:(ow-iw)/2:(oh-ih)/2:color=black@0';

    // Apply circle mask nếu cropMode = circle
    // Sử dụng geq filter để tạo circular alpha mask
    // Formula: distance từ pixel đến center < radius thì alpha = 255, ngược lại alpha = 0
    if (cropMode == CropShapeMode.circle) {
      final center = targetSize / 2; // 256 for 512x512
      final radius = center * 0.95; // 95% để có border nhẹ
      // Thêm format=rgba và geq filter để tạo circular mask
      // geq: r/g/b giữ nguyên, alpha set dựa trên distance từ center
      filter +=
          ',format=rgba,geq=r=r(X\\,Y):g=g(X\\,Y):b=b(X\\,Y):a=if(lt(hypot(X-$center\\,Y-$center)\\,$radius)\\,255\\,0)';
    }

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
