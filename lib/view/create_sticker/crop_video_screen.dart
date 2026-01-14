import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sticker_app/controller/animated_sticker/animated_sticker_controller.dart';
import 'package:sticker_app/helper/dialogs/app_dialogs.dart';
import 'package:sticker_app/model/user_sticker_pack.dart';
import 'package:sticker_app/router/router.dart';
import 'package:sticker_app/service/sticker/user_sticker_pack_service.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Màn hình crop video cho Animated Sticker
/// Flow: Chọn video -> Crop video -> Edit sticker -> Create
class CropVideoScreen extends StatefulWidget {
  const CropVideoScreen({super.key});

  @override
  State<CropVideoScreen> createState() => _CropVideoScreenState();
}

class _CropVideoScreenState extends State<CropVideoScreen> {
  late final UserStickerPack _pack;
  late final File _videoFile;
  late final Duration _videoDuration;
  String? _replaceStickerUri;
  bool _goToUserPackDetail = false;
  bool _isNewPack = false;

  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _processing = false;

  // Crop mode: manual (none), square, circle
  CropShapeMode _cropMode = CropShapeMode.manual; // Default: không có shape

  // Timeline selection (start/end time in seconds)
  final double _startTime = 0;
  double _endTime = 3; // Mặc định 3 giây

