import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sticker_app/core/constants/app_colors.dart';
import 'package:sticker_app/core/utils/date_time_utils.dart';
import 'package:sticker_app/viewmodel/select_video_viewmodel.dart';

/// Màn hình chọn video cho Animated Sticker
class SelectVideoScreen extends StatelessWidget {
  const SelectVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(SelectVideoViewModel());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          'select_video_title'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Obx(() {
            // Đọc canConfirm trực tiếp trong Obx builder
            final canConfirm = viewModel.canConfirm;

            return IconButton(
              onPressed: canConfirm ? viewModel.confirmSelection : null,
              icon: Icon(
                Icons.check,
                color: canConfirm ? AppColors.primary : Colors.grey,
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (viewModel.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!viewModel.hasPermission.value) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'permission_videos_required'.tr,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: viewModel.loadVideos,
                    child: Text('grant_permission'.tr),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: PhotoManager.openSetting,
                    child: Text('open_settings'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        if (viewModel.assets.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'no_videos_found'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Không tìm thấy video trong thư viện',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: viewModel.loadVideos,
                    child: Text('try_reload_button'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        // Đọc selectedAsset và assets trực tiếp trong Obx builder
        final selectedAssetId = viewModel.selectedAsset.value?.id;
        final assets = viewModel.assets;

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: assets.length,
          itemBuilder: (context, index) {
            final asset = assets[index];
            final isSelected = selectedAssetId == asset.id;

            return _VideoTile(
              asset: asset,
              selected: isSelected,
              onTap: () => viewModel.selectAsset(asset),
              thumbFuture: viewModel.thumbFuture(asset),
            );
          },
        );
      }),
    );
  }
}

/// Widget hiển thị video tile với thumbnail và duration
class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.asset,
    required this.selected,
    required this.onTap,
    required this.thumbFuture,
  });

  final AssetEntity asset;
  final bool selected;
  final VoidCallback onTap;
  final Future<Uint8List?> thumbFuture;

  @override
  Widget build(BuildContext context) {
    const radius = 14.0;

    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<Uint8List?>(
              future: thumbFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    color: const Color(0xFFF3F3F3),
                    child: const Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                final data = snapshot.data;
                if (snapshot.hasError || data == null) {
                  return Container(
                    color: const Color(0xFFF3F3F3),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.black26,
                      ),
                    ),
                  );
                }

                return Image.memory(
                  data,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                );
              },
            ),
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatDuration(asset.videoDuration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (selected)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: const Color(0xFF00C979),
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            if (selected)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  height: 22,
                  width: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00C979),
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    return DateTimeUtils.formatDuration(duration);
  }
}
