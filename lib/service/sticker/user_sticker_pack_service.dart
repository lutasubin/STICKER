import 'dart:io';
import 'package:get/get.dart';
import 'package:sticker_app/helper/logger/app_logger.dart';
import 'package:sticker_app/model/user_sticker_pack.dart';
import 'package:sticker_app/service/splash_service/storage_service.dart';

class UserStickerPackService extends GetxService {
  static const String _keyUserStickerPacks = 'user_sticker_packs';
  static const String _keyInstalledAtPrefix = 'pack_installed_at_';

  late final StorageService _storage;

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    AppLogger.i('[UserStickerPackService] Initialized');
  }

  List<UserStickerPack> getAll() {
    AppLogger.d('[UserStickerPackService] Getting all user packs');
    try {
      final raw = _storage.read(_keyUserStickerPacks);
      if (raw is! List) {
        AppLogger.d(
          '[UserStickerPackService] No packs found, returning empty list',
        );
        return <UserStickerPack>[];
      }

      final packs =
          raw
              .whereType<Map>()
              .map(
                (e) => UserStickerPack.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
      AppLogger.i('[UserStickerPackService] Retrieved ${packs.length} packs');
      return packs;
    } catch (e, stackTrace) {
      AppLogger.e(
        '[UserStickerPackService] Failed to get all packs',
        e,
        stackTrace,
      );
      return <UserStickerPack>[];
    }
  }

  void saveAll(List<UserStickerPack> packs) {
    AppLogger.d('[UserStickerPackService] Saving ${packs.length} packs');
    try {
      _storage.write(
        _keyUserStickerPacks,
        packs.map((e) => e.toJson()).toList(),
      );
      AppLogger.i(
        '[UserStickerPackService] Successfully saved ${packs.length} packs',
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        '[UserStickerPackService] Failed to save packs',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  UserStickerPack? getById(String id) {
    AppLogger.d('[UserStickerPackService] Getting pack by id: $id');
    try {
      final packs = getAll();
      final index = packs.indexWhere((p) => p.id == id);
      if (index < 0) {
        AppLogger.w('[UserStickerPackService] Pack not found: $id');
        return null;
      }
      AppLogger.d('[UserStickerPackService] Pack found: $id');
      return packs[index];
    } catch (e, stackTrace) {
      AppLogger.e(
        '[UserStickerPackService] Failed to get pack by id: $id',
        e,
        stackTrace,
      );
      return null;
    }
  }

  UserStickerPack createPack({required String title}) {
    AppLogger.i('[UserStickerPackService] Creating new pack: $title');
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final id = 'user-pack-$now';

      final pack = UserStickerPack(
        id: id,
        title: title,
        createdAtMs: now,
        lastModifiedAtMs: now,
        stickerFileUris: const [],
      );

      final packs = getAll();
      saveAll([pack, ...packs]);

      AppLogger.i('[UserStickerPackService] Pack created successfully: $id');
      return pack;
    } catch (e, stackTrace) {
      AppLogger.e(
        '[UserStickerPackService] Failed to create pack: $title',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  UserStickerPack createDraftPack({required String title}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = 'user-pack-$now';

    return UserStickerPack(
      id: id,
      title: title,
      createdAtMs: now,
      lastModifiedAtMs: now,
      stickerFileUris: const [],
    );
  }

  UserStickerPack commitPack(UserStickerPack pack) {
    final packs = getAll();
    final index = packs.indexWhere((p) => p.id == pack.id);

    if (index >= 0) {
      final next = [...packs];
      next[index] = pack;
      saveAll(next);
      return pack;
    }

    saveAll([pack, ...packs]);
    return pack;
  }

  UserStickerPack? addStickerUri({
    required String packId,
    required String stickerFileUri,
  }) {
    AppLogger.d('[UserStickerPackService] Adding sticker to pack: $packId');
    try {
      final packs = getAll();
      final index = packs.indexWhere((p) => p.id == packId);
      if (index < 0) {
        AppLogger.w('[UserStickerPackService] Pack not found: $packId');
        return null;
      }

      final current = packs[index];
      final now = DateTime.now().millisecondsSinceEpoch;
      final updated = current.copyWith(
        stickerFileUris: [stickerFileUri, ...current.stickerFileUris],
        lastModifiedAtMs: now,
      );

      final next = [...packs];
      next[index] = updated;
      saveAll(next);

      AppLogger.i(
        '[UserStickerPackService] Sticker added: pack=$packId, totalStickers=${updated.stickerFileUris.length}',
      );
      return updated;
    } catch (e, stackTrace) {
      AppLogger.e(
        '[UserStickerPackService] Failed to add sticker: pack=$packId',
        e,
        stackTrace,
      );
      return null;
    }
  }

  UserStickerPack? renamePack({
    required String packId,
    required String newTitle,
  }) {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return null;

    final packs = getAll();
    final index = packs.indexWhere((p) => p.id == packId);
    if (index < 0) return null;

    final current = packs[index];
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = current.copyWith(title: trimmed, lastModifiedAtMs: now);

    final next = [...packs];
    next[index] = updated;
    saveAll(next);
    return updated;
  }

  bool deletePack({required String packId, bool deleteFiles = false}) {
    AppLogger.i(
      '[UserStickerPackService] Deleting pack: $packId, deleteFiles=$deleteFiles',
    );
    try {
      final packs = getAll();
      final index = packs.indexWhere((p) => p.id == packId);
      if (index < 0) {
        AppLogger.w(
          '[UserStickerPackService] Pack not found for deletion: $packId',
        );
        return false;
      }

      final pack = packs[index];
      final next = [...packs]..removeAt(index);
      saveAll(next);

      if (deleteFiles) {
        AppLogger.d(
          '[UserStickerPackService] Deleting ${pack.stickerFileUris.length} files',
        );
        var deletedCount = 0;
        for (final uri in pack.stickerFileUris) {
          try {
            final file = File.fromUri(Uri.parse(uri));
            if (file.existsSync()) {
              file.deleteSync();
              deletedCount++;
            }
          } catch (e, stackTrace) {
            AppLogger.w(
              '[UserStickerPackService] Failed to delete file: $uri',
              e,
              stackTrace,
            );
          }
        }
        AppLogger.i('[UserStickerPackService] Deleted $deletedCount files');
      }

      AppLogger.i(
        '[UserStickerPackService] Pack deleted successfully: $packId',
      );
      return true;
    } catch (e, stackTrace) {
      AppLogger.e(
        '[UserStickerPackService] Failed to delete pack: $packId',
        e,
        stackTrace,
      );
      return false;
    }
  }

  UserStickerPack? removeStickerUri({
    required String packId,
    required String stickerFileUri,
    bool deleteFile = false,
  }) {
    AppLogger.d(
      '[UserStickerPackService] Removing sticker from pack: $packId, deleteFile=$deleteFile',
    );
    try {
      final packs = getAll();
      final index = packs.indexWhere((p) => p.id == packId);
      if (index < 0) {
        AppLogger.w('[UserStickerPackService] Pack not found: $packId');
        return null;
      }

      final current = packs[index];
      final nextUris = [...current.stickerFileUris]
        ..removeWhere((u) => u == stickerFileUri);

      final now = DateTime.now().millisecondsSinceEpoch;
      final updated = current.copyWith(
        stickerFileUris: nextUris,
        lastModifiedAtMs: now,
      );
      final next = [...packs];
      next[index] = updated;
      saveAll(next);

      if (deleteFile) {
        try {
          final file = File.fromUri(Uri.parse(stickerFileUri));
          if (file.existsSync()) {
            file.deleteSync();
            AppLogger.d(
              '[UserStickerPackService] File deleted: $stickerFileUri',
            );
            
            // Xóa cả file nobg tương ứng nếu có
            final nobgPath = '${file.path}_nobg.png';
            final nobgFile = File(nobgPath);
            if (nobgFile.existsSync()) {
              nobgFile.deleteSync();
              AppLogger.d(
                '[UserStickerPackService] Nobg file deleted: $nobgPath',
              );
            }
          }
        } catch (e, stackTrace) {
          AppLogger.w(
            '[UserStickerPackService] Failed to delete file: $stickerFileUri',
            e,
            stackTrace,
          );
        }
      }

      AppLogger.i(
        '[UserStickerPackService] Sticker removed: pack=$packId, remainingStickers=${updated.stickerFileUris.length}',
      );
      return updated;
    } catch (e, stackTrace) {
      AppLogger.e(
        '[UserStickerPackService] Failed to remove sticker: pack=$packId',
        e,
        stackTrace,
      );
      return null;
    }
  }

  UserStickerPack? replaceStickerUri({
    required String packId,
    required String oldStickerFileUri,
    required String newStickerFileUri,
    bool deleteOldFile = false,
  }) {
    final packs = getAll();
    final index = packs.indexWhere((p) => p.id == packId);
    if (index < 0) return null;

    final current = packs[index];
    final nextUris =
        current.stickerFileUris
            .map((u) => u == oldStickerFileUri ? newStickerFileUri : u)
            .toList();

    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = current.copyWith(
      stickerFileUris: nextUris,
      lastModifiedAtMs: now,
    );
    final next = [...packs];
    next[index] = updated;
    saveAll(next);

    if (deleteOldFile) {
      try {
        // Xóa file webp cũ
        final file = File.fromUri(Uri.parse(oldStickerFileUri));
        if (file.existsSync()) {
          file.deleteSync();
          
          // Xóa cả file nobg tương ứng nếu có
          final nobgPath = '${file.path}_nobg.png';
          final nobgFile = File(nobgPath);
          if (nobgFile.existsSync()) {
            nobgFile.deleteSync();
            AppLogger.d(
              '[UserStickerPackService] Deleted old nobg file: $nobgPath',
            );
          }
        }
      } catch (e) {
        AppLogger.w(
          '[UserStickerPackService] Error deleting old sticker files: $e',
        );
      }
    }

    return updated;
  }

  /// Lưu thời điểm pack được thêm vào WhatsApp
  /// Lưu lastModifiedAtMs của pack hiện tại (không phải thời điểm hiện tại)
  /// để đảm bảo pack hiện tại đã được sync với WhatsApp
  void markPackAsInstalled(String packId) {
    final pack = getById(packId);
    if (pack == null) {
      AppLogger.w(
        '[UserStickerPackService] Pack not found when marking as installed: $packId',
      );
      return;
    }

    // Lưu lastModifiedAtMs của pack hiện tại làm installedAt
    // Điều này đảm bảo pack hiện tại đã được sync với WhatsApp
    // Nếu sau này pack được chỉnh sửa, lastModifiedAtMs sẽ > installedAt
    final installedAt = pack.lastModifiedAtMs;
    final key = '$_keyInstalledAtPrefix$packId';
    _storage.write(key, installedAt);
    AppLogger.d(
      '[UserStickerPackService] Marked pack as installed: $packId, installedAt=$installedAt, lastModifiedAtMs=${pack.lastModifiedAtMs}',
    );
  }

  /// Lấy thời điểm pack được thêm vào WhatsApp lần cuối
  int? getPackInstalledAt(String packId) {
    final key = '$_keyInstalledAtPrefix$packId';
    final value = _storage.read(key);
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  /// Kiểm tra xem pack có cần update không (đã được chỉnh sửa sau khi install)
  bool packNeedsUpdate(String packId) {
    final pack = getById(packId);
    if (pack == null) {
      AppLogger.d(
        '[UserStickerPackService] Pack not found for needsUpdate check: $packId',
      );
      return false;
    }

    final installedAt = getPackInstalledAt(packId);
    if (installedAt == null) {
      AppLogger.d('[UserStickerPackService] Pack not installed yet: $packId');
      return false; // Chưa được install
    }

    // Nếu lastModifiedAtMs > installedAt, pack đã được chỉnh sửa sau khi install
    final needsUpdate = pack.lastModifiedAtMs > installedAt;
    AppLogger.i(
      '[UserStickerPackService] Pack needsUpdate check: $packId, '
      'lastModifiedAtMs=${pack.lastModifiedAtMs}, installedAt=$installedAt, needsUpdate=$needsUpdate',
    );
    return needsUpdate;
  }
}
