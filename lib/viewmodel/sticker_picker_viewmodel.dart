import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sticker_app/data/repository/video_cache_repository.dart';
import 'package:sticker_app/service/sticker/sticker_edit_service.dart';
import 'package:sticker_app/view/edit_sticker/widgets/sticker_layer_widget.dart';
import 'package:video_player/video_player.dart';

/// ViewModel for StickerPicker screen
/// Handles business logic and state management
class StickerPickerViewModel extends GetxController {
  final StickerEditService _stickerService;
  final VideoCacheRepository _videoCacheRepository;

  StickerPickerViewModel({
    StickerEditService? stickerService,
    VideoCacheRepository? videoCacheRepository,
  })  : _stickerService = stickerService ?? StickerEditService(),
        _videoCacheRepository =
            videoCacheRepository ?? VideoCacheRepository();

  final Rx<StickerCategory> selectedCategory = StickerCategory.glass.obs;
  final RxList<String> stickers = <String>[].obs;
  final RxBool isLoading = true.obs;
  final Rx<String?> selectedStickerPath = Rx<String?>(null);

  final RxList<StickerLayer> stickerLayers = <StickerLayer>[].obs;
  final Rx<String?> selectedStickerLayerId = Rx<String?>(null);

  final Rx<File?> backgroundImage = Rx<File?>(null);
  final Rxn<VideoPlayerController> videoController = Rxn<VideoPlayerController>();
  final RxBool isLoadingBackground = true.obs;

  String? videoPath;
  double? startTime;
  double? endTime;

  static const double canvasSize = 512.0;

  @override
  void onInit() {
    super.onInit();
    loadBackground();
    loadStickers();
  }

  @override
  void onClose() {
    disposeVideoController();
    super.onClose();
  }

  Future<void> loadBackground() async {
    try {
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null) {
        if (args['videoFile'] != null) {
          videoPath = args['videoFile'] as String;
          startTime = args['startTime'] as double?;
          endTime = args['endTime'] as double?;

          final videoFile = File(videoPath!);
          if (videoFile.existsSync()) {
            final controller = await _videoCacheRepository.getOrCreateController(
              videoPath: videoPath!,
              startTime: startTime,
              endTime: endTime,
              onLoop: () {},
            );

            if (controller != null) {
              videoController.value = controller;

              if (startTime != null && startTime! > 0) {
                await controller.seekTo(
                  Duration(milliseconds: (startTime! * 1000).toInt()),
                );
              }

              await controller.play();
            }
          }
        } else if (args['stickerUri'] != null) {
          final stickerUri = args['stickerUri'] as String;
          backgroundImage.value = File.fromUri(Uri.parse(stickerUri));
        }
      }
    } catch (e) {
      debugPrint('Error loading background: $e');
    } finally {
      isLoadingBackground.value = false;
    }
  }

  void disposeVideoController() {
    if (videoController.value == null || videoPath == null) return;

    final controller = videoController.value;
    final path = videoPath!;
    videoController.value = null;

    Future.microtask(() async {
      try {
        if (controller != null) {
          try {
            await controller.pause();
          } catch (e) {
            debugPrint('Error pausing video controller: $e');
          }
          await _videoCacheRepository.releaseController(path);
        }
      } catch (e) {
        debugPrint('Error in disposeVideoController: $e');
      }
    });
  }

  Future<void> loadStickers() async {
    isLoading.value = true;
    final stickersList = await _stickerService.getStickersByCategory(selectedCategory.value);
    stickers.assignAll(stickersList);
    isLoading.value = false;
  }

  void onCategorySelected(StickerCategory category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    selectedStickerPath.value = null;
    loadStickers();
  }

  Offset getDefaultPositionForCategory(StickerCategory category) {
    switch (category) {
      case StickerCategory.hat:
        return Offset(canvasSize * 0.5, canvasSize * 0.15);
      case StickerCategory.glass:
        return Offset(canvasSize * 0.5, canvasSize * 0.35);
      case StickerCategory.hair:
        return Offset(canvasSize * 0.5, canvasSize * 0.2);
      case StickerCategory.accessory:
        return Offset(canvasSize * 0.5, canvasSize * 0.5);
      case StickerCategory.love:
        return Offset(canvasSize * 0.5, canvasSize * 0.5);
      case StickerCategory.birthday:
        return Offset(canvasSize * 0.5, canvasSize * 0.5);
      case StickerCategory.textStyle:
        return Offset(canvasSize * 0.5, canvasSize * 0.7);
    }
  }

  void onStickerSelected(String stickerPath) {
    selectedStickerPath.value = stickerPath;

    final existingCount = stickerLayers.length;
    final defaultPosition = getDefaultPositionForCategory(selectedCategory.value);
    final offsetX = (existingCount % 3) * 30.0 - 30.0;
    final offsetY = (existingCount ~/ 3) * 30.0;

    final newLayer = StickerLayer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: stickerPath,
      position: Offset(
        defaultPosition.dx + offsetX,
        defaultPosition.dy + offsetY,
      ),
      scale: 1.0,
      rotation: 0.0,
    );

    stickerLayers.add(newLayer);
    selectedStickerLayerId.value = newLayer.id;
  }

  void onStickerTransform(StickerLayer updatedLayer) {
    final index = stickerLayers.indexWhere((l) => l.id == updatedLayer.id);
    if (index != -1) {
      stickerLayers[index] = updatedLayer;
    }
  }

  void onStickerDelete(String layerId) {
    stickerLayers.removeWhere((l) => l.id == layerId);
    if (selectedStickerLayerId.value == layerId) {
      selectedStickerLayerId.value =
          stickerLayers.isNotEmpty ? stickerLayers.last.id : null;
    }
  }

  void onStickerTap(String layerId) {
    selectedStickerLayerId.value = layerId;
  }

  void confirm() {
    Get.back(result: stickerLayers.toList());
  }
}
