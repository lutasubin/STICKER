import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sticker_app/router/router.dart';
import 'package:sticker_app/view/setting/widgets/setting_menu_item.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Get.back();
          },
        ),
        title: Text(
          'setting'.tr,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: Column(
        children: [
          SvgPicture.asset("assets/images/setting_images.svg"),

          // Các mục menu cũ
          SettingMenuItem(
            icon: Icons.language,
            title: 'language'.tr,
            onTap: () {
              Get.toNamed(AppRoutes.lang);
            },
          ),

          const SizedBox(height: 15),
          SettingMenuItem(
            icon: Icons.share,
            title: 'share'.tr,
            onTap: () async {
              final String appLink =
                  'https://play.google.com/store/apps/details?id=com.mobileai.stickerapp';
              final String message = 'Check out Our app: $appLink';

              // ignore: deprecated_member_use
              await Share.share(message, subject: 'Share App');
            },
          ),

          const SizedBox(height: 15),
          SettingMenuItem(
            icon: Icons.privacy_tip,
            title: 'privacy'.tr,
            onTap: () {
              _openPrivacyPolicy();
            },
          ),
        ],
      ),
    );
  }

  
  Future<void> _openPrivacyPolicy() async {
    final Uri url = Uri.parse(
      "https://sites.google.com/view/policystickermaker",
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $url");
    }
  }
}


