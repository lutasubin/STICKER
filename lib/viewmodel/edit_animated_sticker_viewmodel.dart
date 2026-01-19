import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sticker_app/controller/animated_sticker/animated_sticker_controller.dart'
    show AnimatedStickerController, CropShapeMode;
import 'package:sticker_app/service/sticker/animated_sticker_service.dart';
import 'package:sticker_app/helper/logger/app_logger.dart';
import 'package:sticker_app/core/constants/app_colors.dart';
import 'package:sticker_app/core/constants/app_durations.dart';
import 'package:sticker_app/data/model/user_sticker_pack.dart';
import 'package:sticker_app/data/repository/user_sticker_pack_repository.dart';
import 'package:sticker_app/data/repository/video_cache_repository.dart';
import 'package:sticker_app/helper/dialogs/app_dialogs.dart';
import 'package:sticker_app/router/router.dart';
import 'package:sticker_app/view/edit_sticker/animated_text_edit_screen.dart';
import 'package:sticker_app/view/edit_sticker/sticker_picker_screen.dart';
import 'package:sticker_app/view/edit_sticker/widgets/sticker_layer_widget.dart';
import 'package:video_player/video_player.dart';

/// ViewModel for EditAnimatedSticker screen
/// Handles business logic and state management
class EditAnimatedStickerViewModel extends GetxController {
  final UserStickerPackRepository _packRepository;
  final VideoCacheRepository _videoCacheRepository;

  EditAnimatedStickerViewModel({
    UserStickerPackRepository? packRepository,
    VideoCacheRepository? videoCacheRepository,
  }) : _packRepository =
           packRepository ?? Get.find<UserStickerPackRepository>(),
       _videoCacheRepository = videoCacheRepository ?? VideoCacheRepository();

  final Rx<File?> videoFile = Rx<File?>(null);
  final Rx<File?> stickerFile = Rx<File?>(null);
  final RxDouble startTime = 0.0.obs;
  final RxDouble endTime = 3.0.obs;
  final Rx<CropShapeMode?> cropMode = Rx<CropShapeMode?>(null);

  final Rx<UserStickerPack?> pack = Rx<UserStickerPack?>(null);
  final Rx<String?> replaceStickerUri = Rx<String?>(null);
  final RxBool goToUserPackDetail = false.obs;
  final RxBool isNewPack = false.obs;

  final Rxn<VideoPlayerController> videoController =
      Rxn<VideoPlayerController>();
  final RxBool isInitialized = false.obs;
  final RxBool isVideoReady = false.obs;
  final RxBool isProcessing = false.obs;

  final RxList<AnimatedTextItem> textItems = <AnimatedTextItem>[].obs;
  final Rx<String?> selectedTextId = Rx<String?>(null);
  final TextEditingController textController = TextEditingController();
  final FocusNode textFocusNode = FocusNode();
  final ValueNotifier<String> textNotifier = ValueNotifier<String>('');

  Timer? textUpdateTimer;

  final RxList<StickerLayer> stickerLayers = <StickerLayer>[].obs;
  final Rx<String?> selectedStickerLayerId = Rx<String?>(null);

  bool ownsAnimatedController = false;
  DateTime? lastVideoListenerCall;
  static const videoListenerThrottleMs = 100;

