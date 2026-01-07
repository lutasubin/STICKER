import 'package:flutter/material.dart';

class CropAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CropAppBar({
    super.key,
    required this.onBack,
    required this.onNext,
    required this.saving,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool saving;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back, color: Colors.black),
      ),
      title: const Text(
        'Crop',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
      ),
      actions: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: saving
              ? Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C979)),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: onNext,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF00C979),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Next'),
                ),
        ),
      ],
    );
  }
}
