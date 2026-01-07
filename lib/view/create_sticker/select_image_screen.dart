import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sticker_app/model/user_sticker_pack.dart';
import 'package:sticker_app/router/router.dart';

class SelectImageScreen extends StatefulWidget {
  const SelectImageScreen({super.key});

  @override
  State<SelectImageScreen> createState() => _SelectImageScreenState();
}

class _SelectImageScreenState extends State<SelectImageScreen> {
  late final UserStickerPack _pack;
  String? _replaceStickerUri;
  bool _goToUserPackDetail = false;
  bool _isNewPack = false;

  final Map<String, Future<Uint8List?>> _thumbFutures = {};

  final _assets = <AssetEntity>[];
  bool _loading = true;
  bool _hasPermission = false;

  AssetEntity? _selectedAsset;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _pack = args['pack'] as UserStickerPack;
      _replaceStickerUri = args['replaceStickerUri'] as String?;
      _goToUserPackDetail = args['goToUserPackDetail'] == true;
      _isNewPack = args['isNewPack'] == true;
    } else {
      _pack = args as UserStickerPack;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    try {
      final storage = Platform.isAndroid ? await Permission.storage.request() : null;
      debugPrint(
        'Storage permission: granted=${storage?.isGranted}, denied=${storage?.isDenied}, permanentlyDenied=${storage?.isPermanentlyDenied}, restricted=${storage?.isRestricted}, limited=${storage?.isLimited}',
      );

      final permission = await PhotoManager.requestPermissionExtend();
      if (!mounted) return;

      debugPrint(
        'Photo permission: isAuth=${permission.isAuth}, isLimited=${permission.isLimited}',
      );

      final hasAccess =
          permission.isAuth || permission.isLimited || (storage?.isGranted ?? false);

      if (!hasAccess) {
        setState(() {
          _hasPermission = false;
          _assets.clear();
          _thumbFutures.clear();
        });
        return;
      }

      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (!mounted) return;

      debugPrint('Asset paths: ${paths.length}');

      final recent = paths.isNotEmpty ? paths.first : null;
      final list = recent == null
          ? <AssetEntity>[]
          : await recent.getAssetListPaged(page: 0, size: 200);

      if (!mounted) return;

      debugPrint('Loaded assets: ${list.length}');

      final imagesOnly = list.where((e) => e.type == AssetType.image).toList();

      setState(() {
        _hasPermission = true;
        _assets
          ..clear()
          ..addAll(imagesOnly);
        _thumbFutures.clear();
      });
    } catch (e, st) {
      debugPrint('SelectImageScreen._load error: $e');
      debugPrint('$st');
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _assets.clear();
          _thumbFutures.clear();
        });
        Get.snackbar(
          'Error',
          'Load photos failed: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<File?> _resolveAssetFile(AssetEntity asset) async {
    final f1 = await asset.file;
    if (f1 != null) return f1;

    final f2 = await asset.originFile;
    if (f2 != null) return f2;

    final bytes = await asset.originBytes;
    if (bytes == null || bytes.isEmpty) return null;

    final dir = await getTemporaryDirectory();
    final out = File(
      '${dir.path}${Platform.pathSeparator}pm_${asset.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await out.writeAsBytes(bytes, flush: true);
    return out;
  }

  Future<Uint8List?> _thumbFuture(AssetEntity asset) {
    return _thumbFutures.putIfAbsent(
      asset.id,
      () => asset.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
    );
  }

  Future<void> _openCamera() async {
    final cam = await Permission.camera.request();
    if (!cam.isGranted) return;

    final picker = ImagePicker();
    final captured = await picker.pickImage(source: ImageSource.camera);
    if (captured == null) return;

    final file = File(captured.path);
    Get.toNamed(
      AppRoutes.createStickerCrop,
      arguments: {
        'pack': _pack,
        'imageFile': file,
        'replaceStickerUri': _replaceStickerUri,
        'goToUserPackDetail': _goToUserPackDetail,
        'isNewPack': _isNewPack,
      },
    );
  }

  Future<void> _openGalleryPicker() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    Get.toNamed(
      AppRoutes.createStickerCrop,
      arguments: {
        'pack': _pack,
        'imageFile': file,
        'replaceStickerUri': _replaceStickerUri,
        'goToUserPackDetail': _goToUserPackDetail,
        'isNewPack': _isNewPack,
      },
    );
  }

  Future<void> _confirmSelection() async {
    final asset = _selectedAsset;
    if (asset == null) {
      debugPrint('_confirmSelection: no asset selected');
      return;
    }

    debugPrint('_confirmSelection: resolving asset ${asset.id}');
    final file = await _resolveAssetFile(asset);
    if (file == null) {
      Get.snackbar(
        'Error',
        'error_cannot_read_image'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    debugPrint('_confirmSelection: navigating to CropScreen with file ${file.path}');
    Get.toNamed(
      AppRoutes.createStickerCrop,
      arguments: {
        'pack': _pack,
        'imageFile': file,
        'replaceStickerUri': _replaceStickerUri,
        'goToUserPackDetail': _goToUserPackDetail,
        'isNewPack': _isNewPack,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _selectedAsset != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          'select_image_title'.tr,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: canConfirm ? _confirmSelection : null,
            icon: Icon(
              Icons.check,
              color: canConfirm ? const Color(0xFF00C979) : Colors.grey,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'permission_photos_required'.tr,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                child: Text('grant_permission'.tr),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _openGalleryPicker,
                child: const Text('Chọn ảnh từ thư viện'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: PhotoManager.openSetting,
                child: Text('open_settings'.tr),
              ),
            ],
          ),
        ),
      );
    }

    if (_assets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Không load được danh sách ảnh trên thiết bị này. Bạn có thể chọn ảnh từ thư viện để tiếp tục.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _openGalleryPicker,
                child: const Text('Chọn ảnh từ thư viện'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _load,
                child: const Text('Thử tải lại'),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _assets.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _CameraTile(onTap: _openCamera);
        }

        if (index == 1) {
          return _GalleryTile(onTap: _openGalleryPicker);
        }

        final asset = _assets[index - 2];
        final isSelected = _selectedAsset?.id == asset.id;

        return _MediaTile(
          selected: isSelected,
          onTap: () {
            setState(() {
              _selectedAsset = asset;
            });
          },
          child: _AssetThumb(future: _thumbFuture(asset)),
        );
      },
    );
  }
}

