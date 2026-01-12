import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sticker_app/helper/dialogs/app_dialogs.dart';
import 'package:sticker_app/model/user_sticker_pack.dart';
import 'package:sticker_app/router/router.dart';
import 'package:sticker_app/service/sticker/user_sticker_pack_service.dart';
import 'package:sticker_app/view/edit_sticker/text_edit_screen.dart';
import 'package:sticker_app/view/edit_sticker/sticker_picker_screen.dart';
import 'package:sticker_app/view/edit_sticker/widgets/sticker_layer_widget.dart';

enum EditTab { text, sticker, background }

class EditStickerScreen extends StatefulWidget {
  const EditStickerScreen({super.key});

  @override
  State<EditStickerScreen> createState() => _EditStickerScreenState();
}

class _EditStickerScreenState extends State<EditStickerScreen>
    with TickerProviderStateMixin {
  late final File _stickerFile;
  late final PainterController _controller;
  EditTab _selectedTab = EditTab.text;

  late final UserStickerPack _pack;
  String? _replaceStickerUri;
  bool _isNewPack = false;

  bool _showPainter = true;
  bool _isLoadingSticker = true; // Thêm loading state

  bool _saving = false;

  String? _tempStickerUri; // Lưu temp file URI nếu có
  String? _backgroundWebpUri; // Lưu WebP đã compress trong background

  // Transform state cho sticker
  Matrix4 _transformMatrix = Matrix4.identity();
  double _scale = 1.0;
  Offset _translation = Offset.zero;

  // Sticker layers state
  final List<StickerLayer> _stickerLayers = [];
  String? _selectedStickerLayerId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map;
    final stickerUri = args['stickerUri'] as String;
    final isTempFile = args['isTempFile'] == true;
    _stickerFile = File.fromUri(Uri.parse(stickerUri));

    if (isTempFile) {
      // Nếu là file tạm, lưu URI để dùng khi save
      _tempStickerUri = stickerUri;
      // Tìm file WebP đã compress trong background (nếu có)
      _tryFindBackgroundWebp(stickerUri);
    }

    _pack = args['pack'] as UserStickerPack;
    _replaceStickerUri = args['replaceStickerUri'] as String?;
    _isNewPack = args['isNewPack'] == true;

    _controller =
        PainterController()
          ..freeStyleSettings = FreeStyleSettings(mode: FreeStyleMode.none)
          ..textSettings = TextSettings(
            textStyle: const TextStyle(
              fontSize: 24,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            focusNode: FocusNode(),
          );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStickerAsBackground();
    });
  }

  /// Tìm file WebP đã được compress trong background
  Future<void> _tryFindBackgroundWebp(String tempUri) async {
    try {
      // Extract timestamp từ temp file path
      final tempFile = File.fromUri(Uri.parse(tempUri));
      final fileName = tempFile.path.split(Platform.pathSeparator).last;
      final match = RegExp(r'temp_(\d+)\.png').firstMatch(fileName);
      if (match != null) {
        final timestamp = match.group(1);
        final dir = await getApplicationDocumentsDirectory();
        final webpPath =
            '${dir.path}${Platform.pathSeparator}stickers${Platform.pathSeparator}${_pack.id}${Platform.pathSeparator}$timestamp.webp';
        final webpFile = File(webpPath);
        if (await webpFile.exists()) {
          _backgroundWebpUri = Uri.file(webpPath).toString();
          debugPrint('Found background WebP: $_backgroundWebpUri');
        }
      }
    } catch (e) {
      debugPrint('Error finding background WebP: $e');
    }
  }

  Future<void> _loadStickerAsBackground() async {
    try {
      final uiImage = await FileImage(_stickerFile).image;
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Future.microtask(() {
          if (!mounted) return;
          _controller.background = uiImage.backgroundDrawable;
          WidgetsBinding.instance.addPostFrameCallback((__) {
            if (!mounted) return;
            setState(() => _isLoadingSticker = false); // Đánh dấu đã load xong
          });
        });
      });
    } catch (e) {
      debugPrint('Error loading sticker: $e');
      if (mounted) {
        setState(() => _isLoadingSticker = false);
        AppDialogs.showError('Không thể load sticker: $e');
      }
    }
  }

  Future<void> _onCreate() async {
    if (_saving) return;

    // Nếu là pack mới (từ create sticker flow), hiện dialog để chọn pack
    if (_isNewPack) {
      await _showSaveStickerDialog();
      return;
    }

    // Nếu là pack có sẵn (từ my sticker), thêm trực tiếp vào pack đó
    await _saveStickerToPack(_pack);
  }

  /// Render sticker layers lên canvas
  Future<ui.Image> _renderStickerLayers(ui.Image baseImage) async {
    const canvasSize = 512.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Vẽ base image
    canvas.drawImage(baseImage, Offset.zero, Paint());

    // Vẽ từng sticker layer
    for (final layer in _stickerLayers) {
      try {
        final byteData = await rootBundle.load(layer.imagePath);
        final codec = await ui.instantiateImageCodec(
          byteData.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        final stickerImage = frame.image;

        // Tính toán kích thước và vị trí (tỷ lệ 30% so với canvas)
        // TẤT CẢ TÍNH TOÁN ĐỀU DÙNG CANVAS COORDINATES (512x512)
        const stickerSizeRatio = 0.3;
        final baseStickerSize = canvasSize * stickerSizeRatio;
        final stickerSize = baseStickerSize * layer.scale;

        // Position được lưu trong canvas coordinates (512x512) - top-left của sticker
        // Tính center của sticker trong canvas coordinates
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

        // Lưu canvas state
        canvas.save();

        // Áp dụng rotation - rotate từ center (trong canvas coordinates)
        canvas.translate(stickerCenter.dx, stickerCenter.dy);
        canvas.rotate(layer.rotation);
        canvas.translate(-stickerCenter.dx, -stickerCenter.dy);

        // Vẽ sticker (tất cả trong canvas coordinates 512x512)
        canvas.drawImageRect(stickerImage, srcRect, dstRect, Paint());

        // Restore canvas state
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

  Future<void> _saveStickerToPack(UserStickerPack pack) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final baseImage = await _controller.renderImage(const Size(512, 512));
      ui.Image finalImage;

      // Render sticker layers nếu có
      if (_stickerLayers.isNotEmpty) {
        finalImage = await _renderStickerLayers(baseImage);
        baseImage.dispose(); // Dispose base image vì đã merge vào finalImage
      } else {
        finalImage = baseImage;
      }

      final pngBytes = await finalImage.pngBytes;
      if (pngBytes == null) throw Exception('Failed to render PNG');

      // Dispose final image sau khi đã lấy bytes
      if (_stickerLayers.isNotEmpty) {
        finalImage.dispose();
      }

      // Luôn compress WebP mới (vì có thể đã chỉnh sửa trong EditScreen)
      final webpBytes = await _encodeWebp(pngBytes);
      final dir = await getApplicationDocumentsDirectory();
      final outDir = Directory(
        '${dir.path}${Platform.pathSeparator}stickers${Platform.pathSeparator}${pack.id}',
      );
      if (!await outDir.exists()) {
        await outDir.create(recursive: true);
      }
      final outFile = File(
        '${outDir.path}${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}.webp',
      );
      await outFile.writeAsBytes(webpBytes, flush: true);
      final fileUri = Uri.file(outFile.path).toString();

      // Xóa file tạm PNG nếu có
      if (_tempStickerUri != null) {
        try {
          final tempFile = File.fromUri(Uri.parse(_tempStickerUri!));
          if (await tempFile.exists()) {
            await tempFile.delete();
            debugPrint('Deleted temp PNG file');
          }
        } catch (e) {
          debugPrint('Error deleting temp file: $e');
        }
      }

      final service = Get.find<UserStickerPackService>();
      UserStickerPack updatedPack;

      if (_replaceStickerUri != null) {
        service.replaceStickerUri(
          packId: pack.id,
          oldStickerFileUri: _replaceStickerUri!,
          newStickerFileUri: fileUri,
          deleteOldFile: true,
        );
        // Lấy pack đã được update
        updatedPack = service.getById(pack.id)!;
      } else {
        service.addStickerUri(packId: pack.id, stickerFileUri: fileUri);
        // Lấy pack đã được update
        updatedPack = service.getById(pack.id)!;
      }

      PaintingBinding.instance.imageCache.evict(FileImage(_stickerFile));

      // Luôn navigate về pack detail sau khi create
      Get.offAllNamed(AppRoutes.mySticker);
      Get.toNamed(AppRoutes.userPackDetail, arguments: updatedPack);

      AppDialogs.showSuccess(
        'success_saved_to_pack'.trParams({'title': updatedPack.title}),
      );
    } catch (e) {
      if (mounted) AppDialogs.showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showSaveStickerDialog() async {
    final service = Get.find<UserStickerPackService>();
    final allPacks = service.getAll();
    // Tự động chọn pack đầu tiên nếu có
    UserStickerPack? selectedPack = allPacks.isNotEmpty ? allPacks.first : null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  const Text(
                    'Save Sticker',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // New Package button
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context); // Đóng bottom sheet trước
                      final packName = await AppDialogs.showPackNameInputDialog(
                        title: 'Create package',
                        initialText: '',
                        hintText: 'Sticker pack name...',
                      );
                      if (packName != null && packName.isNotEmpty) {
                        final newPack = service.createPack(title: packName);
                        await _saveStickerToPack(newPack);
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
                      backgroundColor: const Color(0xFF00C979),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // List of existing packs
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
                              setDialogState(() {
                                selectedPack = pack;
                              });
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
                                  color:
                                      isSelected
                                          ? const Color(0xFF00C979)
                                          : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                    color:
                                        isSelected
                                            ? const Color(0xFF00C979)
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

                  // Save button
                  if (allPacks.isNotEmpty)
                    ElevatedButton(
                      onPressed: () {
                        final packToSave = selectedPack ?? allPacks.first;
                        Navigator.pop(context); // Đóng bottom sheet
                        _saveStickerToPack(packToSave);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C979),
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
              ),
            );
          },
        );
      },
    );
  }

  Future<Uint8List> _encodeWebp(Uint8List pngBytes) async {
    const maxBytes = 100 * 1024;
    const qualities = [95, 90, 85, 80, 75, 70, 65, 60, 55, 50, 45, 40, 35, 30];
    Uint8List? best;
    for (final q in qualities) {
      final out = await FlutterImageCompress.compressWithList(
        pngBytes,
        format: CompressFormat.webp,
        quality: q,
        keepExif: false,
      );
      if (best == null || out.length < best.length) {
        best = Uint8List.fromList(out);
      }
      if (out.length <= maxBytes) return Uint8List.fromList(out);
    }
    if (best != null) {
      throw Exception(
        'error_sticker_too_large'.trParams({
          'sizeKb': (best.length / 1024).toStringAsFixed(1),
        }),
      );
    }
    throw Exception('error_cannot_encode_webp'.tr);
  }

  Future<void> _openTools(EditTab tab) async {
    setState(() => _selectedTab = tab);

    if (tab == EditTab.text) {
      setState(() => _showPainter = false);
      await Get.to<bool>(
        () => TextEditScreen(controller: _controller),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 200),
      );
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 240));
      if (!mounted) return;
      setState(() => _showPainter = true);
      return;
    }

    if (tab == EditTab.sticker) {
      // Navigate đến màn hình chọn sticker riêng với background image
      final result = await Get.to<dynamic>(
        () => const StickerPickerScreen(),
        arguments: {'stickerUri': _stickerFile.uri.toString()},
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 250),
      );

      // Nếu có sticker layers được chọn (đã transform), thêm vào canvas
      if (result != null && mounted) {
        setState(() {
          // result có thể là List<StickerLayer> hoặc StickerLayer (backward compatibility)
          if (result is List<StickerLayer>) {
            // Nếu là list, thêm tất cả vào
            _stickerLayers.addAll(result);
            if (result.isNotEmpty) {
              _selectedStickerLayerId = result.last.id;
            }
          } else if (result is StickerLayer) {
            // Nếu là single layer (backward compatibility), thêm vào như cũ
            _stickerLayers.add(result);
            _selectedStickerLayerId = result.id;
          }
        });
      }
      return;
    }

    Widget child;
    switch (tab) {
      case EditTab.text:
        child = const SizedBox.shrink();
        break;
      case EditTab.sticker:
        child = const SizedBox.shrink();
        break;
      case EditTab.background:
        child = const SafeArea(
          child: Center(child: Text('Background tools (TODO)')),
        );
        break;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Cập nhật transform của sticker layer
  void _onStickerLayerTransform(StickerLayer updatedLayer) {
    setState(() {
      final index = _stickerLayers.indexWhere((l) => l.id == updatedLayer.id);
      if (index != -1) {
        _stickerLayers[index] = updatedLayer;
      }
    });
  }

  /// Xóa sticker layer
  void _onStickerLayerDelete(String layerId) {
    setState(() {
      _stickerLayers.removeWhere((l) => l.id == layerId);
      if (_selectedStickerLayerId == layerId) {
        _selectedStickerLayerId = null;
      }
    });
  }

  /// Chọn sticker layer
  void _onStickerLayerTap(String layerId) {
    setState(() {
      _selectedStickerLayerId = layerId;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Edit Sticker',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _onCreate,
            child:
                _saving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text(
                      'Create',
                      style: TextStyle(
                        color: Color(0xFF00C979),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Nền caro phủ toàn màn hình
          _CheckerboardBackground(),
          // Nội dung chính ở giữa
          Center(
            child: Builder(
              builder: (context) {
                // Kích thước cố định 512x512 cho canvas
                const canvasSize = 512.0;
                final screenSize = MediaQuery.sizeOf(context);
                final maxSize = screenSize.shortestSide * 0.85;
                final displaySize = canvasSize.clamp(200.0, maxSize);

                // Hiển thị loading khi đang load sticker
                if (_isLoadingSticker) {
                  return SizedBox(
                    width: displaySize,
                    height: displaySize,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF00C979),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Đang tải sticker...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  width: displaySize,
                  height: displaySize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Sticker với khả năng di chuyển và phóng to thu nhỏ
                      if (_showPainter)
                        Positioned.fill(
                          child: _TransformableSticker(
                            displaySize: displaySize,
                            canvasSize: canvasSize,
                            transformMatrix: _transformMatrix,
                            scale: _scale,
                            translation: _translation,
                            onTransformUpdate: (matrix, scale, translation) {
                              setState(() {
                                _transformMatrix = matrix;
                                _scale = scale;
                                _translation = translation;
                              });
                            },
                            child: SizedBox(
                              width: canvasSize,
                              height: canvasSize,
                              child: FlutterPainter(controller: _controller),
                            ),
                          ),
                        ),
                      // Sticker layers overlay - CHỈ HIỂN THỊ, KHÔNG CHO PHÉP CHỈNH SỬA
                      // Position được lưu trong canvas coordinates (512x512)
                      // Widget sẽ tự scale position lên display coordinates
                      if (_showPainter && _stickerLayers.isNotEmpty)
                        Positioned.fill(
                          child: IgnorePointer(
                            // Disable tất cả gesture trên màn edit
                            child: StickerLayersWidget(
                              layers: _stickerLayers,
                              canvasSize: canvasSize,
                              displayScale: displaySize / canvasSize,
                              selectedLayerId:
                                  null, // Không hiển thị selection border
                              onLayerTransform: _onStickerLayerTransform,
                              onLayerDelete: _onStickerLayerDelete,
                              onLayerTap: _onStickerLayerTap,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                iconPath: 'assets/icons/icon_edit_text.svg',
                label: 'Text',
                isSelected: _selectedTab == EditTab.text,
                onTap: () => _openTools(EditTab.text),
              ),
              _BottomNavItem(
                iconPath: 'assets/icons/icon_edit_sticker.svg',
                label: 'Sticker',
                isSelected: _selectedTab == EditTab.sticker,
                onTap: () => _openTools(EditTab.sticker),
              ),
              _BottomNavItem(
                iconPath: 'assets/icons/icon_edit_bckgroud.svg',
                label: 'Background',
                isSelected: _selectedTab == EditTab.background,
                onTap: () => _openTools(EditTab.background),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Nền caro phủ toàn màn hình
class _CheckerboardBackground extends StatelessWidget {
  const _CheckerboardBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CheckerboardPainter(
        light: const Color(0xFFF3F3F3),
        dark: const Color(0xFFE3E3E3),
        squareSize: 32,
        canvasSize: null, // null = phủ toàn màn hình
      ),
      size: Size.infinite,
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  _CheckerboardPainter({
    required this.light,
    required this.dark,
    required this.squareSize,
    this.canvasSize,
  });

  final Color light;
  final Color dark;
  final double squareSize;
  final double? canvasSize; // null = phủ toàn màn hình

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // Vẽ caro phủ toàn màn hình

    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isDark =
            ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 1;
        paint.color = isDark ? dark : light;
        canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) {
    return oldDelegate.light != light ||
        oldDelegate.dark != dark ||
        oldDelegate.squareSize != squareSize ||
        oldDelegate.canvasSize != canvasSize;
  }
}

// Widget cho phép di chuyển và phóng to thu nhỏ sticker
class _TransformableSticker extends StatefulWidget {
  const _TransformableSticker({
    required this.displaySize,
    required this.canvasSize,
    required this.transformMatrix,
    required this.scale,
    required this.translation,
    required this.onTransformUpdate,
    required this.child,
  });

  final double displaySize;
  final double canvasSize;
  final Matrix4 transformMatrix;
  final double scale;
  final Offset translation;
  final Function(Matrix4, double, Offset) onTransformUpdate;
  final Widget child;

  @override
  State<_TransformableSticker> createState() => _TransformableStickerState();
}

class _TransformableStickerState extends State<_TransformableSticker> {
  Matrix4 _matrix = Matrix4.identity();
  double _currentScale = 1.0;
  Offset _currentTranslation = Offset.zero;
  double _lastScale = 1.0;
  Offset _lastTranslation = Offset.zero;

  // ValueNotifier để tối ưu rebuild - chỉ rebuild Transform widget
  late final ValueNotifier<Matrix4> _matrixNotifier;

  // Flag để tránh gọi callback quá nhiều lần
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _matrix = widget.transformMatrix.clone();
    _currentScale = widget.scale;
    _currentTranslation = widget.translation;
    _lastScale = _currentScale;
    _lastTranslation = _currentTranslation;
    // Khởi tạo matrix nếu chưa có
    if (_currentScale != 1.0 || _currentTranslation != Offset.zero) {
      _matrix =
          Matrix4.identity()
            ..translate(_currentTranslation.dx, _currentTranslation.dy)
            ..scale(_currentScale);
    }
    _matrixNotifier = ValueNotifier<Matrix4>(_matrix);
  }

  @override
  void didUpdateWidget(_TransformableSticker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transformMatrix != widget.transformMatrix ||
        oldWidget.scale != widget.scale ||
        oldWidget.translation != widget.translation) {
      _currentScale = widget.scale;
      _currentTranslation = widget.translation;
      _lastScale = _currentScale;
      _lastTranslation = _currentTranslation;
      _matrix =
          Matrix4.identity()
            ..translate(_currentTranslation.dx, _currentTranslation.dy)
            ..scale(_currentScale);
      _matrixNotifier.value = _matrix;
    }
  }

  @override
  void dispose() {
    _matrixNotifier.dispose();
    super.dispose();
  }

  void _updateTransform(double scaleDelta, Offset translationDelta) {
    // Điều chỉnh tốc độ scale để mượt hơn, không bị nhảy quá nhanh
    final scaleSensitivity = 0.15;
    final adjustedScaleDelta = 1.0 + (scaleDelta - 1.0) * scaleSensitivity;

    // Tính scale mới
    final newScale = (_lastScale * adjustedScaleDelta).clamp(0.5, 3.0);

    // Tính translation mới - tối ưu bằng cách cache scaleRatio
    // Convert từ display coordinates sang canvas coordinates
    final scaleRatio = widget.displaySize / widget.canvasSize;
    final translationInCanvas = Offset(
      translationDelta.dx / scaleRatio,
      translationDelta.dy / scaleRatio,
    );

    // Tính translation mới - đơn giản hóa
    var newTranslation = Offset(
      _lastTranslation.dx + translationInCanvas.dx,
      _lastTranslation.dy + translationInCanvas.dy,
    );

    // Giới hạn translation - tối ưu bằng cách tính bounds nhanh hơn
    final halfCanvas = widget.canvasSize * 0.5;
    final halfSticker = widget.canvasSize * newScale * 0.5;

    // Tính bounds một lần duy nhất
    final double maxTranslate, minTranslate;
    if (newScale > 1.0) {
      // Sticker lớn hơn canvas
      final overflow = halfSticker - halfCanvas;
      maxTranslate = overflow;
      minTranslate = -overflow;
    } else {
      // Sticker nhỏ hơn hoặc bằng canvas
      final maxCenterOffset = halfCanvas - halfSticker;
      final minMoveDistance = widget.canvasSize * 0.4;
      maxTranslate =
          maxCenterOffset > minMoveDistance ? maxCenterOffset : minMoveDistance;
      minTranslate = -maxTranslate;
    }

    // Clamp translation - đơn giản và nhanh
    final clampedTranslation = Offset(
      newTranslation.dx.clamp(minTranslate, maxTranslate),
      newTranslation.dy.clamp(minTranslate, maxTranslate),
    );

    // Tạo matrix mới - tối ưu bằng cách set trực tiếp
    final newMatrix =
        Matrix4.identity()
          ..translate(clampedTranslation.dx, clampedTranslation.dy)
          ..scale(newScale);

    // Update state
    _matrix = newMatrix;
    _currentScale = newScale;
    _currentTranslation = clampedTranslation;

    // Update ValueNotifier - chỉ rebuild Transform widget
    // Đây là cách tối ưu nhất - chỉ rebuild Transform, không rebuild parent
    _matrixNotifier.value = _matrix;

    // Callback để parent update state - chỉ gọi khi cần, không block gesture
    // Defer callback để không làm chậm gesture update
    if (!_isUpdating) {
      _isUpdating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isUpdating = false;
        if (mounted) {
          widget.onTransformUpdate(_matrix, _currentScale, _currentTranslation);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // GestureDetector bao phủ toàn bộ vùng
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (details) {
              _lastScale = _currentScale;
              _lastTranslation = _currentTranslation;
            },
            onScaleUpdate: (details) {
              // Update transform trực tiếp, không cần setState
              // ValueNotifier sẽ tự động rebuild Transform widget
              _updateTransform(details.scale, details.focalPointDelta);
            },
            onScaleEnd: (details) {
              _lastScale = _currentScale;
              _lastTranslation = _currentTranslation;
            },
            child: Container(color: Colors.transparent),
          ),
        ),
        // Transform sticker với ValueListenableBuilder để chỉ rebuild Transform
        Center(
          child: IgnorePointer(
            ignoring: true,
            child: RepaintBoundary(
              child: ValueListenableBuilder<Matrix4>(
                valueListenable: _matrixNotifier,
                builder: (context, matrix, child) {
                  return Transform(
                    transform: matrix,
                    alignment: Alignment.center,
                    child: child,
                  );
                },
                child: SizedBox(
                  width: widget.canvasSize,
                  height: widget.canvasSize,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Bottom navigation item với SVG icon
class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.iconPath,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String iconPath;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                isSelected ? const Color(0xFF00C979) : Colors.black54,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF00C979) : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
