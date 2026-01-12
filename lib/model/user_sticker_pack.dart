import 'package:flutter/foundation.dart';

@immutable
class UserStickerPack {
  final String id;
  final String title;
  final int createdAtMs;
  final int lastModifiedAtMs; // Thời điểm chỉnh sửa lần cuối
  final List<String> stickerFileUris;

  const UserStickerPack({
    required this.id,
    required this.title,
    required this.createdAtMs,
    required this.lastModifiedAtMs,
    required this.stickerFileUris,
  });

  UserStickerPack copyWith({
    String? id,
    String? title,
    int? createdAtMs,
    int? lastModifiedAtMs,
    List<String>? stickerFileUris,
  }) {
    return UserStickerPack(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      lastModifiedAtMs: lastModifiedAtMs ?? this.lastModifiedAtMs,
      stickerFileUris: stickerFileUris ?? this.stickerFileUris,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAtMs': createdAtMs,
      'lastModifiedAtMs': lastModifiedAtMs,
      'stickerFileUris': stickerFileUris,
    };
  }

  factory UserStickerPack.fromJson(Map<String, dynamic> json) {
    final rawUris = json['stickerFileUris'];
    final createdAtMs = (json['createdAtMs'] as num?)?.toInt() ?? 0;
    // Nếu không có lastModifiedAtMs, dùng createdAtMs (backward compatibility)
    final lastModifiedAtMs = (json['lastModifiedAtMs'] as num?)?.toInt() ?? createdAtMs;
    return UserStickerPack(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      createdAtMs: createdAtMs,
      lastModifiedAtMs: lastModifiedAtMs,
      stickerFileUris:
          rawUris is List ? rawUris.map((e) => e.toString()).toList() : const [],
    );
  }
}
