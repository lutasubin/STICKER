import 'package:get/get.dart';
import 'package:sticker_app/model/sticker_pack.dart';
import 'package:sticker_app/service/sticker/whatsapp_sticker_service.dart';
import 'package:sticker_app/service/sticker/sticker_service.dart';
import 'package:sticker_app/helper/dialogs/app_dialogs.dart';

/// Controller cho màn hình Home – giữ logic, state, không chứa UI.
class HomeController extends GetxController {
  HomeController({
    StickerService? stickerService,
  }) : _stickerService = stickerService ?? const StickerService();

  final StickerService _stickerService;

  final WhatsappStickerService _whatsappService = const WhatsappStickerService();
  final RxSet<String> _sendingPackIds = <String>{}.obs;

  /// Tab hiện tại
  final Rx<StickerCategory> _currentCategory =
      StickerCategory.animal.obs;

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
    final data = _stickerService.getByCategory(_currentCategory.value);
    packs.assignAll(data);
  }

  Future<void> addPackToWhatsapp(StickerPack pack) async {
    if (_sendingPackIds.contains(pack.id)) return;
    _sendingPackIds.add(pack.id);

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final installed = await _whatsappService.isWhatsAppInstalled();
      if (!installed) {
        AppDialogs.showWhatsAppNotInstalled();
        return;
      }

      final result = await _whatsappService.addPack(pack);

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

  
}


