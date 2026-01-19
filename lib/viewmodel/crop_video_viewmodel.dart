import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sticker_app/core/constants/app_colors.dart';
import 'package:sticker_app/controller/animated_sticker/animated_sticker_controller.dart';
import 'package:sticker_app/data/model/user_sticker_pack.dart';
import 'package:sticker_app/data/repository/user_sticker_pack_repository.dart';
import 'package:sticker_app/data/repository/video_cache_repository.dart';
import 'package:sticker_app/helper/dialogs/app_dialogs.dart';
import 'package:sticker_app/router/router.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Crop shape modes for animated stickers
enum CropShapeMode {
  manual, // Không có shape, giữ nguyên hình dạng
  square,
  circle,
}

/// ViewModel for CropVideo screen
/// Handles business logic and state management
class CropVideoViewModel extends GetxController {
  final UserStickerPackRepository _packRepository;
  final VideoCacheRepository _videoCacheRepository;

  CropVideoViewModel({
    UserStickerPackRepository? packRepository,
    VideoCacheRepository? videoCacheRepository,
  }) : _packRepository =
           packRepository ?? Get.find<UserStickerPackRepository>(),
       _videoCacheRepository = videoCacheRepository ?? VideoCacheRepository();

  final Rx<UserStickerPack?> pack = Rx<UserStickerPack?>(null);
  final Rx<File?> videoFile = Rx<File?>(null);
  final Rx<Duration> videoDuration = const Duration(seconds: 5).obs;
  final Rx<String?> replaceStickerUri = Rx<String?>(null);
  final RxBool goToUserPackDetail = false.obs;
  final RxBool isNewPack = false.obs;

  final Rxn<VideoPlayerController> videoController =
      Rxn<VideoPlayerController>();
  final RxBool isInitialized = false.obs;
  final RxBool processing = false.obs;

  final Rx<CropShapeMode> cropMode = CropShapeMode.manual.obs;
  final RxDouble startTime = 0.0.obs;
  final RxDouble endTime = 3.0.obs;

  @override
  void onInit() {
    super.onInit();
    Get.put(AnimatedStickerController());
    _initFromArguments();
  }

  @override
  void onClose() {
    debugPrint('[CropVideoViewModel] onClose() called');
    // Release video controller từ cache
    if (videoFile.value != null && videoController.value != null) {
      final path = videoFile.value!.path;
      videoController.value = null;
      Future.microtask(() async {
        await _videoCacheRepository.releaseController(path);
      });
    }

    // Clear thumbnail cache để giải phóng memory
    clearThumbnailCache();

    // Cleanup AnimatedStickerController
    Get.delete<AnimatedStickerController>();

    super.onClose();
    debugPrint('[CropVideoViewModel] onClose() completed');
  }

  void _initFromArguments() {
    try {
      final args = Get.arguments;
      if (args is! Map) {
        throw Exception('Expected Map arguments, got ${args.runtimeType}');
      }

      pack.value = args['pack'] as UserStickerPack?;
      final fileArg = args['videoFile'];
      if (fileArg is File) {
        videoFile.value = fileArg;
      } else if (fileArg is String) {
        videoFile.value = File(fileArg);
      }

      if (videoFile.value == null || !videoFile.value!.existsSync()) {
        throw Exception('Video file does not exist');
      }

      final videoDurationArg = args['videoDuration'];
      if (videoDurationArg is Duration) {
        videoDuration.value = videoDurationArg;
      } else if (videoDurationArg is int) {
        videoDuration.value = Duration(milliseconds: videoDurationArg);
      }

      replaceStickerUri.value = args['replaceStickerUri'] as String?;
      goToUserPackDetail.value = args['goToUserPackDetail'] == true;
      isNewPack.value = args['isNewPack'] == true;

      endTime.value = videoDuration.value.inSeconds.toDouble().clamp(1, 5);

      initVideoPlayer();
    } catch (e) {
      AppDialogs.showError('Failed to initialize: $e');
      Future.delayed(const Duration(milliseconds: 500), () => Get.back());
    }
  }

  Future<void> initVideoPlayer() async {
    if (videoFile.value == null) return;

    try {
      if (!videoFile.value!.existsSync()) {
        throw Exception('Video file does not exist: ${videoFile.value!.path}');
      }

      // Dùng VideoCacheRepository để tái sử dụng controller
      final controller = await _videoCacheRepository.getOrCreateController(
        videoPath: videoFile.value!.path,
        startTime: startTime.value,
        endTime: endTime.value,
        onLoop: () {
          // Loop handler - có thể thêm logic nếu cần
        },
      );

      if (controller == null) {
        throw Exception('Failed to create video controller');
      }

      // Đợi controller initialize nếu chưa sẵn sàng
      if (!controller.value.isInitialized) {
        await controller.initialize();
      }

      if (controller.value.duration.inSeconds > 0) {
        final actualDuration = controller.value.duration;
        if (endTime.value > actualDuration.inSeconds) {
          endTime.value = actualDuration.inSeconds.toDouble().clamp(1, 5);
        }
      }

      videoController.value = controller;
      isInitialized.value = true;

      controller.setLooping(true);
      await controller.play();
    } catch (e) {
      debugPrint('[CropVideoViewModel] Error initializing video: $e');
      AppDialogs.showError('Cannot play video: $e');
      Future.delayed(const Duration(seconds: 2), () => Get.back());
    }
  }

