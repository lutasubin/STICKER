import 'package:get/get.dart';
import 'package:sticker_app/data/model/sticker_pack.dart';
import 'package:sticker_app/data/repository/sticker_repository.dart';
import 'package:sticker_app/data/repository/user_sticker_pack_repository.dart';
import 'package:sticker_app/helper/dialogs/app_dialogs.dart';
import 'package:sticker_app/router/router.dart';

/// ViewModel for Home screen
/// Handles business logic and state management
class HomeViewModel extends GetxController {
  final StickerRepository _repository;
  final UserStickerPackRepository _userPackRepository;

  HomeViewModel({
    StickerRepository? repository,
    UserStickerPackRepository? userPackRepository,
  })  : _repository = repository ?? StickerRepository(),
        _userPackRepository =
            userPackRepository ?? Get.find<UserStickerPackRepository>();

  final RxSet<String> _sendingPackIds = <String>{}.obs;

  /// Tab hiện tại
  final Rx<StickerCategory> _currentCategory = StickerCategory.animal.obs;

  StickerCategory get currentCategory => _currentCategory.value;

  /// Danh sách pack theo category hiện tại
  final RxList<StickerPack> packs = <StickerPack>[].obs;

  /// Danh sách tab hiển thị trên UI (theo thứ tự giống design)
  List<StickerCategory> get categoriesOrder => const [
        StickerCategory.animal,
        StickerCategory.funny,
        StickerCategory.love,
        StickerCategory.cartoon,
      ];

  @override
  void onInit() {
    super.onInit();
    _loadPacksForCurrentCategory();
  }

  void onCategorySelected(StickerCategory category) {
    if (category == _currentCategory.value) return;
    _currentCategory.value = category;
    _loadPacksForCurrentCategory();
  }

  void _loadPacksForCurrentCategory() {
    final data = _repository.getPacksByCategory(_currentCategory.value);
    packs.assignAll(data);
  }

  Future<void> addPackToWhatsapp(StickerPack pack) async {
    if (_sendingPackIds.contains(pack.id)) return;
    _sendingPackIds.add(pack.id);

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final installed = await _repository.isWhatsAppInstalled();
      if (!installed) {
        AppDialogs.showWhatsAppNotInstalled();
        return;
      }

      final result = await _repository.addPackToWhatsApp(pack);

      if (result == 'cancelled') {
        return;
      } else if (result == 'already_added') {
        AppDialogs.showStickerAlreadyAdded();
      } else {
        AppDialogs.showStickerAddedSuccess();
      }
    } catch (e) {
      AppDialogs.showError(e.toString());
    } finally {
      _sendingPackIds.remove(pack.id);
    }
  }

  Future<void> createRegularPack() async {
    final pack = _userPackRepository.createDraftPack(
      title: 'default_pack_name'.tr,
    );

    await Get.toNamed(
      AppRoutes.createStickerSelectImage,
      arguments: {'pack': pack, 'isNewPack': true},
    );
  }

  Future<void> createAnimatedPack() async {
    final pack = _userPackRepository.createDraftPack(
      title: 'default_pack_name'.tr,
      isAnimated: true,
    );

    await Get.toNamed(
      AppRoutes.createAnimatedSelectVideo,
      arguments: {'pack': pack, 'isNewPack': true},
    );
  }
}
