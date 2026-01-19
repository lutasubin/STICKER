import 'package:sticker_app/data/model/sticker_pack.dart';

/// Service layer: Low-level data access for sticker packs
/// Pure data access - no business logic
class StickerService {
  const StickerService();

  /// Danh sách tất cả sticker pack, có gắn category để lọc theo tab.
  List<StickerPack> getAllPacks() {
    return [
      // ===== Animal =====
      const StickerPack(
        id: 'animal-moka',
        title: 'Moka the dog',
        subtitle: '30 sticker',
        category: StickerCategory.animal,
        folderPath: 'assets/sticker_maker/Animal/Moka_the_dog',
        itemCount: 30,
        isAnimated: false,
      ),
      const StickerPack(
        id: 'animal-penguin',
        title: 'Penguin',
        subtitle: '24 sticker',
        category: StickerCategory.animal,
        folderPath: 'assets/sticker_maker/Animal/Penguin',
        itemCount: 24,
        isAnimated: false,
      ),
      const StickerPack(
        id: 'animal-pocky',
        title: 'Pocky',
        subtitle: '22 sticker',
        category: StickerCategory.animal,
        folderPath: 'assets/sticker_maker/Animal/Pocky',
        itemCount: 22,
        isAnimated: false,
      ),
      const StickerPack(
        id: 'Twister-dog',
        title: 'Twister the dog',
        subtitle: '17 sticker',
        category: StickerCategory.animal,
        folderPath: 'assets/sticker_maker/Animal/Twister_the_dog',
        itemCount: 17,
        isAnimated: true,
        trayImagePath: 'assets/sticker_maker/tray/1.webp',
      ),

      // ===== Memes / Funny =====
      const StickerPack(
        id: 'memes-face-meme',
        title: 'Face meme',
        subtitle: '30 sticker',
        category: StickerCategory.funny,
        folderPath: 'assets/sticker_maker/Memes/Face_meme',
        itemCount: 30,
        isAnimated: false,
      ),
      // ===== Baby =====
      const StickerPack(
        id: 'baby-children',
        title: 'Children',
        subtitle: '20 sticker',
        category: StickerCategory.love,
        folderPath: 'assets/sticker_maker/Baby/Children',
        itemCount: 20,
        isAnimated: false,
      ),
      const StickerPack(
        id: 'baby-ullzang',
        title: 'Ullzangbaby',
        subtitle: '21 sticker',
        category: StickerCategory.love,
        folderPath: 'assets/sticker_maker/Baby/Ullzangbaby',
        itemCount: 21,
        isAnimated: false,
      ),
      // ===== Anime (map sang tab Cartoon) =====
      const StickerPack(
        id: 'baby-poco',
        title: 'Poco',
        subtitle: '24 sticker',
        category: StickerCategory.cartoon,
        folderPath: 'assets/sticker_maker/Baby/poco',
        itemCount: 24,
        isAnimated: true,
        trayImagePath: 'assets/sticker_maker/tray/1.webp',
      ),
    ];
  }

  /// Lọc pack theo category.
  List<StickerPack> getByCategory(StickerCategory category) {
    final all = getAllPacks();
    return all.where((e) => e.category == category).toList();
  }
}
