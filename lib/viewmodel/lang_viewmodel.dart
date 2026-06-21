import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sticker_app/core/constants/app_storage_keys.dart';
import 'package:sticker_app/router/router.dart';

/// ViewModel for Language selection screen
/// Handles business logic and state management
class LangViewModel extends GetxController {
  final GetStorage storage = GetStorage();
  final RxString selectedLanguage = 'English'.obs;

  final List<Map<String, String>> languages = [
    {'name': 'English', 'flag': '🇬🇧'},
    {'name': 'Hindi', 'flag': '🇮🇳'},
    {'name': 'Arabic', 'flag': '🇸🇦'},
    {'name': 'Japanese', 'flag': '🇯🇵'},
    {'name': 'Brazil', 'flag': '🇧🇷'},
    {'name': 'Vietnamese', 'flag': '🇻🇳'},
    {'name': 'Singapore', 'flag': '🇸🇬'},
    {'name': 'France', 'flag': '🇫🇷'},
    {'name': 'Turkey', 'flag': '🇹🇷'},
    {'name': 'Indonesia', 'flag': '🇮🇩'},
    {'name': 'Korea', 'flag': '🇰🇷'},
    {'name': 'Russia', 'flag': '🇷🇺'},
    {'name': 'Germany', 'flag': '🇩🇪'},
    {'name': 'Ukraine', 'flag': '🇺🇦'},
    {'name': 'China', 'flag': '🇨🇳'},
    {'name': 'Spain', 'flag': '🇪🇸'},
  ];

  final Map<String, Locale> languageLocales = {
    'English': const Locale('en', 'US'),
    'Hindi': const Locale('hi', 'IN'),
    'Arabic': const Locale('ar', 'SA'),
    'Japanese': const Locale('ja', 'JP'),
    'Brazil': const Locale('pt', 'BR'),
    'Vietnamese': const Locale('vi', 'VN'),
    'Singapore': const Locale('en', 'SG'),
    'France': const Locale('fr', 'FR'),
    'Turkey': const Locale('tr', 'TR'),
    'Indonesia': const Locale('id', 'ID'),
    'Korea': const Locale('ko', 'KR'),
    'Russia': const Locale('ru', 'RU'),
    'Germany': const Locale('de', 'DE'),
    'Ukraine': const Locale('uk', 'UA'),
    'China': const Locale('zh', 'CN'),
    'Spain': const Locale('es', 'ES'),
  };

  @override
  void onInit() {
    super.onInit();
    loadSavedLanguage();
  }

  void loadSavedLanguage() {
    final String? savedLanguage = storage.read(AppStorageKeys.selectedLanguage);
    if (savedLanguage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        selectedLanguage.value = savedLanguage;
        if (languageLocales.containsKey(savedLanguage)) {
          Get.updateLocale(languageLocales[savedLanguage]!);
        }
      });
    }
  }

  void selectLanguage(String language) {
    selectedLanguage.value = language;
    saveLanguage(language);
    if (languageLocales.containsKey(language)) {
      Get.updateLocale(languageLocales[language]!);
    }
  }

  void saveLanguage(String language) {
    storage.write(AppStorageKeys.selectedLanguage, language);
  }

  void confirmAndNavigate() {
    Get.offAllNamed(AppRoutes.onboard);
  }
}
