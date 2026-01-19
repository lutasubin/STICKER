import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sticker_app/data/model/user_sticker_pack.dart';
import 'package:sticker_app/data/repository/sticker_repository.dart';
import 'package:sticker_app/data/repository/user_sticker_pack_repository.dart';
import 'package:sticker_app/helper/dialogs/app_dialogs.dart';
import 'package:sticker_app/helper/logger/app_logger.dart';
import 'package:sticker_app/router/router.dart';

/// ViewModel for UserPackDetail screen
/// Handles business logic and state management
class UserPackDetailViewModel extends GetxController {
  final UserStickerPackRepository _userPackRepository;
  final StickerRepository _stickerRepository;

  UserPackDetailViewModel({
    UserStickerPackRepository? userPackRepository,
    StickerRepository? stickerRepository,
  }) : _userPackRepository =
           userPackRepository ?? Get.find<UserStickerPackRepository>(),
       _stickerRepository = stickerRepository ?? StickerRepository();

  final pack = Rxn<UserStickerPack>();
  final isSending = false.obs;
  final changed = false.obs;
  final isInstalled = false.obs;
  final isChecking = true.obs;
  final needsUpdate = false.obs;

  @override
  void onInit() {
    super.onInit();
    final initialPack = Get.arguments as UserStickerPack;
    pack.value = initialPack;
    checkInstalledStatus();
  }

  Future<void> checkInstalledStatus({bool updateNeedsUpdate = true}) async {
    try {
      if (pack.value == null) return;

      final refreshedPack = _userPackRepository.getById(pack.value!.id);
      if (refreshedPack != null) {
        pack.value = refreshedPack;
      }

      final installedInWhatsApp = await _stickerRepository
          .isStickerPackInstalled(pack.value!.id);

      final installedAt = _userPackRepository.getPackInstalledAt(
        pack.value!.id,
      );
      final hasInstalledRecord = installedAt != null;

      final isInstalledValue = installedInWhatsApp || hasInstalledRecord;

      if (installedInWhatsApp && !hasInstalledRecord) {
        AppLogger.i(
          '[UserPackDetailViewModel] Pack installed in WhatsApp but no record found, marking as installed: ${pack.value!.id}',
        );
        _userPackRepository.markPackAsInstalled(pack.value!.id);
      }

      final needsUpdateValue =
          updateNeedsUpdate
              ? _userPackRepository.packNeedsUpdate(pack.value!.id)
              : needsUpdate.value;

      AppLogger.i(
        '[UserPackDetailViewModel] Check installed status: ${pack.value!.id}\n'
        '   - WhatsApp native: $installedInWhatsApp\n'
        '   - Has installedAt record: $hasInstalledRecord (timestamp: $installedAt)\n'
        '   - Final isInstalled: $isInstalledValue\n'
        '   - needsUpdate: $needsUpdateValue\n'
        '   - lastModifiedAtMs: ${pack.value!.lastModifiedAtMs}',
      );

      isInstalled.value = isInstalledValue;
      isChecking.value = false;
      if (updateNeedsUpdate) {
        needsUpdate.value = needsUpdateValue;
      }
    } catch (e) {
      AppLogger.e(
        '[UserPackDetailViewModel] Failed to check installed status',
        e,
      );
      isChecking.value = false;
    }
  }

  Future<void> sharePack() async {
    if (pack.value == null) return;

    final stickers = pack.value!.stickerFileUris;
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

    await Share.shareXFiles(files, subject: pack.value!.title);
  }

  void reloadFromStorage() {
    if (pack.value == null) return;

    final refreshed = _userPackRepository.getById(pack.value!.id);
    if (refreshed != null) {
      final needsUpdateValue = _userPackRepository.packNeedsUpdate(
        refreshed.id,
      );
      AppLogger.i(
        '[UserPackDetailViewModel] Reloading pack: ${refreshed.id}, '
        'lastModifiedAtMs=${refreshed.lastModifiedAtMs}, needsUpdate=$needsUpdateValue, '
        'stickerCount=${refreshed.stickerFileUris.length}',
      );
      pack.value = refreshed;
      changed.value = true;
      needsUpdate.value = needsUpdateValue;
      checkInstalledStatus(updateNeedsUpdate: false);
    }
  }

