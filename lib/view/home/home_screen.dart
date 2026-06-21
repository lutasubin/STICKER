import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:sticker_app/core/constants/app_colors.dart';
import 'package:sticker_app/data/model/sticker_pack.dart';
import 'package:sticker_app/router/router.dart';
import 'package:sticker_app/view/home/widgets/home_bottom_bar.dart';
import 'package:sticker_app/view/home/widgets/home_category_tab_bar.dart';
import 'package:sticker_app/view/home/widgets/sticker_pack_tile.dart';
import 'package:sticker_app/viewmodel/home_viewmodel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openCreateStickerSheet(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'create_sticker_title'.tr,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back<String>(),
                        icon: const Icon(Icons.close, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _CreateStickerOptionCard(
                    svgAsset: 'assets/svg/icon_regular.svg',
                    title: 'sticker_type_regular'.tr,
                    onTap: () => Get.back<String>(result: 'regular'),
                  ),
                  const SizedBox(height: 12),
                  _CreateStickerOptionCard(
                    svgAsset: 'assets/svg/icon_amation.svg',
                    title: 'sticker_type_animated'.tr,
                    onTap: () => Get.back<String>(result: 'animated'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == null) return;

    final controller = Get.put(HomeViewModel());

    if (result == 'regular') {
      await controller.createRegularPack();
      return;
    }

    if (result == 'animated') {
      await controller.createAnimatedPack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeViewModel());

    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'sticker_maker_title'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Get.toNamed(AppRoutes.setting);
            },
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
          ),
        ],

        bottom: HomeCategoryTabBar(controller: controller),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, thickness: 0.5),
          Expanded(
            child: Obx(() {
              // Đọc packs trực tiếp trong Obx builder
              final packs = controller.packs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: packs.length,
                itemBuilder: (context, index) {
                  final StickerPack pack = packs[index];
                  return StickerPackTile(
                    pack: pack,
                    onAdd:
                        () => Get.toNamed(
                          AppRoutes.stickerPackDetail,
                          arguments: pack,
                        ),
                    onTap:
                        () => Get.toNamed(
                          AppRoutes.stickerPackDetail,
                          arguments: pack,
                        ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: HomeBottomBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Get.offAllNamed(AppRoutes.mySticker);
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateStickerSheet(context),
        backgroundColor: const Color(0xFF00C979),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}

class _CreateStickerOptionCard extends StatelessWidget {
  const _CreateStickerOptionCard({
    required this.svgAsset,
    required this.title,
    required this.onTap,
  });

  final String svgAsset;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              SvgPicture.asset(svgAsset, width: 40, height: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}
