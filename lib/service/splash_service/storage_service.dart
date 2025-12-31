import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Service chuyên quản lý local storage
class StorageService extends GetxService {
  late final GetStorage _box;

  // Keys
  static const String _keyFirstOpen = 'isFirstOpen';
  static const String _keySelectedLanguage = 'selectedLanguage';
  static const String _keyLastServer = 'lastConnectedServer';
  static const String _keyAutoConnect = 'autoConnectEnabled';

  @override
  void onInit() {
    super.onInit();
    _box = GetStorage();
    debugPrint('✅ StorageService initialized');
  }

  // ============ First Open ============
  bool isFirstOpen() => _box.read(_keyFirstOpen) ?? true;

  void markAppAsOpened() {
    _box.write(_keyFirstOpen, false);
    debugPrint('📝 App marked as opened');
  }

  void resetFirstOpen() => _box.write(_keyFirstOpen, true);

  // ============ Language ============
  String? getSelectedLanguage() => _box.read(_keySelectedLanguage);

  void saveSelectedLanguage(String languageCode) {
    _box.write(_keySelectedLanguage, languageCode);
    debugPrint('📝 Language saved: $languageCode');
  }

  // ============ Last Server ============
  String? getLastServer() => _box.read(_keyLastServer);

  void saveLastServer(String serverId) {
    _box.write(_keyLastServer, serverId);
    debugPrint('📝 Last server saved: $serverId');
  }

  void clearLastServer() => _box.remove(_keyLastServer);

  // ============ Auto Connect ============
  bool isAutoConnectEnabled() => _box.read(_keyAutoConnect) ?? false;

  void setAutoConnect(bool enabled) {
    _box.write(_keyAutoConnect, enabled);
    debugPrint('📝 Auto connect: $enabled');
  }

  // ============ Utility ============
  void clearAll() {
    _box.erase();
    debugPrint('🗑️ Storage cleared');
  }

  T? read<T>(String key) => _box.read(key);
  
  void write(String key, dynamic value) => _box.write(key, value);
  
  void remove(String key) => _box.remove(key);

  @override
  void onClose() {
    debugPrint('🧹 StorageService disposed');
    super.onClose();
  }
}