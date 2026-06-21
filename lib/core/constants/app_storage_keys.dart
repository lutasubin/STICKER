/// Storage keys for GetStorage
class AppStorageKeys {
  AppStorageKeys._();

  // App state
  static const String isFirstOpen = 'isFirstOpen';
  static const String selectedLanguage = 'selected_language';

  // Server/Connection (if applicable)
  static const String lastServer = 'lastConnectedServer';
  static const String autoConnect = 'autoConnectEnabled';
}
