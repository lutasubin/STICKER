import 'dart:io';
import 'dart:typed_data';
import 'package:flutterbackgroundremover/backgroundremover.dart';
import 'package:sticker_app/service/u2net_background_remover.dart';

class RemoveBgService {
  static Future<Uint8List> removeBackground(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return await U2NetBackgroundRemover.removeBackgroundFromBytes(bytes);
    } catch (e) {
      print('DEBUG: U2Net lỗi, thử flutterbackgroundremover: $e');
      try {
        return await FlutterBackgroundRemover.removeBackground(imageFile);
      } catch (fallbackError) {
        throw Exception('Cả U2Net và fallback đều lỗi: U2Net: $e, Fallback: $fallbackError');
      }
    }
  }

  static Future<Uint8List> removeBackgroundFromBytes(Uint8List imageBytes, String fileName) async {
    try {
      return await U2NetBackgroundRemover.removeBackgroundFromBytes(imageBytes);
    } catch (e) {
      throw Exception('Failed to remove background: $e');
    }
  }
}
