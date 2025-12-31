import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sticker_app/service/sticker/user_sticker_pack_service.dart';
import 'package:sticker_app/service/splash_service/navigation_service.dart';
import 'package:sticker_app/service/splash_service/preload_service.dart';
import 'package:sticker_app/service/splash_service/storage_service.dart';


/// AppBinding - Khởi tạo tất cả services và controllers
/// 
/// Cấu trúc phân tầng:
/// TIER 1: Core Infrastructure (StorageService)
/// TIER 2: Business Services (PreloadService, NavigationService, VpnTimerService)

class AppBinding extends Bindings {
  @override
  Future<void> dependencies() async {
    debugPrint('🚀 AppBinding: Starting initialization...');
    
    // ============ TIER 1: Core Infrastructure ============
    // Services không phụ thuộc vào bất kỳ service nào khác
    
    _initStorageService();
    
    // ============ TIER 2: Business Services ============
    // Services có thể phụ thuộc vào TIER 1
    
    _initPreloadService();
    _initNavigationService();
    _initUserStickerPackService();
    
    
    debugPrint('🎉 AppBinding: Initialization complete!\n');
  }

  /// TIER 1: Storage Service (Permanent)
  void _initStorageService() {
    Get.put<StorageService>(
      StorageService(),
      permanent: true,
    );
    debugPrint('✅ [TIER 1] StorageService initialized');
  }

  /// TIER 2: Preload Service (Lazy - Dispose after splash)
  void _initPreloadService() {
    Get.lazyPut<PreloadService>(
      () => PreloadService(),
      fenix: false, // Không recreate sau khi dispose
    );
    debugPrint('✅ [TIER 2] PreloadService initialized (lazy)');
  }

  /// TIER 2: Navigation Service (Permanent)
  void _initNavigationService() {
    Get.put<NavigationService>(
      NavigationService(),
      permanent: true,
    );
    debugPrint('✅ [TIER 2] NavigationService initialized');
  }

  void _initUserStickerPackService() {
    Get.put<UserStickerPackService>(
      UserStickerPackService(),
      permanent: true,
    );
    debugPrint('✅ [TIER 2] UserStickerPackService initialized');
  }
}