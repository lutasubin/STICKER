import 'package:flutter/material.dart';

class SettingMenuItem extends StatelessWidget {
  const SettingMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.trailingText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
