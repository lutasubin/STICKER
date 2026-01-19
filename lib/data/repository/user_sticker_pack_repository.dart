import 'package:get/get.dart';
import 'package:sticker_app/data/model/user_sticker_pack.dart';
import 'package:sticker_app/data/service/user_sticker_pack_service.dart';

/// Repository layer: Middle layer between ViewModel and Service
/// Handles data mapping and combines multiple services
class UserStickerPackRepository extends GetxService {
  final UserStickerPackService _service;

  UserStickerPackRepository({UserStickerPackService? service})
    : _service = service ?? Get.find<UserStickerPackService>();

  List<UserStickerPack> getAll() {
    return _service.getAll();
  }

  UserStickerPack? getById(String id) {
    return _service.getById(id);
  }

  UserStickerPack createPack({required String title, bool isAnimated = false}) {
    return _service.createPack(title: title, isAnimated: isAnimated);
  }

  UserStickerPack createDraftPack({
    required String title,
    bool isAnimated = false,
  }) {
    return _service.createDraftPack(title: title, isAnimated: isAnimated);
  }

  UserStickerPack commitPack(UserStickerPack pack) {
    return _service.commitPack(pack);
  }

  UserStickerPack? addStickerUri({
    required String packId,
    required String stickerFileUri,
    bool? isAnimatedSticker,
  }) {
    return _service.addStickerUri(
      packId: packId,
      stickerFileUri: stickerFileUri,
      isAnimatedSticker: isAnimatedSticker,
    );
  }

  UserStickerPack? renamePack({
    required String packId,
    required String newTitle,
  }) {
    return _service.renamePack(packId: packId, newTitle: newTitle);
  }

  bool deletePack({required String packId, bool deleteFiles = false}) {
    return _service.deletePack(packId: packId, deleteFiles: deleteFiles);
  }

  UserStickerPack? removeStickerUri({
    required String packId,
    required String stickerFileUri,
    bool deleteFile = false,
  }) {
    return _service.removeStickerUri(
      packId: packId,
      stickerFileUri: stickerFileUri,
      deleteFile: deleteFile,
    );
  }

  UserStickerPack? replaceStickerUri({
    required String packId,
    required String oldStickerFileUri,
    required String newStickerFileUri,
    bool deleteOldFile = false,
  }) {
    return _service.replaceStickerUri(
      packId: packId,
      oldStickerFileUri: oldStickerFileUri,
      newStickerFileUri: newStickerFileUri,
      deleteOldFile: deleteOldFile,
    );
  }

  void markPackAsInstalled(String packId) {
    _service.markPackAsInstalled(packId);
  }

  int? getPackInstalledAt(String packId) {
    return _service.getPackInstalledAt(packId);
  }

  bool packNeedsUpdate(String packId) {
    return _service.packNeedsUpdate(packId);
  }
}
