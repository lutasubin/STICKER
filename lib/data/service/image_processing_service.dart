import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:sticker_app/helper/logger/app_logger.dart';

/// Helper class for crop rectangle
class _CropRect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  _CropRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });
}

/// Service layer: Low-level image processing operations
/// Pure data access - no business logic
class ImageProcessingService {
  const ImageProcessingService();

  /// Process image in isolate for manual crop
  static Future<Uint8List> processImageIsolate(Map<String, dynamic> params) async {
    final imagePath = params['imagePath'] as String;
    final cropRectMap = params['cropRect'] as Map<String, double>?;
    final applyCircle = params['applyCircle'] as bool;
    final applyHeart = params['applyHeart'] as bool;

    final cropRect = cropRectMap != null
        ? _CropRect(
            left: cropRectMap['left']!,
            top: cropRectMap['top']!,
            right: cropRectMap['right']!,
            bottom: cropRectMap['bottom']!,
          )
        : null;

    final file = File(imagePath);
    final inputBytes = await file.readAsBytes();

    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) {
      throw Exception('error_cannot_read_image');
    }

    final cropped = _cropByRectIsolate(decoded, cropRect);
    final canvas = _renderToStickerCanvasIsolate(
      cropped,
      applyCircle: applyCircle,
      applyHeart: applyHeart,
    );

    return Uint8List.fromList(img.encodePng(canvas));
  }

  static img.Image _cropByRectIsolate(img.Image source, _CropRect? rect) {
    if (rect == null) return source;
    final left = rect.left.round().clamp(0, source.width - 1);
    final top = rect.top.round().clamp(0, source.height - 1);
    final right = rect.right.round().clamp(1, source.width);
    final bottom = rect.bottom.round().clamp(1, source.height);
    final w = (right - left).clamp(1, source.width);
    final h = (bottom - top).clamp(1, source.height);
    return img.copyCrop(source, x: left, y: top, width: w, height: h);
  }

  static img.Image _renderToStickerCanvasIsolate(
    img.Image cropped, {
    required bool applyCircle,
    required bool applyHeart,
  }) {
    final rgb = cropped.numChannels == 4 ? cropped : cropped.convert(numChannels: 4);
    final scale = (512 / rgb.width).clamp(0.0, 512 / rgb.height);
    final newW = (rgb.width * scale).round().clamp(1, 512);
    final newH = (rgb.height * scale).round().clamp(1, 512);
    final resized = img.copyResize(rgb, width: newW, height: newH);

    final canvas = img.Image(width: 512, height: 512, numChannels: 4);
    img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

    final dx = ((512 - resized.width) / 2).round();
    final dy = ((512 - resized.height) / 2).round();
    img.compositeImage(canvas, resized, dstX: dx, dstY: dy);

    if (applyCircle) {
      _applyCircleMaskIsolate(canvas);
    } else if (applyHeart) {
      _applyHeartMaskIsolate(canvas);
    }

    return canvas;
  }

  static void _applyCircleMaskIsolate(img.Image canvas) {
    final cx = (canvas.width - 1) / 2.0;
    final cy = (canvas.height - 1) / 2.0;
    final r = (canvas.width < canvas.height ? canvas.width : canvas.height) / 2.0;
    final rSquared = r * r;

    final pixels = canvas.buffer.asUint8List();
    for (var y = 0; y < canvas.height; y++) {
      for (var x = 0; x < canvas.width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final inside = (dx * dx + dy * dy) <= rSquared;
        if (!inside) {
          final index = (y * canvas.width + x) * 4 + 3;
          pixels[index] = 0;
        }
      }
    }
  }

  static void _applyHeartMaskIsolate(img.Image canvas) {
    final cx = (canvas.width - 1) / 2.0;
    final cy = (canvas.height - 1) / 2.0;
    final scale = ((canvas.width < canvas.height ? canvas.width : canvas.height) / 2.0) * 0.77;

    final pixels = canvas.buffer.asUint8List();
    for (var y = 0; y < canvas.height; y++) {
      for (var x = 0; x < canvas.width; x++) {
        final nx = (x - cx) / scale;
        final ny = (y - cy) / scale;
        final yy = -ny;
        final a = nx * nx + yy * yy - 1;
        final f = a * a * a - (nx * nx) * (yy * yy * yy);
        final inside = f <= 0;

        if (!inside) {
          final index = (y * canvas.width + x) * 4 + 3;
          pixels[index] = 0;
        }
      }
    }
  }

  /// Encode PNG to WebP with compression
  Future<Uint8List> encodeWebp(Uint8List pngBytes) async {
    const maxBytes = 100 * 1024;
    const qualities = <int>[90, 80, 70, 60, 50, 40, 30];

    Uint8List? best;
    for (final q in qualities) {
      final out = await FlutterImageCompress.compressWithList(
        pngBytes,
        format: CompressFormat.webp,
        quality: q,
        keepExif: false,
      );
      if (best == null || out.length < best.length) {
        best = Uint8List.fromList(out);
      }
      if (out.length <= maxBytes) {
        return Uint8List.fromList(out);
      }
    }

    if (best != null) {
      throw Exception(
        'error_sticker_too_large',
      );
    }

    throw Exception('error_cannot_encode_webp');
  }

  /// Save WebP file to disk
  Future<String> saveWebpFile({
    required Uint8List webpBytes,
    required String packId,
    int? timestamp,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory(
      '${dir.path}${Platform.pathSeparator}stickers${Platform.pathSeparator}$packId',
    );
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    final fileName = timestamp != null
        ? '$timestamp.webp'
        : '${DateTime.now().millisecondsSinceEpoch}.webp';
    final outFile = File('${outDir.path}${Platform.pathSeparator}$fileName');
    await outFile.writeAsBytes(webpBytes, flush: true);

    AppLogger.d('[ImageProcessingService] WebP saved: ${outFile.path}');
    return Uri.file(outFile.path).toString();
  }

  /// Save temporary PNG file
  Future<String> saveTempPngFile(Uint8List pngBytes) async {
    final tempDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempFile = File(
      '${tempDir.path}${Platform.pathSeparator}temp_$timestamp.png',
    );
    await tempFile.writeAsBytes(pngBytes, flush: true);
    return Uri.file(tempFile.path).toString();
  }
}
