import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sticker_app/data/model/user_sticker_pack.dart';
import 'package:sticker_app/router/router.dart';

/// ViewModel for SelectVideo screen
/// Handles business logic and state management
class SelectVideoViewModel extends GetxController {
  final Rx<UserStickerPack?> pack = Rx<UserStickerPack?>(null);
  final Rx<String?> replaceStickerUri = Rx<String?>(null);
  final RxBool goToUserPackDetail = false.obs;
  final RxBool isNewPack = false.obs;

  final RxList<AssetEntity> assets = <AssetEntity>[].obs;
  final RxBool loading = true.obs;
  final RxBool hasPermission = false.obs;
  final Rx<AssetEntity?> selectedAsset = Rx<AssetEntity?>(null);

  final Map<String, Future<Uint8List?>> _thumbFutures = {};

  @override
  void onInit() {
    super.onInit();
    _initFromArguments();
    loadVideos();
  }

  void _initFromArguments() {
    final args = Get.arguments;
    if (args is Map) {
      pack.value = args['pack'] as UserStickerPack?;
      replaceStickerUri.value = args['replaceStickerUri'] as String?;
      goToUserPackDetail.value = args['goToUserPackDetail'] == true;
      isNewPack.value = args['isNewPack'] == true;
    } else if (args is UserStickerPack) {
      pack.value = args;
    }
  }

  Future<void> loadVideos() async {
    loading.value = true;

    try {
      final storage =
          Platform.isAndroid ? await Permission.storage.request() : null;
      debugPrint(
        '[SelectVideoViewModel] Storage permission: granted=${storage?.isGranted}',
      );

      final permission = await PhotoManager.requestPermissionExtend();

      debugPrint(
        '[SelectVideoViewModel] Photo permission: isAuth=${permission.isAuth}, isLimited=${permission.isLimited}',
      );

      final hasAccess =
          permission.isAuth ||
          permission.isLimited ||
          (storage?.isGranted ?? false);

      if (!hasAccess) {
        hasPermission.value = false;
        assets.clear();
        _thumbFutures.clear();
        return;
      }

      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        onlyAll: true,
      );

      debugPrint('[SelectVideoViewModel] Found ${paths.length} video path(s)');

      final recent = paths.isNotEmpty ? paths.first : null;
      final list =
          recent == null
              ? <AssetEntity>[]
              : await recent.getAssetListPaged(page: 0, size: 200);

      debugPrint('[SelectVideoViewModel] Loaded video assets: ${list.length}');

      final videosOnly = list.where((e) => e.type == AssetType.video).toList();

      debugPrint(
        '[SelectVideoViewModel] Filtered video assets: ${videosOnly.length}',
      );

      hasPermission.value = true;
      assets.assignAll(videosOnly);
      _thumbFutures.clear();
    } catch (e, st) {
      debugPrint('SelectVideoViewModel.loadVideos error: $e');
      debugPrint('$st');
      hasPermission.value = false;
      assets.clear();
      _thumbFutures.clear();
      Get.snackbar(
        'error_generic_title'.tr,
        '${'error_load_videos'.tr}: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      loading.value = false;
    }
  }

  Future<File?> resolveAssetFile(AssetEntity asset) async {
    final f1 = await asset.file;
    if (f1 != null) return f1;

    final f2 = await asset.originFile;
    if (f2 != null) return f2;

    final bytes = await asset.originBytes;
    if (bytes == null || bytes.isEmpty) return null;

    final dir = await getTemporaryDirectory();
    final out = File(
      '${dir.path}${Platform.pathSeparator}pm_video_${asset.id}_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    await out.writeAsBytes(bytes, flush: true);
    return out;
  }

  Future<Uint8List?> thumbFuture(AssetEntity asset) {
    return _thumbFutures.putIfAbsent(
      asset.id,
      () => asset.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
    );
  }

  Future<void> confirmSelection() async {
    final asset = selectedAsset.value;
    if (asset == null) {
      debugPrint('confirmSelection: no asset selected');
      return;
    }

    debugPrint('confirmSelection: resolving video asset ${asset.id}');
    final file = await resolveAssetFile(asset);
    if (file == null) {
      Get.snackbar(
        'error_generic_title'.tr,
        'error_cannot_read_video'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Duration videoDuration = asset.videoDuration;
    if (videoDuration.inSeconds <= 0) {
      debugPrint(
        '[SelectVideoViewModel] videoDuration is invalid (${videoDuration.inSeconds}s), '
        'will be determined from video file',
      );
      videoDuration = const Duration(seconds: 5);
    }

    debugPrint(
      'confirmSelection: navigating to CropVideoScreen with file ${file.path}',
    );
    debugPrint('confirmSelection: videoDuration = ${videoDuration.inSeconds}s');
    navigateToCrop(file, videoDuration);
  }

  void navigateToCrop(File videoFile, Duration duration) {
    Get.toNamed(
      AppRoutes.createAnimatedCrop,
      arguments: {
        'pack': pack.value,
        'videoFile': videoFile,
        'videoDuration': duration,
        'replaceStickerUri': replaceStickerUri.value,
        'goToUserPackDetail': goToUserPackDetail.value,
        'isNewPack': isNewPack.value,
      },
    );
  }

  void selectAsset(AssetEntity asset) {
    selectedAsset.value = asset;
  }

  bool get canConfirm => selectedAsset.value != null;

  @override
  void onClose() {
    // Clear thumb futures để giải phóng memory
    _thumbFutures.clear();
    super.onClose();
  }
}
