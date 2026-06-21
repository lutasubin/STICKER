// Keep original file for StickerCategory enum and service
// This file contains the enum definition that other files depend on
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Danh mục sticker có sẵn
enum StickerCategory {
  glass('Galss', 'assets/sticker_edit/Sticker/Galss/', Icons.dark_mode),
  accessory('Accessory', 'assets/sticker_edit/Sticker/accessory/', Icons.watch),
  hat('Hat', 'assets/sticker_edit/Sticker/hat/', Icons.celebration),
  hair('Hair', 'assets/sticker_edit/Sticker/hair/', Icons.face),
  love('Love', 'assets/sticker_edit/Sticker/love/', Icons.favorite),
  birthday('Birthday', 'assets/sticker_edit/Sticker/Birthday/', Icons.cake),
  textStyle(
    'Text Style',
    'assets/sticker_edit/Sticker/text style/',
    Icons.text_fields,
  );

  const StickerCategory(this.displayName, this.assetPath, this.icon);

  final String displayName;
  final String assetPath;
  final IconData icon;
}

/// Service để quản lý sticker edit assets
class StickerEditService {
  static final StickerEditService _instance = StickerEditService._internal();
  factory StickerEditService() => _instance;
  StickerEditService._internal();

  final Map<StickerCategory, List<String>> _stickerCache = {};

  Future<List<String>> getStickersByCategory(StickerCategory category) async {
    if (_stickerCache.containsKey(category)) {
      return _stickerCache[category]!;
    }

    try {
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> allAssets = assetManifest.listAssets();

      final categoryPath = category.assetPath;
      final stickers =
          allAssets
              .where(
                (key) => key.startsWith(categoryPath) && key.endsWith('.webp'),
              )
              .toList()
            ..sort((a, b) {
              final aMatch = RegExp(r'(\d+)').firstMatch(a);
              final bMatch = RegExp(r'(\d+)').firstMatch(b);
              if (aMatch != null && bMatch != null) {
                return int.parse(
                  aMatch.group(1)!,
                ).compareTo(int.parse(bMatch.group(1)!));
              }
              return a.compareTo(b);
            });

      _stickerCache[category] = stickers;
      return stickers;
    } catch (e) {
      debugPrint('Error loading stickers for ${category.displayName}: $e');
      return [];
    }
  }

  List<StickerCategory> getAllCategories() {
    return StickerCategory.values;
  }

  List<String>? _backgroundCache;

  Future<List<String>> getBackgrounds() async {
    if (_backgroundCache != null) {
      return _backgroundCache!;
    }

    try {
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> allAssets = assetManifest.listAssets();

      const backgroundPath = 'assets/sticker_edit/background/';
      final backgrounds =
          allAssets
              .where(
                (key) =>
                    key.startsWith(backgroundPath) && key.endsWith('.webp'),
              )
              .toList()
            ..sort((a, b) {
              final aMatch = RegExp(r'(\d+)').firstMatch(a);
              final bMatch = RegExp(r'(\d+)').firstMatch(b);
              if (aMatch != null && bMatch != null) {
                return int.parse(
                  aMatch.group(1)!,
                ).compareTo(int.parse(bMatch.group(1)!));
              }
              return a.compareTo(b);
            });

      _backgroundCache = backgrounds;
      return backgrounds;
    } catch (e) {
      debugPrint('Error loading backgrounds: $e');
      return [];
    }
  }

  void clearCache() {
    _stickerCache.clear();
    _backgroundCache = null;
  }
}
