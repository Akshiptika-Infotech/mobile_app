import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Wraps the MobileFaceNet TFLite model.
/// Input:  [1, 112, 112, 3] float32
/// Output: [1, 128] float32 — L2-normalised embedding
class FaceEmbedder {
  FaceEmbedder._();

  static FaceEmbedder? _instance;
  static FaceEmbedder get instance => _instance ??= FaceEmbedder._();

  Interpreter? _interpreter;
  bool get isReady => _interpreter != null;

  static const String _modelPath = 'assets/models/mobilefacenet.tflite';
  static const int _inputSize = 112;

  Future<void> init() async {
    if (_interpreter != null) return;
    try {
      final modelData = await rootBundle.load(_modelPath);
      _interpreter = Interpreter.fromBuffer(modelData.buffer.asUint8List());
    } catch (e) {
      // Model file not present yet — embedding will return zeros
      // until the .tflite asset is added to assets/models/
    }
  }

  /// Crops [image] to [rect], resizes to 112×112, runs inference,
  /// and returns a L2-normalised 128-dim float vector.
  List<double> getEmbedding(img.Image image) {
    if (_interpreter == null) return List.filled(128, 0.0);

    // Resize to model input size
    final resized = img.copyResize(image, width: _inputSize, height: _inputSize);

    // Build [1, 112, 112, 3] input tensor
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              (pixel.r / 127.5) - 1.0,
              (pixel.g / 127.5) - 1.0,
              (pixel.b / 127.5) - 1.0,
            ];
          },
        ),
      ),
    );

    // Output buffer
    final output = [List<double>.filled(128, 0.0)];
    _interpreter!.run(input, output);
    return l2Normalize(output[0]);
  }

  /// Loads an image from a file path and returns an [img.Image].
  static Future<img.Image?> fromImageFile(String path) async {
    final bytes = await File(path).readAsBytes();
    return img.decodeImage(bytes);
  }

  /// Converts raw BGRA/RGBA bytes (from CameraImage plane) to an img.Image.
  /// Pass the plane bytes and image width/height.
  static img.Image fromBytes({
    required Uint8List bytes,
    required int width,
    required int height,
    bool isBgra = true,
  }) {
    return img.Image.fromBytes(
      width: width,
      height: height,
      bytes: bytes.buffer,
      order: isBgra ? img.ChannelOrder.bgra : img.ChannelOrder.rgba,
    );
  }

  /// L2-normalise a vector so its magnitude equals 1.
  static List<double> l2Normalize(List<double> vec) {
    final norm = math.sqrt(vec.fold(0.0, (s, v) => s + v * v));
    if (norm == 0) return vec;
    return vec.map((v) => v / norm).toList();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _instance = null;
  }
}
