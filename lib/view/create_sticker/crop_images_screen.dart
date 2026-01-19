import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sticker_app/view/create_sticker/widgets/crop_app_bar.dart';
import 'package:sticker_app/view/create_sticker/widgets/crop_editor.dart';
import 'package:sticker_app/view/create_sticker/widgets/crop_mode_selector.dart';
import 'package:sticker_app/view/create_sticker/widgets/crop_painters.dart';
import 'package:sticker_app/viewmodel/crop_image_viewmodel.dart';

class CropScreen extends StatelessWidget {
  const CropScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(CropImageViewModel());

    return Obx(() {
      // Đọc tất cả observables trực tiếp trong Obx builder
      final imageFile = viewModel.imageFile.value;
      final mode = viewModel.mode.value;
      final saving = viewModel.saving.value;
      final loadingMessage = viewModel.loadingMessage.value;
      
      if (imageFile == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: Get.back,
                icon: const Icon(Icons.arrow_back),
              ),
              title: Text('error_crop_title'.tr),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('error_crop_loading'.tr),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: Get.back,
                    child: Text('go_back_button'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        final cropAspectRatio = switch (mode) {
          CropMode.square => 1.0,
          CropMode.circle => 1.0,
          CropMode.heart => 1.0,
          CropMode.manual => null,
          CropMode.autoCutout => null,
        };

        EditorCropLayerPainter? cropLayerPainter;
        try {
          cropLayerPainter = switch (mode) {
            CropMode.circle => CircleCropLayerPainter(),
            CropMode.heart => HeartCropLayerPainter(),
            _ => const EditorCropLayerPainter(),
          };
        } catch (e) {
          debugPrint('Error creating crop layer painter: $e');
          cropLayerPainter = const EditorCropLayerPainter();
        }

        return Scaffold(
          appBar: CropAppBar(
            onBack: Get.back,
            onNext: viewModel.processAndNavigate,
            saving: saving,
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: CropEditor(
                      imageFile: imageFile,
                      modeKey: mode,
                      editorKey: viewModel.editorKey,
                      cropAspectRatio: cropAspectRatio,
                      cropLayerPainter: cropLayerPainter,
                    ),
                  ),
                  CropModeSelector(
                    items: [
                      CropModeItemData(
                        iconAsset: 'assets/icons/AI_cut.svg',
                        label: 'crop_mode_auto'.tr,
                        selected: mode == CropMode.autoCutout,
                        onTap: () => viewModel.setMode(CropMode.autoCutout),
                      ),
                      CropModeItemData(
                        iconAsset: 'assets/icons/Crop.svg',
                        label: 'crop_mode_manual'.tr,
                        selected: mode == CropMode.manual,
                        onTap: () => viewModel.setMode(CropMode.manual),
                      ),
                      CropModeItemData(
                        iconAsset: 'assets/icons/square.svg',
                        label: 'crop_mode_square'.tr,
                        selected: mode == CropMode.square,
                        onTap: () => viewModel.setMode(CropMode.square),
                      ),
                      CropModeItemData(
                        iconAsset: 'assets/icons/Circle.svg',
                        label: 'crop_mode_circle'.tr,
                        selected: mode == CropMode.circle,
                        onTap: () => viewModel.setMode(CropMode.circle),
                      ),
                      CropModeItemData(
                        iconAsset: 'assets/icons/heart.svg',
                        label: 'crop_mode_heart'.tr,
                        selected: mode == CropMode.heart,
                        onTap: () => viewModel.setMode(CropMode.heart),
                      ),
                    ],
                  ),
                ],
              ),
              if (saving &&
                  loadingMessage != null &&
                  mode == CropMode.autoCutout)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF00C979),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            loadingMessage!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
