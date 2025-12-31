import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CropModeItemData {
  const CropModeItemData({
    required this.iconAsset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final bool selected;
  final VoidCallback onTap;
}

class CropModeSelector extends StatelessWidget {
  const CropModeSelector({
    super.key,
    required this.items,
  });

  final List<CropModeItemData> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items
                .map(
                  (e) => _ModeItem(
                    iconAsset: e.iconAsset,
                    label: e.label,
                    selected: e.selected,
                    onTap: e.onTap,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  const _ModeItem({
    required this.iconAsset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF00C979) : Colors.black54;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
