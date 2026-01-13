import 'dart:io';

import 'package:flutter/material.dart';

class AddStickerTile extends StatelessWidget {
  const AddStickerTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = 12.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: const Color(0xFF00C979),
          radius: radius,
          strokeWidth: 2,
          dashLength: 6,
          gapLength: 4,
        ),
        child: const Center(
          child: CircleAvatar(
            backgroundColor: Color(0xFF00C979),
            child: Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
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
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        final extract = metric.extractPath(
          distance,
          next.clamp(0, metric.length),
        );
        canvas.drawPath(extract, paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}

class UserPackStickerGrid extends StatelessWidget {
  const UserPackStickerGrid({
    super.key,
    required this.stickers,
    required this.onAddSticker,
    required this.onOpenSticker,
  });

  final List<String> stickers;
  final VoidCallback onAddSticker;
  final void Function(String stickerUri) onOpenSticker;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: stickers.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            if (index == 0) {
              return AddStickerTile(onTap: onAddSticker);
            }

            final uri = stickers[index - 1];
            final file = File.fromUri(Uri.parse(uri));

            return GestureDetector(
              onTap: () => onOpenSticker(uri),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: const Color(0xFFF3F3F3),
                  child:
                      file.existsSync()
                          ? Image.file(
                            file,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Log error để debug
                              debugPrint(
                                '[UserPackStickerGrid] Failed to load image: $uri, error: $error',
                              );
                              return const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.black26,
                              );
                            },
                          )
                          : const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.black26,
                          ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
