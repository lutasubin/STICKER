import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sticker_app/data/service/image_processing_service.dart';
import 'package:sticker_app/data/service/remove_bg_service.dart';

/// Repository layer: Middle layer between ViewModel and Service
/// Handles data mapping and combines multiple services
class ImageProcessingRepository {
  final ImageProcessingService _imageService;
  final RemoveBgService _removeBgService;

  ImageProcessingRepository({
    ImageProcessingService? imageService,
    RemoveBgService? removeBgService,
  })  : _imageService = imageService ?? const ImageProcessingService(),
        _removeBgService = removeBgService ?? const RemoveBgService();

  /// Process image in isolate for manual crop
  Future<Uint8List> processImageInIsolate({
    required String imagePath,
    Rect? cropRect,
    required bool applyCircle,
    required bool applyHeart,
  }) async {
    return await compute(
      ImageProcessingService.processImageIsolate,
      {
        'imagePath': imagePath,
        'cropRect': cropRect != null
            ? {
                'left': cropRect.left,
                'top': cropRect.top,
                'right': cropRect.right,
                'bottom': cropRect.bottom,
              }
            : null,
        'applyCircle': applyCircle,
        'applyHeart': applyHeart,
      },
    );
  }

  /// Remove background using AI
  Future<Uint8List> removeBackground(File imageFile) async {
    return await _removeBgService.removeBackground(imageFile);
  }

  /// Encode PNG to WebP
  Future<Uint8List> encodeWebp(Uint8List pngBytes) async {
    return await _imageService.encodeWebp(pngBytes);
  }

  /// Save WebP file
  Future<String> saveWebpFile({
    required Uint8List webpBytes,
    required String packId,
    int? timestamp,
  }) async {
    return await _imageService.saveWebpFile(
      webpBytes: webpBytes,
      packId: packId,
      timestamp: timestamp,
    );
  }

  /// Save temporary PNG file
  Future<String> saveTempPngFile(Uint8List pngBytes) async {
    return await _imageService.saveTempPngFile(pngBytes);
  }
}
