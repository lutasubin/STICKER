import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class UserPackExportButton extends StatelessWidget {
  const UserPackExportButton({
    super.key,
    required this.isSending,
    required this.onPressed,
    this.isInstalled = false,
    this.isChecking = false,
    this.needsUpdate = false,
  });

  final bool isSending;
  final VoidCallback? onPressed;
  final bool isInstalled;
  final bool isChecking;
  final bool needsUpdate; // Pack đã được chỉnh sửa sau khi install

  @override
  Widget build(BuildContext context) {
    // Nếu đang kiểm tra trạng thái, hiển thị loading
    if (isChecking) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Đang kiểm tra...',
                    style: TextStyle(
                      color: Colors.grey,
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

    // Nếu đã được thêm vào nhưng chưa chỉnh sửa, hiển thị nút xám với text "Đã được thêm vào"
    // Nếu đã được thêm vào VÀ đã chỉnh sửa, hiển thị nút xanh với text "Update to WhatsApp"
    if (isInstalled && !needsUpdate) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.grey.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Đã được thêm vào',
                    style: TextStyle(
                      color: Colors.grey.shade700,
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

    // Nếu đã được thêm vào NHƯNG đã chỉnh sửa, hiển thị nút xanh "Update to WhatsApp"
    if (isInstalled && needsUpdate) {
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
                  Text(
                    isSending
                        ? 'updating_button'.tr
                        : 'update_to_whatsapp_button'.tr,
                    style: const TextStyle(
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

    // Nếu chưa được thêm, hiển thị nút xanh bình thường
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
                Text(
                  'export_package_button'.tr,
                  style: const TextStyle(
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
