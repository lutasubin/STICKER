import 'package:flutter/services.dart';
import 'package:sticker_app/model/sticker_pack.dart';
import 'package:sticker_app/model/user_sticker_pack.dart';

/// Bridge to the native WhatsApp sticker plugin through a MethodChannel.
class WhatsappStickerService {
  const WhatsappStickerService();

  static const MethodChannel _channel = MethodChannel('whatsapp_stickers');
  static const _fallbackEmoji = '🙂';

  Future<bool> isWhatsAppInstalled() async {
    try {
      final installed = await _channel.invokeMethod<bool>(
        'isWhatsAppInstalled',
      );
      return installed ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Build payload and request Android to add the sticker pack to WhatsApp.
  Future<String> addPack(StickerPack pack) async {
    final stickers = <String, List<String>>{};
    for (var i = 0; i < pack.itemCount; i++) {
      final assetPath = '${pack.folderPath}/${i + 1}.webp';
      stickers['assets://$assetPath'] = [_fallbackEmoji];
    }

    final args = {
      'identifier': pack.id,
      'name': pack.title,
      'publisher': 'Sticker App',
      // ✅ Với animated packs, dùng tray image riêng (static) thay vì 1.webp động
      'trayImageFileName': 'assets://${pack.effectiveTrayImagePath}',
      'publisherWebsite': '',
      'privacyPolicyWebsite': '',
      'licenseAgreementWebsite': '',
      'stickers': stickers,

      // 🔥 then chốt
      'isAnimated': pack.isAnimated,
    };

    try {
      final result = await _channel.invokeMethod<String>(
        'sendToWhatsApp',
        args,
      );
      return result ?? 'success';
    } on PlatformException catch (e) {
      // validation_error từ WhatsApp
      if (e.code == 'validation_error') {
        throw PlatformException(
          code: e.code,
          message: e.message ?? 'Sticker pack không hợp lệ.',
        );
      }
      throw PlatformException(
        code: e.code,
        message: e.message ?? 'Không thể thêm sticker pack.',
      );
    }
  }

  /// Build payload and request Android to add a user-created sticker pack (stored as files)
  /// to WhatsApp.
  ///
  /// Notes:
  /// - Android native validator requires 3..30 stickers.
  /// - `file://` URIs are supported by the native code in this project.
  Future<String> addUserPack(UserStickerPack pack) async {
    final stickerUris = pack.stickerFileUris;
    if (stickerUris.length < 3 || stickerUris.length > 30) {
      throw PlatformException(
        code: 'validation_error',
        message: 'Sticker pack phải có từ 3 đến 30 sticker.',
      );
    }

    // Use a fixed asset tray icon to avoid WhatsApp rejecting local file paths.
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
      'isAnimated': false,
    };

    try {
      final result = await _channel.invokeMethod<String>(
        'sendToWhatsApp',
        args,
      );
      return result ?? 'success';
    } on PlatformException catch (e) {
      if (e.code == 'validation_error') {
        throw PlatformException(
          code: e.code,
          message: e.message ?? 'Sticker pack không hợp lệ.',
        );
      }
      throw PlatformException(
        code: e.code,
        message: e.message ?? 'Không thể thêm sticker pack.',
      );
    }
  }
}
