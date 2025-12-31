import 'dart:math' as math;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class CircleCropLayerPainter extends EditorCropLayerPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
    ExtendedImageCropLayerPainter painter,
    Rect rect,
  ) {
    final cropRect = painter.cropRect;
    final maskColor = painter.maskColor;
    final lineColor = painter.lineColor;
    final lineHeight = painter.lineHeight;

    canvas.saveLayer(rect, Paint());
    canvas.drawRect(rect, Paint()..style = PaintingStyle.fill..color = maskColor);
    canvas.clipRRect(RRect.fromRectAndRadius(cropRect, Radius.circular(cropRect.width / 2)));
    canvas.drawRect(rect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    final circlePaint = Paint()
      ..color = lineColor
      ..strokeWidth = lineHeight
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      Offset(cropRect.left + cropRect.width / 2, cropRect.top + cropRect.height / 2),
      cropRect.width / 2,
      circlePaint,
    );
  }
}

class HeartCropLayerPainter extends EditorCropLayerPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
    ExtendedImageCropLayerPainter painter,
    Rect rect,
  ) {
    final cropRect = painter.cropRect;
    final maskColor = painter.maskColor;
    final lineColor = painter.lineColor;
    final lineHeight = painter.lineHeight;

    final heartPath = _buildHeartPath(cropRect);

    canvas.saveLayer(rect, Paint());
    canvas.drawRect(rect, Paint()..style = PaintingStyle.fill..color = maskColor);
    canvas.clipPath(heartPath);
    canvas.drawRect(rect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    final heartPaint = Paint()
      ..color = lineColor
      ..strokeWidth = lineHeight
      ..style = PaintingStyle.stroke;
    canvas.drawPath(heartPath, heartPaint);
  }

  Path _buildHeartPath(Rect rect) {
    final cx = rect.left + rect.width / 2;
    final cy = rect.top + rect.height / 2;
    const baseX = 16.0;
    const baseY = 17.0;
    final scaleX = (rect.width / (2 * baseX)) * 0.95;
    final scaleY = (rect.height / (2 * baseY)) * 0.95;

    final path = Path();
    var first = true;
    for (double t = 0; t <= math.pi * 2; t += 0.05) {
      final x = cx + scaleX * (16 * math.pow(math.sin(t), 3)).toDouble();
      final y = cy -
          scaleY *
              (13 * math.cos(t) -
                  5 * math.cos(2 * t) -
                  2 * math.cos(3 * t) -
                  math.cos(4 * t));
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
}
