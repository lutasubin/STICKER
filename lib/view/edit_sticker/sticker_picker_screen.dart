import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sticker_app/service/sticker/sticker_edit_service.dart';
import 'package:sticker_app/service/sticker/video_cache_service.dart';
import 'package:sticker_app/view/edit_sticker/widgets/sticker_layer_widget.dart';
import 'package:video_player/video_player.dart';

/// Màn hình chọn sticker (tách riêng như trong ảnh)
class StickerPickerScreen extends StatefulWidget {
  const StickerPickerScreen({super.key});

  @override
  State<StickerPickerScreen> createState() => _StickerPickerScreenState();
}

class _StickerPickerScreenState extends State<StickerPickerScreen> {
  final StickerEditService _service = StickerEditService();
  StickerCategory _selectedCategory = StickerCategory.glass;
  List<String> _stickers = [];
  bool _isLoading = true;
  String? _selectedStickerPath;

  // Danh sách sticker layers để transform trên màn này
  final List<StickerLayer> _stickerLayers = [];
  String? _selectedStickerLayerId;
  static const double _canvasSize = 512.0;

  // Background image (sticker gốc) hoặc video player
  File? _backgroundImage;
  VideoPlayerController? _videoController; // Video player với loop
  bool _isLoadingBackground = true;
  bool _isDisposed = false;

  // Video info từ arguments
  String? _videoPath;
  double? _startTime;
  double? _endTime;

  @override
  void initState() {
    super.initState();
    _loadBackground();
    _loadStickers();
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Release video controller từ cache
    if (_videoController != null && _videoPath != null) {
      try {
        _videoController!.removeListener(_videoListener);
        _videoController!.pause();
        VideoCacheService().releaseController(_videoPath!);
      } catch (e) {
        debugPrint('Error releasing video controller: $e');
      }
      _videoController = null;
    }

    super.dispose();
  }

  void _videoListener() {
    if (_isDisposed || _videoController == null) return;
    // Listener được xử lý bởi VideoCacheService
  }

