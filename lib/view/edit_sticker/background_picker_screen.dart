import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sticker_app/service/sticker/sticker_edit_service.dart';

/// Màn hình chọn background (tương tự StickerPickerScreen)
class BackgroundPickerScreen extends StatefulWidget {
  const BackgroundPickerScreen({super.key});

  @override
  State<BackgroundPickerScreen> createState() => _BackgroundPickerScreenState();
}

class _BackgroundPickerScreenState extends State<BackgroundPickerScreen> {
  final StickerEditService _service = StickerEditService();
  List<String> _backgrounds = [];
  bool _isLoading = true;
  String? _previewBackgroundPath; // Background đang preview

  // Background image (sticker gốc)
  File? _stickerFile;
  bool _isLoadingSticker = true;

  @override
  void initState() {
    super.initState();
    _loadStickerFile();
    _loadBackgrounds();
  }

  /// Load sticker file từ arguments
  Future<void> _loadStickerFile() async {
    try {
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null && args['stickerUri'] != null) {
        final stickerUri = args['stickerUri'] as String;
        _stickerFile = File.fromUri(Uri.parse(stickerUri));

        // Load background hiện tại nếu có (khi edit sticker đã có background)
        if (args['currentBackground'] != null) {
          final currentBg = args['currentBackground'] as String;
          setState(() {
            _previewBackgroundPath = currentBg;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading sticker file: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingSticker = false);
      }
    }
  }

  Future<void> _loadBackgrounds() async {
    setState(() => _isLoading = true);
    final backgrounds = await _service.getBackgrounds();
    if (mounted) {
      setState(() {
        _backgrounds = backgrounds;
        _isLoading = false;
      });
    }
  }

  void _onBackgroundSelected(String backgroundPath) {
    setState(() {
      _previewBackgroundPath = backgroundPath;
    });
  }

  void _onClearBackground() {
    setState(() {
      _previewBackgroundPath = null;
    });
  }

  void _onConfirm() {
    // Trả về background path đã chọn (null nếu không chọn)
    Get.back(result: _previewBackgroundPath);
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
                  Text(
                    'background_title'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFF00C979)),
                    onPressed: _onConfirm,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Preview area với sticker và background
            Expanded(
              child: Container(
                color: Colors.white,
                child: Center(
                  child:
                      _isLoadingSticker
                          ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF00C979),
                            ),
                          )
                          : _stickerFile == null
                          ? Center(
                            child: Text(
                              'no_sticker_preview'.tr,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                          : Stack(
                            children: [
                              // Background được chọn
                              if (_previewBackgroundPath != null)
                                Positioned.fill(
                                  child: Image.asset(
                                    _previewBackgroundPath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error_outline),
                                      );
                                    },
                                  ),
                                )
                              else
                                // Nền caro nếu không có background
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _CheckerboardPainter(
                                      light: const Color(0xFFF3F3F3),
                                      dark: const Color(0xFFE3E3E3),
                                      squareSize: 16,
                                    ),
                                  ),
                                ),
                              // Sticker gốc ở trên cùng
                              Positioned.fill(
                                child: Image.file(
                                  _stickerFile!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ),

            // Background selection grid
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  const Divider(height: 1),
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
                            : _backgrounds.isEmpty
                            ? const Center(
                              child: Text(
                                'Không có background nào',
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
                              itemCount:
                                  _backgrounds.length +
                                  1, // +1 cho "no background"
                              itemBuilder: (context, index) {
                                // Item đầu tiên là "no background"
                                if (index == 0) {
                                  final isSelected =
                                      _previewBackgroundPath == null;
                                  return GestureDetector(
                                    onTap: _onClearBackground,
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
                                      child: Stack(
                                        children: [
                                          // Diagonal line để chỉ "no background"
                                          CustomPaint(
                                            painter: _DiagonalLinePainter(),
                                            size: const Size(
                                              double.infinity,
                                              double.infinity,
                                            ),
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
                                  );
                                }

                                // Các background khác
                                final backgroundPath = _backgrounds[index - 1];
                                final isSelected =
                                    _previewBackgroundPath == backgroundPath;
                                return GestureDetector(
                                  onTap:
                                      () =>
                                          _onBackgroundSelected(backgroundPath),
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
                                            backgroundPath,
                                            fit: BoxFit.cover,
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

// Painter cho diagonal line (no background)
class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey[400]!
          ..strokeWidth = 2;

    // Vẽ đường chéo từ góc trên trái đến góc dưới phải
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _DiagonalLinePainter oldDelegate) => false;
}
