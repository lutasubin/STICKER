import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class CropEditor extends StatelessWidget {
  const CropEditor({
    super.key,
    required this.imageFile,
    required this.modeKey,
    required this.editorKey,
    required this.cropAspectRatio,
    required this.cropLayerPainter,
  });

  final File imageFile;
  final Object modeKey;
  final GlobalKey<ExtendedImageEditorState> editorKey;
  final double? cropAspectRatio;
  final EditorCropLayerPainter cropLayerPainter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExtendedImage.file(
          key: ValueKey(modeKey),
          imageFile,
          fit: BoxFit.contain,
          mode: ExtendedImageMode.editor,
          extendedImageEditorKey: editorKey,
          initEditorConfigHandler: (state) {
            return EditorConfig(
              maxScale: 8.0,
              cropRectPadding: const EdgeInsets.all(20.0),
              hitTestSize: 20.0,
              cropAspectRatio: cropAspectRatio,
              initCropRectType: InitCropRectType.imageRect,
              cropLayerPainter: cropLayerPainter,
            );
          },
        ),
      ),
    );
  }
}
