import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sticker_app/core/constants/app_durations.dart';
import 'package:sticker_app/service/splash_service/navigation_service.dart';
import 'package:sticker_app/service/splash_service/preload_service.dart';

/// ViewModel for Splash screen
/// Handles business logic and state management
class SplashViewModel extends GetxController
    with GetSingleTickerProviderStateMixin {
  final PreloadService _preloadService;
  final NavigationService _navigationService;

  SplashViewModel({
    PreloadService? preloadService,
    NavigationService? navigationService,
  })  : _preloadService = preloadService ?? Get.find<PreloadService>(),
        _navigationService =
            navigationService ?? Get.find<NavigationService>();

  late final AnimationController animationController;

  @override
  void onInit() {
    super.onInit();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    animationController = AnimationController(
      vsync: this,
      duration: AppDurations.splashAnimation,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeApp();
    });
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }

  Future<void> initializeApp() async {
    try {
      await Future.wait([
        animationController.forward(),
        _preloadService.preloadAll(Get.context!),
      ]);

      await Future.delayed(AppDurations.mediumDelay);

      await _navigationService.navigateFromSplash();
    } catch (e) {
      debugPrint('❌ Splash error: $e');
      await _navigationService.navigateFromSplash();
    }
  }
}
