import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sticker_app/core/constants/app_paths.dart';
import 'package:sticker_app/view/setting/widgets/setting_menu_item.dart';
import 'package:sticker_app/viewmodel/setting_viewmodel.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(SettingViewModel());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'setting'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: Column(
        children: [
          SvgPicture.asset(AppPaths.settingImage),
          SettingMenuItem(
            icon: Icons.language,
            title: 'language'.tr,
            onTap: viewModel.navigateToLanguage,
          ),
          const SizedBox(height: 15),
          SettingMenuItem(
            icon: Icons.share,
            title: 'share'.tr,
            onTap: viewModel.shareApp,
          ),
          const SizedBox(height: 15),
          SettingMenuItem(
            icon: Icons.privacy_tip,
            title: 'privacy'.tr,
            onTap: viewModel.openPrivacyPolicy,
          ),
        ],
      ),
    );
  }
}