class _CameraTile extends StatelessWidget {
  const _CameraTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _MediaTile(
      selected: false,
      onTap: onTap,
      child: const Center(
        child: Icon(Icons.photo_camera_outlined, size: 32, color: Colors.black54),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedRRectBorderPainter(
            color: const Color(0xFF00C979),
            radius: 14,
            strokeWidth: 2,
            dashLength: 7,
            gapLength: 6,
          ),
          child: Center(
            child: Container(
              height: 44,
              width: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF00C979),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectBorderPainter extends CustomPainter {
  _DashedRRectBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(strokeWidth / 2), Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList(growable: false);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.child,
    required this.onTap,
    required this.selected,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    const radius = 14.0;

    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (selected)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: const Color(0xFF00C979),
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            if (selected)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  height: 22,
                  width: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00C979),
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssetThumb extends StatelessWidget {
  const _AssetThumb({required this.future});

  final Future<Uint8List?> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: const Color(0xFFF3F3F3),
            child: const Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final data = snapshot.data;
        if (snapshot.hasError || data == null) {
          return Container(
            color: const Color(0xFFF3F3F3),
            child: const Center(
              child: Icon(Icons.broken_image_outlined, color: Colors.black26),
            ),
          );
        }

        return Image.memory(data, fit: BoxFit.cover, gaplessPlayback: true);
      },
    );
  }
}