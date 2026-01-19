import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:sticker_app/data/service/video_cache_service.dart';

/// Repository layer: Middle layer between ViewModel and Service
/// Handles data mapping and combines multiple services if needed
class VideoCacheRepository {
  final VideoCacheService _service;

  VideoCacheRepository({VideoCacheService? service})
      : _service = service ?? VideoCacheService();

  /// Get or create video controller with caching
  Future<VideoPlayerController?> getOrCreateController({
    required String videoPath,
    double? startTime,
    double? endTime,
    required VoidCallback onLoop,
  }) async {
    return await _service.getOrCreateController(
      videoPath: videoPath,
      startTime: startTime,
      endTime: endTime,
      onLoop: onLoop,
    );
  }

  /// Release controller reference
  Future<void> releaseController(String videoPath) async {
    await _service.releaseController(videoPath);
  }

  /// Check if video is cached
  bool isCached(String videoPath) {
    return _service.isCached(videoPath);
  }

  /// Dispose all cached controllers
  Future<void> disposeAll() async {
    await _service.disposeAll();
  }
}
