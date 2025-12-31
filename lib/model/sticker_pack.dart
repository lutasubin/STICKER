import 'package:flutter/foundation.dart';

/// Loại danh mục sticker hiển thị trên tab
enum StickerCategory { animal, funny, love, cartoon }

extension StickerCategoryX on StickerCategory {
  String get label {
    switch (this) {
      case StickerCategory.animal:
        return 'Animal';
      case StickerCategory.funny:
        return 'Funny';
      case StickerCategory.love:
        return 'Love';
      case StickerCategory.cartoon:
        return 'Cartoon';
    }
  }
}

/// Model đại diện cho 1 gói sticker trên màn hình Home
@immutable
class StickerPack {
  final String id;
  final String title;
  final String subtitle;
  final StickerCategory category;

  /// Thư mục chứa ảnh, ví dụ: assets/sticker_maker/Memes/Face meme
  final String folderPath;

  /// Số lượng ảnh trong pack (1.webp -> itemCount.webp)
  final int itemCount;

  /// ✅ QUAN TRỌNG: pack có phải sticker động không
  final bool isAnimated;

  /// Đường dẫn đến tray image (static image cho icon của pack)
  /// Với animated packs: BẮT BUỘC phải có static tray image (tray.webp hoặc tray.png)
  /// Với static packs: có thể dùng null để tự động dùng 1.webp
  final String? trayImagePath;

  const StickerPack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.folderPath,
    required this.itemCount,
    required this.isAnimated,
    this.trayImagePath,
  });

  /// Path đến tray image - với animated packs cần static image
  /// ⚠️ Với animated packs, nếu không có trayImagePath sẽ dùng 1.webp (có thể bị lỗi từ WhatsApp)
  String get effectiveTrayImagePath {
    if (trayImagePath != null) {
      return trayImagePath!;
    }
    // Fallback: với animated packs nên có tray image riêng
    // Tự động tìm tray.webp hoặc tray.png trong folder
    // Nếu không tìm thấy, dùng 1.webp (có thể sẽ bị lỗi)
    return '$folderPath/1.webp';
  }

  /// Toàn bộ path ảnh trong pack
  List<String> get allAssets =>
      List.generate(itemCount, (index) => '$folderPath/${index + 1}.webp');

  /// Ảnh preview (tối đa 5 cái đầu)
  List<String> get previewAssets =>
      allAssets.length <= 5 ? allAssets : allAssets.sublist(0, 5);
}
