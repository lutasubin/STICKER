// import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:get_storage/get_storage.dart';

// class AnalyticsHelper {
//   static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
//   static FirebaseAnalyticsObserver observer =
//       FirebaseAnalyticsObserver(analytics: _analytics);

//   static final _storage = GetStorage();

//   static FirebaseAnalytics get instance => _analytics;

//   static Future<void> logVpnConnect(
//       String serverName, String serverCountry) async {
//     await _analytics.logEvent(
//       name: 'vpn_connect',
//       parameters: {
//         'server_name': serverName,
//         'server_country': serverCountry,
//         'value': 0.00258,
//         'currency': 'USD',
//         'timestamp': DateTime.now().toIso8601String(),
//       },
//     );

//     /// ✅ Lưu bằng GetStorage thay vì SharedPreferences
//     final key = 'vpn_count_$serverName';
//     final currentCount = _storage.read(key) ?? 0;
//     _storage.write(key, currentCount + 1);
//   }

//   static Future<void> logVpnDisconnect(
//       String serverName, int connectionDuration) async {
//     await _analytics.logEvent(
//       name: 'vpn_disconnect',
//       parameters: {
//         'server_name': serverName,
//         'duration_seconds': connectionDuration,
//         'timestamp': DateTime.now().toIso8601String(),
//       },
//     );
//   }

//   static Future<void> logSettingChange(String settingName, String value) async {
//     await _analytics.logEvent(
//       name: 'setting_change',
//       parameters: {
//         'setting_name': settingName,
//         'value': value,
//         'timestamp': DateTime.now().toIso8601String(),
//       },
//     );
//   }

//   static Future<void> logServerSelection(
//       String serverName, String serverCountry) async {
//     await _analytics.logEvent(
//       name: 'server_selection',
//       parameters: {
//         'server_name': serverName,
//         'server_country': serverCountry,
//         'timestamp': DateTime.now().toIso8601String(),
//       },
//     );
//   }

//   static Future<void> logAppOpen() async {
//     await _analytics.logAppOpen();
//   }
// }
