import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserPackExportButton extends StatelessWidget {
  const UserPackExportButton({
    super.key,
    required this.isSending,
    required this.onPressed,
  });

  final bool isSending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isSending ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSending)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  SvgPicture.asset(
                    'assets/icons/phone_icons2.svg',
                    width: 24,
                    height: 24,
                  ),
                const SizedBox(width: 10),
                const Text(
                  'Export Package Sticker',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