  Future<void> addSticker() async {
    if (pack.value == null) return;

    if (pack.value!.isAnimated) {
      await Get.toNamed(
        AppRoutes.createAnimatedSelectVideo,
        arguments: {
          'pack': pack.value,
          'isNewPack': false,
          'goToUserPackDetail': true,
        },
      );
    } else {
      await Get.toNamed(
        AppRoutes.createStickerSelectImage,
        arguments: {'pack': pack.value, 'goToUserPackDetail': true},
      );
    }

    await Future.delayed(const Duration(milliseconds: 100));
    reloadFromStorage();
  }

  Future<void> exportPack() async {
    if (isSending.value || pack.value == null) return;
    isSending.value = true;

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final installed = await _stickerRepository.isWhatsAppInstalled();
      if (!installed) {
        AppDialogs.showWhatsAppNotInstalled();
        return;
      }

      final result = await _stickerRepository.addUserPackToWhatsApp(
        pack.value!,
      );

      if (result == 'cancelled') {
        return;
      } else if (result == 'already_added' ||
          result == 'add_successful' ||
          result == 'success') {
        final refreshedPack = _userPackRepository.getById(pack.value!.id);
        if (refreshedPack != null) {
          pack.value = refreshedPack;
        }

        final wasUpdating = needsUpdate.value;

        _userPackRepository.markPackAsInstalled(pack.value!.id);

        isInstalled.value = true;
        needsUpdate.value = false;

        if (wasUpdating) {
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
      isSending.value = false;
    }
  }

  Future<void> confirmDeletePack() async {
    final ok = await AppDialogs.showDeletePackageConfirm();
    if (!ok) return;

    _userPackRepository.deletePack(packId: pack.value!.id, deleteFiles: true);
    Get.offAllNamed(AppRoutes.mySticker);
  }

  Future<void> renamePack() async {
    if (pack.value == null) return;

    final result = await AppDialogs.showPackNameInputDialog(
      title: 'default_pack_name'.tr,
      initialText: pack.value!.title,
      hintText: 'Sticker pack name...',
    );
    if (result == null) return;

    final updated = _userPackRepository.renamePack(
      packId: pack.value!.id,
      newTitle: result,
    );
    if (updated != null) {
      final needsUpdateValue = _userPackRepository.packNeedsUpdate(updated.id);
      pack.value = updated;
      changed.value = true;
      needsUpdate.value = needsUpdateValue;
    }
  }

  Future<void> openStickerViewer(String stickerUri) async {
    AppDialogs.showStickerViewer(
      stickerUri: stickerUri,
      onDelete: () async {
        _userPackRepository.removeStickerUri(
          packId: pack.value!.id,
          stickerFileUri: stickerUri,
          deleteFile: true,
        );
        Get.back();
        await Future.delayed(const Duration(milliseconds: 100));
        reloadFromStorage();
      },
      onShare: () async {
        final file = File.fromUri(Uri.parse(stickerUri));
        if (!file.existsSync()) return;
        await Share.shareXFiles([
          XFile(file.path, mimeType: 'image/webp'),
        ], subject: pack.value!.title);
      },
      onEdit: () async {
        Get.back();

        if (pack.value!.isAnimated) {
          await Get.dialog(
            AlertDialog(
              title: Text('edit_animated_sticker_title'.tr),
              content: Text(
                'edit_animated_sticker_message'.tr,
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(onPressed: () => Get.back(), child: Text('ok'.tr)),
              ],
            ),
          );
          return;
        } else {
          await Get.toNamed(
            AppRoutes.editSticker,
            arguments: {'pack': pack.value, 'stickerUri': stickerUri},
          );
        }

        reloadFromStorage();
      },
    );
  }

  bool get hasChanged => changed.value;
}
