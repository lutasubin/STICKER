import 'package:get/get.dart';
import 'package:sticker_app/data/model/user_sticker_pack.dart';
import 'package:sticker_app/data/repository/user_sticker_pack_repository.dart';
import 'package:sticker_app/router/router.dart';

/// ViewModel for MySticker screen
/// Handles business logic and state management
class MyStickerViewModel extends GetxController {
  final UserStickerPackRepository _repository;

  MyStickerViewModel({UserStickerPackRepository? repository})
      : _repository = repository ?? Get.find<UserStickerPackRepository>();

  final RxList<UserStickerPack> packs = <UserStickerPack>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadPacks();
  }

  void loadPacks() {
    final allPacks = _repository.getAll();
    packs.assignAll(allPacks);
  }

  Future<void> createRegularPack() async {
    final pack = _repository.createDraftPack(
      title: 'default_pack_name'.tr,
    );

    await Get.toNamed(
      AppRoutes.createStickerSelectImage,
      arguments: {'pack': pack, 'isNewPack': true},
    );

    loadPacks();
  }

  Future<void> createAnimatedPack() async {
    final pack = _repository.createDraftPack(
      title: 'default_pack_name'.tr,
      isAnimated: true,
    );

    await Get.toNamed(
      AppRoutes.createAnimatedSelectVideo,
      arguments: {'pack': pack, 'isNewPack': true},
    );

    loadPacks();
  }
}
