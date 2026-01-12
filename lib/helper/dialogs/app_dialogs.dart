import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sticker_app/view/my_sticker/widgets/sticker_viewer_dialog.dart';

/// Tập trung các dialog/snackbar dùng chung trong app.
class AppDialogs {
  AppDialogs._();

  // ================= SNACKBAR =================

  /// Hiển thị snackbar thành công (màu xanh).
  static void showSuccess(String message) {
    Get.snackbar(
      'snackbar_success_title'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF25D366),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  /// Hiển thị snackbar lỗi (màu đỏ).
  static void showError(String message) {
    Get.snackbar(
      'snackbar_error_title'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  /// Hiển thị snackbar cảnh báo (màu cam).
  static void showWarning(String message) {
    Get.snackbar(
      'snackbar_warning_title'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
    );
  }

  /// Hiển thị snackbar thông tin (màu xanh dương).
  static void showInfo(String message) {
    Get.snackbar(
      'snackbar_info_title'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blueAccent,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.info_outline, color: Colors.white),
    );
  }

  // ================= LOADING DIALOG =================

  /// Hiển thị loading dialog.
  static void showLoading({String? message}) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF25D366)),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Ẩn loading dialog.
  static void hideLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  // ================= CONFIRM DIALOG =================

  /// Hiển thị dialog xác nhận với 2 nút.
  static Future<bool> showConfirm({
    required String title,
    required String message,
    String confirmText = '',
    String cancelText = '',
  }) async {
    final resolvedConfirmText =
        confirmText.isEmpty ? 'confirm_ok'.tr : confirmText;
    final resolvedCancelText =
        cancelText.isEmpty ? 'confirm_cancel'.tr : cancelText;
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              resolvedCancelText,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              resolvedConfirmText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<bool> showDeletePackageConfirm() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'delete_package_title'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text('delete_package_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'cancel_button'.tr,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'ok_button'.tr,
              style: const TextStyle(
                color: Color(0xFF00C979),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<String?> showPackNameInputDialog({
    required String title,
    required String initialText,
    required String hintText,
  }) async {
    final controller = TextEditingController(text: initialText);

    final result = await Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: const Color(0xFFF3F3F3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF00C979), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<String>(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: Text('cancel_button'.tr),
          ),
          TextButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isEmpty) return;
              Get.back(result: trimmed);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00C979),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: Text(
              'ok_button'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    // FIX: Đợi một chút để dialog hoàn tất animation đóng
    // trước khi dispose controller
    await Future.delayed(const Duration(milliseconds: 100));
    controller.dispose();

    return result;
  }

  static void showComingSoon(String message) {
    showInfo(message);
  }

  static void showStickerViewer({
    required String stickerUri,
    required VoidCallback onEdit,
    required VoidCallback onShare,
    required VoidCallback onDelete,
  }) {
    Get.dialog(
      StickerViewerDialog(
        stickerUri: stickerUri,
        onEdit: onEdit,
        onShare: onShare,
        onDelete: onDelete,
      ),
      barrierColor: Colors.black54,
    );
  }

  // ================= STICKER SPECIFIC =================

  /// Thông báo WhatsApp chưa cài đặt.
  static void showWhatsAppNotInstalled() {
    showError('error_whatsapp_not_installed'.tr);
  }

  /// Thông báo thêm sticker thành công.
  static void showStickerAddedSuccess() {
    showSuccess('success_sent_to_whatsapp'.tr);
  }

  /// Thông báo sticker đã tồn tại.
  static void showStickerAlreadyAdded() {
    showWarning('warning_pack_already_in_whatsapp'.tr);
  }

  /// Thông báo sticker pack đã được update thành công.
  static void showStickerUpdatedSuccess() {
    showSuccess('success_sticker_updated'.tr);
  }
}
