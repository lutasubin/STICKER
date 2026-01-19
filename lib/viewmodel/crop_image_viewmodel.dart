import 'dart:io';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:sticker_app/data/model/user_sticker_pack.dart';
import 'package:sticker_app/data/repository/image_processing_repository.dart';
import 'package:sticker_app/helper/dialogs/app_dialogs.dart';
import 'package:sticker_app/helper/logger/app_logger.dart';
import 'package:sticker_app/router/router.dart';

/// Crop mode enum
enum CropMode { autoCutout, manual, square, circle, heart }

/// ViewModel for CropImage screen
/// Handles business logic and state management
class CropImageViewModel extends GetxController {
  final ImageProcessingRepository _repository;

  CropImageViewModel({ImageProcessingRepository? repository})
    : _repository = repository ?? ImageProcessingRepository();

  final Rx<UserStickerPack?> pack = Rx<UserStickerPack?>(null);
  final Rx<File?> imageFile = Rx<File?>(null);
  final Rx<String?> replaceStickerUri = Rx<String?>(null);
  final RxBool goToUserPackDetail = false.obs;
  final RxBool isNewPack = false.obs;

  final Rx<CropMode> mode = CropMode.manual.obs;
  final RxBool saving = false.obs;
  final Rx<String?> loadingMessage = Rx<String?>(null);

  final GlobalKey<ExtendedImageEditorState> editorKey =
      GlobalKey<ExtendedImageEditorState>();

  @override
  void onInit() {
    super.onInit();
    _initFromArguments();
  }

  void _initFromArguments() {
    try {
      final args = Get.arguments;
      if (args is! Map) {
        throw Exception('Expected Map arguments, got ${args.runtimeType}');
      }
      pack.value = args['pack'] as UserStickerPack;
      imageFile.value = args['imageFile'] as File;
      replaceStickerUri.value = args['replaceStickerUri'] as String?;
      goToUserPackDetail.value = args['goToUserPackDetail'] == true;
      isNewPack.value = args['isNewPack'] == true;
    } catch (e) {
      AppLogger.e('[CropImageViewModel] Failed to initialize', e);
      AppDialogs.showError('Failed to initialize CropScreen: $e');
      Get.back();
    }
  }

  Future<void> setMode(CropMode newMode) async {
    if (saving.value) return;
    if (mode.value == newMode) return;

    try {
      mode.value = newMode;
      await Future.delayed(Duration.zero);

      if (editorKey.currentState != null) {
        editorKey.currentState?.reset();
      }
    } catch (e) {
      AppLogger.e('[CropImageViewModel] Error changing crop mode', e);
      AppDialogs.showError('Failed to change crop mode: $e');
    }
  }

  Future<void> processAndNavigate() async {
    if (saving.value || imageFile.value == null || pack.value == null) return;
    saving.value = true;

    try {
      AppLogger.i(
        '[CropImageViewModel] Starting crop process, mode=${mode.value}',
      );

      final editorState = editorKey.currentState;
      final cropRect = editorState?.getCropRect();

      Uint8List pngBytes;

      if (mode.value == CropMode.autoCutout) {
        loadingMessage.value = 'processing_ai'.tr;
        await Future.delayed(Duration.zero);
        pngBytes = await _processAICrop();
      } else {
        AppLogger.d('[CropImageViewModel] Processing manual crop in isolate');
        pngBytes = await _repository.processImageInIsolate(
          imagePath: imageFile.value!.path,
          cropRect: cropRect,
          applyCircle: mode.value == CropMode.circle,
          applyHeart: mode.value == CropMode.heart,
        );
      }

      AppLogger.d(
        '[CropImageViewModel] Image processed, size=${pngBytes.length} bytes',
      );

      if (mode.value == CropMode.autoCutout) {
        loadingMessage.value = 'compressing_image'.tr;
        await Future.delayed(Duration.zero);

        final webpBytes = await _repository.encodeWebp(pngBytes);
        final fileUri = await _repository.saveWebpFile(
          webpBytes: webpBytes,
          packId: pack.value!.id,
        );

        AppLogger.i('[CropImageViewModel] File saved: $fileUri');

        Get.toNamed(
          AppRoutes.editSticker,
          arguments: {
            'stickerUri': fileUri,
            'pack': pack.value,
            'replaceStickerUri': replaceStickerUri.value,
            'goToUserPackDetail': goToUserPackDetail.value,
            'isNewPack': isNewPack.value,
          },
        );
      } else {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempUri = await _repository.saveTempPngFile(pngBytes);

        AppLogger.i(
          '[CropImageViewModel] Navigate immediately with temp PNG file',
        );

        Get.toNamed(
          AppRoutes.editSticker,
          arguments: {
            'stickerUri': tempUri,
            'pack': pack.value,
            'replaceStickerUri': replaceStickerUri.value,
            'goToUserPackDetail': goToUserPackDetail.value,
            'isNewPack': isNewPack.value,
            'isTempFile': true,
          },
        );

        _compressAndSaveInBackground(pngBytes, tempUri, timestamp);
      }

      AppLogger.i('[CropImageViewModel] Navigation completed');
    } catch (e, st) {
      AppLogger.e('[CropImageViewModel] Error during crop process', e, st);
      AppDialogs.showError(e.toString());
    } finally {
      saving.value = false;
      loadingMessage.value = null;
    }
  }

