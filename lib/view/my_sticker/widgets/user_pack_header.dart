import 'package:flutter/material.dart';

class UserPackHeader extends StatelessWidget {
  const UserPackHeader({
    super.key,
    required this.title,
    required this.stickerCount,
  });

  final String title;
  final int stickerCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF5F5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$stickerCount sticker',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
