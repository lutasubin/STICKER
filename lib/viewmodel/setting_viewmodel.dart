import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sticker_app/core/constants/app_strings.dart';
import 'package:sticker_app/router/router.dart';
import 'package:url_launcher/url_launcher.dart';

/// ViewModel for Setting screen
/// Handles business logic and state management
class SettingViewModel extends GetxController {
  Future<void> navigateToLanguage() async {
    Get.toNamed(AppRoutes.lang);
  }

  Future<void> shareApp() async {
    await Share.share(
      AppStrings.shareAppMessage,
      subject: AppStrings.shareAppSubject,
    );
  }

  Future<void> openPrivacyPolicy() async {
    final Uri url = Uri.parse(AppStrings.privacyPolicyUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
