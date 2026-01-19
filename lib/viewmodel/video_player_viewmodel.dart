import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:sticker_app/data/repository/video_cache_repository.dart';

/// ViewModel for video player management
/// Handles business logic and state management for video playback
class VideoPlayerViewModel extends GetxController {
  final VideoCacheRepository _repository;

  VideoPlayerViewModel({VideoCacheRepository? repository})
    : _repository = repository ?? VideoCacheRepository();

  // State
  final videoController = Rxn<VideoPlayerController>();
  final isVideoReady = false.obs;
  final isVideoPlaying = false.obs;
  final videoError = Rxn<String>();

  String? _currentVideoPath;
  double? _startTime;
  double? _endTime;

  /// Initialize video player from file path
  Future<void> initializeVideo({
    required String videoPath,
    double? startTime,
    double? endTime,
    VoidCallback? onLoop,
  }) async {
    try {
      _currentVideoPath = videoPath;
      _startTime = startTime;
      _endTime = endTime;

      videoError.value = null;
      isVideoReady.value = false;

      final controller = await _repository.getOrCreateController(
        videoPath: videoPath,
        startTime: startTime,
        endTime: endTime,
        onLoop: onLoop ?? () {},
      );

      if (controller == null) {
        videoError.value = 'Failed to initialize video controller';
        return;
      }

      videoController.value = controller;
      isVideoReady.value = controller.value.isInitialized;

      // Add listener for state changes
      controller.addListener(_videoListener);
    } catch (e) {
      debugPrint('[VideoPlayerViewModel] Error initializing video: $e');
      videoError.value = e.toString();
    }
  }

  /// Video listener for state updates
  void _videoListener() {
    final controller = videoController.value;
    if (controller == null) return;

    isVideoPlaying.value = controller.value.isPlaying;
    isVideoReady.value = controller.value.isInitialized;

    if (controller.value.hasError) {
      videoError.value = controller.value.errorDescription;
    }
  }

  /// Play video
  Future<void> play() async {
    final controller = videoController.value;
    if (controller != null && controller.value.isInitialized) {
      await controller.play();
    }
  }

  /// Pause video
  Future<void> pause() async {
    final controller = videoController.value;
    if (controller != null && controller.value.isInitialized) {
      await controller.pause();
    }
  }

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    final controller = videoController.value;
    if (controller != null && controller.value.isInitialized) {
      await controller.seekTo(position);
    }
  }

  /// Remove video listener
  void removeVideoListener() {
    final controller = videoController.value;
    if (controller != null) {
      controller.removeListener(_videoListener);
    }
  }

  /// Reinitialize video controller (useful when resuming from another screen)
  Future<void> reinitializeController({VoidCallback? onLoop}) async {
    if (_currentVideoPath == null) return;

    try {
      // Remove old listener
      removeVideoListener();

      // Get controller from cache
      final controller = await _repository.getOrCreateController(
        videoPath: _currentVideoPath!,
        startTime: _startTime,
        endTime: _endTime,
        onLoop: onLoop ?? () {},
      );

      if (controller != null) {
        videoController.value = controller;
        controller.addListener(_videoListener);
        isVideoReady.value = controller.value.isInitialized;
      }
    } catch (e) {
      debugPrint('[VideoPlayerViewModel] Error reinitializing: $e');
      videoError.value = e.toString();
    }
  }

  @override
  void onClose() {
    // Release controller when ViewModel is disposed
    if (_currentVideoPath != null) {
      final path = _currentVideoPath!;
      Future.microtask(() async {
        await _repository.releaseController(path);
      });
    }
    removeVideoListener();
    super.onClose();
  }
}
