import 'package:flutter/services.dart';
import 'package:sticker_app/data/model/sticker_pack.dart';
import 'package:sticker_app/data/model/user_sticker_pack.dart';
import 'package:sticker_app/helper/logger/app_logger.dart';

/// Service layer: Low-level WhatsApp integration via MethodChannel
/// Pure data access - no business logic
class WhatsappStickerService {
  const WhatsappStickerService();

  static const MethodChannel _channel = MethodChannel('whatsapp_stickers');
  static const _fallbackEmoji = '🙂';

  Future<bool> isWhatsAppInstalled() async {
    try {
      AppLogger.d('[WhatsappStickerService] Checking if WhatsApp is installed...');
      final installed = await _channel.invokeMethod<bool>(
        'isWhatsAppInstalled',
      );
      final result = installed ?? false;
      AppLogger.i('[WhatsappStickerService] WhatsApp installed: $result');
      return result;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.e(
        '[WhatsappStickerService] Failed to check WhatsApp installation',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Check if a sticker pack is already installed in WhatsApp
  Future<bool> isStickerPackInstalled(String identifier) async {
    try {
      AppLogger.d(
        '[WhatsappStickerService] Checking if sticker pack is installed: $identifier',
      );
      final installed = await _channel.invokeMethod<bool>(
        'isStickerPackInstalled',
        {'identifier': identifier},
      );
      final result = installed ?? false;
      AppLogger.i(
        '[WhatsappStickerService] Sticker pack installed: $identifier = $result',
      );
      return result;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.e(
        '[WhatsappStickerService] Failed to check sticker pack installation: $identifier',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Build payload and request Android to add the sticker pack to WhatsApp.
  Future<String> addPack(StickerPack pack) async {
    AppLogger.i(
      '[WhatsappStickerService] Adding pack to WhatsApp: ${pack.id} (${pack.title})',
    );
    AppLogger.d(
      '[WhatsappStickerService] Pack details: itemCount=${pack.itemCount}, isAnimated=${pack.isAnimated}, folderPath=${pack.folderPath}',
    );

    final stickers = <String, List<String>>{};
    for (var i = 0; i < pack.itemCount; i++) {
      final assetPath = '${pack.folderPath}/${i + 1}.webp';
      stickers['assets://$assetPath'] = [_fallbackEmoji];
    }

    final args = {
      'identifier': pack.id,
      'name': pack.title,
      'publisher': 'Sticker App',
      'trayImageFileName': 'assets://${pack.effectiveTrayImagePath}',
      'publisherWebsite': '',
      'privacyPolicyWebsite': '',
      'licenseAgreementWebsite': '',
      'stickers': stickers,
      'isAnimated': pack.isAnimated,
    };

    AppLogger.d(
      '[WhatsappStickerService] Sending to WhatsApp: identifier=${pack.id}, stickerCount=${stickers.length}',
    );

    try {
      final result = await _channel.invokeMethod<String>(
        'sendToWhatsApp',
        args,
      );
      final finalResult = result ?? 'success';
      AppLogger.i(
        '[WhatsappStickerService] Pack added successfully: ${pack.id}, result=$finalResult',
      );
      return finalResult;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.e(
        '[WhatsappStickerService] Failed to add pack to WhatsApp: ${pack.id}',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Remove sticker pack from WhatsApp
  Future<String> removePack(String identifier) async {
    AppLogger.i(
      '[WhatsappStickerService] Removing pack from WhatsApp: $identifier',
    );
    try {
      final result = await _channel.invokeMethod<String>(
        'removeFromWhatsApp',
        {'identifier': identifier},
      );
      final finalResult = result ?? 'success';
      AppLogger.i(
        '[WhatsappStickerService] Pack removed successfully: $identifier, result=$finalResult',
      );
      return finalResult;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.e(
        '[WhatsappStickerService] Failed to remove pack from WhatsApp: $identifier',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Build payload and request Android to add a user-created sticker pack (stored as files)
  /// to WhatsApp.
  ///
  /// Notes:
  /// - Android native validator requires 3..30 stickers.
  /// - `file://` URIs are supported by the native code in this project.
  Future<String> addUserPack(UserStickerPack pack) async {
    AppLogger.i(
      '[WhatsappStickerService] Adding user pack to WhatsApp: ${pack.id} (${pack.title})',
    );

    final stickerUris = pack.stickerFileUris;
    AppLogger.d(
      '[WhatsappStickerService] User pack sticker count: ${stickerUris.length}',
    );

    if (stickerUris.length < 3 || stickerUris.length > 30) {
      AppLogger.w(
        '[WhatsappStickerService] Invalid sticker count: ${stickerUris.length} (required: 3-30)',
      );
      throw PlatformException(
        code: 'validation_error',
        message: 'Sticker pack phải có từ 3 đến 30 sticker.',
      );
    }

    const trayUri = 'assets://assets/sticker_maker/tray/1.webp';

    final stickers = <String, List<String>>{};
    for (final u in stickerUris.take(30)) {
      stickers[u] = [_fallbackEmoji];
    }

    final args = {
      'identifier': pack.id,
      'name': pack.title,
      'publisher': 'Sticker App',
      'trayImageFileName': trayUri,
      'publisherWebsite': '',
      'privacyPolicyWebsite': '',
      'licenseAgreementWebsite': '',
      'stickers': stickers,
      'isAnimated': pack.isAnimated,
    };

    AppLogger.d(
      '[WhatsappStickerService] Sending user pack to WhatsApp: identifier=${pack.id}, stickerCount=${stickers.length}',
    );

    try {
      final result = await _channel.invokeMethod<String>(
        'sendToWhatsApp',
        args,
      );
      final finalResult = result ?? 'success';
      AppLogger.i(
        '[WhatsappStickerService] User pack added successfully: ${pack.id}, result=$finalResult',
      );
      return finalResult;
    } on PlatformException catch (e, stackTrace) {
      if (e.code == 'validation_error') {
        AppLogger.e(
          '[WhatsappStickerService] Validation error for user pack: ${pack.id}',
          e,
          stackTrace,
        );
        throw PlatformException(
          code: e.code,
          message: e.message ?? 'Sticker pack không hợp lệ.',
        );
      }
      AppLogger.e(
        '[WhatsappStickerService] Failed to add user pack: ${pack.id}',
        e,
        stackTrace,
      );
      throw PlatformException(
        code: e.code,
        message: e.message ?? 'Không thể thêm sticker pack.',
      );
    }
  }
}
