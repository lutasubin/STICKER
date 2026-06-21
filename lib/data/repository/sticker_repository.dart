import 'package:sticker_app/data/model/sticker_pack.dart';
import 'package:sticker_app/data/model/user_sticker_pack.dart';
import 'package:sticker_app/data/service/sticker_service.dart';
import 'package:sticker_app/data/service/whatsapp_sticker_service.dart';

/// Repository layer: Middle layer between ViewModel and Service
/// Handles data mapping and combines multiple services
class StickerRepository {
  final StickerService _stickerService;
  final WhatsappStickerService _whatsappService;

  StickerRepository({
    StickerService? stickerService,
    WhatsappStickerService? whatsappService,
  }) : _stickerService = stickerService ?? const StickerService(),
       _whatsappService = whatsappService ?? const WhatsappStickerService();

  /// Get sticker packs by category
  List<StickerPack> getPacksByCategory(StickerCategory category) {
    return _stickerService.getByCategory(category);
  }

  /// Get all sticker packs
  List<StickerPack> getAllPacks() {
    return _stickerService.getAllPacks();
  }

  /// Check if WhatsApp is installed
  Future<bool> isWhatsAppInstalled() async {
    return await _whatsappService.isWhatsAppInstalled();
  }

  /// Check if sticker pack is installed in WhatsApp
  Future<bool> isStickerPackInstalled(String identifier) async {
    return await _whatsappService.isStickerPackInstalled(identifier);
  }

  /// Add sticker pack to WhatsApp
  Future<String> addPackToWhatsApp(StickerPack pack) async {
    return await _whatsappService.addPack(pack);
  }

  /// Remove sticker pack from WhatsApp
  Future<String> removePackFromWhatsApp(String identifier) async {
    return await _whatsappService.removePack(identifier);
  }

  /// Add user-created sticker pack to WhatsApp
  Future<String> addUserPackToWhatsApp(UserStickerPack pack) async {
    return await _whatsappService.addUserPack(pack);
  }
}