  /// Load background image hoặc video player từ arguments
  Future<void> _loadBackground() async {
    try {
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null) {
        // Ưu tiên video file nếu có (cho animated sticker)
        // Dùng VideoCacheService để reuse video controller đã load
        if (args['videoFile'] != null) {
          _videoPath = args['videoFile'] as String;
          _startTime = args['startTime'] as double?;
          _endTime = args['endTime'] as double?;

          final videoFile = File(_videoPath!);
          if (videoFile.existsSync()) {
            // Sử dụng VideoCacheService để lấy hoặc tạo controller
            _videoController = await VideoCacheService().getOrCreateController(
              videoPath: _videoPath!,
              startTime: _startTime,
              endTime: _endTime,
              onLoop: () {
                // Callback khi video loop
              },
            );

            if (_videoController != null && mounted && !_isDisposed) {
              _videoController!.addListener(_videoListener);

              // Seek đến startTime nếu có
              if (_startTime != null && _startTime! > 0) {
                await _videoController!.seekTo(
                  Duration(milliseconds: (_startTime! * 1000).toInt()),
                );
              }

              // Play video với loop
              await _videoController!.play();
            }
          } else {
            debugPrint('Video file does not exist: $_videoPath');
          }
        } else if (args['stickerUri'] != null) {
          // Load sticker image (cho static sticker)
          final stickerUri = args['stickerUri'] as String;
          _backgroundImage = File.fromUri(Uri.parse(stickerUri));
        }
      }
    } catch (e) {
      debugPrint('Error loading background: $e');
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoadingBackground = false);
      }
    }
  }

  Future<void> _loadStickers() async {
    setState(() => _isLoading = true);
    final stickers = await _service.getStickersByCategory(_selectedCategory);
    if (mounted) {
      setState(() {
        _stickers = stickers;
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(StickerCategory category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _selectedStickerPath = null; // Reset selection khi đổi category
      // Không reset sticker layers khi đổi category
    });
    _loadStickers();
  }

  /// Tính vị trí mặc định dựa trên category
  Offset _getDefaultPositionForCategory(StickerCategory category) {
    // Tất cả tính toán trong canvas coordinates (512x512)
    switch (category) {
      case StickerCategory.hat:
        // Mũ - ở trên đầu (phần trên của canvas)
        return Offset(_canvasSize * 0.5, _canvasSize * 0.15);
      case StickerCategory.glass:
        // Kính - ở vị trí mắt (giữa trên)
        return Offset(_canvasSize * 0.5, _canvasSize * 0.35);
      case StickerCategory.hair:
        // Tóc - ở trên đầu
        return Offset(_canvasSize * 0.5, _canvasSize * 0.2);
      case StickerCategory.accessory:
        // Phụ kiện - ở cổ/ngực (giữa)
        return Offset(_canvasSize * 0.5, _canvasSize * 0.5);
      case StickerCategory.love:
        // Tình yêu - ở giữa
        return Offset(_canvasSize * 0.5, _canvasSize * 0.5);
      case StickerCategory.birthday:
        // Sinh nhật - ở giữa
        return Offset(_canvasSize * 0.5, _canvasSize * 0.5);
      case StickerCategory.textStyle:
        // Text style - ở giữa dưới
        return Offset(_canvasSize * 0.5, _canvasSize * 0.7);
    }
  }

  void _onStickerSelected(String stickerPath) {
    setState(() {
      _selectedStickerPath = stickerPath;
      // Tạo sticker layer mới với vị trí mặc định dựa trên category
      // Offset một chút để tránh trùng với sticker cũ
      final existingCount = _stickerLayers.length;
      final defaultPosition = _getDefaultPositionForCategory(_selectedCategory);
      final offsetX = (existingCount % 3) * 30.0 - 30.0; // -30, 0, 30
      final offsetY = (existingCount ~/ 3) * 30.0;

      final newLayer = StickerLayer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: stickerPath,
        position: Offset(
          defaultPosition.dx + offsetX,
          defaultPosition.dy + offsetY,
        ),
        scale: 1.0,
        rotation: 0.0,
      );

      // Thêm vào list thay vì replace
      _stickerLayers.add(newLayer);
      _selectedStickerLayerId = newLayer.id;
    });
  }

  void _onStickerTransform(StickerLayer updatedLayer) {
    setState(() {
      final index = _stickerLayers.indexWhere((l) => l.id == updatedLayer.id);
      if (index != -1) {
        _stickerLayers[index] = updatedLayer;
      }
    });
  }

  void _onStickerDelete(String layerId) {
    setState(() {
      _stickerLayers.removeWhere((l) => l.id == layerId);
      if (_selectedStickerLayerId == layerId) {
        _selectedStickerLayerId =
            _stickerLayers.isNotEmpty ? _stickerLayers.last.id : null;
      }
    });
  }

  void _onStickerTap(String layerId) {
    setState(() {
      _selectedStickerLayerId = layerId;
    });
  }

  void _onConfirm() {
    // Trả về danh sách sticker layers đã được transform
    Get.back(result: _stickerLayers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header với nút đóng và tích
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sticker',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.check,
                      color:
                          _stickerLayers.isNotEmpty
                              ? const Color(0xFF00C979)
                              : Colors.grey,
                    ),
                    onPressed: _stickerLayers.isNotEmpty ? _onConfirm : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Canvas area với nền caro (chiếm toàn bộ màn hình)
            // Đảm bảo canvas được hiển thị với kích thước cố định và scale đúng
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Tính toán display scale GIỐNG HỆT màn edit
                  // Đảm bảo canvas vuông và fit trong màn hình
                  final screenWidth = constraints.maxWidth;
                  final screenHeight = constraints.maxHeight;
                  final shortestSide =
                      screenWidth < screenHeight ? screenWidth : screenHeight;
                  final maxSize = shortestSide * 0.85;
                  // Giới hạn kích thước hiển thị (GIỐNG HỆT màn edit)
                  final displaySize = _canvasSize.clamp(200.0, maxSize);
                  final displayScale = displaySize / _canvasSize;

                  return Container(
                    color: Colors.white,
                    child: Center(
                      child: SizedBox(
                        width: displaySize,
                        height: displaySize,
                        child: Stack(
                          children: [
                            // Nền caro
                            CustomPaint(
                              painter: _CheckerboardPainter(
                                light: const Color(0xFFF3F3F3),
                                dark: const Color(0xFFE3E3E3),
                                squareSize: 16,
                              ),
                              size: Size(displaySize, displaySize),
                            ),
                            // Background image hoặc video player (sticker gốc) - hiển thị với kích thước canvas
                            if (_isLoadingBackground)
                              const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF00C979),
                                  ),
                                ),
                              )
                            else if (_videoController != null &&
                                _videoController!.value.isInitialized &&
                                !_videoController!.value.hasError)
                              // Hiển thị video player với loop
                              Positioned.fill(
                                child: Center(
                                  child: AspectRatio(
                                    aspectRatio:
                                        _videoController!.value.aspectRatio,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                ),
                              )
                            else if (_backgroundImage != null)
                              // Hiển thị image nếu có
                              Positioned.fill(
                                child: Image.file(
                                  _backgroundImage!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            // Sticker layers có thể transform (hiển thị trên background)
                            if (_stickerLayers.isNotEmpty)
                              Positioned.fill(
                                child: StickerLayersWidget(
                                  layers: _stickerLayers,
                                  canvasSize: _canvasSize,
                                  displayScale: displayScale,
                                  selectedLayerId: _selectedStickerLayerId,
                                  onLayerTransform: _onStickerTransform,
                                  onLayerDelete: _onStickerDelete,
                                  onLayerTap: _onStickerTap,
                                  isEditable: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Sticker selection tray
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Hàng danh mục (category icons)
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: StickerCategory.values.length,
                      itemBuilder: (context, index) {
                        final category = StickerCategory.values[index];
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () => _onCategorySelected(category),
                          child: Container(
                            width: 50,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? const Color(
                                        0xFF00C979,
                                      ).withOpacity(0.15)
                                      : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  category.icon,
                                  color:
                                      isSelected
                                          ? const Color(0xFF00C979)
                                          : Colors.black54,
                                  size: 24,
                                ),
                                if (isSelected)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    height: 2,
                                    width: 30,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00C979),
                                      borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(1),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(height: 1),

                  // Lưới sticker
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    child:
                        _isLoading
                            ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF00C979),
                                ),
                              ),
                            )
                            : _stickers.isEmpty
                            ? const Center(
                              child: Text(
                                'Không có sticker nào',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            )
                            : GridView.builder(
                              scrollDirection: Axis.horizontal,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1,
                                  ),
                              itemCount: _stickers.length,
                              itemBuilder: (context, index) {
                                final stickerPath = _stickers[index];
                                final isSelected =
                                    _selectedStickerPath == stickerPath;
                                return GestureDetector(
                                  onTap: () => _onStickerSelected(stickerPath),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? const Color(0xFF00C979)
                                                : Colors.grey[300]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        children: [
                                          Image.asset(
                                            stickerPath,
                                            fit: BoxFit.contain,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Center(
                                                child: Icon(
                                                  Icons.error_outline,
                                                  color: Colors.grey,
                                                  size: 24,
                                                ),
                                              );
                                            },
                                          ),
                                          if (isSelected)
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF00C979,
                                                  ).withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Nền caro cho canvas
class _CheckerboardPainter extends CustomPainter {
  _CheckerboardPainter({
    required this.light,
    required this.dark,
    required this.squareSize,
  });

  final Color light;
  final Color dark;
  final double squareSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
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
        oldDelegate.squareSize != squareSize;
  }
}
