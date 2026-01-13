import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sticker_app/model/user_sticker_pack.dart';
import 'package:sticker_app/router/router.dart';

/// Màn hình chọn video cho Animated Sticker
class SelectVideoScreen extends StatefulWidget {
  const SelectVideoScreen({super.key});

  @override
  State<SelectVideoScreen> createState() => _SelectVideoScreenState();
}

class _SelectVideoScreenState extends State<SelectVideoScreen> {
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
      // Request storage permission
      final storage =
          Platform.isAndroid ? await Permission.storage.request() : null;
      debugPrint(
        '[SelectVideo] Storage permission: granted=${storage?.isGranted}, denied=${storage?.isDenied}',
      );

      // Request photo/video permission
      final permission = await PhotoManager.requestPermissionExtend();
      if (!mounted) return;

      debugPrint(
        '[SelectVideo] Photo permission: isAuth=${permission.isAuth}, isLimited=${permission.isLimited}',
      );

      final hasAccess =
          permission.isAuth ||
          permission.isLimited ||
          (storage?.isGranted ?? false);

      if (!hasAccess) {
        setState(() {
          _hasPermission = false;
          _assets.clear();
          _thumbFutures.clear();
        });
        return;
      }

      // Load videos thay vì images
      // Load video galleries
      debugPrint('[SelectVideo] Loading video paths...');
      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        onlyAll: true,
      );

      if (!mounted) return;

      debugPrint('[SelectVideo] Found ${paths.length} video path(s)');
      if (paths.isEmpty) {
        debugPrint('[SelectVideo] No video paths found - may need permission');
      }

      final recent = paths.isNotEmpty ? paths.first : null;
      final list =
          recent == null
              ? <AssetEntity>[]
              : await recent.getAssetListPaged(page: 0, size: 200);

      if (!mounted) return;

      debugPrint('Loaded video assets: ${list.length}');

      // Filter chỉ lấy video (bỏ filter duration để hiển thị tất cả)
      final videosOnly =
          list.where((e) {
            return e.type == AssetType.video;
          }).toList();

      debugPrint('Filtered video assets: ${videosOnly.length}');

      setState(() {
        _hasPermission = true;
        _assets
          ..clear()
          ..addAll(videosOnly);
        _thumbFutures.clear();
      });
    } catch (e, st) {
      debugPrint('SelectVideoScreen._load error: $e');
      debugPrint('$st');
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _assets.clear();
          _thumbFutures.clear();
        });
        Get.snackbar(
          'error_generic_title'.tr,
          '${'error_load_videos'.tr}: $e',
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
      '${dir.path}${Platform.pathSeparator}pm_${asset.id}_${DateTime.now().millisecondsSinceEpoch}.mp4',
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

  Future<void> _confirmSelection() async {
    final asset = _selectedAsset;
    if (asset == null) {
      debugPrint('_confirmSelection: no asset selected');
      return;
    }

    debugPrint('_confirmSelection: resolving video asset ${asset.id}');
    final file = await _resolveAssetFile(asset);
    if (file == null) {
      Get.snackbar(
        'error_generic_title'.tr,
        'error_cannot_read_video'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Get video duration
    Duration videoDuration = asset.videoDuration;
    if (videoDuration.inSeconds <= 0) {
      debugPrint(
        '[SelectVideoScreen] videoDuration is invalid (${videoDuration.inSeconds}s), '
        'will be determined from video file',
      );
      // Set default, sẽ được update từ video controller
      videoDuration = const Duration(seconds: 5);
    }

    debugPrint(
      '_confirmSelection: navigating to CropVideoScreen with file ${file.path}',
    );
    debugPrint(
      '_confirmSelection: videoDuration = ${videoDuration.inSeconds}s',
    );

    Get.toNamed(
      AppRoutes.createAnimatedCrop,
      arguments: {
        'pack': _pack,
        'videoFile': file,
        'videoDuration': videoDuration,
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
          'select_video_title'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
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
                'permission_videos_required'.tr,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                child: Text('grant_permission'.tr),
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
              const Icon(
                Icons.video_library_outlined,
                size: 64,
                color: Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(
                'no_videos_found'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Không tìm thấy video trong thư viện',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: Text('try_reload_button'.tr)),
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
      itemCount: _assets.length,
      itemBuilder: (context, index) {
        final asset = _assets[index];
        final isSelected = _selectedAsset?.id == asset.id;

        return _VideoTile(
          asset: asset,
          selected: isSelected,
          onTap: () {
            setState(() {
              _selectedAsset = asset;
            });
          },
          thumbFuture: _thumbFuture(asset),
        );
      },
    );
  }
}

/// Widget hiển thị video tile với thumbnail và duration
class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.asset,
    required this.selected,
    required this.onTap,
    required this.thumbFuture,
  });

  final AssetEntity asset;
  final bool selected;
  final VoidCallback onTap;
  final Future<Uint8List?> thumbFuture;

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
            // Thumbnail
            FutureBuilder<Uint8List?>(
              future: thumbFuture,
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
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.black26,
                      ),
                    ),
                  );
                }

                return Image.memory(
                  data,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                );
              },
            ),

            // Video icon overlay
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),

            // Duration overlay
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatDuration(asset.videoDuration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Selected border
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

            // Selected checkmark
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }
}
