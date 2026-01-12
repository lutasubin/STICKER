import 'dart:convert';

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

  /// Cache danh sách sticker theo category
  final Map<StickerCategory, List<String>> _stickerCache = {};

  /// Load danh sách sticker từ một category
  Future<List<String>> getStickersByCategory(StickerCategory category) async {
    // Kiểm tra cache trước
    if (_stickerCache.containsKey(category)) {
      return _stickerCache[category]!;
    }

    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap =
          const JsonDecoder().convert(manifestContent) as Map<String, dynamic>;

      // Lọc các asset thuộc category này
      final categoryPath = category.assetPath;
      final stickers =
          manifestMap.keys
              .where(
                (key) => key.startsWith(categoryPath) && key.endsWith('.webp'),
              )
              .toList()
            ..sort((a, b) {
              // Sắp xếp theo số thứ tự trong tên file
              final aMatch = RegExp(r'(\d+)').firstMatch(a);
              final bMatch = RegExp(r'(\d+)').firstMatch(b);
              if (aMatch != null && bMatch != null) {
                return int.parse(
                  aMatch.group(1)!,
                ).compareTo(int.parse(bMatch.group(1)!));
              }
              return a.compareTo(b);
            });

      // Cache kết quả
      _stickerCache[category] = stickers;
      return stickers;
    } catch (e) {
      debugPrint('Error loading stickers for ${category.displayName}: $e');
      return [];
    }
  }

  /// Lấy tất cả categories
  List<StickerCategory> getAllCategories() {
    return StickerCategory.values;
  }

  /// Clear cache (nếu cần)
  void clearCache() {
    _stickerCache.clear();
  }
}
