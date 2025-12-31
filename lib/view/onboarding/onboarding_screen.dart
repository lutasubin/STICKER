import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sticker_app/model/onboard.dart';

import '../../router/router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      image: 'assets/images/1.png',
      title: 'Create Sticker',
      description:
          'Turn your photos into cool, custom stickers\n'
          'with text, effects, and creative tools.',
    ),
    OnboardingData(
      image: 'assets/images/2.png',
      title: 'Export and Share',
      description:
          'Export stickers instantly, use them, and share\n'
          'with friends on your favorite apps.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
        Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// PAGE VIEW
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      SizedBox(height: size.height * 0.06),

                      /// IMAGE
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Image.asset(
                            _pages[index].image,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// TITLE (ĐẬM – GIỐNG STORE)
                      Text(
                        _pages[index].title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmall ? 22 : 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// DESCRIPTION (NHẠT)
                      Text(
                        _pages[index].description,
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

            /// INDICATOR + NEXT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// DOTS
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF00C979)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  /// NEXT
                  TextButton(
                    onPressed: _nextPage,
                    child: const Text(
                      'NEXT',
                      style: TextStyle(
                        color: Color(0xFF00C979),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
