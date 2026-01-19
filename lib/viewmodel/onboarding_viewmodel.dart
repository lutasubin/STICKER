import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sticker_app/core/constants/app_durations.dart';
import 'package:sticker_app/core/constants/app_paths.dart';
import 'package:sticker_app/model/onboard.dart';
import 'package:sticker_app/router/router.dart';

/// ViewModel for Onboarding screen
/// Handles business logic and state management
class OnboardingViewModel extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  final List<OnboardingData> pages = [
    OnboardingData(
      image: AppPaths.onboardingImage1,
      title: 'Create Sticker',
      description:
          'Turn your photos into cool, custom stickers\n'
          'with text, effects, and creative tools.',
    ),
    OnboardingData(
      image: AppPaths.onboardingImage2,
      title: 'Export and Share',
      description:
          'Export stickers instantly, use them, and share\n'
          'with friends on your favorite apps.',
    ),
  ];

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void nextPage() {
    if (currentPage.value < pages.length - 1) {
      pageController.nextPage(
        duration: AppDurations.navigationTransition,
        curve: Curves.easeInOut,
      );
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }
}
