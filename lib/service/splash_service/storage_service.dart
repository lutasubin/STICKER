import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sticker_app/helper/logger/app_logger.dart';

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
    AppLogger.i('[StorageService] Initialized');
  }

  // ============ First Open ============
  bool isFirstOpen() => _box.read(_keyFirstOpen) ?? true;

  void markAppAsOpened() {
    _box.write(_keyFirstOpen, false);
    AppLogger.i('[StorageService] App marked as opened');
  }

  void resetFirstOpen() {
    _box.write(_keyFirstOpen, true);
    AppLogger.d('[StorageService] First open reset');
  }

  // ============ Language ============
  String? getSelectedLanguage() => _box.read(_keySelectedLanguage);

  void saveSelectedLanguage(String languageCode) {
    _box.write(_keySelectedLanguage, languageCode);
    AppLogger.i('[StorageService] Language saved: $languageCode');
  }

  // ============ Last Server ============
  String? getLastServer() => _box.read(_keyLastServer);

  void saveLastServer(String serverId) {
    _box.write(_keyLastServer, serverId);
    AppLogger.i('[StorageService] Last server saved: $serverId');
  }

  void clearLastServer() {
    _box.remove(_keyLastServer);
    AppLogger.d('[StorageService] Last server cleared');
  }

  // ============ Auto Connect ============
  bool isAutoConnectEnabled() => _box.read(_keyAutoConnect) ?? false;

  void setAutoConnect(bool enabled) {
    _box.write(_keyAutoConnect, enabled);
    AppLogger.i('[StorageService] Auto connect: $enabled');
  }

  // ============ Utility ============
  void clearAll() {
    AppLogger.w('[StorageService] Clearing all storage data');
    _box.erase();
    AppLogger.i('[StorageService] Storage cleared');
  }

  T? read<T>(String key) => _box.read(key);
  
  void write(String key, dynamic value) => _box.write(key, value);
  
  void remove(String key) => _box.remove(key);

  @override
  void onClose() {
    AppLogger.d('[StorageService] Disposed');
    super.onClose();
  }
}