  @override
  void initState() {
    super.initState();

    // Initialize controller trước
    Get.put(AnimatedStickerController());

    try {
      final args = Get.arguments;
      if (args is! Map) {
        throw Exception('Expected Map arguments, got ${args.runtimeType}');
      }
      _pack = args['pack'] as UserStickerPack;
      _videoFile = args['videoFile'] as File;

      // Validate video file exists
      if (!_videoFile.existsSync()) {
        throw Exception('Video file does not exist: ${_videoFile.path}');
      }

      // Get video duration - có thể null nên cần handle
      final videoDurationArg = args['videoDuration'];
      if (videoDurationArg is Duration) {
        _videoDuration = videoDurationArg;
      } else if (videoDurationArg is int) {
        // Nếu là milliseconds
        _videoDuration = Duration(milliseconds: videoDurationArg);
      } else {
        // Fallback: sẽ lấy từ video controller sau khi initialize
        _videoDuration = const Duration(seconds: 5);
        debugPrint(
          '[CropVideoScreen] videoDuration not provided, using default 5s',
        );
      }

      _replaceStickerUri = args['replaceStickerUri'] as String?;
      _goToUserPackDetail = args['goToUserPackDetail'] == true;
      _isNewPack = args['isNewPack'] == true;

      // Set end time = min(duration, 5s) - WhatsApp animated sticker limit
      _endTime = _videoDuration.inSeconds.toDouble().clamp(1, 5);

      debugPrint(
        '[CropVideoScreen] Initializing with video: ${_videoFile.path}',
      );
      debugPrint(
        '[CropVideoScreen] Video duration: ${_videoDuration.inSeconds}s',
      );

      _initVideoPlayer();
    } catch (e, st) {
      debugPrint('CropVideoScreen initState error: $e');
      debugPrint(st.toString());
      if (mounted) {
        Get.snackbar(
          'error_generic_title'.tr,
          'Failed to initialize: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Get.back();
        });
      }
    }
  }

  Future<void> _initVideoPlayer() async {
    try {
      debugPrint(
        '[CropVideoScreen] Creating VideoPlayerController for: ${_videoFile.path}',
      );

      // Validate file exists
      if (!_videoFile.existsSync()) {
        throw Exception('Video file does not exist: ${_videoFile.path}');
      }

      _videoController = VideoPlayerController.file(_videoFile);

      debugPrint('[CropVideoScreen] Initializing VideoPlayerController...');
      await _videoController!.initialize();

      debugPrint(
        '[CropVideoScreen] VideoPlayerController initialized successfully',
      );
      debugPrint(
        '[CropVideoScreen] Video duration: ${_videoController!.value.duration.inSeconds}s',
      );
      debugPrint(
        '[CropVideoScreen] Video size: ${_videoController!.value.size}',
      );
      debugPrint(
        '[CropVideoScreen] Aspect ratio: ${_videoController!.value.aspectRatio}',
      );

      if (!mounted) {
        debugPrint(
          '[CropVideoScreen] Widget not mounted, disposing controller',
        );
        _videoController?.dispose();
        return;
      }

      // Update end time nếu duration thực tế nhỏ hơn end time hiện tại
      final actualDuration = _videoController!.value.duration;
      if (actualDuration.inSeconds > 0) {
        // Chỉ update end time, không gán lại _videoDuration (vì là late final)
        if (_endTime > actualDuration.inSeconds) {
          _endTime = actualDuration.inSeconds.toDouble().clamp(1, 5);
        }
        debugPrint(
          '[CropVideoScreen] Actual video duration: ${actualDuration.inSeconds}s, '
          'using endTime: ${_endTime}s',
        );
      }

      setState(() {
        _isInitialized = true;
      });

      debugPrint('[CropVideoScreen] Setting up video playback...');
      // Auto play và loop
      _videoController!.setLooping(true);
      await _videoController!.play();

      debugPrint('[CropVideoScreen] Video playback started');
    } catch (e, st) {
      debugPrint('[CropVideoScreen] _initVideoPlayer error: $e');
      debugPrint('[CropVideoScreen] Stack trace: $st');
      if (mounted) {
        Get.snackbar(
          'error_generic_title'.tr,
          'Cannot play video: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        // Quay lại màn trước sau 2 giây
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Get.back();
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    Get.delete<AnimatedStickerController>();
    super.dispose();
  }

  Future<void> _onNext() async {
    if (_processing) return;

    // Nếu là pack mới (từ create sticker flow), hiện dialog để chọn pack
    if (_isNewPack) {
      await _showSaveStickerDialog();
      return;
    }

    // Nếu là pack có sẵn (từ my sticker), process và lưu trực tiếp vào pack đó
    await _processAndSaveToPack(_pack);
  }

  /// Process video và lưu vào pack
  Future<void> _processAndSaveToPack(UserStickerPack pack) async {
    if (_processing) return;

    setState(() => _processing = true);

    try {
      // Validate duration (WhatsApp animated sticker limit: 1-5s)
      final duration = _endTime - _startTime;
      if (duration < 1) {
        throw Exception('animated_duration_too_short'.tr);
      }
      if (duration > 5) {
        throw Exception('animated_duration_too_long'.tr);
      }

      // Pause video trước khi process
      await _videoController?.pause();

      // Process video to animated WebP
      final controller = Get.find<AnimatedStickerController>();

      // Tạo output path
      final dir = await getApplicationDocumentsDirectory();
      final packDir = Directory(
        '${dir.path}${Platform.pathSeparator}stickers${Platform.pathSeparator}${pack.id}',
      );
      if (!await packDir.exists()) {
        await packDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath =
          '${packDir.path}${Platform.pathSeparator}$timestamp.webp';

      // Process video
      final result = await controller.processVideoToAnimatedSticker(
        videoFile: _videoFile,
        outputPath: outputPath,
        startTime: _startTime,
        endTime: _endTime,
        cropMode: _cropMode,
      );

      if (result == null) {
        throw Exception('Failed to process video');
      }

      // Save to pack
      final service = Get.find<UserStickerPackService>();
      final outputUri = Uri.file(result).toString();

      try {
        if (_replaceStickerUri != null) {
          // Replace existing sticker
          service.replaceStickerUri(
            packId: pack.id,
            oldStickerFileUri: _replaceStickerUri!,
            newStickerFileUri: outputUri,
          );
        } else {
          // Add new sticker - specify isAnimated = true vì đây là animated sticker
          service.addStickerUri(
            packId: pack.id,
            stickerFileUri: outputUri,
            isAnimatedSticker: true, // Đây là animated sticker từ video
          );
        }
      } catch (e) {
        // Validation error: sticker type không match với pack type
        if (mounted) {
          Get.snackbar(
            'Lỗi',
            e.toString(),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
        return; // Không navigate nếu có lỗi
      }

      if (!mounted) return;

      // Lấy pack đã được update
      final updatedPack = service.getById(pack.id)!;

      // Show success và navigate
      Get.snackbar(
        'success_title'.tr,
        'success_saved_to_pack'.trParams({'title': updatedPack.title}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF00C979),
        colorText: Colors.white,
      );

      // Navigate logic:
      // - Nếu là pack mới (_isNewPack) hoặc _goToUserPackDetail → navigate đến pack detail
      // - Ngược lại → navigate về My Sticker screen
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      try {
        if (_isNewPack) {
          // Pack mới: navigate đến pack detail screen
          Get.offAllNamed(AppRoutes.mySticker);
          Get.toNamed(AppRoutes.userPackDetail, arguments: updatedPack);
        } else if (_goToUserPackDetail) {
          // Thêm vào pack có sẵn từ pack detail: quay lại pack detail với data mới
          // Clear navigation stack và navigate đến pack detail
          // Để khi bấm back từ pack detail sẽ quay về mySticker, không phải select video
          Get.offAllNamed(AppRoutes.mySticker);
          Get.toNamed(AppRoutes.userPackDetail, arguments: updatedPack);
        } else {
          // Navigate về My Sticker screen
          Get.until((route) => route.settings.name == AppRoutes.mySticker);
        }
      } catch (e) {
        debugPrint('Navigation error: $e');
        // Fallback: navigate về My Sticker screen
        Get.offAllNamed(AppRoutes.mySticker);
        // Nếu là pack mới, navigate đến pack detail
        if (_isNewPack) {
          Get.toNamed(AppRoutes.userPackDetail, arguments: updatedPack);
        } else if (_goToUserPackDetail) {
          // Thêm vào pack có sẵn từ pack detail: quay lại pack detail với data mới
          // Clear navigation stack và navigate đến pack detail
          // Để khi bấm back từ pack detail sẽ quay về mySticker, không phải select video
          Get.toNamed(AppRoutes.userPackDetail, arguments: updatedPack);
        }
      }
    } catch (e, st) {
      debugPrint('_processAndSaveToPack error: $e');
      debugPrint('$st');
      if (mounted) {
        Get.snackbar(
          'error_generic_title'.tr,
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  /// Hiện dialog để chọn pack hoặc tạo pack mới (giống EditStickerScreen)
  Future<void> _showSaveStickerDialog() async {
    // Process video trước (tạo sticker file tạm)
    setState(() => _processing = true);

    String? tempStickerPath;
    try {
      // Validate duration
      final duration = _endTime - _startTime;
      if (duration < 1) {
        throw Exception('animated_duration_too_short'.tr);
      }
      if (duration > 5) {
        throw Exception('animated_duration_too_long'.tr);
      }

      // Pause video trước khi process
      await _videoController?.pause();

      // Process video to animated WebP
      final controller = Get.find<AnimatedStickerController>();

      // Tạo output path tạm (dùng temp directory)
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      tempStickerPath =
          '${dir.path}${Platform.pathSeparator}temp_video_$timestamp.webp';

      // Process video
      final result = await controller.processVideoToAnimatedSticker(
        videoFile: _videoFile,
        outputPath: tempStickerPath,
        startTime: _startTime,
        endTime: _endTime,
        cropMode: _cropMode,
      );

      if (result == null) {
        throw Exception('Failed to process video');
      }

      tempStickerPath = result;
    } catch (e, st) {
      debugPrint('_showSaveStickerDialog process error: $e');
      debugPrint('$st');
      if (mounted) {
        setState(() => _processing = false);
        Get.snackbar(
          'error_generic_title'.tr,
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() => _processing = false);

    final service = Get.find<UserStickerPackService>();
    // CHỈ hiển thị pack animated (vì đây là flow tạo sticker động)
    final allPacks = service.getAll().where((p) => p.isAnimated).toList();
    // Tự động chọn pack animated đầu tiên nếu có
    UserStickerPack? selectedPack = allPacks.isNotEmpty ? allPacks.first : null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title với indicator
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Save Sticker',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      // Indicator cho animated pack
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C979).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00C979),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.play_circle_outline,
                              size: 14,
                              color: Color(0xFF00C979),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Động',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF00C979),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // New Package button
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context); // Đóng bottom sheet trước
                      final packName = await AppDialogs.showPackNameInputDialog(
                        title: 'Create package',
                        initialText: '',
                        hintText: 'Sticker pack name...',
                      );
                      if (packName != null && packName.isNotEmpty) {
                        // Tạo pack mới với isAnimated = true (vì đây là flow tạo sticker động)
                        final newPack = service.createPack(
                          title: packName,
                          isAnimated: true,
                        );
                        await _saveTempStickerToPack(tempStickerPath!, newPack);
                      }
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'New Package',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C979),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // List of existing packs
                  if (allPacks.isNotEmpty) ...[
                    const Text(
                      'Select package:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: allPacks.length,
                        itemBuilder: (context, index) {
                          final pack = allPacks[index];
                          final isSelected = selectedPack?.id == pack.id;
                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedPack = pack;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? const Color(0xFF00C979)
                                          : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                pack.title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            // Indicator cho animated pack
                                            if (pack.isAnimated)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  left: 8,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF00C979,
                                                  ).withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF00C979,
                                                    ),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.play_circle_outline,
                                                      size: 12,
                                                      color: Color(0xFF00C979),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      'Động',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: const Color(
                                                          0xFF00C979,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${pack.stickerFileUris.length} sticker${pack.stickerFileUris.length != 1 ? 's' : ''}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color:
                                        isSelected
                                            ? const Color(0xFF00C979)
                                            : Colors.grey[400],
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No packages yet. Create a new one!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Save button
                  if (allPacks.isNotEmpty)
                    ElevatedButton(
                      onPressed: () {
                        final packToSave = selectedPack ?? allPacks.first;
                        Navigator.pop(context); // Đóng bottom sheet
                        _saveTempStickerToPack(tempStickerPath!, packToSave);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C979),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Lưu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Lưu sticker file tạm vào pack (move từ temp sang pack directory)
  Future<void> _saveTempStickerToPack(
    String tempStickerPath,
    UserStickerPack pack,
  ) async {
    if (_processing) return;

    setState(() => _processing = true);

    try {
      final tempFile = File(tempStickerPath);
      if (!await tempFile.exists()) {
        throw Exception('Temp sticker file not found');
      }

      // Tạo pack directory
      final dir = await getApplicationDocumentsDirectory();
      final packDir = Directory(
        '${dir.path}${Platform.pathSeparator}stickers${Platform.pathSeparator}${pack.id}',
      );
      if (!await packDir.exists()) {
        await packDir.create(recursive: true);
      }

      // Move file từ temp sang pack directory
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalPath =
          '${packDir.path}${Platform.pathSeparator}$timestamp.webp';
      await tempFile.copy(finalPath);
      await tempFile.delete(); // Xóa file tạm

      final service = Get.find<UserStickerPackService>();
      final outputUri = Uri.file(finalPath).toString();

      try {
        if (_replaceStickerUri != null) {
          // Replace existing sticker
          service.replaceStickerUri(
            packId: pack.id,
            oldStickerFileUri: _replaceStickerUri!,
            newStickerFileUri: outputUri,
          );
        } else {
          // Add new sticker - specify isAnimated = true vì đây là animated sticker
          service.addStickerUri(
            packId: pack.id,
            stickerFileUri: outputUri,
            isAnimatedSticker: true, // Đây là animated sticker từ video
          );
        }
      } catch (e) {
        // Validation error: sticker type không match với pack type
        if (mounted) {
          Get.snackbar(
            'Lỗi',
            e.toString(),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
        return; // Không navigate nếu có lỗi
      }

      if (!mounted) return;

      // Lấy pack đã được update
      final updatedPack = service.getById(pack.id)!;

      // Show success và navigate
      Get.snackbar(
        'success_title'.tr,
        'success_saved_to_pack'.trParams({'title': updatedPack.title}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF00C979),
        colorText: Colors.white,
      );

      // Navigate logic:
      // - Nếu là pack mới (_isNewPack) hoặc _goToUserPackDetail → navigate đến pack detail
      // - Ngược lại → navigate về My Sticker screen
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      try {
        if (_isNewPack) {
          // Pack mới: navigate đến pack detail screen
          Get.offAllNamed(AppRoutes.mySticker);
          Get.toNamed(AppRoutes.userPackDetail, arguments: updatedPack);
        } else if (_goToUserPackDetail) {
          // Thêm vào pack có sẵn từ pack detail: quay lại pack detail với data mới
          // Clear navigation stack và navigate đến pack detail
          // Để khi bấm back từ pack detail sẽ quay về mySticker, không phải select video
          Get.offAllNamed(AppRoutes.mySticker);
          Get.toNamed(AppRoutes.userPackDetail, arguments: updatedPack);
        } else {
          // Navigate về My Sticker screen
          Get.until((route) => route.settings.name == AppRoutes.mySticker);
        }
      } catch (e) {
        debugPrint('Navigation error: $e');
        // Fallback: navigate về My Sticker screen
        Get.offAllNamed(AppRoutes.mySticker);
        // Nếu là pack mới, navigate đến pack detail
        if (_isNewPack) {
          Get.toNamed(AppRoutes.userPackDetail, arguments: updatedPack);
        } else if (_goToUserPackDetail) {
          // Thêm vào pack có sẵn từ pack detail: quay lại pack detail với data mới
          // Clear navigation stack đã được thực hiện ở trên (Get.offAllNamed)
          // Chỉ cần navigate đến pack detail
          Get.toNamed(AppRoutes.userPackDetail, arguments: updatedPack);
        }
      }
    } catch (e, st) {
      debugPrint('_saveTempStickerToPack error: $e');
      debugPrint('$st');
      if (mounted) {
        Get.snackbar(
          'error_generic_title'.tr,
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: _processing ? null : Get.back,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          'crop_video_title'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_processing)
            TextButton(
              onPressed: _onNext,
              child: Text(
                'next'.tr,
                style: const TextStyle(
                  color: Color(0xFF00C979),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          _isInitialized
              ? Column(
                children: [
                  Expanded(child: _buildVideoPreview()),
                  _buildTimelineEditor(),
                  _buildCropModeSelector(),
                ],
              )
              : const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C979)),
                ),
              ),

          // Processing overlay - chỉ hiển thị vòng tròn loading đơn giản
          if (_processing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C979)),
                  strokeWidth: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Checkered background pattern
        Positioned.fill(
          child: CustomPaint(painter: _CheckeredBackgroundPainter()),
        ),
        // Video centered
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(controller),
                // Crop shape overlay
                if (_cropMode == CropShapeMode.circle)
                  CustomPaint(
                    painter: _CircleOverlayPainter(),
                    size: Size.infinite,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCropModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn hình cắt',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildCropModeButton(
                  icon:
                      Icons.not_interested, // vòng tròn có gạch chéo như design
                  label: 'Không có',
                  mode: CropShapeMode.manual,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCropModeButton(
                  icon: Icons.crop_square,
                  label: 'Hình vuông',
                  mode: CropShapeMode.square,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCropModeButton(
                  icon: Icons.circle_outlined,
                  label: 'Hình tròn',
                  mode: CropShapeMode.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCropModeButton({
    required IconData icon,
    required String label,
    required CropShapeMode mode,
  }) {
    final isSelected = _cropMode == mode;
    return InkWell(
      onTap: () {
        setState(() => _cropMode = mode);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          size: 60,
          color: isSelected ? const Color(0xFF00C979) : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildTimelineEditor() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Column(
        children: [
          // Video thumbnails strip
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border(
                top: const BorderSide(color: Color(0xFF00C979), width: 2),
                bottom: const BorderSide(color: Color(0xFF00C979), width: 2),
                left: const BorderSide(color: Color(0xFF00C979), width: 2),
                right: BorderSide.none,
              ),
            ),
            child: Stack(
              children: [
                // Thumbnails row
                Row(
                  children: List.generate(7, (index) {
                    return Expanded(
                      child: Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.all(0),
                            decoration: BoxDecoration(color: Colors.grey[300]),
                            child: FutureBuilder<Uint8List?>(
                              future: _generateThumbnail(index),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          // Vertical divider between frames (except last)
                          if (index < 6)
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(width: 1, color: Colors.white),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
                // Right trim indicator (green border)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: const BoxDecoration(color: Color(0xFF00C979)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Duration text
          Text(
            (_endTime - _startTime).toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Generate thumbnail for timeline
  Future<Uint8List?> _generateThumbnail(int index) async {
    try {
      final position = (_videoDuration.inMilliseconds / 7 * index).toInt();
      final thumbnailData = await VideoThumbnail.thumbnailData(
        video: _videoFile.path,
        imageFormat: ImageFormat.PNG,
        timeMs: position,
        quality: 50,
      );
      return thumbnailData;
    } catch (e) {
      return null;
    }
  }
}

/// Custom painter để vẽ checkered background (transparent pattern)
class _CheckeredBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const squareSize = 12.0; // Kích thước mỗi ô vuông (nhỏ hơn để rõ hơn)
    final paint1 = Paint()..color = const Color(0xFFE0E0E0); // Xám đậm hơn
    final paint2 = Paint()..color = Colors.white;

    // Vẽ pattern caro
    for (var y = 0.0; y < size.height; y += squareSize) {
      for (var x = 0.0; x < size.width; x += squareSize) {
        final isEvenRow = (y ~/ squareSize) % 2 == 0;
        final isEvenCol = (x ~/ squareSize) % 2 == 0;
        final paint = (isEvenRow == isEvenCol) ? paint1 : paint2;

        canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter để vẽ circle overlay
class _CircleOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.9;

    // Draw outer dim area
    final outerPaint =
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, outerPaint);

    // Clear circle in the middle
    final circlePaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawCircle(center, radius, circlePaint);

    // Draw circle border
    final borderPaint =
        Paint()
          ..color = const Color(0xFF00C979)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}