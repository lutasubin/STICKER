import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:sticker_app/core/constants/app_colors.dart';
import 'package:sticker_app/data/model/user_sticker_pack.dart';
import 'package:sticker_app/router/router.dart';
import 'package:sticker_app/view/home/widgets/home_bottom_bar.dart';
import 'package:sticker_app/viewmodel/my_sticker_viewmodel.dart';

class MyStickerScreen extends StatelessWidget {
  const MyStickerScreen({super.key});

  Future<void> _openCreateStickerSheet(BuildContext context) async {
    final viewModel = Get.put(MyStickerViewModel());
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

    if (result == 'regular') {
      await viewModel.createRegularPack();
      return;
    }

    if (result == 'animated') {
      await viewModel.createAnimatedPack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(MyStickerViewModel());

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
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
      ),
      body: Obx(() {
        // Đọc packs trực tiếp trong Obx builder
        final packs = viewModel.packs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: packs.length,
          itemBuilder: (context, index) {
            final pack = packs[index];
            return InkWell(
              onTap: () async {
                final changed = await Get.toNamed(
                  AppRoutes.userPackDetail,
                  arguments: pack,
                );
                if (changed == true) viewModel.loadPacks();
              },
              borderRadius: BorderRadius.circular(16),
              child: _UserPackTile(pack: pack),
            );
          },
        );
      }),
      bottomNavigationBar: HomeBottomBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Get.offAllNamed(AppRoutes.home);
            return;
          }
          if (index == 1) {
            viewModel.loadPacks();
            return;
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateStickerSheet(context),
        backgroundColor: AppColors.primary,
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

class _UserPackTile extends StatelessWidget {
  const _UserPackTile({required this.pack});

  final UserStickerPack pack;

  @override
  Widget build(BuildContext context) {
    final stickers = pack.stickerFileUris;
    final previews = stickers.take(5).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pack.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (pack.isAnimated)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_circle_outline,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Động',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stickers.length} sticker${stickers.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: previews.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final uri = previews[index];
                return Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File.fromUri(Uri.parse(uri)),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.black26,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