  void setCropMode(CropShapeMode mode) {
    cropMode.value = mode;
  }

  void setEndTime(double time) {
    final duration = time - startTime.value;
    if (duration >= 1 && duration <= 5) {
      endTime.value = time.clamp(0, videoDuration.value.inSeconds.toDouble());
    }
  }

  Future<void> processAndNavigate() async {
    if (processing.value) return;

    final duration = endTime.value - startTime.value;
    if (duration < 1) {
      Get.snackbar(
        'error_generic_title'.tr,
        'animated_duration_too_short'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (duration > 5) {
      Get.snackbar(
        'error_generic_title'.tr,
        'animated_duration_too_long'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    videoController.value?.pause();

    if (pack.value != null) {
      final existingPack = _packRepository.getById(pack.value!.id);
      if (existingPack != null) {
        await navigateToEditScreen(pack.value!, null);
      } else {
        await showSaveStickerDialog();
      }
    } else {
      await showSaveStickerDialog();
    }
  }

  Future<void> navigateToEditScreen(
    UserStickerPack pack,
    CropShapeMode? cropModeOverride,
  ) async {
    if (videoFile.value == null) return;

    final duration = endTime.value - startTime.value;
    if (duration < 1 || duration > 5) {
      Get.snackbar(
        'error_generic_title'.tr,
        duration < 1
            ? 'animated_duration_too_short'.tr
            : 'animated_duration_too_long'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await Get.toNamed(
      AppRoutes.editAnimatedSticker,
      arguments: {
        'videoFile': videoFile.value!.path,
        'startTime': startTime.value,
        'endTime': endTime.value,
        'cropMode': (cropModeOverride ?? cropMode.value).name,
        'pack': pack,
        'replaceStickerUri': replaceStickerUri.value,
        'goToUserPackDetail': goToUserPackDetail.value,
        'isNewPack': isNewPack.value,
        'isTempFile': true,
      },
    );
  }

  Future<void> showSaveStickerDialog() async {
    videoController.value?.pause();

    final allPacks =
        _packRepository.getAll().where((p) => p.isAnimated).toList();
    UserStickerPack? selectedPack = allPacks.isNotEmpty ? allPacks.first : null;

    await Get.bottomSheet<void>(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Save Sticker',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 1),
                      ),
                      child: Text(
                        'Animated',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // New Package button - LUÔN hiển thị để cho phép tạo pack mới
                ElevatedButton.icon(
                  onPressed: () async {
                    Get.back();
                    final packName = await AppDialogs.showPackNameInputDialog(
                      title: 'Create package',
                      initialText: '',
                      hintText: 'Sticker pack name...',
                    );
                    if (packName != null && packName.isNotEmpty) {
                      // Tạo pack mới với isAnimated = true
                      final newPack = _packRepository.createPack(
                        title: packName,
                        isAnimated: true,
                      );
                      // Navigate đến edit screen để add text trên video
                      await navigateToEditScreen(newPack, null);
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'New Package',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // List of existing packs
                if (allPacks.isNotEmpty) ...[
                  const Text(
                    'Select package:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: allPacks.length,
                      itemBuilder: (context, index) {
                        final pack = allPacks[index];
                        return RadioListTile<UserStickerPack>(
                          title: Text(pack.title),
                          subtitle: Text(
                            '${pack.stickerFileUris.length} sticker${pack.stickerFileUris.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          value: pack,
                          groupValue: selectedPack,
                          onChanged: (value) {
                            setDialogState(() => selectedPack = value);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Save button
                  ElevatedButton(
                    onPressed: () async {
                      Get.back();
                      final packToSave = selectedPack ?? allPacks.first;
                      await navigateToEditScreen(packToSave, null);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Lưu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No packages yet. Create a new one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      isScrollControlled: true,
    );
  }

  // Cache để tránh generate thumbnail nhiều lần
  final Map<int, Future<Uint8List?>> _thumbnailCache = {};

  // Giới hạn số lượng thumbnail generation đồng thời
  static const int _maxConcurrentThumbnails = 3;
  int _activeThumbnailGenerations = 0;

  Future<Uint8List?> generateThumbnail(int index) async {
    if (videoFile.value == null) return null;

    // Kiểm tra cache
    if (_thumbnailCache.containsKey(index)) {
      return await _thumbnailCache[index];
    }

    // Giới hạn số lượng generation đồng thời
    while (_activeThumbnailGenerations >= _maxConcurrentThumbnails) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      _activeThumbnailGenerations++;
      final position = (videoDuration.value.inMilliseconds / 7 * index).toInt();

      // Tạo future và cache
      final future = VideoThumbnail.thumbnailData(
        video: videoFile.value!.path,
        imageFormat: ImageFormat.PNG,
        timeMs: position,
        quality: 30, // Giảm quality từ 50 xuống 30 để tiết kiệm memory
      );

      _thumbnailCache[index] = future;
      final thumbnailData = await future;
      return thumbnailData;
    } catch (e) {
      debugPrint('[CropVideoViewModel] Error generating thumbnail $index: $e');
      return null;
    } finally {
      _activeThumbnailGenerations--;
    }
  }

  void clearThumbnailCache() {
    _thumbnailCache.clear();
  }

  double get selectedDuration => endTime.value - startTime.value;
}
