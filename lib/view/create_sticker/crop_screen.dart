import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sticker_app/service/remove_bg_service.dart';
import 'package:get/get.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:sticker_app/model/user_sticker_pack.dart';
import 'package:sticker_app/router/router.dart';
import 'package:sticker_app/helper/dialogs/app_dialogs.dart';
import 'package:sticker_app/view/create_sticker/widgets/crop_app_bar.dart';
import 'package:sticker_app/view/create_sticker/widgets/crop_editor.dart';
import 'package:sticker_app/view/create_sticker/widgets/crop_mode_selector.dart';
import 'package:sticker_app/view/create_sticker/widgets/crop_painters.dart';

class CropScreen extends StatefulWidget {
  const CropScreen({super.key});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

enum _CropMode {
  autoCutout,
  manual,
  square,
  circle,
  heart,
}

extension on _CropMode {
}

class _CropScreenState extends State<CropScreen> {
  late final UserStickerPack _pack;
  late final File _imageFile;
  String? _replaceStickerUri;
  bool _goToUserPackDetail = false;
  bool _isNewPack = false;

  final GlobalKey<ExtendedImageEditorState> _editorKey =
      GlobalKey<ExtendedImageEditorState>();

  bool _saving = false;

  _CropMode _mode = _CropMode.manual;

