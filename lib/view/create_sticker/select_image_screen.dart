import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sticker_app/core/constants/app_colors.dart';
import 'package:sticker_app/viewmodel/select_image_viewmodel.dart';

class SelectImageScreen extends StatelessWidget {
  const SelectImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(SelectImageViewModel());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          'select_image_title'.tr,
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
                    'permission_photos_required'.tr,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: viewModel.loadAssets,
                    child: Text('grant_permission'.tr),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: viewModel.openGalleryPicker,
                    child: Text('select_from_library'.tr),
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
                  Text('load_failed_message'.tr, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: viewModel.openGalleryPicker,
                    child: Text('select_from_library'.tr),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: viewModel.loadAssets,
                    child: Text('try_reload_button'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        // Đọc selectedAsset trực tiếp trong Obx builder
        final selectedAssetId = viewModel.selectedAsset.value?.id;
        final assets = viewModel.assets;

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: assets.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _CameraTile(onTap: viewModel.openCamera);
            }

            if (index == 1) {
              return _GalleryTile(onTap: viewModel.openGalleryPicker);
            }

            final asset = assets[index - 2];
            final isSelected = selectedAssetId == asset.id;

            return _MediaTile(
              selected: isSelected,
              onTap: () => viewModel.selectAsset(asset),
              child: _AssetThumb(future: viewModel.thumbFuture(asset)),
            );
          },
        );
      }),
    );
  }
}

class _CameraTile extends StatelessWidget {
  const _CameraTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _MediaTile(
      selected: false,
      onTap: onTap,
      child: const Center(
        child: Icon(
          Icons.photo_camera_outlined,
          size: 32,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedRRectBorderPainter(
            color: AppColors.primary,
            radius: 14,
            strokeWidth: 2,
            dashLength: 7,
            gapLength: 6,
          ),
          child: Center(
            child: Container(
              height: 44,
              width: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF00C979),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectBorderPainter extends CustomPainter {
  _DashedRRectBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList(growable: false);

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.child,
    required this.onTap,
    required this.selected,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool selected;

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
            child,
            if (selected)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: AppColors.primary, width: 2.5),
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
}

class _AssetThumb extends StatelessWidget {
  const _AssetThumb({required this.future});

  final Future<Uint8List?> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: future,
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
              child: Icon(Icons.broken_image_outlined, color: Colors.black26),
            ),
          );
        }

        return Image.memory(data, fit: BoxFit.cover, gaplessPlayback: true);
      },
    );
  }
}
