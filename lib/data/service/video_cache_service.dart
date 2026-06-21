import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Service layer: Low-level video controller caching
/// Pure data access - no business logic
class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  // Cache video controllers theo file path
  final Map<String, _CachedVideoController> _cache = {};

  // Giới hạn số lượng controllers trong cache để tránh OutOfMemory
  static const int _maxCacheSize = 3;

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

      // Nếu cache đầy, dispose controller cũ nhất (referenceCount = 0)
      if (_cache.length >= _maxCacheSize) {
        debugPrint(
          '[VideoCacheService] Cache full (${_cache.length}/$_maxCacheSize), disposing oldest unused controller',
        );
        _evictOldestUnused();
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
        '[VideoCacheService] Controller cached for: $videoPath (refs: 1, cache size: ${_cache.length})',
      );
      return controller;
    } catch (e) {
      debugPrint('[VideoCacheService] Error creating controller: $e');
      return null;
    }
  }

  /// Release reference đến controller
  /// Khi referenceCount = 0, controller sẽ được dispose
  Future<void> releaseController(String videoPath) async {
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
        // Remove tất cả listeners trước khi dispose
        cached.controller.pause();
        // Dispose controller
        await cached.controller.dispose();
      } catch (e) {
        debugPrint('[VideoCacheService] Error disposing controller: $e');
      }
      _cache.remove(videoPath);
    }
  }

  /// Dispose tất cả cached controllers
  Future<void> disposeAll() async {
    debugPrint('[VideoCacheService] Disposing all cached controllers');
    for (final entry in _cache.entries) {
      try {
        entry.value.controller.pause();
        await entry.value.controller.dispose();
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

  /// Dispose controller cũ nhất không được sử dụng (referenceCount = 0)
  void _evictOldestUnused() {
    // Tìm controller có referenceCount = 0
    String? oldestUnused;
    for (final entry in _cache.entries) {
      if (entry.value.referenceCount <= 0) {
        oldestUnused = entry.key;
        break;
      }
    }

    // Nếu không có unused, dispose controller đầu tiên
    if (oldestUnused == null && _cache.isNotEmpty) {
      oldestUnused = _cache.keys.first;
    }

    if (oldestUnused != null) {
      debugPrint('[VideoCacheService] Evicting controller for: $oldestUnused');
      final cached = _cache[oldestUnused]!;
      try {
        cached.controller.removeListener(() {});
        cached.controller.pause();
        cached.controller.dispose();
      } catch (e) {
        debugPrint(
          '[VideoCacheService] Error disposing evicted controller: $e',
        );
      }
      _cache.remove(oldestUnused);
    }
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
