import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:sticker_app/controller/animated_sticker/animated_sticker_controller.dart'
    hide CropShapeMode;
import 'package:sticker_app/helper/dialogs/app_dialogs.dart';
import 'package:sticker_app/model/user_sticker_pack.dart';
import 'package:sticker_app/router/router.dart';
import 'package:sticker_app/data/service/user_sticker_pack_service.dart';
import 'package:sticker_app/viewmodel/crop_video_viewmodel.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Màn hình crop video cho Animated Sticker
/// Flow: Chọn video -> Crop video -> Edit sticker -> Create
class CropVideoScreen extends StatefulWidget {
  const CropVideoScreen({super.key});

  @override
  State<CropVideoScreen> createState() => _CropVideoScreenState();
}

class _CropVideoScreenState extends State<CropVideoScreen> {
  late CropVideoViewModel _viewModel;

  // Crop mode: manual (none), square, circle
  CropShapeMode _cropMode = CropShapeMode.manual; // Default: không có shape

  @override
  void initState() {
    super.initState();

    // Initialize ViewModel (ViewModel sẽ tự init từ arguments)
    _viewModel = Get.put(CropVideoViewModel());
    Get.put(AnimatedStickerController());
  }

  @override
  void dispose() {
    debugPrint('[CropVideoScreen] dispose() called');

    // Cleanup ViewModel và Controller (ViewModel sẽ tự dispose video controller)
    Get.delete<CropVideoViewModel>();
    Get.delete<AnimatedStickerController>();

    super.dispose();
    debugPrint('[CropVideoScreen] dispose() completed');
  }

  /// Hiện dialog để chọn pack hoặc tạo pack mới
  /// Sau khi chọn pack → Navigate đến EditAnimatedStickerScreen để add text
  Future<void> _showSaveStickerDialog() async {
    await _viewModel.showSaveStickerDialog();
  }

