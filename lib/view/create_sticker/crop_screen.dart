import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sticker_app/helper/logger/app_logger.dart';
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

enum _CropMode { autoCutout, manual, square, circle, heart }

extension on _CropMode {}

class _CropScreenState extends State<CropScreen> {
  late final UserStickerPack _pack;
  late final File _imageFile;
  String? _replaceStickerUri;
  bool _goToUserPackDetail = false;
  bool _isNewPack = false;

  final GlobalKey<ExtendedImageEditorState> _editorKey =
      GlobalKey<ExtendedImageEditorState>();

  bool _saving = false;
  String? _loadingMessage;

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
        throw Exception(
          'Expected Map arguments, got ${args.runtimeType}: $args',
        );
      }
      _pack = args['pack'] as UserStickerPack;
      _imageFile = args['imageFile'] as File;
      _replaceStickerUri = args['replaceStickerUri'] as String?;
      _goToUserPackDetail = args['goToUserPackDetail'] == true;
      _isNewPack = args['isNewPack'] == true;
      debugPrint(
        'CropScreen initState: pack=${_pack.title}, imageFile=${_imageFile.path}, replaceStickerUri=$_replaceStickerUri, goToUserPackDetail=$_goToUserPackDetail, isNewPack=$_isNewPack',
      );
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
      AppLogger.i('[CropScreen] Starting crop process, mode=$_mode');

      // Show immediate feedback
      if (mounted) {
        setState(() {});
      }

      final editorState = _editorKey.currentState;
      final cropRect = editorState?.getCropRect();

      Uint8List pngBytes;

      if (_mode == _CropMode.autoCutout) {
        // AI crop phải chạy trên main thread (TensorFlow Lite không hoạt động trong isolate)
        AppLogger.d('[CropScreen] Processing AI cutout on main thread');
        if (mounted) {
          setState(() => _loadingMessage = 'Đang xử lý AI...');
        }
        // Yield để UI update
        await Future.delayed(Duration.zero);
        pngBytes = await _processAICrop();
      } else {
        // Manual crop có thể chạy trong isolate
        AppLogger.d('[CropScreen] Processing manual crop in isolate');
        if (mounted) {
          setState(() => _loadingMessage = 'Đang xử lý...');
        }
        pngBytes = await _processImageInIsolate(cropRect);
      }

      if (mounted) {
        setState(() => _loadingMessage = 'Đang nén ảnh...');
      }
      // Yield để UI update
      await Future.delayed(Duration.zero);

      AppLogger.d(
        '[CropScreen] Image processed, size=${pngBytes.length} bytes',
      );

      // Compress và save trên main thread (cần plugin)
      final fileUri = await _compressAndSave(pngBytes);
      AppLogger.i('[CropScreen] File saved: $fileUri');

      // Navigate ngay
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

      AppLogger.i('[CropScreen] Navigation completed');
    } catch (e, st) {
      AppLogger.e('[CropScreen] Error during crop process', e, st);
      if (mounted) {
        AppDialogs.showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _loadingMessage = null;
        });
      }
    }
  }

  /// Process AI crop trên main thread (TensorFlow Lite cần main thread)
  /// Tối ưu bằng cách yield để UI update và giảm processing time
  Future<Uint8List> _processAICrop() async {
    // Bước 1: Remove background (bước nặng nhất)
    if (mounted) {
      setState(() => _loadingMessage = 'Đang xóa nền bằng AI...');
    }
    await Future.delayed(Duration.zero); // Yield để UI update

    final resultBytes = await RemoveBgService.removeBackground(_imageFile);

    // Bước 2: Decode image
    if (mounted) {
      setState(() => _loadingMessage = 'Đang xử lý ảnh...');
    }
    await Future.delayed(Duration.zero);

    final decoded = img.decodeImage(resultBytes);
    if (decoded == null) {
      throw Exception('error_cannot_read_image'.tr);
    }

    // Bước 3: Apply threshold (tối ưu bằng cách xử lý trực tiếp trên buffer)
    if (mounted) {
      setState(() => _loadingMessage = 'Đang làm sạch ảnh...');
    }
    await Future.delayed(Duration.zero);

    if (decoded.numChannels == 4) {
      // Tối ưu: xử lý trực tiếp trên buffer thay vì getPixel/setPixel
      final pixels = decoded.buffer.asUint8List();
      // RGBA format: mỗi pixel 4 bytes [R, G, B, A]
      for (int i = 3; i < pixels.length; i += 4) {
        if (pixels[i] <= 64) {
          pixels[i] = 0; // Set alpha = 0 (transparent)
          // Có thể set RGB = 0 để tiết kiệm memory, nhưng không cần thiết
        }
      }
    }

    // Bước 4: Render to canvas
    if (mounted) {
      setState(() => _loadingMessage = 'Đang tạo sticker...');
    }
    await Future.delayed(Duration.zero);

    final canvas = _renderToStickerCanvas(
      decoded,
      applyCircle: false,
      applyHeart: false,
    );

    return Uint8List.fromList(img.encodePng(canvas));
  }

  /// Render to sticker canvas (helper method)
  img.Image _renderToStickerCanvas(
    img.Image cropped, {
    required bool applyCircle,
    required bool applyHeart,
  }) {
    final rgb =
        cropped.numChannels == 4 ? cropped : cropped.convert(numChannels: 4);
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
    final rSquared = r * r;

    for (var y = 0; y < canvas.height; y++) {
      for (var x = 0; x < canvas.width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final inside = (dx * dx + dy * dy) <= rSquared;
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

  /// Process manual crop trong isolate (không dùng plugin)
  Future<Uint8List> _processImageInIsolate(Rect? cropRect) async {
    return await compute(_processImageIsolate, {
      'imagePath': _imageFile.path,
      'cropRect':
          cropRect != null
              ? {
                'left': cropRect.left,
                'top': cropRect.top,
                'right': cropRect.right,
                'bottom': cropRect.bottom,
              }
              : null,
      'applyCircle': _mode == _CropMode.circle,
      'applyHeart': _mode == _CropMode.heart,
    });
  }

  /// Compress và save trên main thread (cần plugin)
  Future<String> _compressAndSave(Uint8List pngBytes) async {
    // Compress WebP
    final webpBytes = await _encodeWebp(pngBytes);
    AppLogger.d('[CropScreen] WebP encoded, size=${webpBytes.length} bytes');

    // Save file
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory(
      '${dir.path}${Platform.pathSeparator}stickers${Platform.pathSeparator}${_pack.id}',
    );
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    final outFile = File(
      '${outDir.path}${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}.webp',
    );
    await outFile.writeAsBytes(webpBytes, flush: true);

    return Uri.file(outFile.path).toString();
  }

  /// Encode WebP trên main thread (cần plugin)
  Future<Uint8List> _encodeWebp(Uint8List pngBytes) async {
    const maxBytes = 100 * 1024;
    const qualities = <int>[
      95,
      90,
      85,
      80,
      75,
      70,
      65,
      60,
      55,
      50,
      45,
      40,
      35,
      30,
    ];

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
        'error_sticker_too_large'.trParams({
          'sizeKb': (best.length / 1024).toStringAsFixed(1),
        }),
      );
    }

    throw Exception('error_cannot_encode_webp'.tr);
  }

  /// Static function để chạy trong isolate (chỉ xử lý manual crop, trả về PNG bytes)
  static Future<Uint8List> _processImageIsolate(
    Map<String, dynamic> params,
  ) async {
    final imagePath = params['imagePath'] as String;
    final cropRectMap = params['cropRect'] as Map<String, double>?;
    final applyCircle = params['applyCircle'] as bool;
    final applyHeart = params['applyHeart'] as bool;

    final cropRect =
        cropRectMap != null
            ? Rect.fromLTRB(
              cropRectMap['left']!,
              cropRectMap['top']!,
              cropRectMap['right']!,
              cropRectMap['bottom']!,
            )
            : null;

    // Read image
    final file = File(imagePath);
    final inputBytes = await file.readAsBytes();

    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) {
      throw Exception('error_cannot_read_image');
    }

    // Crop
    final img.Image cropped = _cropByRectIsolate(decoded, cropRect);

    // Render to canvas
    final canvas = _renderToStickerCanvasIsolate(
      cropped,
      applyCircle: applyCircle,
      applyHeart: applyHeart,
    );

    // Trả về PNG bytes (WebP sẽ làm trên main thread)
    return Uint8List.fromList(img.encodePng(canvas));
  }

  static img.Image _cropByRectIsolate(img.Image source, Rect? rect) {
    if (rect == null) return source;
    final left = rect.left.round().clamp(0, source.width - 1);
    final top = rect.top.round().clamp(0, source.height - 1);
    final right = rect.right.round().clamp(1, source.width);
    final bottom = rect.bottom.round().clamp(1, source.height);
    final w = math.max(1, right - left);
    final h = math.max(1, bottom - top);
    return img.copyCrop(source, x: left, y: top, width: w, height: h);
  }

  static img.Image _renderToStickerCanvasIsolate(
    img.Image cropped, {
    required bool applyCircle,
    required bool applyHeart,
  }) {
    final rgb =
        cropped.numChannels == 4 ? cropped : cropped.convert(numChannels: 4);

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
      _applyCircleMaskIsolate(canvas);
    } else if (applyHeart) {
      _applyHeartMaskIsolate(canvas);
    }

    return canvas;
  }

  static void _applyCircleMaskIsolate(img.Image canvas) {
    final cx = (canvas.width - 1) / 2.0;
    final cy = (canvas.height - 1) / 2.0;
    final r = math.min(canvas.width, canvas.height) / 2.0;
    final rSquared = r * r;

    for (var y = 0; y < canvas.height; y++) {
      for (var x = 0; x < canvas.width; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final inside = (dx * dx + dy * dy) <= rSquared;
        if (!inside) {
          final p = canvas.getPixel(x, y);
          canvas.setPixelRgba(x, y, p.r, p.g, p.b, 0);
        }
      }
    }
  }

  static void _applyHeartMaskIsolate(img.Image canvas) {
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
        appBar: CropAppBar(onBack: Get.back, onNext: _onNext, saving: _saving),
        body: Stack(
          children: [
            Column(
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
            // Loading overlay khi đang xử lý
            if (_saving && _loadingMessage != null)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00C979),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _loadingMessage!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
              ElevatedButton(onPressed: Get.back, child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }
  }
}
