import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sticker_app/core/constants/app_colors.dart';
import 'package:sticker_app/viewmodel/onboarding_viewmodel.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(OnboardingViewModel());
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: viewModel.pageController,
                itemCount: viewModel.pages.length,
                onPageChanged: viewModel.onPageChanged,
                itemBuilder: (context, index) {
                  final page = viewModel.pages[index];
                  return Column(
                    children: [
                      SizedBox(height: size.height * 0.06),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Image.asset(page.image, fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmall ? 22 : 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        page.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmall ? 14 : 16,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Obx(() {
                // Đọc currentPage trực tiếp trong Obx builder
                final currentPageIndex = viewModel.currentPage.value;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        viewModel.pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          width: currentPageIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                currentPageIndex == index
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: viewModel.nextPage,
                      child: const Text(
                        'NEXT',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
