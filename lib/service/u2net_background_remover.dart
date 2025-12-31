import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class U2NetBackgroundRemover {
  static const int _inputSize = 320;
  static const List<double> _mean = <double>[0.485, 0.456, 0.406];
  static const List<double> _std = <double>[0.229, 0.224, 0.225];

  static const String _defaultModelAssetPath = 'assets/models/u2netp_320.tflite';

  static Interpreter? _interpreter;
  static String? _loadedModel;

  static Future<Interpreter> _getInterpreter({String modelAssetPath = _defaultModelAssetPath}) async {
    if (_interpreter != null && _loadedModel == modelAssetPath) {
      return _interpreter!;
    }

    _interpreter?.close();

    final options = InterpreterOptions()..threads = 4;
    final interpreter = await Interpreter.fromAsset(modelAssetPath, options: options);

    _interpreter = interpreter;
    _loadedModel = modelAssetPath;
    return interpreter;
  }

  static Future<Uint8List> removeBackgroundFromBytes(
    Uint8List imageBytes, {
    String modelAssetPath = _defaultModelAssetPath,
    int? alphaThreshold,
    double maskLevelLow = 0.10,
    double maskLevelHigh = 0.90,
    double maskGamma = 0.70,
  }) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw Exception('Cannot decode image');
    }

    final interpreter = await _getInterpreter(modelAssetPath: modelAssetPath);

    final resizedForModel = img.copyResize(
      decoded,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    final inputShape = interpreter.getInputTensor(0).shape;
    final outputShape = interpreter.getOutputTensor(0).shape;
    print('U2Net inputShape=$inputShape outputShape=$outputShape');

    // Use nested Lists for I/O to avoid reshape/view issues where output buffer
    // is not populated.
    final inputTensor = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (_) => List.generate(
          _inputSize,
          (_) => List<double>.filled(3, 0.0),
        ),
      ),
    );

    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final p = resizedForModel.getPixel(x, y);
        final r = p.r.toDouble() / 255.0;
        final g = p.g.toDouble() / 255.0;
        final b = p.b.toDouble() / 255.0;

        inputTensor[0][y][x][0] = (r - _mean[0]) / _std[0];
        inputTensor[0][y][x][1] = (g - _mean[1]) / _std[1];
        inputTensor[0][y][x][2] = (b - _mean[2]) / _std[2];
      }
    }

    final outH = outputShape.length == 4 ? outputShape[1] : _inputSize;
    final outW = outputShape.length == 4 ? outputShape[2] : _inputSize;

    final outputTensor = List.generate(
      1,
      (_) => List.generate(
        outH,
        (_) => List.generate(
          outW,
          (_) => List<double>.filled(1, 0.0),
        ),
      ),
    );

    interpreter.run(inputTensor, outputTensor);

    final out0 = Float32List(outH * outW);
    var o = 0;
    for (var y = 0; y < outH; y++) {
      for (var x = 0; x < outW; x++) {
        out0[o++] = outputTensor[0][y][x][0].toDouble();
      }
    }

    var minV = double.infinity;
    var maxV = -double.infinity;
    for (final v in out0) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }

    // If output looks like logits, apply sigmoid before scaling.
    final looksLikeLogits = minV < 0.0 || maxV > 1.0;
    if (looksLikeLogits) {
      for (var j = 0; j < out0.length; j++) {
        final v = out0[j];
        out0[j] = 1.0 / (1.0 + math.exp(-v));
      }
      minV = double.infinity;
      maxV = -double.infinity;
      for (final v in out0) {
        if (v < minV) minV = v;
        if (v > maxV) maxV = v;
      }
    }

    print('U2Net mask min=$minV max=$maxV logits=$looksLikeLogits');

    final denom = (maxV - minV).abs() < 1e-12 ? 1.0 : (maxV - minV);

    double centerSum = 0.0;
    var centerCount = 0;
    double borderSum = 0.0;
    var borderCount = 0;
    const centerRadius = 32;
    const borderWidth = 24;

    final maskSmall = img.Image(width: outW, height: outH);
    var idx = 0;
    for (var y = 0; y < outH; y++) {
      for (var x = 0; x < outW; x++) {
        final n = ((out0[idx++] - minV) / denom);
        final leveled = ((n - maskLevelLow) / (maskLevelHigh - maskLevelLow)).clamp(0.0, 1.0);
        final refined = maskGamma == 1.0 ? leveled : math.pow(leveled, maskGamma).toDouble();
        final dx = (x - (outW ~/ 2)).abs();
        final dy = (y - (outH ~/ 2)).abs();
        if (dx <= centerRadius && dy <= centerRadius) {
          centerSum += refined;
          centerCount++;
        }
        if (x < borderWidth || y < borderWidth || x >= outW - borderWidth || y >= outH - borderWidth) {
          borderSum += refined;
          borderCount++;
        }

        final a = (refined * 255.0).clamp(0.0, 255.0).round();
        maskSmall.setPixelRgba(x, y, a, a, a, 255);
      }
    }

    final centerMean = centerCount == 0 ? 0.0 : (centerSum / centerCount);
    final borderMean = borderCount == 0 ? 0.0 : (borderSum / borderCount);
    final shouldInvert = centerMean < borderMean;

    print('U2Net centerMean=$centerMean borderMean=$borderMean invert=$shouldInvert');

    if (shouldInvert) {
      for (var y = 0; y < outH; y++) {
        for (var x = 0; x < outW; x++) {
          final p = maskSmall.getPixel(x, y);
          final v = 255 - p.r;
          maskSmall.setPixelRgba(x, y, v, v, v, 255);
        }
      }
    }

    final mask = img.copyResize(
      maskSmall,
      width: decoded.width,
      height: decoded.height,
      interpolation: img.Interpolation.linear,
    );

    final out = img.Image(width: decoded.width, height: decoded.height, numChannels: 4);
    for (var y = 0; y < decoded.height; y++) {
      for (var x = 0; x < decoded.width; x++) {
        final src = decoded.getPixel(x, y);
        final m = mask.getPixel(x, y).r;
        var a = m;
        if (alphaThreshold != null) {
          a = a < alphaThreshold ? 0 : a;
        }
        out.setPixelRgba(x, y, src.r, src.g, src.b, a);
      }
    }

    return Uint8List.fromList(img.encodePng(out));
  }

  static Future<Uint8List> removeBackground(img.Image image, {String modelAssetPath = _defaultModelAssetPath}) {
    return removeBackgroundFromBytes(Uint8List.fromList(img.encodePng(image)), modelAssetPath: modelAssetPath);
  }

  static Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _loadedModel = null;
  }
}
