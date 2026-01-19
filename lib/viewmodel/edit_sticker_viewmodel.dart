import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sticker_app/core/constants/app_colors.dart';
import 'package:sticker_app/data/model/user_sticker_pack.dart';
import 'package:sticker_app/data/repository/image_processing_repository.dart';
import 'package:sticker_app/data/repository/user_sticker_pack_repository.dart';
import 'package:sticker_app/helper/dialogs/app_dialogs.dart';
import 'package:sticker_app/router/router.dart';
import 'package:sticker_app/view/edit_sticker/background_picker_screen.dart';
import 'package:sticker_app/view/edit_sticker/sticker_picker_screen.dart';
import 'package:sticker_app/view/edit_sticker/text_edit_screen.dart';
import 'package:sticker_app/view/edit_sticker/widgets/sticker_layer_widget.dart';

enum EditTab { text, sticker, background }

/// ViewModel for EditSticker screen
/// Handles business logic and state management
class EditStickerViewModel extends GetxController {
  final UserStickerPackRepository _packRepository;
  final ImageProcessingRepository _imageRepository;

  EditStickerViewModel({
    UserStickerPackRepository? packRepository,
    ImageProcessingRepository? imageRepository,
  })  : _packRepository =
            packRepository ?? Get.find<UserStickerPackRepository>(),
        _imageRepository = imageRepository ?? ImageProcessingRepository();

  final Rx<File?> stickerFile = Rx<File?>(null);
  final Rx<UserStickerPack?> pack = Rx<UserStickerPack?>(null);
  final Rx<String?> replaceStickerUri = Rx<String?>(null);
  final RxBool isNewPack = false.obs;
  final Rx<String?> tempStickerUri = Rx<String?>(null);
  final Rx<String?> backgroundWebpUri = Rx<String?>(null);
  final Rx<String?> noBgStickerUri = Rx<String?>(null);
  final Rx<String?> selectedBackgroundPath = Rx<String?>(null);

  final Rx<EditTab> selectedTab = EditTab.text.obs;
  final RxBool showPainter = true.obs;
  final RxBool isLoadingSticker = true.obs;
  final RxBool saving = false.obs;

  final Rx<Matrix4> transformMatrix = Matrix4.identity().obs;
  final RxDouble scale = 1.0.obs;
  final Rx<Offset> translation = Offset.zero.obs;

  final RxList<StickerLayer> stickerLayers = <StickerLayer>[].obs;
  final Rx<String?> selectedStickerLayerId = Rx<String?>(null);

  PainterController? _controller;

