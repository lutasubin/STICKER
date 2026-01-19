import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Service để cache và share video controller giữa các màn hình
/// Giúp tránh load video nhiều lần, tối ưu performance
class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  // Cache video controllers theo file path
  final Map<String, _CachedVideoController> _cache = {};

  /// Lấy hoặc tạo video controller cho file path
  /// Nếu đã có trong cache, trả về controller đã có
  /// Nếu chưa có, tạo mới và cache lại
  Future<VideoPlayerController?> getOrCreateController({
    required String videoPath,
    double? startTime,
    double? endTime,
    required VoidCallback onLoop,
  }) async {
    try {
      final file = File(videoPath);
      if (!file.existsSync()) {
        debugPrint('[VideoCacheService] Video file does not exist: $videoPath');
        return null;
      }

      // Kiểm tra cache
      if (_cache.containsKey(videoPath)) {
        final cached = _cache[videoPath]!;
        cached.referenceCount++;
        debugPrint(
          '[VideoCacheService] Reusing cached controller for: $videoPath (refs: ${cached.referenceCount})',
        );
        return cached.controller;
      }

      // Tạo mới controller
      debugPrint('[VideoCacheService] Creating new controller for: $videoPath');
      final controller = VideoPlayerController.file(file);
      await controller.initialize();

      // Setup looping = false (mỗi màn hình sẽ tự add listener riêng)
      controller.setLooping(false);

      // Cache controller
      _cache[videoPath] = _CachedVideoController(
        controller: controller,
        referenceCount: 1,
        startTime: startTime,
        endTime: endTime,
        onLoop: onLoop,
      );

      debugPrint(
        '[VideoCacheService] Controller cached for: $videoPath (refs: 1)',
      );
      return controller;
    } catch (e) {
      debugPrint('[VideoCacheService] Error creating controller: $e');
      return null;
    }
  }

  // Throttle cho loop listener để tránh lag
  final Map<String, DateTime> _lastLoopCheck = {};

  /// Tạo loop listener cho video trong khoảng startTime-endTime
  void _createLoopListener(
    VideoPlayerController controller,
    double startTime,
    double endTime,
    VoidCallback onLoop,
  ) {
    try {
      final value = controller.value;
      if (!value.isPlaying) return;

      // Throttle: chỉ check mỗi 100ms
      final now = DateTime.now();
      final cacheKey = controller.hashCode.toString();
      if (_lastLoopCheck.containsKey(cacheKey)) {
        final diff = now.difference(_lastLoopCheck[cacheKey]!);
        if (diff.inMilliseconds < 100) {
          return; // Skip nếu chưa đủ 100ms
        }
      }
      _lastLoopCheck[cacheKey] = now;

      final currentTime = value.position.inMilliseconds / 1000.0;
      if (currentTime >= endTime - 0.2) {
        controller.seekTo(Duration(milliseconds: (startTime * 1000).toInt()));
        onLoop();
      }
    } catch (e) {
      debugPrint('[VideoCacheService] Error in loop listener: $e');
    }
  }

  /// Release reference đến controller
  /// Khi referenceCount = 0, controller sẽ được dispose
  void releaseController(String videoPath) {
    if (!_cache.containsKey(videoPath)) {
      return;
    }

    final cached = _cache[videoPath]!;
    cached.referenceCount--;

    debugPrint(
      '[VideoCacheService] Released controller for: $videoPath (refs: ${cached.referenceCount})',
    );

    // Nếu không còn ai dùng, dispose và remove khỏi cache
    if (cached.referenceCount <= 0) {
      debugPrint('[VideoCacheService] Disposing controller for: $videoPath');
      try {
        cached.controller.removeListener(() {});
        cached.controller.pause();
        cached.controller.dispose();
      } catch (e) {
        debugPrint('[VideoCacheService] Error disposing controller: $e');
      }
      _cache.remove(videoPath);
    }
  }

  /// Dispose tất cả cached controllers
  void disposeAll() {
    debugPrint('[VideoCacheService] Disposing all cached controllers');
    for (final entry in _cache.entries) {
      try {
        entry.value.controller.removeListener(() {});
        entry.value.controller.pause();
        entry.value.controller.dispose();
      } catch (e) {
        debugPrint(
          '[VideoCacheService] Error disposing controller for ${entry.key}: $e',
        );
      }
    }
    _cache.clear();
  }

  /// Kiểm tra xem video path có trong cache không
  bool isCached(String videoPath) {
    return _cache.containsKey(videoPath);
  }
}

/// Wrapper cho cached video controller với reference counting
class _CachedVideoController {
  final VideoPlayerController controller;
  int referenceCount;
  final double? startTime;
  final double? endTime;
  final VoidCallback onLoop;

  _CachedVideoController({
    required this.controller,
    required this.referenceCount,
    this.startTime,
    this.endTime,
    required this.onLoop,
  });
}
