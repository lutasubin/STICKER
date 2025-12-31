import 'package:flutter/foundation.dart';

@immutable
class UserStickerPack {
  final String id;
  final String title;
  final int createdAtMs;
  final List<String> stickerFileUris;

  const UserStickerPack({
    required this.id,
    required this.title,
    required this.createdAtMs,
    required this.stickerFileUris,
  });

  UserStickerPack copyWith({
    String? id,
    String? title,
    int? createdAtMs,
    List<String>? stickerFileUris,
  }) {
    return UserStickerPack(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      stickerFileUris: stickerFileUris ?? this.stickerFileUris,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAtMs': createdAtMs,
      'stickerFileUris': stickerFileUris,
    };
  }

  factory UserStickerPack.fromJson(Map<String, dynamic> json) {
    final rawUris = json['stickerFileUris'];
    return UserStickerPack(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
      stickerFileUris:
          rawUris is List ? rawUris.map((e) => e.toString()).toList() : const [],
    );
  }
}
