import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sticker_app/helper/dialogs/app_dialogs.dart';
import 'package:sticker_app/helper/logger/app_logger.dart';
import 'package:sticker_app/model/user_sticker_pack.dart';
import 'package:sticker_app/router/router.dart';
import 'package:sticker_app/service/sticker/user_sticker_pack_service.dart';
import 'package:sticker_app/service/sticker/whatsapp_sticker_service.dart';
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
  bool _isInstalled = false;
  bool _isChecking = true;
  bool _needsUpdate = false; // Track nếu pack cần update

  @override
  void initState() {
    super.initState();
    _pack = Get.arguments as UserStickerPack;
    _checkInstalledStatus();
  }

  Future<void> _checkInstalledStatus({bool updateNeedsUpdate = true}) async {
    try {
      final installed = await _whatsApp.isStickerPackInstalled(_pack.id);
      final service = Get.find<UserStickerPackService>();
      // Reload pack để lấy lastModifiedAtMs mới nhất
      final refreshedPack = service.getById(_pack.id);
      if (refreshedPack != null) {
        _pack = refreshedPack;
      }

      // Nếu pack đã được install nhưng installedAt chưa được lưu, tự động lưu
      if (installed) {
        final installedAt = service.getPackInstalledAt(_pack.id);
        if (installedAt == null) {
          // Pack đã được install nhưng chưa có record, tự động mark as installed
          AppLogger.i(
            '[UserPackDetailScreen] Pack already installed but no record found, marking as installed: ${_pack.id}',
          );
          service.markPackAsInstalled(_pack.id);
        }
      }

      final needsUpdate =
          updateNeedsUpdate ? service.packNeedsUpdate(_pack.id) : _needsUpdate;
      AppLogger.i(
        '[UserPackDetailScreen] Check installed status: ${_pack.id}, '
        'installed=$installed, needsUpdate=$needsUpdate, '
        'lastModifiedAtMs=${_pack.lastModifiedAtMs}',
      );
      if (mounted) {
        setState(() {
          _isInstalled = installed;
          _isChecking = false;
          if (updateNeedsUpdate) {
            _needsUpdate = needsUpdate;
          }
        });
      }
    } catch (e) {
      AppLogger.e('[UserPackDetailScreen] Failed to check installed status', e);
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
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
      final needsUpdate = service.packNeedsUpdate(refreshed.id);
      AppLogger.i(
        '[UserPackDetailScreen] Reloading pack: ${refreshed.id}, '
        'lastModifiedAtMs=${refreshed.lastModifiedAtMs}, needsUpdate=$needsUpdate',
      );
      setState(() {
        _pack = refreshed;
        _changed = true;
        _needsUpdate = needsUpdate;
      });
      // Kiểm tra lại trạng thái installed sau khi reload (không update needsUpdate vì đã tính ở trên)
      _checkInstalledStatus(updateNeedsUpdate: false);
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
      } else if (result == 'already_added' ||
          result == 'add_successful' ||
          result == 'success') {
        // Reload pack để lấy lastModifiedAtMs mới nhất
        final service = Get.find<UserStickerPackService>();
        final refreshedPack = service.getById(_pack.id);
        if (refreshedPack != null) {
          _pack = refreshedPack;
        }

        // Kiểm tra xem đây là update hay add mới
        final wasUpdating = _needsUpdate;

        // Đánh dấu pack đã được thêm vào WhatsApp
        // Lưu lastModifiedAtMs hiện tại của pack làm installedAt
        // Để sau này nếu pack được chỉnh sửa, lastModifiedAtMs sẽ > installedAt
        service.markPackAsInstalled(_pack.id);

        // Cập nhật trạng thái đã được thêm vào
        if (mounted) {
          setState(() {
            _isInstalled = true;
            _needsUpdate =
                false; // Vừa mới install/update, không cần update nữa
          });
        }

        // Hiển thị thông báo phù hợp
        if (wasUpdating) {
          // Đây là update pack (pack cũ đã được WhatsApp tự động replace)
          AppDialogs.showStickerUpdatedSuccess();
        } else if (result == 'already_added') {
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
      final needsUpdate = service.packNeedsUpdate(updated.id);
      setState(() {
        _pack = updated;
        _changed = true;
        _needsUpdate = needsUpdate;
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
          arguments: {'pack': _pack, 'stickerUri': stickerUri},
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
            Builder(
              builder: (context) {
                // Tính lại needsUpdate mỗi lần build để đảm bảo luôn đúng
                final service = Get.find<UserStickerPackService>();
                // Reload pack để lấy lastModifiedAtMs mới nhất
                final refreshedPack = service.getById(_pack.id);
                final currentPack = refreshedPack ?? _pack;
                final currentNeedsUpdate = service.packNeedsUpdate(
                  currentPack.id,
                );

                // Update state nếu giá trị thay đổi
                if (currentNeedsUpdate != _needsUpdate && mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _needsUpdate = currentNeedsUpdate;
                        if (refreshedPack != null) {
                          _pack = refreshedPack;
                        }
                      });
                    }
                  });
                }

                return UserPackExportButton(
                  isSending: _isSending,
                  onPressed: _exportPack,
                  isInstalled: _isInstalled,
                  isChecking: _isChecking,
                  needsUpdate: currentNeedsUpdate,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
