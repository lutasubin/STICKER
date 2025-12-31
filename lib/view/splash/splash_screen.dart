import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:sticker_app/service/splash_service/navigation_service.dart';
import 'package:sticker_app/service/splash_service/preload_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final PreloadService _preloadService;
  late final NavigationService _navigationService;

  @override
  void initState() {
    super.initState();

    _preloadService = Get.find<PreloadService>();
    _navigationService = Get.find<NavigationService>();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.wait([
        _controller.forward(),
        _preloadService.preloadAll(context),
      ]);

      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        await _navigationService.navigateFromSplash();
      }
    } catch (e) {
      debugPrint('❌ Splash error: $e');
      if (mounted) {
        await _navigationService.navigateFromSplash();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Stack(
          children: [
            /// 🌫 Background SVG
            Positioned.fill(
              child: SvgPicture.asset(
                "assets/svg/backgroud.svg",
                fit: BoxFit.cover,
              ),
            ),

            /// 🌟 Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                /// LOGO + TITLE
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// LOGO
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeIn,
                        ),
                        child: ScaleTransition(
                          scale: CurvedAnimation(
                            parent: _controller,
                            curve: Curves.easeOutBack,
                          ),
                          child: Image.asset(
                            'assets/images/splash_image.png',
                            height: 120,
                            width: 220,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// TITLE (hiện sau logo)
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _controller,
                          curve:
                              const Interval(0.6, 1.0, curve: Curves.easeIn),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _controller,
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

                /// PROGRESS BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Stack(
                          children: [
                            Container(height: 6, color: Colors.grey[300]),
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor:
                                  Curves.easeInOut.transform(_controller.value),
                              child: Container(
                                height: 6,
                                color: const Color(0xFF00C979),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// DISCLAIMER
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
                  ),
                  child: Text(
                    "This action may contain ads",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
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
