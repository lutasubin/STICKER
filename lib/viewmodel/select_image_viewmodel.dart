import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sticker_app/data/model/user_sticker_pack.dart';
import 'package:sticker_app/router/router.dart';

/// ViewModel for SelectImage screen
/// Handles business logic and state management
class SelectImageViewModel extends GetxController {
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
    loadAssets();
  }

  void _initFromArguments() {
    final args = Get.arguments;
    if (args is Map) {
      pack.value = args['pack'] as UserStickerPack;
      replaceStickerUri.value = args['replaceStickerUri'] as String?;
      goToUserPackDetail.value = args['goToUserPackDetail'] == true;
      isNewPack.value = args['isNewPack'] == true;
    } else if (args is UserStickerPack) {
      pack.value = args;
    }
  }

  Future<void> loadAssets() async {
    loading.value = true;

    try {
      final storage = Platform.isAndroid ? await Permission.storage.request() : null;
      debugPrint(
        'Storage permission: granted=${storage?.isGranted}, denied=${storage?.isDenied}',
      );

      final permission = await PhotoManager.requestPermissionExtend();

      debugPrint(
        'Photo permission: isAuth=${permission.isAuth}, isLimited=${permission.isLimited}',
      );

      final hasAccess =
          permission.isAuth || permission.isLimited || (storage?.isGranted ?? false);

      if (!hasAccess) {
        hasPermission.value = false;
        assets.clear();
        _thumbFutures.clear();
        return;
      }

      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      debugPrint('Asset paths: ${paths.length}');

      final recent = paths.isNotEmpty ? paths.first : null;
      final list = recent == null
          ? <AssetEntity>[]
          : await recent.getAssetListPaged(page: 0, size: 200);

      debugPrint('Loaded assets: ${list.length}');

      final imagesOnly = list.where((e) => e.type == AssetType.image).toList();

      hasPermission.value = true;
      assets.assignAll(imagesOnly);
      _thumbFutures.clear();
    } catch (e, st) {
      debugPrint('SelectImageViewModel.loadAssets error: $e');
      debugPrint('$st');
      hasPermission.value = false;
      assets.clear();
      _thumbFutures.clear();
      Get.snackbar(
        'error_generic_title'.tr,
        '${'error_load_photos'.tr}: $e',
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
      '${dir.path}${Platform.pathSeparator}pm_${asset.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
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

  Future<void> openCamera() async {
    final cam = await Permission.camera.request();
    if (!cam.isGranted) return;

    final picker = ImagePicker();
    final captured = await picker.pickImage(source: ImageSource.camera);
    if (captured == null) return;

    final file = File(captured.path);
    navigateToCrop(file);
  }

  Future<void> openGalleryPicker() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    navigateToCrop(file);
  }

  Future<void> confirmSelection() async {
    final asset = selectedAsset.value;
    if (asset == null) {
      debugPrint('confirmSelection: no asset selected');
      return;
    }

    debugPrint('confirmSelection: resolving asset ${asset.id}');
    final file = await resolveAssetFile(asset);
    if (file == null) {
      Get.snackbar(
        'error_generic_title'.tr,
        'error_cannot_read_image'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    debugPrint('confirmSelection: navigating to CropScreen with file ${file.path}');
    navigateToCrop(file);
  }

  void navigateToCrop(File imageFile) {
    Get.toNamed(
      AppRoutes.createStickerCrop,
      arguments: {
        'pack': pack.value,
        'imageFile': imageFile,
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
}
