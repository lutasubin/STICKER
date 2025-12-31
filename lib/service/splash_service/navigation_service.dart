import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sticker_app/router/router.dart';
import 'package:sticker_app/service/splash_service/storage_service.dart';


/// Service chuyên quản lý navigation logic
class NavigationService extends GetxService {
  final _isNavigating = false.obs;
  late final StorageService _storage;

  bool get isNavigating => _isNavigating.value;

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    debugPrint('✅ NavigationService initialized');
  }

  /// Navigate từ splash đến màn hình tiếp theo
  Future<void> navigateFromSplash() async {
    if (_isNavigating.value) {
      debugPrint('⚠️ Navigation in progress');
      return;
    }

    _isNavigating.value = true;

    try {
      if (_storage.isFirstOpen()) {
        await _goToLanguageSelection();
      } else {
        await _goToHomeWithAd();
      }
    } finally {
      _isNavigating.value = false;
    }
  }

  /// Đi đến màn hình chọn ngôn ngữ (lần đầu)
  Future<void> _goToLanguageSelection() async {
    _storage.markAppAsOpened();
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    Get.offAllNamed(AppRoutes.langFirst);
    debugPrint('🌍 → Language Selection');
  }

  /// Đi đến home với open ad
  Future<void> _goToHomeWithAd() async {
    await Future.delayed(const Duration(milliseconds: 150));

    // OpenAdsManager.showOpenAd(
    //   onComplete: () {
        Get.offAllNamed(AppRoutes.home);
        debugPrint('🏠 → Home');
    //   },
    // );
  }

  /// Navigate trực tiếp không cần check
  Future<void> goToHome() async {
    Get.offAllNamed(AppRoutes.home);
    debugPrint('🏠 → Home (direct)');
  }

  Future<void> goToLanguageSelection() async {
    Get.offAllNamed(AppRoutes.langFirst);
    debugPrint('🌍 → Language Selection (direct)');
  }

  @override
  void onClose() {
    debugPrint('🧹 NavigationService disposed');
    super.onClose();
  }
}