  // Helper method để show dialog (được gọi từ ViewModel)
  Future<void> _showSaveStickerDialogInternal() async {
    if (!mounted) return;

    final service = Get.find<UserStickerPackService>();
    // CHỈ hiển thị pack animated (vì đây là flow tạo sticker động)
    final allPacks = service.getAll().where((p) => p.isAnimated).toList();
    // Tự động chọn pack animated đầu tiên nếu có
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
                  // Title với indicator
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Save Sticker',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      // Indicator cho animated pack
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C979).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00C979),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.play_circle_outline,
                              size: 14,
                              color: Color(0xFF00C979),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Động',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF00C979),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                        // Tạo pack mới với isAnimated = true (vì đây là flow tạo sticker động)
                        final newPack = service.createPack(
                          title: packName,
                          isAnimated: true,
                        );
                        // Navigate đến edit screen để add text trên video
                        await _viewModel.navigateToEditScreen(newPack, null);
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
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                pack.title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            // Indicator cho animated pack
                                            if (pack.isAnimated)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  left: 8,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF00C979,
                                                  ).withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF00C979,
                                                    ),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.play_circle_outline,
                                                      size: 12,
                                                      color: Color(0xFF00C979),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      'Động',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: const Color(
                                                          0xFF00C979,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
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
                      onPressed: () async {
                        final packToSave = selectedPack ?? allPacks.first;
                        Navigator.pop(context); // Đóng bottom sheet
                        // Navigate đến edit screen để add text trên video
                        await _viewModel.navigateToEditScreen(packToSave, null);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Obx(
          () => IconButton(
            onPressed: _viewModel.processing.value ? null : Get.back,
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
        ),
        title: Text(
          'crop_video_title'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Obx(
            () =>
                _viewModel.processing.value
                    ? const SizedBox.shrink()
                    : TextButton(
                      onPressed: () => _viewModel.processAndNavigate(),
                      child: Text(
                        'next'.tr,
                        style: const TextStyle(
                          color: Color(0xFF00C979),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
          ),
        ],
      ),
      body: Obx(() {
        final isInitialized = _viewModel.isInitialized.value;
        final processing = _viewModel.processing.value;

        return Stack(
          children: [
            isInitialized
                ? Column(
                  children: [
                    Expanded(child: _buildVideoPreview()),
                    _buildTimelineEditor(),
                    _buildCropModeSelector(),
                  ],
                )
                : const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF00C979),
                    ),
                  ),
                ),

            // Processing overlay
            if (processing)
              Container(
                color: Colors.black87,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF00C979),
                    ),
                    strokeWidth: 4,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildVideoPreview() {
    return Obx(() {
      final controller = _viewModel.videoController.value;
      if (controller == null || !controller.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }

      return Stack(
        children: [
          // Checkered background pattern
          Positioned.fill(
            child: CustomPaint(painter: _CheckeredBackgroundPainter()),
          ),
          // Video centered
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(controller),
                  // Crop shape overlay
                  if (_cropMode == CropShapeMode.square)
                    CustomPaint(
                      painter: _SquareOverlayPainter(),
                      size: Size.infinite,
                    ),
                  if (_cropMode == CropShapeMode.circle)
                    CustomPaint(
                      painter: _CircleOverlayPainter(),
                      size: Size.infinite,
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCropModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn hình cắt',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildCropModeButton(
                  iconAsset: 'assets/icons/không.svg',
                  label: 'Không có',
                  mode: CropShapeMode.manual,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCropModeButton(
                  iconAsset: 'assets/icons/vuong.svg',
                  label: 'Hình vuông',
                  mode: CropShapeMode.square,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCropModeButton(
                  iconAsset: 'assets/icons/tròn.svg',
                  label: 'Hình tròn',
                  mode: CropShapeMode.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCropModeButton({
    required String iconAsset,
    required String label,
    required CropShapeMode mode,
  }) {
    return Obx(() {
      final isSelected = _viewModel.cropMode.value == mode;
      return InkWell(
        onTap: () {
          _viewModel.setCropMode(mode);
          setState(() => _cropMode = mode);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 40,
                height: 40,
                colorFilter: ColorFilter.mode(
                  isSelected ? const Color(0xFF00C979) : Colors.grey[600]!,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? const Color(0xFF00C979) : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTimelineEditor() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Column(
        children: [
          // Video thumbnails strip
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border(
                top: const BorderSide(color: Color(0xFF00C979), width: 2),
                bottom: const BorderSide(color: Color(0xFF00C979), width: 2),
                left: const BorderSide(color: Color(0xFF00C979), width: 2),
                right: BorderSide.none,
              ),
            ),
            child: Stack(
              children: [
                // Thumbnails row
                Row(
                  children: List.generate(7, (index) {
                    return Expanded(
                      child: Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.all(0),
                            decoration: BoxDecoration(color: Colors.grey[300]),
                            child: FutureBuilder<Uint8List?>(
                              future: _viewModel.generateThumbnail(index),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    cacheWidth: 100, // Giảm memory usage
                                    cacheHeight: 60,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          // Vertical divider between frames (except last)
                          if (index < 6)
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(width: 1, color: Colors.white),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
                // Right trim indicator (green border)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: const BoxDecoration(color: Color(0xFF00C979)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Duration text
          Obx(
            () => Text(
              (_viewModel.endTime.value - _viewModel.startTime.value)
                  .toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter để vẽ checkered background (transparent pattern)
class _CheckeredBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const squareSize = 12.0; // Kích thước mỗi ô vuông (nhỏ hơn để rõ hơn)
    final paint1 = Paint()..color = const Color(0xFFE0E0E0); // Xám đậm hơn
    final paint2 = Paint()..color = Colors.white;

    // Vẽ pattern caro
    for (var y = 0.0; y < size.height; y += squareSize) {
      for (var x = 0.0; x < size.width; x += squareSize) {
        final isEvenRow = (y ~/ squareSize) % 2 == 0;
        final isEvenCol = (x ~/ squareSize) % 2 == 0;
        final paint = (isEvenRow == isEvenCol) ? paint1 : paint2;

        canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter để vẽ square overlay
class _SquareOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Tính kích thước vuông (lấy cạnh nhỏ hơn để fit trong preview)
    final squareSize =
        (size.width < size.height ? size.width : size.height) * 0.9;

    final squareRect = Rect.fromCenter(
      center: center,
      width: squareSize,
      height: squareSize,
    );

    // Cần dùng saveLayer để BlendMode.clear hoạt động đúng
    canvas.saveLayer(Offset.zero & size, Paint());

    // Draw outer dim area
    final outerPaint =
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, outerPaint);

    // Clear square in the middle
    final squarePaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRect(squareRect, squarePaint);

    canvas.restore();

    // Draw square border (vẽ sau khi restore để border không bị clear)
    final borderPaint =
        Paint()
          ..color = const Color(0xFF00C979)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
    canvas.drawRect(squareRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter để vẽ circle overlay
class _CircleOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width : size.height) / 2 * 0.9;

    // Cần dùng saveLayer để BlendMode.clear hoạt động đúng
    canvas.saveLayer(Offset.zero & size, Paint());

    // Draw outer dim area
    final outerPaint =
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, outerPaint);

    // Clear circle in the middle
    final circlePaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawCircle(center, radius, circlePaint);

    canvas.restore();

    // Draw circle border (vẽ sau khi restore để border không bị clear)
    final borderPaint =
        Paint()
          ..color = const Color(0xFF00C979)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
