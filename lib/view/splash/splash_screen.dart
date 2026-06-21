import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:sticker_app/core/constants/app_colors.dart';
import 'package:sticker_app/core/constants/app_paths.dart';
import 'package:sticker_app/viewmodel/splash_viewmodel.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(SplashViewModel());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                AppPaths.backgroundSvg,
                fit: BoxFit.cover,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: viewModel.animationController,
                          curve: Curves.easeIn,
                        ),
                        child: ScaleTransition(
                          scale: CurvedAnimation(
                            parent: viewModel.animationController,
                            curve: Curves.easeOutBack,
                          ),
                          child: Image.asset(
                            AppPaths.splashImage,
                            height: 120,
                            width: 220,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: viewModel.animationController,
                          curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: viewModel.animationController,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: const Text(
                            'Sticker Maker',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedBuilder(
                      animation: viewModel.animationController,
                      builder: (context, child) {
                        return Stack(
                          children: [
                            Container(height: 6, color: Colors.grey[300]),
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: Curves.easeInOut.transform(
                                viewModel.animationController.value,
                              ),
                              child: Container(
                                height: 6,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: viewModel.animationController,
                    curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
                  ),
                  child: Text(
                    'This action may contain ads',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