  Future<void> _setMode(_CropMode mode) async {
    if (_saving) return;
    if (_mode == mode) return;

    try {
      setState(() => _mode = mode);

      // Force editor to apply new aspect ratio by resetting after rebuild.
      await Future<void>.delayed(Duration.zero);
      
      if (_editorKey.currentState != null) {
        _editorKey.currentState?.reset();
      } else {
        debugPrint('Warning: editorKey.currentState is null in _setMode');
      }
    } catch (e, st) {
      debugPrint('_setMode error: $e');
      debugPrint(st.toString());
      if (mounted) {
        AppDialogs.showError('Failed to change crop mode: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    try {
      final args = Get.arguments;
      if (args is! Map) {
        throw Exception('Expected Map arguments, got ${args.runtimeType}: $args');
      }
      _pack = args['pack'] as UserStickerPack;
      _imageFile = args['imageFile'] as File;
      _replaceStickerUri = args['replaceStickerUri'] as String?;
      _goToUserPackDetail = args['goToUserPackDetail'] == true;
      _isNewPack = args['isNewPack'] == true;
      debugPrint('CropScreen initState: pack=${_pack.title}, imageFile=${_imageFile.path}, replaceStickerUri=$_replaceStickerUri, goToUserPackDetail=$_goToUserPackDetail, isNewPack=$_isNewPack');
    } catch (e, st) {
      debugPrint('CropScreen initState error: $e');
      debugPrint(st.toString());
      if (mounted) {
        AppDialogs.showError('Failed to initialize CropScreen: $e');
        Get.back();
      }
    }
  }

  Future<void> _onNext() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      debugPrint('_onNext: starting, mode=$_mode');
      
      // Show immediate feedback
      if (mounted) {
        setState(() {});
      }
      
      // Small delay to allow UI to update
      await Future.delayed(const Duration(milliseconds: 100));
      
      final editorState = _editorKey.currentState;
      final cropRect = editorState?.getCropRect();
      debugPrint('_onNext: cropRect=$cropRect');

      final Uint8List inputBytes;
      if (_mode == _CropMode.autoCutout) {
        debugPrint('_onNext: using auto cutout');
        inputBytes = await _removeBgCutout();
      } else {
        debugPrint('_onNext: reading image file');
        inputBytes = await _imageFile.readAsBytes();
      }
      debugPrint('_onNext: inputBytes length=${inputBytes.length}');

      final decoded = img.decodeImage(inputBytes);
      if (decoded == null) {
        throw Exception('error_cannot_read_image'.tr);
      }
      debugPrint('_onNext: decoded image ${decoded.width}x${decoded.height}');

      final img.Image cropped =
          _mode == _CropMode.autoCutout ? decoded : _cropByRect(decoded, cropRect);
      debugPrint('_onNext: cropped image ${cropped.width}x${cropped.height}');

      debugPrint('_onNext: rendering to sticker canvas');
      final canvas = _renderToStickerCanvas(
        cropped,
        applyCircle: _mode == _CropMode.circle,
        applyHeart: _mode == _CropMode.heart,
      );
      debugPrint('_onNext: canvas rendered ${canvas.width}x${canvas.height}');

      debugPrint('_onNext: encoding webp');
      final webpBytes = await _encodeWebp(canvas);
      debugPrint('_onNext: webp encoded size=${webpBytes.length}');

      final dir = await getApplicationDocumentsDirectory();
      final outDir = Directory('${dir.path}${Platform.pathSeparator}stickers${Platform.pathSeparator}${_pack.id}');
      if (!await outDir.exists()) {
        await outDir.create(recursive: true);
      }

      final outFile = File(
        '${outDir.path}${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}.webp',
      );
      await outFile.writeAsBytes(webpBytes, flush: true);
      debugPrint('_onNext: file written to ${outFile.path}');

      final fileUri = Uri.file(outFile.path).toString();

      debugPrint('_onNext: navigating to edit sticker');
      
      // Smooth transition with delay
      await Future.delayed(const Duration(milliseconds: 200));
      
      Get.toNamed(
        AppRoutes.editSticker,
        arguments: {
          'stickerUri': fileUri,
          'pack': _pack,
          'replaceStickerUri': _replaceStickerUri,
          'goToUserPackDetail': _goToUserPackDetail,
          'isNewPack': _isNewPack,
        },
      );
      debugPrint('_onNext: navigation completed');
    } catch (e, st) {
      debugPrint('_onNext ERROR: $e');
      debugPrint(st.toString());
      if (mounted) {
        AppDialogs.showError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  img.Image _cropByRect(img.Image source, Rect? rect) {
    if (rect == null) return source;
    final left = rect.left.round().clamp(0, source.width - 1);
    final top = rect.top.round().clamp(0, source.height - 1);
    final right = rect.right.round().clamp(1, source.width);
    final bottom = rect.bottom.round().clamp(1, source.height);
    final w = math.max(1, right - left);
    final h = math.max(1, bottom - top);
    return img.copyCrop(source, x: left, y: top, width: w, height: h);
  }

  img.Image _renderToStickerCanvas(
    img.Image cropped, {
    required bool applyCircle,
    required bool applyHeart,
  }) {
    final rgb = cropped.numChannels == 4
        ? cropped
        : cropped.convert(numChannels: 4);

    final scale = math.min(512 / rgb.width, 512 / rgb.height);
    final newW = math.max(1, (rgb.width * scale).round());
    final newH = math.max(1, (rgb.height * scale).round());
    final resized = img.copyResize(rgb, width: newW, height: newH);

    final canvas = img.Image(width: 512, height: 512, numChannels: 4);
    img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

    final dx = ((512 - resized.width) / 2).round();
    final dy = ((512 - resized.height) / 2).round();
    img.compositeImage(canvas, resized, dstX: dx, dstY: dy);

    if (applyCircle) {
      _applyCircleMask(canvas);
    } else if (applyHeart) {
      _applyHeartMask(canvas);
    }

    return canvas;
  }

  void _applyCircleMask(img.Image canvas) {
    final cx = (canvas.width - 1) / 2.0;
    final cy = (canvas.height - 1) / 2.0;
    final r = math.min(canvas.width, canvas.height) / 2.0;

    for (var y = 0; y < canvas.height; y++) {
      for (var x = 0; x < canvas.width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final inside = (dx * dx + dy * dy) <= (r * r);
        if (!inside) {
          final p = canvas.getPixel(x, y);
          canvas.setPixelRgba(x, y, p.r, p.g, p.b, 0);
        }
      }
    }
  }

  void _applyHeartMask(img.Image canvas) {
    final cx = (canvas.width - 1) / 2.0;
    final cy = (canvas.height - 1) / 2.0;
    final scale = (math.min(canvas.width, canvas.height) / 2.0) * 0.77;

    for (var y = 0; y < canvas.height; y++) {
      for (var x = 0; x < canvas.width; x++) {
        final nx = (x - cx) / scale;
        final ny = (y - cy) / scale;

        final yy = -ny;
        final a = nx * nx + yy * yy - 1;
        final f = a * a * a - (nx * nx) * (yy * yy * yy);
        final inside = f <= 0;

        if (!inside) {
          final p = canvas.getPixel(x, y);
          canvas.setPixelRgba(x, y, p.r, p.g, p.b, 0);
        }
      }
    }
  }

  Future<Uint8List> _encodeWebp(img.Image image) async {
    // Encode PNG first to preserve alpha, then compress to WebP with quality loop.
    final pngBytes = Uint8List.fromList(img.encodePng(image));
    const maxBytes = 100 * 1024;

    // Try a descending set of qualities.
    const qualities = <int>[95, 90, 85, 80, 75, 70, 65, 60, 55, 50, 45, 40, 35, 30];

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
      debugPrint('⚠️ Không đạt <100KB. Best=${best.length} bytes');
      throw Exception(
        'error_sticker_too_large'.trParams({
          'sizeKb': (best.length / 1024).toStringAsFixed(1),
        }),
      );
    }

    throw Exception('error_cannot_encode_webp'.tr);
  }

  img.Image _unsharpMask(img.Image src, {double amount = 0.5, int radius = 1, int threshold = 0}) {
    final blurred = img.gaussianBlur(src, radius: radius);
    final result = img.Image(width: src.width, height: src.height, numChannels: src.numChannels);
    for (int y = 0; y < src.height; ++y) {
      for (int x = 0; x < src.width; ++x) {
        final srcPixel = src.getPixel(x, y);
        final blurPixel = blurred.getPixel(x, y);
        final diff = (srcPixel.r - blurPixel.r).abs() +
                    (srcPixel.g - blurPixel.g).abs() +
                    (srcPixel.b - blurPixel.b).abs();
        if (diff > threshold * 3) {
          final r = (srcPixel.r + (srcPixel.r - blurPixel.r) * amount).clamp(0, 255).toInt();
          final g = (srcPixel.g + (srcPixel.g - blurPixel.g) * amount).clamp(0, 255).toInt();
          final b = (srcPixel.b + (srcPixel.b - blurPixel.b) * amount).clamp(0, 255).toInt();
          final a = srcPixel.a;
          result.setPixelRgba(x, y, r, g, b, a);
        } else {
          result.setPixel(x, y, srcPixel);
        }
      }
    }
    return result;
  }

  Future<Uint8List> _removeBgCutout() async {
  // Read original image
  final originalBytes = await _imageFile.readAsBytes();
  final original = img.decodeImage(originalBytes);
  if (original == null) throw Exception('Cannot decode image');

  // Upscale to at least 1536px on the longer side for better ML Kit quality
  const targetLongSide = 1536;
  final scale = targetLongSide / math.max(original.width, original.height);
  final upscaled = scale > 1
      ? img.copyResize(original, width: (original.width * scale).round(), height: (original.height * scale).round(), interpolation: img.Interpolation.average)
      : original;

  // Write upscaled to temp file
  final tempDir = await getTemporaryDirectory();
  final tempFile = File('${tempDir.path}/upscaled_${DateTime.now().millisecondsSinceEpoch}.png');
  await tempFile.writeAsBytes(img.encodePng(upscaled));

  // Call background remover using remove.bg API
  final resultBytes = await RemoveBgService.removeBackground(tempFile);

  // Clean up temp file
  await tempFile.delete();

  // Optional: apply slight edge smoothing to mask (simple blur on alpha channel)
  final result = img.decodeImage(resultBytes);
  if (result != null && result.numChannels == 4) {
    // Apply threshold to mask: keep only high-confidence foreground (alpha > 64)
    for (int y = 0; y < result.height; ++y) {
      for (int x = 0; x < result.width; ++x) {
        final pixel = result.getPixel(x, y);
        if (pixel.a <= 64) {
          result.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, 0);
        }
      }
    }
    // Very light blur on alpha to soften edges
    final blurred = img.gaussianBlur(result, radius: 0);
    // Apply unsharp mask to sharpen edges (optional)
    final sharpened = _unsharpMask(blurred);
    return Uint8List.fromList(img.encodePng(sharpened));
  }

  return resultBytes;
}

  @override
  Widget build(BuildContext context) {
    try {
      final cropAspectRatio = switch (_mode) {
        _CropMode.square => 1.0,
        _CropMode.circle => 1.0,
        _CropMode.heart => 1.0,
        _CropMode.manual => null,
        _CropMode.autoCutout => null,
      };
      
      EditorCropLayerPainter? cropLayerPainter;
      try {
        cropLayerPainter = switch (_mode) {
          _CropMode.circle => CircleCropLayerPainter(),
          _CropMode.heart => HeartCropLayerPainter(),
          _ => const EditorCropLayerPainter(),
        };
      } catch (e) {
        debugPrint('Error creating crop layer painter: $e');
        cropLayerPainter = const EditorCropLayerPainter();
      }

      return Scaffold(
        appBar: CropAppBar(
          onBack: Get.back,
          onNext: _onNext,
          saving: _saving,
        ),
        body: Column(
          children: [
            Expanded(
              child: CropEditor(
                imageFile: _imageFile,
                modeKey: _mode,
                editorKey: _editorKey,
                cropAspectRatio: cropAspectRatio,
                cropLayerPainter: cropLayerPainter,
              ),
            ),
            CropModeSelector(
              items: [
                CropModeItemData(
                  iconAsset: 'assets/icons/AI_cut.svg',
                  label: 'crop_mode_auto'.tr,
                  selected: _mode == _CropMode.autoCutout,
                  onTap: () => _setMode(_CropMode.autoCutout),
                ),
                CropModeItemData(
                  iconAsset: 'assets/icons/Crop.svg',
                  label: 'crop_mode_manual'.tr,
                  selected: _mode == _CropMode.manual,
                  onTap: () => _setMode(_CropMode.manual),
                ),
                CropModeItemData(
                  iconAsset: 'assets/icons/square.svg',
                  label: 'crop_mode_square'.tr,
                  selected: _mode == _CropMode.square,
                  onTap: () => _setMode(_CropMode.square),
                ),
                CropModeItemData(
                  iconAsset: 'assets/icons/Circle.svg',
                  label: 'crop_mode_circle'.tr,
                  selected: _mode == _CropMode.circle,
                  onTap: () => _setMode(_CropMode.circle),
                ),
                CropModeItemData(
                  iconAsset: 'assets/icons/heart.svg',
                  label: 'crop_mode_heart'.tr,
                  selected: _mode == _CropMode.heart,
                  onTap: () => _setMode(_CropMode.heart),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('CropScreen build error: $e');
      debugPrint(st.toString());
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Crop Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('An error occurred while loading the crop screen.'),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: Get.back,
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
