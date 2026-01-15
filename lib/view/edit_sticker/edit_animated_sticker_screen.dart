import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sticker_app/controller/animated_sticker/animated_sticker_controller.dart'
    show AnimatedStickerController, CropShapeMode;
import 'package:sticker_app/model/user_sticker_pack.dart';
import 'package:sticker_app/router/router.dart';
import 'package:sticker_app/service/sticker/user_sticker_pack_service.dart';
import 'package:sticker_app/view/edit_sticker/animated_text_edit_screen.dart';
import 'package:video_player/video_player.dart';

/// Model cho mỗi text item - dùng AnimatedTextItem từ animated_text_edit_screen.dart
typedef TextItem = AnimatedTextItem;

/// Text editor tabs - dùng từ animated_text_edit_screen.dart
typedef _TextEditorTab = AnimatedTextEditorTab;

/// Màn hình edit animated sticker - thêm text tĩnh vào sticker động
/// Pipeline: Render text → PNG → Overlay vào animated WebP → Export
class EditAnimatedStickerScreen extends StatefulWidget {
  const EditAnimatedStickerScreen({super.key});

  @override
  State<EditAnimatedStickerScreen> createState() =>
      _EditAnimatedStickerScreenState();
}

class _EditAnimatedStickerScreenState extends State<EditAnimatedStickerScreen> {
  // Video file (từ CropVideoScreen) - chưa convert
  File? _videoFile;
  double? _startTime;
  double? _endTime;
  CropShapeMode? _cropMode;

  // Sticker file (từ UserPackDetailScreen) - đã có sẵn
  File? _stickerFile;

  late final UserStickerPack _pack;
  String? _replaceStickerUri;
  bool _goToUserPackDetail = false;
  bool _isNewPack = false;

  // Text editor state - hỗ trợ nhiều text items
  List<TextItem> _textItems = [];
  String? _selectedTextId; // ID của text đang được chọn để edit
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode(); // FocusNode để quản lý focus
  final ValueNotifier<String> _textNotifier = ValueNotifier<String>(
    '',
  ); // ValueNotifier để update text overlay

  // Timer để debounce setState khi nhập text
  Timer? _textUpdateTimer;

  // Text editor tabs - giống sticker tĩnh
  _TextEditorTab _textEditorTab = _TextEditorTab.text;

  // Fonts list - giống sticker tĩnh
  static const List<String> _fonts = [
    'Roboto',
    'Risque',
    'Rockwell Condensed',
    'Satisfy',
    'Pacifico',
    'Segoe Script',
  ];

