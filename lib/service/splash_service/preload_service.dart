import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sticker_app/helper/logger/app_logger.dart';


/// Service chuyên quản lý preload resources (ads, images)
class PreloadService extends GetxService {
  final _adsLoaded = false.obs;
  final _imagesLoaded = false.obs;
  final _progress = 0.0.obs;

  // Getters
  bool get adsLoaded => _adsLoaded.value;
  bool get imagesLoaded => _imagesLoaded.value;
  bool get allLoaded => _adsLoaded.value && _imagesLoaded.value;
  double get progress => _progress.value;

  @override
  void onInit() {
    super.onInit();
    AppLogger.i('[PreloadService] Initialized');
  }

  /// Preload tất cả resources song song
  Future<void> preloadAll(BuildContext context) async {
    AppLogger.i('[PreloadService] Starting preload all resources');
    _progress.value = 0.0;

    try {
      await Future.wait([
        // _loadAds(),
        _loadImages(context),
      ]);

      _progress.value = 1.0;
      AppLogger.i('[PreloadService] All resources loaded successfully');
    } catch (e, stackTrace) {
      AppLogger.e(
        '[PreloadService] Preload error',
        e,
        stackTrace,
      );
      _progress.value = 1.0;
    }
  }

  // /// Load ads với timeout - Sử dụng async ads manager
  // Future<void> _loadAds() async {
  //   if (_adsLoaded.value) return;

  //   try {
  //     // Load ads song song với timeout riêng cho từng ad
  //     final results = await Future.wait([
  //       InterstitialAdsManager.precacheInterstitialAd()
  //           .timeout(
  //             const Duration(seconds: 5),
  //             onTimeout: () {
  //               debugPrint('⏱️ Interstitial ad timeout');
  //               return false;
  //             },
  //           ),
  //       OpenAdsManager.precacheOpenAd()
  //           .timeout(
  //             const Duration(seconds: 5),
  //             onTimeout: () {
  //               debugPrint('⏱️ Open ad timeout');
  //               return false;
  //             },
  //           ),
  //     ]);

  //     // Log kết quả từng ad
  //     if (results[0]) {
  //       debugPrint('✅ Interstitial ad loaded');
  //     } else {
  //       debugPrint('⚠️ Interstitial ad failed or timeout');
  //     }

  //     if (results[1]) {
  //       debugPrint('✅ Open ad loaded');
  //     } else {
  //       debugPrint('⚠️ Open ad failed or timeout');
  //     }

  //     _adsLoaded.value = true;
  //     _progress.value += 0.5;
  //     debugPrint('✅ Ads loading completed');
  //   } catch (e) {
  //     debugPrint('⚠️ Ads error: $e');
  //     _adsLoaded.value = true;
  //     _progress.value += 0.5;
  //   }
  // }

  /// Load images với timeout
  Future<void> _loadImages(BuildContext context) async {
    if (_imagesLoaded.value) {
      AppLogger.d('[PreloadService] Images already loaded, skipping');
      return;
    }

    AppLogger.d('[PreloadService] Loading images...');
    try {
      // Precache splash_image.png vì nó được hiển thị trong splash screen
      // logo.png không cần precache vì chỉ dùng làm launcher icon
      await precacheImage(
        const AssetImage('assets/images/splash_image.png'),
        context,
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          AppLogger.w('[PreloadService] splash_image.png timeout after 3 seconds');
        },
      );

      _imagesLoaded.value = true;
      _progress.value += 0.5;
      AppLogger.i('[PreloadService] Images loaded successfully');
    } catch (e, stackTrace) {
      AppLogger.e(
        '[PreloadService] Images loading error',
        e,
        stackTrace,
      );
      _imagesLoaded.value = true;
      _progress.value += 0.5;
    }
  }

  /// Reset state
  void reset() {
    AppLogger.d('[PreloadService] Resetting state');
    _adsLoaded.value = false;
    _imagesLoaded.value = false;
    _progress.value = 0.0;
  }

  @override
  void onClose() {
    AppLogger.d('[PreloadService] Disposed');
    super.onClose();
  }
}