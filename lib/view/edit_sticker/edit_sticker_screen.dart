import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import 'package:get/get.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:sticker_app/helper/dialogs/app_dialogs.dart';
import 'package:sticker_app/model/user_sticker_pack.dart';
import 'package:sticker_app/router/router.dart';
import 'package:sticker_app/service/sticker/user_sticker_pack_service.dart';
import 'package:sticker_app/view/edit_sticker/text_edit_screen.dart';

enum EditTab { text, sticker, background }

class EditStickerScreen extends StatefulWidget {
  const EditStickerScreen({super.key});

  @override
  State<EditStickerScreen> createState() => _EditStickerScreenState();
}

class _EditStickerScreenState extends State<EditStickerScreen>
    with TickerProviderStateMixin {
  late final File _stickerFile;
  late final PainterController _controller;
  EditTab _selectedTab = EditTab.text;

  late final UserStickerPack _pack;
  String? _replaceStickerUri;
  bool _isNewPack = false;

  bool _showPainter = true;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map;
    final stickerUri = args['stickerUri'] as String;
    _stickerFile = File.fromUri(Uri.parse(stickerUri));

    _pack = args['pack'] as UserStickerPack;
    _replaceStickerUri = args['replaceStickerUri'] as String?;
    _isNewPack = args['isNewPack'] == true;

    _controller =
        PainterController()
          ..freeStyleSettings = FreeStyleSettings(mode: FreeStyleMode.none)
          ..textSettings = TextSettings(
            textStyle: const TextStyle(
              fontSize: 24,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            focusNode: FocusNode(),
          );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStickerAsBackground();
    });
  }

  Future<void> _loadStickerAsBackground() async {
    final uiImage = await FileImage(_stickerFile).image;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.microtask(() {
        if (!mounted) return;
        _controller.background = uiImage.backgroundDrawable;
        WidgetsBinding.instance.addPostFrameCallback((__) {
          if (!mounted) return;
          setState(() {});
        });
      });
    });
  }

  Future<void> _onCreate() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final uiImage = await _controller.renderImage(const Size(512, 512));
      final pngBytes = await uiImage.pngBytes;
      if (pngBytes == null) throw Exception('Failed to render PNG');

      final webpBytes = await _encodeWebp(pngBytes);
      await _stickerFile.writeAsBytes(webpBytes, flush: true);

      final fileUri = Uri.file(_stickerFile.path).toString();

      final service = Get.find<UserStickerPackService>();
      UserStickerPack updatedPack;

      if (_replaceStickerUri != null) {
        service.replaceStickerUri(
          packId: _pack.id,
          oldStickerFileUri: _replaceStickerUri!,
          newStickerFileUri: fileUri,
          deleteOldFile: true,
        );
        // Lấy pack đã được update
        updatedPack = service.getById(_pack.id)!;
      } else {
        if (_isNewPack) {
          final committed = service.commitPack(
            _pack.copyWith(stickerFileUris: [fileUri]),
          );
          // Navigate về pack detail
          Get.offAllNamed(AppRoutes.mySticker);
          Get.toNamed(AppRoutes.userPackDetail, arguments: committed);

          AppDialogs.showSuccess(
            'success_saved_to_pack'.trParams({'title': committed.title}),
          );
          return;
        }

        service.addStickerUri(packId: _pack.id, stickerFileUri: fileUri);
        // Lấy pack đã được update
        updatedPack = service.getById(_pack.id)!;
      }

      PaintingBinding.instance.imageCache.evict(FileImage(_stickerFile));

      // Luôn navigate về pack detail sau khi create
      Get.offAllNamed(AppRoutes.mySticker);
      Get.toNamed(AppRoutes.userPackDetail, arguments: updatedPack);

      AppDialogs.showSuccess(
        'success_saved_to_pack'.trParams({'title': updatedPack.title}),
      );
    } catch (e) {
      if (mounted) AppDialogs.showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<Uint8List> _encodeWebp(Uint8List pngBytes) async {
    const maxBytes = 100 * 1024;
    const qualities = [95, 90, 85, 80, 75, 70, 65, 60, 55, 50, 45, 40, 35, 30];
    Uint8List? best;
    for (final q in qualities) {
      final out = await FlutterImageCompress.compressWithList(
        pngBytes,
        format: CompressFormat.webp,
        quality: q,
        keepExif: false,
      );
      if (best == null || out.length < best.length) {
        best = Uint8List.fromList(out);
      }
      if (out.length <= maxBytes) return Uint8List.fromList(out);
    }
    if (best != null) {
      throw Exception(
        'error_sticker_too_large'.trParams({
          'sizeKb': (best.length / 1024).toStringAsFixed(1),
        }),
      );
    }
    throw Exception('error_cannot_encode_webp'.tr);
  }

  Future<void> _openTools(EditTab tab) async {
    setState(() => _selectedTab = tab);

    if (tab == EditTab.text) {
      setState(() => _showPainter = false);
      await Get.to<bool>(
        () => TextEditScreen(controller: _controller),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 200),
      );
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 240));
      if (!mounted) return;
      setState(() => _showPainter = true);
      return;
    }

    Widget child;
    switch (tab) {
      case EditTab.text:
        child = const SizedBox.shrink();
        break;
      case EditTab.sticker:
        child = const SafeArea(
          child: Center(child: Text('Sticker tools (TODO)')),
        );
        break;
      case EditTab.background:
        child = const SafeArea(
          child: Center(child: Text('Background tools (TODO)')),
        );
        break;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Edit Sticker',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _onCreate,
            child:
                _saving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text(
                      'Create',
                      style: TextStyle(
                        color: Color(0xFF00C979),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
          ),
        ],
      ),
      body: _CheckerboardBackground(
        child: Center(
          child: Builder(
            builder: (context) {
              final maxSize = MediaQuery.sizeOf(context).shortestSide;
              final size = (maxSize * 0.72).clamp(220.0, 360.0);
              return SizedBox(
                width: size,
                height: size,
                child:
                    _showPainter
                        ? FlutterPainter(controller: _controller)
                        : const SizedBox.shrink(),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab.index,
        onTap: (index) => _openTools(EditTab.values[index]),
        selectedItemColor: const Color(0xFF00C979),
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.text_fields), label: 'Text'),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_emotions_outlined),
            label: 'Sticker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_paint_outlined),
            label: 'Background',
          ),
        ],
      ),
    );
  }
}

class _CheckerboardBackground extends StatelessWidget {
  const _CheckerboardBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CheckerboardPainter(
        light: const Color(0xFFF3F3F3),
        dark: const Color(0xFFE3E3E3),
        squareSize: 14,
      ),
      child: child,
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  _CheckerboardPainter({
    required this.light,
    required this.dark,
    required this.squareSize,
  });

  final Color light;
  final Color dark;
  final double squareSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isDark =
            ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 1;
        paint.color = isDark ? dark : light;
        canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) {
    return oldDelegate.light != light ||
        oldDelegate.dark != dark ||
        oldDelegate.squareSize != squareSize;
  }
}