  Future<Uint8List> _processAICrop() async {
    if (imageFile.value == null) {
      throw Exception('Image file is null');
    }

    loadingMessage.value = 'removing_background_ai'.tr;
    await Future.delayed(Duration.zero);

    final resultBytes = await _repository.removeBackground(imageFile.value!);

    loadingMessage.value = 'processing_image'.tr;
    await Future.delayed(Duration.zero);

    final decoded = img.decodeImage(resultBytes);
    if (decoded == null) {
      throw Exception('error_cannot_read_image'.tr);
    }

    loadingMessage.value = 'cleaning_image'.tr;
    await Future.delayed(Duration.zero);

    if (decoded.numChannels == 4) {
      final pixels = decoded.buffer.asUint8List();
      for (int i = 3; i < pixels.length; i += 4) {
        if (pixels[i] <= 64) {
          pixels[i] = 0;
        }
      }
    }

    loadingMessage.value = 'creating_sticker'.tr;
    await Future.delayed(Duration.zero);

    final canvas = _renderToStickerCanvas(
      decoded,
      applyCircle: false,
      applyHeart: false,
    );
    return Uint8List.fromList(img.encodePng(canvas));
  }

  img.Image _renderToStickerCanvas(
    img.Image cropped, {
    required bool applyCircle,
    required bool applyHeart,
  }) {
    final rgb =
        cropped.numChannels == 4 ? cropped : cropped.convert(numChannels: 4);
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
      _applyCircleMask(canvas);
    } else if (applyHeart) {
      _applyHeartMask(canvas);
    }

    return canvas;
  }

  void _applyCircleMask(img.Image canvas) {
    final cx = (canvas.width - 1) / 2.0;
    final cy = (canvas.height - 1) / 2.0;
    final r =
        (canvas.width < canvas.height ? canvas.width : canvas.height) / 2.0;
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

  void _applyHeartMask(img.Image canvas) {
    final cx = (canvas.width - 1) / 2.0;
    final cy = (canvas.height - 1) / 2.0;
    final scale =
        ((canvas.width < canvas.height ? canvas.width : canvas.height) / 2.0) *
        0.77;

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

  Future<void> _compressAndSaveInBackground(
    Uint8List pngBytes,
    String tempUri,
    int timestamp,
  ) async {
    try {
      final webpBytes = await _repository.encodeWebp(pngBytes);
      AppLogger.d(
        '[CropImageViewModel] WebP encoded in background, size=${webpBytes.length} bytes',
      );

      await _repository.saveWebpFile(
        webpBytes: webpBytes,
        packId: pack.value!.id,
        timestamp: timestamp,
      );

      AppLogger.i('[CropImageViewModel] WebP saved in background');
    } catch (e, st) {
      AppLogger.e(
        '[CropImageViewModel] Error in background compress/save',
        e,
        st,
      );
    }
  }
}
