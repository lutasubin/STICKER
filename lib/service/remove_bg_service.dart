import 'dart:io';
import 'dart:typed_data';
import 'package:sticker_app/service/u2net_background_remover.dart';

class RemoveBgService {
  static Future<Uint8List> removeBackground(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return await U2NetBackgroundRemover.removeBackgroundFromBytes(bytes);
  }

  static Future<Uint8List> removeBackgroundFromBytes(Uint8List imageBytes) async {
    return await U2NetBackgroundRemover.removeBackgroundFromBytes(imageBytes);
  }
}