  AnimatedTextItem? get selectedTextItem {
    if (selectedTextId.value == null) return null;
    try {
      return textItems.firstWhere((item) => item.id == selectedTextId.value);
    } catch (e) {
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();

    if (!Get.isRegistered<AnimatedStickerController>()) {
      Get.put(AnimatedStickerController());
      ownsAnimatedController = true;
    }

    textController.addListener(_onTextChanged);
    initFromArguments();
  }

  @override
  void onClose() {
    textUpdateTimer?.cancel();
    textController.removeListener(_onTextChanged);
    textController.dispose();
    textFocusNode.dispose();
    textNotifier.dispose();

    disposeVideoController();

    if (ownsAnimatedController &&
        Get.isRegistered<AnimatedStickerController>()) {
      Get.delete<AnimatedStickerController>();
    }

    super.onClose();
  }

  void _onTextChanged() {
    final newText = textController.text;
    final selectedItem = selectedTextItem;

    if (selectedItem != null && selectedItem.text != newText) {
      textUpdateTimer?.cancel();
      textUpdateTimer = Timer(const Duration(milliseconds: 100), () {
        final index = textItems.indexWhere(
          (item) => item.id == selectedItem.id,
        );
        if (index != -1) {
          textItems[index] = selectedItem.copyWith(text: newText);
          textNotifier.value = newText;
        }
      });
    }
  }

  void initFromArguments() {
    try {
      final args = Get.arguments;
      if (args is! Map) {
        throw Exception('Expected Map arguments, got ${args.runtimeType}');
      }

      final packArg = args['pack'];
      if (packArg == null || packArg is! UserStickerPack) {
        throw Exception('Pack is required but not provided or invalid');
      }
      pack.value = packArg;
      replaceStickerUri.value = args['replaceStickerUri'] as String?;
      goToUserPackDetail.value = args['goToUserPackDetail'] == true;
      isNewPack.value = args['isNewPack'] == true;

      if (args.containsKey('videoFile')) {
        videoFile.value = File(args['videoFile'] as String);
        startTime.value = (args['startTime'] as double?) ?? 0.0;
        endTime.value = (args['endTime'] as double?) ?? 3.0;
        final cropModeStr = args['cropMode'] as String?;
        if (cropModeStr != null) {
          cropMode.value = CropShapeMode.values.firstWhere(
            (e) => e.name == cropModeStr,
            orElse: () => CropShapeMode.manual,
          );
        } else {
          cropMode.value = CropShapeMode.manual;
        }

        if (!videoFile.value!.existsSync()) {
          throw Exception(
            'Video file does not exist: ${videoFile.value!.path}',
          );
        }
      } else if (args.containsKey('stickerUri')) {
        stickerFile.value = File(
          (args['stickerUri'] as String).replaceFirst('file://', ''),
        );
        if (!stickerFile.value!.existsSync()) {
          throw Exception(
            'Sticker file does not exist: ${stickerFile.value!.path}',
          );
        }
      } else {
        throw Exception(
          'Missing required arguments: need either videoFile or stickerUri',
        );
      }

      isInitialized.value = true;
      initVideoPlayer().catchError((e) {
        debugPrint('initVideoPlayer error: $e');
      });
    } catch (e) {
      Get.snackbar(
        'error_generic_title'.tr,
        'Failed to initialize: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      Future.delayed(const Duration(milliseconds: 500), () => Get.back());
    }
  }

  Future<void> initVideoPlayer() async {
    try {
      if (videoFile.value != null && videoFile.value!.existsSync()) {
        if (videoController.value != null) {
          try {
            videoController.value!.removeListener(_videoListener);
            await videoController.value!.pause();
            await videoController.value!.dispose();
          } catch (e) {
            debugPrint('Error disposing old video controller: $e');
          }
          videoController.value = null;
        }

        final controller = await _videoCacheRepository.getOrCreateController(
          videoPath: videoFile.value!.path,
          startTime: startTime.value,
          endTime: endTime.value,
          onLoop: () {},
        );

        if (controller != null) {
          videoController.value = controller;
          controller.addListener(_videoListener);

          if (startTime.value > 0) {
            await controller.seekTo(
              Duration(milliseconds: (startTime.value * 1000).toInt()),
            );
          }

          await controller.play();
          isVideoReady.value = true;
        }
      } else {
        isVideoReady.value = true;
      }
    } catch (e) {
      debugPrint('initVideoPlayer error: $e');
      isInitialized.value = true;
    }
  }

  void _videoListener() {
    if (videoController.value == null) return;

    final now = DateTime.now();
    if (lastVideoListenerCall != null) {
      final diff = now.difference(lastVideoListenerCall!);
      if (diff.inMilliseconds < videoListenerThrottleMs) {
        return;
      }
    }
    lastVideoListenerCall = now;

    try {
      final value = videoController.value!.value;

      if (value.isPlaying) {
        final currentSeconds = value.position.inSeconds.toDouble();
        if (currentSeconds >= endTime.value) {
          videoController.value!.seekTo(
            Duration(milliseconds: (startTime.value * 1000).toInt()),
          );
        }
      }
    } catch (e) {
      debugPrint('Video listener error: $e');
    }
  }

  void disposeVideoController() {
    if (videoController.value == null || videoFile.value == null) return;

    final controller = videoController.value;
    final videoPath = videoFile.value!.path;
    videoController.value = null;

    Future.microtask(() async {
      try {
        if (controller != null) {
          try {
            controller.removeListener(_videoListener);
            await controller.pause();
          } catch (e) {
            debugPrint('Error removing video listener: $e');
          }
          await _videoCacheRepository.releaseController(videoPath);
        }
      } catch (e) {
        debugPrint('Error in disposeVideoController: $e');
      }
    });
  }

  void pauseVideoForGesture() {
    if (videoController.value != null &&
        videoController.value!.value.isInitialized &&
        videoController.value!.value.isPlaying) {
      videoController.value!.pause();
    }
  }

  void resumeVideoAfterGesture() {
    if (videoController.value != null &&
        videoController.value!.value.isInitialized &&
        !videoController.value!.value.isPlaying) {
      videoController.value!.play();
    }
  }

  Future<File?> renderTextToPng() async {
    if (textItems.isEmpty && stickerLayers.isEmpty) {
      return null;
    }

    if (textItems.isNotEmpty &&
        !textItems.any((item) => item.text.isNotEmpty) &&
        stickerLayers.isEmpty) {
      return null;
    }

    try {
      const size = Size(512, 512);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      for (final stickerLayer in stickerLayers) {
        try {
          final ByteData data = await rootBundle.load(stickerLayer.imagePath);
          final Uint8List bytes = data.buffer.asUint8List();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          final image = frame.image;

          const stickerSizeRatio = 0.3;
          final baseStickerSize = 512.0 * stickerSizeRatio;
          final stickerSize = baseStickerSize * stickerLayer.scale;

          canvas.save();
          canvas.translate(stickerLayer.position.dx, stickerLayer.position.dy);
          canvas.rotate(stickerLayer.rotation);
          canvas.translate(-stickerSize / 2, -stickerSize / 2);

          final srcRect = Rect.fromLTWH(
            0,
            0,
            image.width.toDouble(),
            image.height.toDouble(),
          );
          final dstRect = Rect.fromLTWH(0, 0, stickerSize, stickerSize);

          canvas.drawImageRect(image, srcRect, dstRect, Paint());
          canvas.restore();
        } catch (e) {
          debugPrint('Error rendering sticker layer ${stickerLayer.id}: $e');
        }
      }

      for (final item in textItems) {
        if (item.text.isEmpty) continue;

        if (item.backgroundColor != null) {
          final textSpan = TextSpan(
            text: item.text,
            style: TextStyle(
              color: item.textColor,
              fontSize: item.fontSize * item.scale,
              fontFamily: item.fontFamily,
              fontWeight: item.fontWeight,
            ),
          );

          final textPainter = TextPainter(
            text: textSpan,
            textAlign: item.textAlign,
            textDirection: TextDirection.ltr,
          );

          textPainter.layout();

          final bgRect = Rect.fromLTWH(
            item.position.dx - textPainter.width / 2 - 4,
            item.position.dy - textPainter.height / 2 - 4,
            textPainter.width + 8,
            textPainter.height + 8,
          );

          final bgPaint =
              Paint()
                ..color = item.backgroundColor!
                ..style = PaintingStyle.fill;

          canvas.drawRRect(
            RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
            bgPaint,
          );
        }

        final baseStyle = TextStyle(
          fontSize: item.fontSize * item.scale,
          fontFamily: item.fontFamily,
          fontWeight: item.fontWeight,
          shadows:
              item.shadowColor != null && item.shadowBlur > 0
                  ? [
                    Shadow(
                      color: item.shadowColor!.withOpacity(item.opacity),
                      offset: item.shadowOffset,
                      blurRadius: item.shadowBlur,
                    ),
                  ]
                  : null,
          backgroundColor: item.backgroundColor,
        );

        if (item.strokeColor != null && item.strokeWidth > 0) {
          final strokeSpan = TextSpan(text: item.text, style: baseStyle);
          final strokePainter = TextPainter(
            text: strokeSpan,
            textAlign: item.textAlign,
            textDirection: TextDirection.ltr,
          );
          strokePainter.layout();

          final strokeTextSpan = TextSpan(
            text: item.text,
            style: baseStyle.copyWith(
              foreground:
                  Paint()
                    ..color = item.strokeColor!
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = item.strokeWidth,
            ),
          );

          final strokeTextPainter = TextPainter(
            text: strokeTextSpan,
            textAlign: item.textAlign,
            textDirection: TextDirection.ltr,
          );
          strokeTextPainter.layout();

          strokeTextPainter.paint(
            canvas,
            Offset(
              item.position.dx - strokeTextPainter.width / 2,
              item.position.dy - strokeTextPainter.height / 2,
            ),
          );
        }

        final textSpan = TextSpan(
          text: item.text,
          style: baseStyle.copyWith(color: item.textColor),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textAlign: item.textAlign,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        textPainter.paint(
          canvas,
          Offset(
            item.position.dx - textPainter.width / 2,
            item.position.dy - textPainter.height / 2,
          ),
        );
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      picture.dispose();

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData == null) return null;
      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}${Platform.pathSeparator}text_overlay_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(pngBytes);

      return tempFile;
    } catch (e) {
      debugPrint('Error rendering text to PNG: $e');
      return null;
    }
  }

  Future<void> processAndSave() async {
    if (isProcessing.value || pack.value == null) return;
    isProcessing.value = true;

    try {
      final packDir = Directory(
        '${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}stickers${Platform.pathSeparator}${pack.value!.id}',
      );
      if (!await packDir.exists()) {
        await packDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath =
          '${packDir.path}${Platform.pathSeparator}$timestamp.webp';

      final controller = Get.find<AnimatedStickerController>();

      String? result;
      File? textPngFile;

      if ((textItems.isNotEmpty &&
              textItems.any((item) => item.text.isNotEmpty)) ||
          stickerLayers.isNotEmpty) {
        textPngFile = await renderTextToPng();
      }

      if (videoFile.value != null && cropMode.value != null) {
        if (textPngFile != null &&
            ((textItems.isNotEmpty &&
                    textItems.any((item) => item.text.isNotEmpty)) ||
                stickerLayers.isNotEmpty)) {
          String position = 'center';
          if (textItems.isNotEmpty &&
              textItems.any((item) => item.text.isNotEmpty)) {
            final firstText = textItems.firstWhere(
              (item) => item.text.isNotEmpty,
            );
            if (firstText.position.dy < 100) {
              position = 'top';
            } else if (firstText.position.dy > 400) {
              position = 'bottom';
            }
          } else if (stickerLayers.isNotEmpty) {
            final firstSticker = stickerLayers.first;
            if (firstSticker.position.dy < 100) {
              position = 'top';
            } else if (firstSticker.position.dy > 400) {
              position = 'bottom';
            }
          }

          result = await controller.processVideoToAnimatedStickerWithOverlay(
            videoFile: videoFile.value!,
            outputPath: outputPath,
            startTime: startTime.value,
            endTime: endTime.value,
            cropMode: cropMode.value!,
            textImageFile: textPngFile,
            position: position,
          );
        } else {
          result = await controller.processVideoToAnimatedSticker(
            videoFile: videoFile.value!,
            outputPath: outputPath,
            startTime: startTime.value,
            endTime: endTime.value,
            cropMode: cropMode.value!,
          );
        }
      } else if (stickerFile.value != null) {
        if (textPngFile != null &&
            ((textItems.isNotEmpty &&
                    textItems.any((item) => item.text.isNotEmpty)) ||
                stickerLayers.isNotEmpty)) {
          String position = 'center';
          if (textItems.isNotEmpty &&
              textItems.any((item) => item.text.isNotEmpty)) {
            final firstText = textItems.firstWhere(
              (item) => item.text.isNotEmpty,
            );
            if (firstText.position.dy < 100) {
              position = 'top';
            } else if (firstText.position.dy > 400) {
              position = 'bottom';
            }
          } else if (stickerLayers.isNotEmpty) {
            final firstSticker = stickerLayers.first;
            if (firstSticker.position.dy < 100) {
              position = 'top';
            } else if (firstSticker.position.dy > 400) {
              position = 'bottom';
            }
          }

          result = await controller.overlayTextOnAnimatedSticker(
            baseStickerFile: stickerFile.value!,
            textImageFile: textPngFile,
            outputPath: outputPath,
            position: position,
          );
        } else {
          result = stickerFile.value!.path;
        }
      } else {
        throw Exception('Missing videoFile or stickerFile');
      }

      if (textPngFile != null) {
        try {
          await textPngFile.delete();
        } catch (e) {
          debugPrint('Failed to delete temp file: $e');
        }
      }

      if (result == null) {
        throw Exception('Failed to create sticker');
      }

      // Validate và compress file nếu > 500KB (WhatsApp requirement)
      String finalResult = result;
      try {
        final compressedPath =
            await AnimatedStickerService.compressAnimatedWebPIfNeeded(
              filePath: finalResult,
              maxSizeKB: 500,
            );
        finalResult = compressedPath;
      } catch (e) {
        AppLogger.e(
          '[EditAnimatedStickerViewModel] Failed to compress file: $e',
        );
        // Vẫn tiếp tục với file gốc, nhưng log warning
        Get.snackbar(
          'Cảnh báo',
          'File có thể quá lớn. Vui lòng thử với video ngắn hơn.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }

      final outputUri = Uri.file(finalResult).toString();

      try {
        if (replaceStickerUri.value != null) {
          _packRepository.replaceStickerUri(
            packId: pack.value!.id,
            oldStickerFileUri: replaceStickerUri.value!,
            newStickerFileUri: outputUri,
          );
        } else {
          _packRepository.addStickerUri(
            packId: pack.value!.id,
            stickerFileUri: outputUri,
            isAnimatedSticker: true,
          );
        }
      } catch (e) {
        Get.snackbar(
          'Lỗi',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        isProcessing.value = false;
        return;
      }

      final updatedPack = _packRepository.getById(pack.value!.id);
      if (updatedPack == null) {
        throw Exception('Pack not found after save');
      }

      Get.snackbar(
        'success_title'.tr,
        'success_saved_to_pack'.trParams({'title': updatedPack.title}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );

      await Future.delayed(AppDurations.debounceDelay);

      if (isNewPack.value) {
        Get.offAllNamed(AppRoutes.mySticker);
        Get.toNamed(AppRoutes.userPackDetail, arguments: updatedPack);
      } else if (goToUserPackDetail.value) {
        Get.offAllNamed(AppRoutes.mySticker);
        Get.toNamed(AppRoutes.userPackDetail, arguments: updatedPack);
      } else {
        Get.until((route) => route.settings.name == AppRoutes.mySticker);
      }
    } catch (e) {
      AppDialogs.showError(e.toString());
    } finally {
      isProcessing.value = false;
    }
  }

  void onTextItemTransform(AnimatedTextItem updatedItem) {
    final index = textItems.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      textItems[index] = updatedItem;
    }
  }

  void onTextItemDelete(String itemId) {
    textItems.removeWhere((item) => item.id == itemId);
    if (selectedTextId.value == itemId) {
      selectedTextId.value = textItems.isNotEmpty ? textItems.last.id : null;
    }
  }

  void onTextItemTap(String itemId) {
    selectedTextId.value = itemId;
  }

  void onStickerLayerTransform(StickerLayer updatedLayer) {
    final index = stickerLayers.indexWhere((l) => l.id == updatedLayer.id);
    if (index != -1) {
      stickerLayers[index] = updatedLayer;
    }
  }

  void onStickerLayerDelete(String layerId) {
    stickerLayers.removeWhere((l) => l.id == layerId);
    if (selectedStickerLayerId.value == layerId) {
      selectedStickerLayerId.value =
          stickerLayers.isNotEmpty ? stickerLayers.last.id : null;
    }
  }

  void onStickerLayerTap(String layerId) {
    selectedStickerLayerId.value = layerId;
  }

  Future<void> openTextEditor() async {
    if (videoFile.value == null && stickerFile.value == null) return;

    final result = await Get.to<AnimatedTextItem?>(
      () => AnimatedTextEditScreen(
        videoFile: videoFile.value ?? stickerFile.value!,
        textItems: textItems.toList(),
        selectedTextId: selectedTextId.value,
        onTextItemsChanged: (items) {
          textItems.assignAll(items);
        },
        onSelectedTextIdChanged: (id) {
          selectedTextId.value = id;
        },
        startTime: startTime.value,
        endTime: endTime.value,
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 250),
    );

    if (result != null) {
      final index = textItems.indexWhere((item) => item.id == result.id);
      if (index != -1) {
        textItems[index] = result;
      } else {
        textItems.add(result);
      }
      selectedTextId.value = result.id;
    }
  }

  Future<void> openStickerPicker() async {
    final result = await Get.to<dynamic>(
      () => const StickerPickerScreen(),
      arguments: {
        'stickerUri':
            stickerFile.value?.uri.toString() ??
            videoFile.value?.uri.toString(),
      },
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 250),
    );

    if (result != null) {
      if (result is List<StickerLayer>) {
        stickerLayers.addAll(result);
        if (result.isNotEmpty) {
          selectedStickerLayerId.value = result.last.id;
        }
      } else if (result is StickerLayer) {
        stickerLayers.add(result);
        selectedStickerLayerId.value = result.id;
      }
    }
  }
}
