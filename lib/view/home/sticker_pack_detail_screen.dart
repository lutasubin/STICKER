import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sticker_app/helper/dialogs/app_dialogs.dart';
import 'package:sticker_app/helper/logger/app_logger.dart';
import 'package:sticker_app/model/sticker_pack.dart';
import 'package:sticker_app/service/sticker/whatsapp_sticker_service.dart';

class StickerPackDetailScreen extends StatefulWidget {
  const StickerPackDetailScreen({super.key});

  @override
  State<StickerPackDetailScreen> createState() =>
      _StickerPackDetailScreenState();
}

class _StickerPackDetailScreenState extends State<StickerPackDetailScreen> {
  final _service = const WhatsappStickerService();
  late final StickerPack _pack;
  bool _isSending = false;
  bool _isInstalled = false;
  bool _isChecking = true;

  Future<void> _sharePack() async {
    final assets = _pack.allAssets;
    if (assets.isEmpty) {
      AppDialogs.showWarning('No stickers to share.');
      return;
    }

    final dir = await getTemporaryDirectory();
    final outDir = Directory('${dir.path}${Platform.pathSeparator}share_pack_${_pack.id}');
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    final files = <XFile>[];
    for (final assetPath in assets) {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final ext = assetPath.split('.').last.toLowerCase();
      final outFile = File(
        '${outDir.path}${Platform.pathSeparator}${assetPath.split('/').last}',
      );
      if (!await outFile.exists()) {
        await outFile.writeAsBytes(bytes, flush: true);
      }

      final mime = switch (ext) {
        'webp' => 'image/webp',
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        _ => 'application/octet-stream',
      };
      files.add(XFile(outFile.path, mimeType: mime));
    }

    // ignore: deprecated_member_use
    await Share.shareXFiles(files, subject: _pack.title);
  }

  @override
  void initState() {
    super.initState();
    _pack = Get.arguments as StickerPack;
    _checkInstalledStatus();
  }

  Future<void> _checkInstalledStatus() async {
    try {
      final installed = await _service.isStickerPackInstalled(_pack.id);
      if (mounted) {
        setState(() {
          _isInstalled = installed;
          _isChecking = false;
        });
      }
    } catch (e) {
      AppLogger.e(
        '[StickerPackDetailScreen] Failed to check installed status',
        e,
      );
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildGrid()),
          _buildAddButton(),
        ],
      ),
    );
  }

  // ================= APP BAR =================

  AppBar _buildAppBar() {
    return AppBar(
      leading: IconButton(
        onPressed: Get.back,
        icon: const Icon(Icons.arrow_back, color: Colors.black),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.black),
          onPressed: _sharePack,
        ),
      ],
    );
  }

  // ================= PACK INFO =================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF5F5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _pack.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _pack.subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ================= STICKER GRID =================

  Widget _buildGrid() {
    final items = _pack.allAssets;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (_, index) {
          final asset = items[index];
          return GestureDetector(
            onTap: () => _showStickerViewer(asset),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(asset, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  // ================= ADD TO WHATSAPP BUTTON =================

  Widget _buildAddButton() {
    // Nếu đang kiểm tra trạng thái, hiển thị loading
    if (_isChecking) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Đang kiểm tra...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Nếu đã được thêm vào, hiển thị nút xám với text "Đã được thêm vào"
    if (_isInstalled) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.grey.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Has been added',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Nếu chưa được thêm, hiển thị nút xanh bình thường
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSending ? null : _addToWhatsapp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSending)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  SvgPicture.asset(
                    'assets/icons/phone_icons2.svg',
                    width: 24,
                    height: 24,
                  ),
                const SizedBox(width: 10),
                Text(
                  _isSending ? 'Adding...' : 'Add to whatsapp',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= ADD PACK LOGIC =================

  Future<void> _addToWhatsapp() async {
    setState(() => _isSending = true);

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final installed = await _service.isWhatsAppInstalled();
      if (!installed) {
        AppDialogs.showWhatsAppNotInstalled();
        return;
      }

      final result = await _service.addPack(_pack);

      if (result == 'cancelled') {
        return;
      } else if (result == 'already_added' || result == 'add_successful' || result == 'success') {
        // Cập nhật trạng thái đã được thêm vào
        if (mounted) {
          setState(() {
            _isInstalled = true;
          });
        }
        
        if (result == 'already_added') {
          AppDialogs.showStickerAlreadyAdded();
        } else {
          AppDialogs.showStickerAddedSuccess();
        }
      }
    } catch (e) {
      AppDialogs.showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ================= STICKER VIEWER =================

  void _showStickerViewer(String asset) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder:
          (_) => GestureDetector(
            onTap: Get.back,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    child: Hero(tag: asset, child: Image.asset(asset)),
                  ),
                ),
                const Positioned(
                  top: 32,
                  right: 16,
                  child: CloseButton(color: Colors.white),
                ),
              ],
            ),
          ),
    );
  }
}
