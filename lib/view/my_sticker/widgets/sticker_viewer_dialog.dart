import 'dart:io';

import 'package:flutter/material.dart';

class StickerViewerDialog extends StatelessWidget {
  const StickerViewerDialog({
    super.key,
    required this.stickerUri,
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
  });

  final String stickerUri;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final file = File.fromUri(Uri.parse(stickerUri));

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: file.existsSync()
                          ? Image.file(file, fit: BoxFit.cover)
                          : const ColoredBox(color: Color(0xFFF3F3F3)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActionItem(
                        icon: Icons.edit_outlined,
                        label: 'Chỉnh sửa',
                        onTap: onEdit,
                      ),
                      _ActionItem(
                        icon: Icons.share_outlined,
                        label: 'Chia sẻ',
                        onTap: onShare,
                      ),
                      _ActionItem(
                        icon: Icons.delete_outline,
                        label: 'Xóa',
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                right: 0,
                top: 0,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFFEDEDED),
                    child: Icon(Icons.close, size: 16, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
