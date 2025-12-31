import 'package:get/get.dart';
import 'package:sticker_app/model/user_sticker_pack.dart';
import 'package:sticker_app/service/splash_service/storage_service.dart';
import 'dart:io';

class UserStickerPackService extends GetxService {
  static const String _keyUserStickerPacks = 'user_sticker_packs';

  late final StorageService _storage;

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
  }

  List<UserStickerPack> getAll() {
    final raw = _storage.read(_keyUserStickerPacks);
    if (raw is! List) return <UserStickerPack>[];

    return raw
        .whereType<Map>()
        .map((e) => UserStickerPack.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  void saveAll(List<UserStickerPack> packs) {
    _storage.write(
      _keyUserStickerPacks,
      packs.map((e) => e.toJson()).toList(),
    );
  }

  UserStickerPack? getById(String id) {
    final packs = getAll();
    final index = packs.indexWhere((p) => p.id == id);
    if (index < 0) return null;
    return packs[index];
  }

  UserStickerPack createPack({required String title}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = 'user-pack-$now';

    final pack = UserStickerPack(
      id: id,
      title: title,
      createdAtMs: now,
      stickerFileUris: const [],
    );

    final packs = getAll();
    saveAll([pack, ...packs]);

    return pack;
  }

  UserStickerPack createDraftPack({required String title}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = 'user-pack-$now';

    return UserStickerPack(
      id: id,
      title: title,
      createdAtMs: now,
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
    final packs = getAll();
    final index = packs.indexWhere((p) => p.id == packId);
    if (index < 0) return null;

    final current = packs[index];
    final updated = current.copyWith(
      stickerFileUris: [stickerFileUri, ...current.stickerFileUris],
    );

    final next = [...packs];
    next[index] = updated;
    saveAll(next);

    return updated;
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
    final updated = current.copyWith(title: trimmed);

    final next = [...packs];
    next[index] = updated;
    saveAll(next);
    return updated;
  }

  bool deletePack({
    required String packId,
    bool deleteFiles = false,
  }) {
    final packs = getAll();
    final index = packs.indexWhere((p) => p.id == packId);
    if (index < 0) return false;

    final pack = packs[index];
    final next = [...packs]..removeAt(index);
    saveAll(next);

    if (deleteFiles) {
      for (final uri in pack.stickerFileUris) {
        try {
          final file = File.fromUri(Uri.parse(uri));
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (_) {
          // ignore
        }
      }
    }

    return true;
  }

  UserStickerPack? removeStickerUri({
    required String packId,
    required String stickerFileUri,
    bool deleteFile = false,
  }) {
    final packs = getAll();
    final index = packs.indexWhere((p) => p.id == packId);
    if (index < 0) return null;

    final current = packs[index];
    final nextUris = [...current.stickerFileUris]
      ..removeWhere((u) => u == stickerFileUri);

    final updated = current.copyWith(stickerFileUris: nextUris);
    final next = [...packs];
    next[index] = updated;
    saveAll(next);

    if (deleteFile) {
      try {
        final file = File.fromUri(Uri.parse(stickerFileUri));
        if (file.existsSync()) file.deleteSync();
      } catch (_) {
        // ignore
      }
    }

    return updated;
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
    final nextUris = current.stickerFileUris
        .map((u) => u == oldStickerFileUri ? newStickerFileUri : u)
        .toList();

    final updated = current.copyWith(stickerFileUris: nextUris);
    final next = [...packs];
    next[index] = updated;
    saveAll(next);

    if (deleteOldFile) {
      try {
        final file = File.fromUri(Uri.parse(oldStickerFileUri));
        if (file.existsSync()) file.deleteSync();
      } catch (_) {
        // ignore
      }
    }

    return updated;
  }
}