  PainterController get controller {
    _controller ??= PainterController()
      ..freeStyleSettings = FreeStyleSettings(mode: FreeStyleMode.none)
      ..textSettings = TextSettings(
        textStyle: const TextStyle(
          fontSize: 24,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        focusNode: FocusNode(),
      );
    return _controller!;
  }

  @override
  void onInit() {
    super.onInit();
    _initFromArguments();
  }

  @override
  void onClose() {
    _controller?.dispose();
    super.onClose();
  }

  void _initFromArguments() {
    try {
      final args = Get.arguments as Map;
      final stickerUri = args['stickerUri'] as String;
      final isTempFile = args['isTempFile'] == true;

      stickerFile.value = File.fromUri(Uri.parse(stickerUri));

      if (isTempFile) {
        tempStickerUri.value = stickerUri;
      }

      pack.value = args['pack'] as UserStickerPack;
      replaceStickerUri.value = args['replaceStickerUri'] as String?;
      isNewPack.value = args['isNewPack'] == true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await tryFindBackgroundWebp(stickerUri);
        await loadStickerAsBackground();
      });
    } catch (e) {
      AppDialogs.showError('Failed to initialize: $e');
    }
  }

  Future<void> tryFindBackgroundWebp(String stickerUri) async {
    try {
      final uri = Uri.parse(stickerUri);
      final filePath = uri.toFilePath();

      if (filePath.endsWith('.webp')) {
        final nobgPath = '${filePath}_nobg.png';
        final nobgFile = File(nobgPath);

        if (await nobgFile.exists()) {
          noBgStickerUri.value = nobgFile.uri.toString();
          backgroundWebpUri.value = stickerUri;
          return;
        }
      }

      final tempFile = File.fromUri(uri);
      final fileName = tempFile.path.split(Platform.pathSeparator).last;
      final match = RegExp(r'temp_(\d+)\.png').firstMatch(fileName);
      if (match != null) {
        final timestamp = match.group(1);
        final dir = await getApplicationDocumentsDirectory();
        final webpPath =
            '${dir.path}${Platform.pathSeparator}stickers${Platform.pathSeparator}${pack.value!.id}${Platform.pathSeparator}$timestamp.webp';
        final webpFile = File(webpPath);
        if (await webpFile.exists()) {
          backgroundWebpUri.value = Uri.file(webpPath).toString();

          final nobgPath = '${webpPath}_nobg.png';
          final nobgFile = File(nobgPath);
          if (await nobgFile.exists()) {
            noBgStickerUri.value = nobgFile.uri.toString();
          }
        }
      }
    } catch (e) {
      debugPrint('Error finding background WebP: $e');
    }
  }

  Future<void> loadStickerAsBackground() async {
    try {
      final fileToLoad = noBgStickerUri.value != null
          ? File.fromUri(Uri.parse(noBgStickerUri.value!))
          : stickerFile.value!;

      final uiImage = await FileImage(fileToLoad).image;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.microtask(() {
          controller.background = uiImage.backgroundDrawable;
          WidgetsBinding.instance.addPostFrameCallback((__) {
            isLoadingSticker.value = false;
          });
        });
      });
    } catch (e) {
      isLoadingSticker.value = false;
      AppDialogs.showError('Không thể load sticker: $e');
    }
  }

  Future<void> onCreate() async {
    if (saving.value) return;

    if (isNewPack.value) {
      await showSaveStickerDialog();
      return;
    }

    await saveStickerToPack(pack.value!);
  }

  Future<void> saveStickerToPack(UserStickerPack pack) async {
    if (saving.value || stickerFile.value == null) return;
    saving.value = true;

    try {
      ui.Image baseImage = await controller.renderImage(const Size(512, 512));

      Uint8List? nobgPngBytes;
      if (selectedBackgroundPath.value != null) {
        try {
          nobgPngBytes = await baseImage.pngBytes;
        } catch (e) {
          debugPrint('Error getting nobg PNG bytes: $e');
        }
      }

      ui.Image finalImage;

      if (stickerLayers.isNotEmpty || selectedBackgroundPath.value != null) {
        finalImage = await renderStickerLayers(baseImage);
        baseImage.dispose();
      } else {
        finalImage = baseImage;
      }

      final pngBytes = await finalImage.pngBytes;
      if (pngBytes == null) throw Exception('Failed to render PNG');

      finalImage.dispose();

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final dir = await getApplicationDocumentsDirectory();
      final outDir = Directory(
        '${dir.path}${Platform.pathSeparator}stickers${Platform.pathSeparator}${pack.id}',
      );
      if (!await outDir.exists()) {
        await outDir.create(recursive: true);
      }

      if (nobgPngBytes != null) {
        try {
          final nobgFile = File(
            '${outDir.path}${Platform.pathSeparator}$timestamp.webp_nobg.png',
          );
          await nobgFile.writeAsBytes(nobgPngBytes);
          noBgStickerUri.value = nobgFile.uri.toString();
        } catch (e) {
          debugPrint('Error saving no-background sticker file: $e');
        }
      }

      final webpBytes = await _imageRepository.encodeWebp(pngBytes);

      final outFile = File(
        '${outDir.path}${Platform.pathSeparator}$timestamp.webp',
      );
      await outFile.writeAsBytes(webpBytes, flush: true);
      final fileUri = Uri.file(outFile.path).toString();

      if (tempStickerUri.value != null) {
        try {
          final tempFile = File.fromUri(Uri.parse(tempStickerUri.value!));
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (e) {
          debugPrint('Error deleting temp file: $e');
        }
      }

      UserStickerPack updatedPack;

      try {
        if (replaceStickerUri.value != null) {
          _packRepository.replaceStickerUri(
            packId: pack.id,
            oldStickerFileUri: replaceStickerUri.value!,
            newStickerFileUri: fileUri,
            deleteOldFile: true,
          );
          updatedPack = _packRepository.getById(pack.id)!;
        } else {
          _packRepository.addStickerUri(
            packId: pack.id,
            stickerFileUri: fileUri,
            isAnimatedSticker: false,
          );
          updatedPack = _packRepository.getById(pack.id)!;
        }
      } catch (e) {
        Get.snackbar(
          'Lỗi',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      PaintingBinding.instance.imageCache.evict(FileImage(stickerFile.value!));

      Get.offAllNamed(AppRoutes.mySticker);
      Get.toNamed(AppRoutes.userPackDetail, arguments: updatedPack);

      AppDialogs.showSuccess(
        'success_saved_to_pack'.trParams({'title': updatedPack.title}),
      );
    } catch (e) {
      AppDialogs.showError(e.toString());
    } finally {
      saving.value = false;
    }
  }

  Future<ui.Image> renderStickerLayers(ui.Image baseImage) async {
    const canvasSize = 512.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    if (selectedBackgroundPath.value != null) {
      try {
        final byteData = await rootBundle.load(selectedBackgroundPath.value!);
        final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        final backgroundImage = frame.image;

        canvas.drawImageRect(
          backgroundImage,
          Rect.fromLTWH(
            0,
            0,
            backgroundImage.width.toDouble(),
            backgroundImage.height.toDouble(),
          ),
          Rect.fromLTWH(0, 0, canvasSize, canvasSize),
          Paint(),
        );

        backgroundImage.dispose();
        canvas.drawImage(baseImage, Offset.zero, Paint());
      } catch (e) {
        canvas.drawImage(baseImage, Offset.zero, Paint());
      }
    } else {
      canvas.drawImage(baseImage, Offset.zero, Paint());
    }

    for (final layer in stickerLayers) {
      try {
        final byteData = await rootBundle.load(layer.imagePath);
        final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        final stickerImage = frame.image;

        const stickerSizeRatio = 0.3;
        final baseStickerSize = canvasSize * stickerSizeRatio;
        final stickerSize = baseStickerSize * layer.scale;

        final stickerCenter = Offset(
          layer.position.dx + stickerSize / 2,
          layer.position.dy + stickerSize / 2,
        );

        final srcRect = Rect.fromLTWH(
          0,
          0,
          stickerImage.width.toDouble(),
          stickerImage.height.toDouble(),
        );
        final dstRect = Rect.fromCenter(
          center: stickerCenter,
          width: stickerSize,
          height: stickerSize,
        );

        canvas.save();
        canvas.translate(stickerCenter.dx, stickerCenter.dy);
        canvas.rotate(layer.rotation);
        canvas.translate(-stickerCenter.dx, -stickerCenter.dy);
        canvas.drawImageRect(stickerImage, srcRect, dstRect, Paint());
        canvas.restore();

        stickerImage.dispose();
      } catch (e) {
        debugPrint('Error rendering sticker layer ${layer.id}: $e');
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    picture.dispose();

    return image;
  }

  Future<void> showSaveStickerDialog() async {
    final allPacks = _packRepository.getAll().where((p) => !p.isAnimated).toList();
    UserStickerPack? selectedPack = allPacks.isNotEmpty ? allPacks.first : null;

    await Get.bottomSheet<void>(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Save Sticker',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    Get.back();
                    final packName = await AppDialogs.showPackNameInputDialog(
                      title: 'Create package',
                      initialText: '',
                      hintText: 'Sticker pack name...',
                    );
                    if (packName != null && packName.isNotEmpty) {
                      final newPack = _packRepository.createPack(
                        title: packName,
                        isAnimated: false,
                      );
                      await saveStickerToPack(newPack);
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'New Package',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (allPacks.isNotEmpty) ...[
                  const Text(
                    'Select package:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: allPacks.length,
                      itemBuilder: (context, index) {
                        final pack = allPacks[index];
                        final isSelected = selectedPack?.id == pack.id;
                        return InkWell(
                          onTap: () {
                            setDialogState(() => selectedPack = pack);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pack.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${pack.stickerFileUris.length} sticker${pack.stickerFileUris.length != 1 ? 's' : ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey[400],
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No packages yet. Create a new one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (allPacks.isNotEmpty)
                  ElevatedButton(
                    onPressed: () {
                      final packToSave = selectedPack ?? allPacks.first;
                      Get.back();
                      saveStickerToPack(packToSave);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Lưu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> openTools(EditTab tab) async {
    selectedTab.value = tab;

    if (tab == EditTab.text) {
      showPainter.value = false;
      await Get.to<bool>(
        () => TextEditScreen(controller: controller),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 200),
      );
      await Future.delayed(const Duration(milliseconds: 240));
      showPainter.value = true;
      return;
    }

    if (tab == EditTab.sticker) {
      final result = await Get.to<dynamic>(
        () => const StickerPickerScreen(),
        arguments: {'stickerUri': stickerFile.value!.uri.toString()},
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 250),
      );

      if (result != null) {
        if (result is List<StickerLayer>) {
          addStickerLayers(result);
        } else if (result is StickerLayer) {
          addStickerLayer(result);
        }
      }
      return;
    }

    if (tab == EditTab.background) {
      final result = await Get.to<String?>(
        () => const BackgroundPickerScreen(),
        arguments: {
          'stickerUri': stickerFile.value!.uri.toString(),
          'currentBackground': selectedBackgroundPath.value,
        },
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 250),
      );

      selectedBackgroundPath.value = result;
      return;
    }
  }

  void updateTransform(Matrix4 matrix, double scaleValue, Offset translationValue) {
    transformMatrix.value = matrix;
    scale.value = scaleValue;
    translation.value = translationValue;
  }

  void onStickerLayerTransform(StickerLayer updatedLayer) {
    final index = stickerLayers.indexWhere((l) => l.id == updatedLayer.id);
    if (index != -1) {
      stickerLayers[index] = updatedLayer;
    }
  }

  void onStickerLayerDelete(String layerId) {
    stickerLayers.removeWhere((l) => l.id == layerId);
    if (selectedStickerLayerId.value == layerId) {
      selectedStickerLayerId.value = null;
    }
  }

  void onStickerLayerTap(String layerId) {
    selectedStickerLayerId.value = layerId;
  }

  void setSelectedBackgroundPath(String? path) {
    selectedBackgroundPath.value = path;
  }

  void addStickerLayer(StickerLayer layer) {
    stickerLayers.add(layer);
    selectedStickerLayerId.value = layer.id;
  }

  void addStickerLayers(List<StickerLayer> layers) {
    stickerLayers.addAll(layers);
    if (layers.isNotEmpty) {
      selectedStickerLayerId.value = layers.last.id;
    }
  }
}