  // Color palette - giống sticker tĩnh
  static const List<Color> _palette = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Color(0xFF00C979),
  ];

  // Getter cho text item đang được chọn
  TextItem? get _selectedTextItem {
    if (_selectedTextId == null) return null;
    try {
      return _textItems.firstWhere((item) => item.id == _selectedTextId);
    } catch (e) {
      return null;
    }
  }

  // Preview state
  bool _isInitialized = false;
  bool _isProcessing = false;
  VideoPlayerController? _videoController;
  bool _isDisposed = false; // Flag để track dispose state

  // UI state
  final bool _showTextEditor = false;

  // Track controller ownership để tránh delete controller dùng chung
  bool _ownsAnimatedController = false;

  /// Helper method để setState an toàn (check mounted và disposed)
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  /// Video listener để xử lý khi video kết thúc hoặc có lỗi
  /// Tối ưu: Chỉ xử lý khi video thực sự kết thúc, không xử lý mỗi frame
  void _videoListener() {
    if (_isDisposed || _videoController == null) return;

    try {
      final value = _videoController!.value;

      // Chỉ xử lý khi video đã kết thúc và đang playing
      // Tránh xử lý mỗi frame để giảm memory usage
      if (value.isPlaying &&
          value.position >= value.duration &&
          value.duration > Duration.zero) {
        // Pause video khi kết thúc để tránh memory leak
        _videoController!.pause();
        // Seek về đầu để có thể play lại nếu cần
        _videoController!.seekTo(Duration.zero);
      }
    } catch (e) {
      debugPrint('Error in video listener: $e');
      // Nếu có lỗi, remove listener để tránh leak
      try {
        _videoController?.removeListener(_videoListener);
      } catch (e2) {
        debugPrint('Error removing listener: $e2');
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Đảm bảo AnimatedStickerController đã được inject
    // Nếu chưa có → tạo mới và đánh dấu là của màn này
    if (!Get.isRegistered<AnimatedStickerController>()) {
      Get.put(AnimatedStickerController());
      _ownsAnimatedController = true;
    }

    // Thêm listener cho TextEditingController để update _text
    // Không làm mất focus như onChanged
    _textController.addListener(_onTextChanged);

    _initFromArguments();
  }

  /// Listener cho TextEditingController - update text real-time mà không làm mất focus
  void _onTextChanged() {
    final newText = _textController.text;
    final selectedItem = _selectedTextItem;

    if (selectedItem != null && selectedItem.text != newText) {
      // Update text của item đang được chọn ngay lập tức
      final index = _textItems.indexWhere((item) => item.id == selectedItem.id);
      if (index != -1) {
        // Cập nhật text item ngay lập tức để overlay cập nhật real-time
        _textItems[index] = selectedItem.copyWith(text: newText);

        // Cập nhật ValueNotifier ngay lập tức (không debounce) để text overlay cập nhật real-time
        if (mounted && !_isDisposed) {
          _textNotifier.value = newText;
          // Trigger setState để rebuild overlay
          setState(() {
            // Chỉ cần setState để rebuild, text đã được update ở trên
          });
        }
      }
    }
  }

  /// Thêm text item mới
  void _addNewText() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newTextItem = TextItem(
      id: newId,
      text: '', // Để trống mặc định
      position: const Offset(256, 256), // Center
      textColor: Colors.white,
      fontSize: 40.0,
      scale: 1.0,
    );

    setState(() {
      _textItems.add(newTextItem);
      _selectedTextId = newId;
      _textController.text = ''; // Để trống
      _textNotifier.value = ''; // Cập nhật notifier
    });

    // Focus vào text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _textFocusNode.requestFocus();
      }
    });
  }

  /// Xóa text item
  void _deleteSelectedText() {
    if (_selectedTextId != null) {
      setState(() {
        _textItems.removeWhere((item) => item.id == _selectedTextId);
        _selectedTextId = _textItems.isNotEmpty ? _textItems.last.id : null;
        if (_selectedTextId != null) {
          _textController.text = _selectedTextItem?.text ?? '';
        } else {
          _textController.text = '';
        }
      });
    }
  }

  /// Chọn text item
  void _selectTextItem(String id) {
    setState(() {
      _selectedTextId = id;
      final item = _textItems.firstWhere((item) => item.id == id);
      _textController.text = item.text;
      _textNotifier.value = item.text;
    });
  }

  void _initFromArguments() {
    try {
      final args = Get.arguments;
      if (args is! Map) {
        throw Exception('Expected Map arguments, got ${args.runtimeType}');
      }

      final packArg = args['pack'];
      if (packArg == null || packArg is! UserStickerPack) {
        throw Exception('Pack is required but not provided or invalid');
      }
      _pack = packArg;
      _replaceStickerUri = args['replaceStickerUri'] as String?;
      _goToUserPackDetail = args['goToUserPackDetail'] == true;
      _isNewPack = args['isNewPack'] == true;

      // Flow 1: Từ CropVideoScreen - có videoFile, startTime, endTime, cropMode
      if (args.containsKey('videoFile')) {
        _videoFile = File(args['videoFile'] as String);
        _startTime = args['startTime'] as double? ?? 0.0;
        _endTime = args['endTime'] as double? ?? 3.0;
        final cropModeStr = args['cropMode'] as String?;
        if (cropModeStr != null) {
          // Parse cropMode từ name (manual, square, circle)
          _cropMode = CropShapeMode.values.firstWhere(
            (e) => e.name == cropModeStr,
            orElse: () => CropShapeMode.manual,
          );
        } else {
          _cropMode = CropShapeMode.manual;
        }

        if (!_videoFile!.existsSync()) {
          throw Exception('Video file does not exist: ${_videoFile!.path}');
        }
      }
      // Flow 2: Từ UserPackDetailScreen - có stickerUri (đã convert rồi)
      else if (args.containsKey('stickerUri')) {
        _stickerFile = File(
          (args['stickerUri'] as String).replaceFirst('file://', ''),
        );
        if (!_stickerFile!.existsSync()) {
          throw Exception('Sticker file does not exist: ${_stickerFile!.path}');
        }
      } else {
        throw Exception(
          'Missing required arguments: need either videoFile or stickerUri',
        );
      }

      // Gọi _initVideoPlayer async nhưng không block
      _initVideoPlayer().catchError((e) {
        debugPrint('_initVideoPlayer error in initState: $e');
      });
    } catch (e, st) {
      debugPrint('EditAnimatedStickerScreen initState error: $e');
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
    // Check mounted và dispose state trước khi bắt đầu
    if (!mounted || _isDisposed) return;

    try {
      if (_videoFile != null && _videoFile!.existsSync()) {
        // Dispose controller cũ nếu có (tránh leak)
        if (_videoController != null) {
          try {
            _videoController!.removeListener(_videoListener);
            await _videoController!.pause();
            await _videoController!.dispose();
          } catch (e) {
            debugPrint('Error disposing old video controller: $e');
          }
          _videoController = null;
        }

        // Check lại sau khi dispose
        if (!mounted || _isDisposed) return;

        // Initialize video player nếu có video file
        _videoController = VideoPlayerController.file(_videoFile!);

        // Initialize video
        await _videoController!.initialize();

        // Check mounted và dispose state sau mỗi async operation
        if (!mounted || _isDisposed) {
          await _videoController?.dispose();
          _videoController = null;
          return;
        }

        // Setup video - KHÔNG loop để tránh memory leak
        // Loop sẽ gây OutOfMemoryError khi video chạy nhiều lần
        _videoController!.setLooping(false);

        // Thêm listener để xử lý khi video kết thúc
        // Lưu ý: Listener sẽ được remove trong dispose
        _videoController!.addListener(_videoListener);

        // Check lại trước khi play
        if (!mounted || _isDisposed) {
          _videoController?.removeListener(_videoListener);
          await _videoController?.dispose();
          _videoController = null;
          return;
        }

        // Play video một lần, không loop
        // Listener sẽ tự động pause khi video kết thúc
        await _videoController!.play();
      }

      // Check mounted và dispose state trước khi setState
      _safeSetState(() {
        _isInitialized = true;
      });
    } catch (e, st) {
      debugPrint('_initVideoPlayer error: $e');
      debugPrint(st.toString());

      // Dispose controller nếu có lỗi
      if (_videoController != null) {
        try {
          _videoController!.removeListener(_videoListener);
          await _videoController!.pause();
          await _videoController!.dispose();
        } catch (e2) {
          debugPrint('Error disposing video controller on error: $e2');
        }
        _videoController = null;
      }

      // Chỉ setState nếu widget vẫn còn mounted và chưa dispose
      _safeSetState(() {
        _isInitialized = true; // Vẫn hiển thị UI dù không play được
      });
    }
  }

  @override
  void dispose() {
    // Đánh dấu đã dispose để tránh setState sau dispose
    _isDisposed = true;

    // Hủy timer nếu có
    _textUpdateTimer?.cancel();
    // Remove listener trước khi dispose
    _textController.removeListener(_onTextChanged);
    // Dispose text controller, focus node và notifier
    _textController.dispose();
    _textFocusNode.dispose();
    _textNotifier.dispose();

    // Dispose video controller an toàn (fire-and-forget vì dispose không thể async)
    _disposeVideoControllerSync();

    // Chỉ delete controller nếu chính màn này tạo ra
    if (_ownsAnimatedController &&
        Get.isRegistered<AnimatedStickerController>()) {
      Get.delete<AnimatedStickerController>();
    }
    super.dispose();
  }

  /// Tạm dừng video khi bắt đầu gesture để tối ưu performance
  void _pauseVideoForGesture() {
    if (_videoController != null &&
        !_isDisposed &&
        _videoController!.value.isInitialized &&
        _videoController!.value.isPlaying) {
      _videoController!.pause();
    }
  }

  /// Tiếp tục phát video sau khi kết thúc gesture
  void _resumeVideoAfterGesture() {
    if (_videoController != null &&
        !_isDisposed &&
        _videoController!.value.isInitialized &&
        !_videoController!.value.isPlaying) {
      _videoController!.play();
    }
  }

  /// Dispose video controller an toàn (sync version)
  void _disposeVideoControllerSync() {
    if (_videoController == null) return;

    final controller = _videoController;
    _videoController = null; // Set null ngay để tránh race condition

    // Fire-and-forget async dispose
    Future.microtask(() async {
      try {
        // Remove listener trước
        if (controller != null) {
          try {
            controller.removeListener(_videoListener);
          } catch (e) {
            debugPrint('Error removing video listener: $e');
          }
        }

        // Pause trước nếu đã initialized
        if (controller != null && controller.value.isInitialized) {
          try {
            await controller.pause();
          } catch (e) {
            debugPrint('Error pausing video controller in dispose: $e');
          }
        }
      } catch (e) {
        debugPrint('Error in pause step of dispose: $e');
      }

      try {
        // Dispose controller
        if (controller != null) {
          await controller.dispose();
        }
      } catch (e) {
        debugPrint('Error disposing video controller: $e');
      }
    });
  }

  /// Render tất cả text items thành PNG trong suốt
  Future<File?> _renderTextToPng() async {
    if (_textItems.isEmpty) {
      return null; // Không có text thì return null, không báo lỗi
    }

    try {
      // Tạo canvas 512x512 (kích thước sticker)
      const size = Size(512, 512);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Vẽ tất cả text items
      for (final item in _textItems) {
        if (item.text.isEmpty) continue;

        // Vẽ background nếu có
        if (item.backgroundColor != null) {
          final textSpan = TextSpan(
            text: item.text,
            style: TextStyle(
              color: item.textColor,
              fontSize: item.fontSize * item.scale,
              fontFamily: item.fontFamily,
              fontWeight: item.fontWeight,
            ),
          );

          final textPainter = TextPainter(
            text: textSpan,
            textAlign: item.textAlign,
            textDirection: TextDirection.ltr,
          );

          textPainter.layout();

          // Vẽ background rectangle
          final bgRect = Rect.fromLTWH(
            item.position.dx - textPainter.width / 2 - 4,
            item.position.dy - textPainter.height / 2 - 4,
            textPainter.width + 8,
            textPainter.height + 8,
          );

          final bgPaint =
              Paint()
                ..color = item.backgroundColor!
                ..style = PaintingStyle.fill;

          canvas.drawRRect(
            RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
            bgPaint,
          );
        }

        // Vẽ text với stroke và shadow - giống sticker tĩnh
        // Tạo text style base
        final baseStyle = TextStyle(
          fontSize: item.fontSize * item.scale,
          fontFamily: item.fontFamily,
          fontWeight: item.fontWeight,
          // Shadow (đổ bóng)
          shadows:
              item.shadowColor != null && item.shadowBlur > 0
                  ? [
                    Shadow(
                      color: item.shadowColor!.withOpacity(item.opacity),
                      offset: item.shadowOffset,
                      blurRadius: item.shadowBlur,
                    ),
                  ]
                  : null,
          backgroundColor: item.backgroundColor,
        );

        // Vẽ stroke trước (nếu có) - vẽ text với Paint stroke
        if (item.strokeColor != null && item.strokeWidth > 0) {
          final strokeSpan = TextSpan(text: item.text, style: baseStyle);

          final strokePainter = TextPainter(
            text: strokeSpan,
            textAlign: item.textAlign,
            textDirection: TextDirection.ltr,
          );

          strokePainter.layout();

          // Vẽ stroke bằng cách vẽ text với màu stroke ở các vị trí xung quanh
          final strokeTextSpan = TextSpan(
            text: item.text,
            style: baseStyle.copyWith(
              color: item.strokeColor!.withOpacity(item.opacity),
            ),
          );
          final strokeTextPainter = TextPainter(
            text: strokeTextSpan,
            textAlign: item.textAlign,
            textDirection: TextDirection.ltr,
          );
          strokeTextPainter.layout();

          final textOffset = Offset(
            item.position.dx - strokeTextPainter.width / 2,
            item.position.dy - strokeTextPainter.height / 2,
          );

          // Vẽ stroke ở các vị trí xung quanh để tạo viền
          final strokeOffsets = [
            Offset(-item.strokeWidth, 0),
            Offset(item.strokeWidth, 0),
            Offset(0, -item.strokeWidth),
            Offset(0, item.strokeWidth),
            Offset(-item.strokeWidth * 0.7, -item.strokeWidth * 0.7),
            Offset(item.strokeWidth * 0.7, item.strokeWidth * 0.7),
            Offset(-item.strokeWidth * 0.7, item.strokeWidth * 0.7),
            Offset(item.strokeWidth * 0.7, -item.strokeWidth * 0.7),
          ];

          for (final offset in strokeOffsets) {
            strokeTextPainter.paint(canvas, textOffset + offset);
          }
        }

        // Vẽ text chính
        final textSpan = TextSpan(
          text: item.text,
          style: baseStyle.copyWith(
            color: item.textColor.withOpacity(item.opacity),
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textAlign: item.textAlign,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        // Tính toán vị trí text (center của text tại item.position)
        final textOffset = Offset(
          item.position.dx - textPainter.width / 2,
          item.position.dy - textPainter.height / 2,
        );

        textPainter.paint(canvas, textOffset);
      }

      // Convert canvas thành image
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Lưu vào temp file
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File(
        '${dir.path}${Platform.pathSeparator}text_$timestamp.png',
      );
      await tempFile.writeAsBytes(pngBytes);

      return tempFile;
    } catch (e, st) {
      debugPrint('_renderTextToPng error: $e');
      debugPrint(st.toString());
      Get.snackbar(
        'Lỗi',
        'Không thể render text: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Export sticker với text overlay (nếu có text) hoặc không overlay (nếu không có text)
  Future<void> _exportSticker() async {
    if (_isProcessing || _isDisposed) return;

    if (!mounted || _isDisposed) return;
    _safeSetState(() => _isProcessing = true);

    try {
      // 2. Tạo output path
      final dir = await getApplicationDocumentsDirectory();
      final packDir = Directory(
        '${dir.path}${Platform.pathSeparator}stickers${Platform.pathSeparator}${_pack.id}',
      );
      if (!await packDir.exists()) {
        await packDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath =
          '${packDir.path}${Platform.pathSeparator}$timestamp.webp';

      // 3. Process video với hoặc không có text overlay
      final controller = Get.find<AnimatedStickerController>();

      String? result;
      File? textPngFile;

      // 1. Render text thành PNG nếu có text items
      if (_textItems.isNotEmpty &&
          _textItems.any((item) => item.text.isNotEmpty)) {
        textPngFile = await _renderTextToPng();
        // Nếu render text fail, vẫn tiếp tục tạo sticker không có text
        if (textPngFile == null) {
          debugPrint('Failed to render text, continuing without text overlay');
        }
      }

      // Check lại sau async operation
      if (!mounted || _isDisposed) return;

      if (_videoFile != null &&
          _startTime != null &&
          _endTime != null &&
          _cropMode != null) {
        // Flow 1: Từ CropVideoScreen
        if (textPngFile != null && _textItems.isNotEmpty) {
          // Có text: overlay text lên VIDEO rồi convert sang WebP
          String position = 'center';
          // Dùng vị trí của text đầu tiên để xác định position
          final firstText = _textItems.first;
          if (firstText.position.dy < 100) {
            position = 'top';
          } else if (firstText.position.dy > 400) {
            position = 'bottom';
          }

          result = await controller.processVideoToAnimatedStickerWithOverlay(
            videoFile: _videoFile!,
            outputPath: outputPath,
            startTime: _startTime!,
            endTime: _endTime!,
            cropMode: _cropMode!,
            textImageFile: textPngFile,
            position: position,
          );
        } else {
          // Không có text: convert video trực tiếp sang WebP (không overlay)
          result = await controller.processVideoToAnimatedSticker(
            videoFile: _videoFile!,
            outputPath: outputPath,
            startTime: _startTime!,
            endTime: _endTime!,
            cropMode: _cropMode!,
          );
        }
      } else if (_stickerFile != null) {
        // Flow 2: Từ UserPackDetailScreen
        if (textPngFile != null && _textItems.isNotEmpty) {
          // Có text: overlay text lên WebP
          String position = 'center';
          // Dùng vị trí của text đầu tiên để xác định position
          final firstText = _textItems.first;
          if (firstText.position.dy < 100) {
            position = 'top';
          } else if (firstText.position.dy > 400) {
            position = 'bottom';
          }

          result = await controller.overlayTextOnAnimatedSticker(
            baseStickerFile: _stickerFile!,
            textImageFile: textPngFile,
            outputPath: outputPath,
            position: position,
          );
        } else {
          // Không có text: copy sticker file (hoặc return sticker file path)
          // Vì đã có sticker file rồi, không cần process lại
          result = _stickerFile!.path;
        }
      } else {
        throw Exception('Missing videoFile or stickerFile');
      }

      // Xóa temp file nếu có
      if (textPngFile != null) {
        try {
          await textPngFile.delete();
        } catch (e) {
          debugPrint('Failed to delete temp file: $e');
        }
      }

      if (result == null) {
        throw Exception('Failed to create sticker');
      }

      // 4. Lưu vào pack
      final service = Get.find<UserStickerPackService>();
      final outputUri = Uri.file(result).toString();

      try {
        if (_replaceStickerUri != null) {
          service.replaceStickerUri(
            packId: _pack.id,
            oldStickerFileUri: _replaceStickerUri!,
            newStickerFileUri: outputUri,
          );
        } else {
          service.addStickerUri(
            packId: _pack.id,
            stickerFileUri: outputUri,
            isAnimatedSticker: true,
          );
        }
      } catch (e) {
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
        _safeSetState(() => _isProcessing = false);
        return;
      }

      if (!mounted) return;

      // 5. Navigate
      final updatedPack = service.getById(_pack.id);
      if (updatedPack == null) {
        throw Exception('Pack not found after save');
      }

      Get.snackbar(
        'success_title'.tr,
        'success_saved_to_pack'.trParams({'title': updatedPack.title}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF00C979),
        colorText: Colors.white,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      try {
        if (_isNewPack) {
          Get.offAllNamed(AppRoutes.mySticker);
          Get.toNamed(AppRoutes.userPackDetail, arguments: updatedPack);
        } else if (_goToUserPackDetail) {
          Get.offAllNamed(AppRoutes.mySticker);
          Get.toNamed(AppRoutes.userPackDetail, arguments: updatedPack);
        } else {
          Get.until((route) => route.settings.name == AppRoutes.mySticker);
        }
      } catch (e) {
        debugPrint('Navigation error: $e');
        Get.offAllNamed(AppRoutes.mySticker);
        if (_isNewPack || _goToUserPackDetail) {
          Get.toNamed(AppRoutes.userPackDetail, arguments: updatedPack);
        }
      }
    } catch (e, st) {
      debugPrint('_exportSticker error: $e');
      debugPrint(st.toString());
      if (mounted) {
        Get.snackbar(
          'error_generic_title'.tr,
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        _safeSetState(() => _isProcessing = false);
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
          onPressed: _isProcessing ? null : Get.back,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          'Edit Sticker',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isProcessing)
            TextButton(
              onPressed: _exportSticker,
              child: const Text(
                'Create',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00C979),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        color: Colors.white, // Background trắng cho toàn bộ body
        child: Stack(
          clipBehavior: Clip.none, // Cho phép text overlay vượt ra ngoài bounds
          children: [
            // Preview area
            Center(child: _buildPreview()),

            // Text overlays (draggable, scalable) - render tất cả text items
            ..._textItems.map((item) => _buildTextOverlay(item)),

            // Text editor panel
            if (_showTextEditor) _buildTextEditor(),

            // Processing overlay
            if (_isProcessing)
              Container(
                color: Colors.white.withOpacity(
                  0.9,
                ), // Background trắng mờ thay vì đen
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF00C979),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        final controller =
                            Get.find<AnimatedStickerController>();
                        return Text(
                          controller.processingMessage.value.isNotEmpty
                              ? controller.processingMessage.value
                              : 'Processing...',
                          style: const TextStyle(color: Colors.black),
                        );
                      }),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: 512,
      height: 512,
      decoration: BoxDecoration(
        color: Colors.white, // Background trắng thay vì đen
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child:
          _isInitialized
              ? Stack(
                children: [
                  // Background trắng (không có checkered pattern)
                  Positioned.fill(child: Container(color: Colors.white)),
                  // Video preview nếu có video file
                  if (_videoController != null &&
                      !_isDisposed &&
                      _videoController!.value.isInitialized &&
                      !_videoController!.value.hasError)
                    Center(
                      child: Container(
                        width: 512,
                        height: 512,
                        color: Colors.white, // Background trắng cho video
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // VideoPlayer với error handling
                              Builder(
                                builder: (context) {
                                  try {
                                    if (_videoController != null &&
                                        !_isDisposed &&
                                        _videoController!.value.isInitialized) {
                                      return VideoPlayer(_videoController!);
                                    }
                                    return const SizedBox.shrink();
                                  } catch (e) {
                                    debugPrint(
                                      'Error building VideoPlayer: $e',
                                    );
                                    return const SizedBox.shrink();
                                  }
                                },
                              ),
                              // Crop shape overlay
                              if (_cropMode != null &&
                                  _cropMode == CropShapeMode.square)
                                CustomPaint(
                                  painter: _SquareOverlayPainter(),
                                  size: Size.infinite,
                                ),
                              if (_cropMode != null &&
                                  _cropMode == CropShapeMode.circle)
                                CustomPaint(
                                  painter: _CircleOverlayPainter(),
                                  size: Size.infinite,
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                  // Sticker preview nếu có sticker file
                  else if (_stickerFile != null)
                    Center(
                      child: Container(
                        width: 512,
                        height: 512,
                        color: Colors.white, // Background trắng cho image
                        child: Image.file(
                          _stickerFile!,
                          width: 512,
                          height: 512,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  // Placeholder nếu không có gì
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_circle_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Animated Sticker',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '512x512',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              )
              : const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C979)),
                ),
              ),
    );
  }

  Widget _buildTextOverlay(TextItem item) {
    final isSelected = item.id == _selectedTextId;
    return _DraggableTextOverlay(
      key: ValueKey(item.id),
      item: item,
      isSelected: isSelected,
      onTap: () => _selectTextItem(item.id),
      onTransform: (newPosition, newScale) {
        final index = _textItems.indexWhere((i) => i.id == item.id);
        if (index != -1 && mounted && !_isDisposed) {
          setState(() {
            _textItems[index] = item.copyWith(
              position: newPosition,
              scale: newScale,
            );
          });
        }
      },
    );
  }

  Widget _buildTextEditor() {
    final selectedItem = _selectedTextItem;
    final keyboardActive = _textFocusNode.hasFocus;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bottom toolbar với tabs - giống sticker tĩnh
          _BottomToolbar(
            tab: _textEditorTab,
            keyboardActive: keyboardActive,
            textSelected: selectedItem != null,
            onTabChanged: (tab) {
              setState(() => _textEditorTab = tab);
            },
            onKeyboardPressed: () {
              if (_textFocusNode.hasFocus) {
                _textFocusNode.unfocus();
              } else {
                _textFocusNode.requestFocus();
              }
            },
            onAddText: _addNewText,
            onDeleteText: _selectedTextId != null ? _deleteSelectedText : null,
          ),

          // Bottom panel với tabs content - giống sticker tĩnh
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child:
                keyboardActive
                    ? const SizedBox.shrink()
                    : _BottomPanel(
                      tab: _textEditorTab,
                      textController: _textController,
                      focusNode: _textFocusNode,
                      selectedFont: selectedItem?.fontFamily ?? 'Roboto',
                      fonts: _fonts,
                      onFontSelected: (f) {
                        if (selectedItem != null) {
                          _safeSetState(() {
                            final index = _textItems.indexWhere(
                              (item) => item.id == _selectedTextId,
                            );
                            if (index != -1) {
                              _textItems[index] = selectedItem.copyWith(
                                fontFamily: f,
                              );
                            }
                          });
                        }
                      },
                      palette: _palette,
                      textColor: selectedItem?.textColor ?? Colors.white,
                      onTextColorChanged: (c) {
                        if (selectedItem != null) {
                          _safeSetState(() {
                            final index = _textItems.indexWhere(
                              (item) => item.id == _selectedTextId,
                            );
                            if (index != -1) {
                              _textItems[index] = selectedItem.copyWith(
                                textColor: c,
                              );
                            }
                          });
                        }
                      },
                      strokeColor: selectedItem?.strokeColor ?? Colors.black,
                      onStrokeColorChanged: (c) {
                        if (selectedItem != null) {
                          _safeSetState(() {
                            final index = _textItems.indexWhere(
                              (item) => item.id == _selectedTextId,
                            );
                            if (index != -1) {
                              _textItems[index] = selectedItem.copyWith(
                                strokeColor: c,
                              );
                            }
                          });
                        }
                      },
                      strokeWidth: selectedItem?.strokeWidth ?? 0.0,
                      onStrokeWidthChanged: (v) {
                        if (selectedItem != null) {
                          _safeSetState(() {
                            final index = _textItems.indexWhere(
                              (item) => item.id == _selectedTextId,
                            );
                            if (index != -1) {
                              _textItems[index] = selectedItem.copyWith(
                                strokeWidth: v,
                              );
                            }
                          });
                        }
                      },
                      shadowColor: selectedItem?.shadowColor ?? Colors.black,
                      onShadowColorChanged: (c) {
                        if (selectedItem != null) {
                          _safeSetState(() {
                            final index = _textItems.indexWhere(
                              (item) => item.id == _selectedTextId,
                            );
                            if (index != -1) {
                              _textItems[index] = selectedItem.copyWith(
                                shadowColor: c,
                              );
                            }
                          });
                        }
                      },
                      shadowBlur: selectedItem?.shadowBlur ?? 0.0,
                      onShadowBlurChanged: (v) {
                        if (selectedItem != null) {
                          _safeSetState(() {
                            final index = _textItems.indexWhere(
                              (item) => item.id == _selectedTextId,
                            );
                            if (index != -1) {
                              _textItems[index] = selectedItem.copyWith(
                                shadowBlur: v,
                              );
                            }
                          });
                        }
                      },
                      backgroundColor: selectedItem?.backgroundColor,
                      onBackgroundColorChanged: (c) {
                        if (selectedItem != null) {
                          _safeSetState(() {
                            final index = _textItems.indexWhere(
                              (item) => item.id == _selectedTextId,
                            );
                            if (index != -1) {
                              _textItems[index] = selectedItem.copyWith(
                                backgroundColor: c,
                              );
                            }
                          });
                        }
                      },
                      opacity: selectedItem?.opacity ?? 1.0,
                      onOpacityChanged: (v) {
                        if (selectedItem != null) {
                          _safeSetState(() {
                            final index = _textItems.indexWhere(
                              (item) => item.id == _selectedTextId,
                            );
                            if (index != -1) {
                              _textItems[index] = selectedItem.copyWith(
                                opacity: v,
                              );
                            }
                          });
                        }
                      },
                    ),
          ),

          // Hidden TextField để nhập text
          Offstage(
            offstage: true,
            child: TextField(
              controller: _textController,
              focusNode: _textFocusNode,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Text button - Navigate đến màn hình edit text riêng
          Expanded(
            child: InkWell(
              onTap: () async {
                // Navigate đến màn hình edit text riêng - giống sticker tĩnh
                await Get.to(
                  () => AnimatedTextEditScreen(
                    videoFile: _videoFile!,
                    textItems: _textItems,
                    selectedTextId: _selectedTextId,
                    onTextItemsChanged: (items) {
                      setState(() {
                        _textItems = items;
                      });
                    },
                    onSelectedTextIdChanged: (id) {
                      setState(() {
                        _selectedTextId = id;
                        if (id != null) {
                          final item = _textItems.firstWhere((i) => i.id == id);
                          _textController.text = item.text;
                        } else {
                          _textController.text = '';
                        }
                      });
                    },
                  ),
                  transition: Transition.rightToLeft,
                  duration: const Duration(milliseconds: 200),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.text_fields,
                    color:
                        _showTextEditor
                            ? const Color(0xFF00C979)
                            : Colors.grey[600],
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Text',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          _showTextEditor
                              ? const Color(0xFF00C979)
                              : Colors.grey[600],
                      fontWeight:
                          _showTextEditor ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sticker button
          Expanded(
            child: InkWell(
              onTap: () {
                // TODO: Implement sticker picker
                Get.snackbar(
                  'Info',
                  'Sticker feature coming soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.grey[600],
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sticker',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom toolbar với tabs - giống sticker tĩnh
class _BottomToolbar extends StatelessWidget {
  const _BottomToolbar({
    required this.tab,
    required this.keyboardActive,
    required this.textSelected,
    required this.onTabChanged,
    required this.onKeyboardPressed,
    required this.onAddText,
    this.onDeleteText,
  });

  final _TextEditorTab tab;
  final bool keyboardActive;
  final bool textSelected;
  final ValueChanged<_TextEditorTab> onTabChanged;
  final VoidCallback onKeyboardPressed;
  final VoidCallback onAddText;
  final VoidCallback? onDeleteText;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(
            0.8,
          ), // Background tối để icon trắng dễ nhìn
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Nút Add Text
            IconButton(
              onPressed: onAddText,
              icon: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Thêm text mới',
            ),
            // Nút Delete Text
            if (onDeleteText != null)
              IconButton(
                onPressed: onDeleteText,
                icon: const Icon(Icons.delete, color: Colors.white),
                tooltip: 'Xóa text',
              ),
            IconButton(
              onPressed: onKeyboardPressed,
              icon: Icon(
                Icons.keyboard,
                color: keyboardActive ? const Color(0xFF00C979) : Colors.white,
              ),
            ),
            _ToolIcon(
              selected: tab == _TextEditorTab.text && textSelected,
              icon: Icons.title,
              onTap: () => onTabChanged(_TextEditorTab.text),
            ),
            _ToolIcon(
              selected: tab == _TextEditorTab.stroke,
              icon: Icons.border_color,
              onTap: () => onTabChanged(_TextEditorTab.stroke),
            ),
            _ToolIcon(
              selected: tab == _TextEditorTab.shadow,
              icon: Icons.blur_on,
              onTap: () => onTabChanged(_TextEditorTab.shadow),
            ),
            _ToolIcon(
              selected: tab == _TextEditorTab.background,
              icon: Icons.chat_bubble_outline,
              onTap: () => onTabChanged(_TextEditorTab.background),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Màu trắng mặc định, xanh khi selected
    final color = selected ? const Color(0xFF00C979) : Colors.white;
    return IconButton(onPressed: onTap, icon: Icon(icon, color: color));
  }
}

/// Bottom panel với tabs content - giống sticker tĩnh
class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.tab,
    required this.textController,
    required this.focusNode,
    required this.selectedFont,
    required this.fonts,
    required this.onFontSelected,
    required this.palette,
    required this.textColor,
    required this.onTextColorChanged,
    required this.strokeColor,
    required this.onStrokeColorChanged,
    required this.strokeWidth,
    required this.onStrokeWidthChanged,
    required this.shadowColor,
    required this.onShadowColorChanged,
    required this.shadowBlur,
    required this.onShadowBlurChanged,
    required this.backgroundColor,
    required this.onBackgroundColorChanged,
    required this.opacity,
    required this.onOpacityChanged,
  });

  final _TextEditorTab tab;

  final TextEditingController textController;
  final FocusNode focusNode;

  final String selectedFont;
  final List<String> fonts;
  final ValueChanged<String> onFontSelected;

  final List<Color> palette;
  final Color textColor;
  final ValueChanged<Color> onTextColorChanged;

  final Color strokeColor;
  final ValueChanged<Color> onStrokeColorChanged;
  final double strokeWidth;
  final ValueChanged<double> onStrokeWidthChanged;

  final Color shadowColor;
  final ValueChanged<Color> onShadowColorChanged;
  final double shadowBlur;
  final ValueChanged<double> onShadowBlurChanged;

  final Color? backgroundColor;
  final ValueChanged<Color?> onBackgroundColorChanged;

  final double opacity;
  final ValueChanged<double> onOpacityChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
        ),
        child: switch (tab) {
          _TextEditorTab.text => _TextTab(
            textController: textController,
            focusNode: focusNode,
            selectedFont: selectedFont,
            fonts: fonts,
            onFontSelected: onFontSelected,
            palette: palette,
            textColor: textColor,
            onTextColorChanged: onTextColorChanged,
          ),
          _TextEditorTab.stroke => _EffectsTab(
            title: 'Đường viền',
            palette: palette,
            selectedColor: strokeColor,
            onColorSelected: onStrokeColorChanged,
            sliderLabel: 'Độ dày',
            sliderValue: strokeWidth,
            sliderMin: 0,
            sliderMax: 10,
            onSliderChanged: onStrokeWidthChanged,
            opacity: opacity,
            onOpacityChanged: onOpacityChanged,
          ),
          _TextEditorTab.shadow => _EffectsTab(
            title: 'Bóng',
            palette: palette,
            selectedColor: shadowColor,
            onColorSelected: onShadowColorChanged,
            sliderLabel: 'Độ mờ',
            sliderValue: shadowBlur,
            sliderMin: 0,
            sliderMax: 10,
            onSliderChanged: onShadowBlurChanged,
            opacity: opacity,
            onOpacityChanged: onOpacityChanged,
          ),
          _TextEditorTab.background => _BackgroundTab(
            palette: palette,
            selectedColor: backgroundColor,
            onColorSelected: onBackgroundColorChanged,
            opacity: opacity,
            onOpacityChanged: onOpacityChanged,
          ),
        },
      ),
    );
  }
}

class _TextTab extends StatelessWidget {
  const _TextTab({
    required this.textController,
    required this.focusNode,
    required this.selectedFont,
    required this.fonts,
    required this.onFontSelected,
    required this.palette,
    required this.textColor,
    required this.onTextColorChanged,
  });

  final TextEditingController textController;
  final FocusNode focusNode;

  final String selectedFont;
  final List<String> fonts;
  final ValueChanged<String> onFontSelected;

  final List<Color> palette;
  final Color textColor;
  final ValueChanged<Color> onTextColorChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Màu chữ', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: palette.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final c = palette[index];
              final selected = c.value == textColor.value;
              return GestureDetector(
                onTap: () => onTextColorChanged(c),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          selected
                              ? const Color(0xFF00C979)
                              : const Color(0xFFDDDDDD),
                      width: selected ? 3 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        const Text('Font', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.4,
            ),
            itemCount: fonts.length,
            itemBuilder: (context, index) {
              final f = fonts[index];
              final selected = f == selectedFont;
              return InkWell(
                onTap: () => onFontSelected(f),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          selected
                              ? const Color(0xFF00C979)
                              : const Color(0xFFE0E0E0),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    f,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: f,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EffectsTab extends StatelessWidget {
  const _EffectsTab({
    required this.title,
    required this.palette,
    required this.selectedColor,
    required this.onColorSelected,
    required this.sliderLabel,
    required this.sliderValue,
    required this.sliderMin,
    required this.sliderMax,
    required this.onSliderChanged,
    required this.opacity,
    required this.onOpacityChanged,
  });

  final String title;
  final List<Color> palette;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  final String sliderLabel;
  final double sliderValue;
  final double sliderMin;
  final double sliderMax;
  final ValueChanged<double> onSliderChanged;

  final double opacity;
  final ValueChanged<double> onOpacityChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: palette.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final c = palette[index];
              final selected = c.value == selectedColor.value;
              return GestureDetector(
                onTap: () => onColorSelected(c),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          selected
                              ? const Color(0xFF00C979)
                              : const Color(0xFFDDDDDD),
                      width: selected ? 3 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(sliderLabel, style: const TextStyle(color: Colors.black54)),
        Slider(
          value: sliderValue.clamp(sliderMin, sliderMax),
          min: sliderMin,
          max: sliderMax,
          onChanged: onSliderChanged,
        ),
        const SizedBox(height: 6),
        const Text('Độ mờ', style: TextStyle(color: Colors.black54)),
        Slider(value: opacity, min: 0, max: 1, onChanged: onOpacityChanged),
      ],
    );
  }
}

class _BackgroundTab extends StatelessWidget {
  const _BackgroundTab({
    required this.palette,
    required this.selectedColor,
    required this.onColorSelected,
    required this.opacity,
    required this.onOpacityChanged,
  });

  final List<Color> palette;
  final Color? selectedColor;
  final ValueChanged<Color?> onColorSelected;

  final double opacity;
  final ValueChanged<double> onOpacityChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nền', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: palette.length + 1, // +1 for transparent
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                // Transparent option
                final selected = selectedColor == null;
                return GestureDetector(
                  onTap: () => onColorSelected(null),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            selected
                                ? const Color(0xFF00C979)
                                : const Color(0xFFDDDDDD),
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.clear,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }
              final c = palette[index - 1];
              final selected = c.value == selectedColor?.value;
              return GestureDetector(
                onTap: () => onColorSelected(c),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          selected
                              ? const Color(0xFF00C979)
                              : const Color(0xFFDDDDDD),
                      width: selected ? 3 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        const Text('Độ mờ', style: TextStyle(color: Colors.black54)),
        Slider(value: opacity, min: 0, max: 1, onChanged: onOpacityChanged),
      ],
    );
  }
}

/// Custom painter để vẽ square overlay
class _SquareOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final squareSize =
        (size.width < size.height ? size.width : size.height) * 0.9;
    final squareRect = Rect.fromCenter(
      center: center,
      width: squareSize,
      height: squareSize,
    );

    canvas.saveLayer(Offset.zero & size, Paint());

    // Draw outer dim area
    final outerPaint =
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, outerPaint);

    // Clear square in the middle
    final squarePaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRect(squareRect, squarePaint);

    canvas.restore();

    // Draw square border
    final borderPaint =
        Paint()
          ..color = const Color(0xFF00C979)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
    canvas.drawRect(squareRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter để vẽ circle overlay
class _CircleOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width : size.height) / 2 * 0.9;

    canvas.saveLayer(Offset.zero & size, Paint());

    // Draw outer dim area
    final outerPaint =
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, outerPaint);

    // Clear circle in the middle
    final circlePaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawCircle(center, radius, circlePaint);

    canvas.restore();

    // Draw circle border
    final borderPaint =
        Paint()
          ..color = const Color(0xFF00C979)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget hiển thị text overlay có thể di chuyển và scale - GIỐNG Y HỆT STICKER TĨNH
class _DraggableTextOverlay extends StatefulWidget {
  const _DraggableTextOverlay({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onTransform,
  });

  final TextItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(Offset position, double scale) onTransform;

  @override
  State<_DraggableTextOverlay> createState() => _DraggableTextOverlayState();
}

class _DraggableTextOverlayState extends State<_DraggableTextOverlay> {
  // Dùng ValueNotifier để tối ưu - chỉ rebuild Transform, không rebuild toàn bộ widget
  late final ValueNotifier<Matrix4> _matrixNotifier;
  late Offset _position;
  late double _scale;
  Offset? _panStart;
  double? _scaleStart;
  bool _isUpdating = false; // Flag để defer callback

  @override
  void initState() {
    super.initState();
    _position = widget.item.position;
    _scale = widget.item.scale;
    _matrixNotifier = ValueNotifier(_buildMatrix());
  }

  @override
  void didUpdateWidget(_DraggableTextOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _position = widget.item.position;
      _scale = widget.item.scale;
      _matrixNotifier.value = _buildMatrix();
    }
  }

  @override
  void dispose() {
    _matrixNotifier.dispose();
    super.dispose();
  }

  Matrix4 _buildMatrix() {
    // Position là center của text, Transform sẽ scale từ center
    return Matrix4.identity()..scale(_scale);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _scaleStart = _scale;
    _panStart = _position;
    widget.onTap();
    // Tạm dừng video khi bắt đầu di chuyển để tối ưu performance
    _pauseVideoIfNeeded();
  }

  void _pauseVideoIfNeeded() {
    // Tìm parent state để pause video
    final context = this.context;
    final ancestor =
        context.findAncestorStateOfType<_EditAnimatedStickerScreenState>();
    ancestor?._pauseVideoForGesture();
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_scaleStart == null || _panStart == null) {
      return;
    }

    // Xử lý Scale (2 ngón tay - pinch zoom)
    final scaleDelta = details.scale;
    final hasScaleChange = (scaleDelta - 1.0).abs() > 0.01;
    if (hasScaleChange) {
      _scale = (_scaleStart! * scaleDelta).clamp(0.5, 3.0);
    }

    // Xử lý Pan (di chuyển) - DÙNG focalPointDelta TRỰC TIẾP
    _position = Offset(
      _panStart!.dx + details.focalPointDelta.dx,
      _panStart!.dy + details.focalPointDelta.dy,
    );

    // Clamp position để giữ text trong bounds (512x512 preview area)
    const textWidthEstimate = 200.0;
    const textHeightEstimate = 40.0;
    final minX = textWidthEstimate / 2;
    final maxX = 512 - textWidthEstimate / 2;
    final minY = textHeightEstimate / 2;
    final maxY = 512 - textHeightEstimate / 2;

    _position = Offset(
      _position.dx.clamp(minX, maxX),
      _position.dy.clamp(minY, maxY),
    );

    // Update ValueNotifier - chỉ rebuild Transform widget, không rebuild toàn bộ
    _matrixNotifier.value = _buildMatrix();

    // Defer callback để không block gesture - giống sticker tĩnh
    if (!_isUpdating) {
      _isUpdating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isUpdating = false;
        if (mounted) {
          widget.onTransform(_position, _scale);
        }
      });
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _scaleStart = null;
    _panStart = null;
    // Đảm bảo callback được gọi lần cuối
    widget.onTransform(_position, _scale);
    // Tiếp tục phát video sau khi kết thúc gesture
    _resumeVideoIfNeeded();
  }

  void _resumeVideoIfNeeded() {
    final context = this.context;
    final ancestor =
        context.findAncestorStateOfType<_EditAnimatedStickerScreenState>();
    ancestor?._resumeVideoAfterGesture();
  }

  @override
  Widget build(BuildContext context) {
    // Cache text style để tránh rebuild style mỗi lần
    final textStyle = TextStyle(
      color: widget.item.textColor.withOpacity(widget.item.opacity),
      fontSize: widget.item.fontSize * _scale,
      fontFamily: widget.item.fontFamily,
      fontWeight: widget.item.fontWeight,
      shadows:
          widget.item.shadowColor != null && widget.item.shadowBlur > 0
              ? [
                Shadow(
                  color: widget.item.shadowColor!.withOpacity(
                    widget.item.opacity,
                  ),
                  offset: widget.item.shadowOffset,
                  blurRadius: widget.item.shadowBlur,
                ),
              ]
              : null,
      backgroundColor: widget.item.backgroundColor,
    );

    // Tính toán position để center text
    const textWidthEstimate = 200.0;
    const textHeightEstimate = 40.0;
    final displayPosition = Offset(
      _position.dx - textWidthEstimate / 2,
      _position.dy - textHeightEstimate / 2,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // GestureDetector bao phủ toàn bộ vùng - GIỐNG Y HỆT STICKER TĨNH
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, // Giống sticker tĩnh
            onTap: widget.onTap,
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Transform text với ValueListenableBuilder - chỉ rebuild Transform - GIỐNG Y HỆT STICKER TĨNH
        Positioned(
          left: displayPosition.dx,
          top: displayPosition.dy,
          child: IgnorePointer(
            ignoring:
                true, // Ignore pointer cho Transform, chỉ GestureDetector nhận
            child: RepaintBoundary(
              child: ValueListenableBuilder<Matrix4>(
                valueListenable: _matrixNotifier,
                builder: (context, matrix, child) {
                  return Transform(
                    transform: matrix,
                    alignment: Alignment.center,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        widget.item.backgroundColor ??
                        widget.item.textColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color:
                          widget.isSelected
                              ? Colors.blue
                              : widget.item.textColor,
                      width: widget.isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    widget.item.text,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
