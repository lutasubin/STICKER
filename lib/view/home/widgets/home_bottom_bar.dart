import 'package:flutter/material.dart';

class HomeBottomBar extends StatelessWidget {
  const HomeBottomBar({super.key, this.currentIndex = 0, this.onTap});

  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomBarItem(
              icon: Icons.home_outlined,
              iconFilled: Icons.home,
              label: 'Home',
              isActive: currentIndex == 0,
              onTap: () => onTap?.call(0),
            ),
            const SizedBox(width: 56), // space for FAB
            _BottomBarItem(
              icon: Icons.emoji_emotions_outlined,
              iconFilled: Icons.emoji_emotions,
              label: 'My Sticker',
              isActive: currentIndex == 1,
              onTap: () => onTap?.call(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.icon,
    required this.iconFilled,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  final IconData icon;
  final IconData iconFilled;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.black : Colors.grey.shade400;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? iconFilled : icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
