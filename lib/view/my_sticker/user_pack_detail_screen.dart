import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sticker_app/model/user_sticker_pack.dart';
import 'package:sticker_app/router/router.dart';
import 'package:sticker_app/service/sticker/user_sticker_pack_service.dart';
import 'package:sticker_app/service/sticker/whatsapp_sticker_service.dart';
import 'package:sticker_app/helper/dialogs/app_dialogs.dart';
import 'package:sticker_app/view/my_sticker/widgets/user_pack_export_button.dart';
import 'package:sticker_app/view/my_sticker/widgets/user_pack_header.dart';
import 'package:sticker_app/view/my_sticker/widgets/user_pack_sticker_grid.dart';

class UserPackDetailScreen extends StatefulWidget {
  const UserPackDetailScreen({super.key});

  @override
  State<UserPackDetailScreen> createState() => _UserPackDetailScreenState();
}

class _UserPackDetailScreenState extends State<UserPackDetailScreen> {
  late UserStickerPack _pack;
  final _whatsApp = const WhatsappStickerService();
  bool _isSending = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _pack = Get.arguments as UserStickerPack;
  }

  Future<void> _sharePack() async {
    final stickers = _pack.stickerFileUris;
    final files = <XFile>[];

    for (final uri in stickers) {
      final file = File.fromUri(Uri.parse(uri));
      if (!file.existsSync()) continue;
      files.add(XFile(file.path, mimeType: 'image/webp'));
    }

    if (files.isEmpty) {
      AppDialogs.showWarning('No stickers to share.');
      return;
    }

    // ignore: deprecated_member_use
    await Share.shareXFiles(files, subject: _pack.title);
  }

  void _reloadFromStorage() {
    final service = Get.find<UserStickerPackService>();
    final refreshed = service.getById(_pack.id);
    if (refreshed != null) {
      setState(() {
        _pack = refreshed;
        _changed = true;
      });
    }
  }

  Future<void> _addSticker() async {
    await Get.toNamed(
      AppRoutes.createStickerSelectImage,
      arguments: {'pack': _pack, 'goToUserPackDetail': true},
    );
    if (!mounted) return;
    _reloadFromStorage();
  }

  Future<void> _exportPack() async {
    if (_isSending) return;
    if (mounted) setState(() => _isSending = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final installed = await _whatsApp.isWhatsAppInstalled();
      if (!installed) {
        AppDialogs.showWhatsAppNotInstalled();
        return;
      }

      final result = await _whatsApp.addUserPack(_pack);

      if (result == 'cancelled') {
        return;
      } else if (result == 'already_added') {
        AppDialogs.showStickerAlreadyAdded();
      } else {
        AppDialogs.showStickerAddedSuccess();
      }
    } catch (e) {
      AppDialogs.showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _confirmDeletePack() async {
    final ok = await AppDialogs.showDeletePackageConfirm();
    if (!ok) return;

    final service = Get.find<UserStickerPackService>();
    service.deletePack(packId: _pack.id, deleteFiles: true);

    Get.offAllNamed(AppRoutes.mySticker);
  }

  Future<void> _renamePack() async {
    final result = await AppDialogs.showPackNameInputDialog(
      title: 'Create package',
      initialText: _pack.title,
      hintText: 'Sticker pack name...',
    );
    if (result == null) return;

    final service = Get.find<UserStickerPackService>();
    final updated = service.renamePack(packId: _pack.id, newTitle: result);
    if (updated != null) {
      setState(() {
        _pack = updated;
        _changed = true;
      });
    }
  }

  void _openStickerViewer(String stickerUri) {
    AppDialogs.showStickerViewer(
      stickerUri: stickerUri,
      onDelete: () {
        final service = Get.find<UserStickerPackService>();
        service.removeStickerUri(
          packId: _pack.id,
          stickerFileUri: stickerUri,
          deleteFile: true,
        );
        Get.back();
        _reloadFromStorage();
      },
      onShare: () async {
        final file = File.fromUri(Uri.parse(stickerUri));
        if (!file.existsSync()) return;
        await Share.shareXFiles([
          XFile(file.path, mimeType: 'image/webp'),
        ], subject: _pack.title);
      },
      onEdit: () async {
        Get.back();
        await Get.toNamed(
          AppRoutes.editSticker,
          arguments: {
            'pack': _pack,
            'stickerUri': stickerUri,
          },
        );
        if (!mounted) return;
        _reloadFromStorage();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stickers = _pack.stickerFileUris;

    return WillPopScope(
      onWillPop: () async {
        Get.back(result: _changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Get.back(result: _changed);
            },
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.black),
              onPressed: _renamePack,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.black),
              onPressed: _sharePack,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.black),
              onPressed: _confirmDeletePack,
            ),
          ],
        ),
        body: Column(
          children: [
            UserPackHeader(title: _pack.title, stickerCount: stickers.length),
            UserPackStickerGrid(
              stickers: stickers,
              onAddSticker: _addSticker,
              onOpenSticker: _openStickerViewer,
            ),
            UserPackExportButton(isSending: _isSending, onPressed: _exportPack),
          ],
        ),
      ),
    );
  }
}
