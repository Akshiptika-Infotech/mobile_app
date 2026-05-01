import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Result of converting a photo into a printable pencil-sketch.
class Sketch {
  const Sketch({
    required this.png,
    required this.tsplBitmap,
    required this.tsplWidthBytes,
    required this.tsplHeight,
  });

  /// Re-encoded PNG (1-bit black on white) suitable for embedding in PDF.
  final Uint8List png;

  /// Packed monochrome bitmap for TSPL `BITMAP` (MSB-first, 0 = black).
  final Uint8List tsplBitmap;

  /// Width of [tsplBitmap] in bytes (= ceil(widthPx / 8)). The TSPL `BITMAP`
  /// command takes byte width, not pixel width.
  final int tsplWidthBytes;

  /// Height of [tsplBitmap] in dots/pixels.
  final int tsplHeight;

  int get tsplWidthPx => tsplWidthBytes * 8;
}

/// Builds a Sobel-edge pencil-sketch from a photograph.
///
/// Algorithm:
/// 1. Decode → resize to a working square ([targetSize]).
/// 2. Convert to grayscale and lightly blur to suppress sensor noise.
/// 3. Sobel X + Sobel Y edges → magnitude map.
/// 4. Tone map: invert and threshold so edges become black ink on white.
/// 5. Output two artefacts:
///    - PNG (for PDF) — anti-aliased grayscale converted to 1-bit.
///    - Packed bit array for TSPL `BITMAP` (MSB-first, 0 = black ink).
///
/// Runs purely on-device. Typical 800×800 photo → ~80–150 ms on a mid-range
/// phone. Returns `null` if the bytes can't be decoded.
Sketch? sketchify(
  Uint8List sourceBytes, {
  int targetSize = 256,
  int edgeThreshold = 28,
}) {
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) return null;

  // Crop to a centred square so the sketch sits nicely on the pass badge.
  final side = decoded.width < decoded.height ? decoded.width : decoded.height;
  final cropX = ((decoded.width - side) / 2).round();
  final cropY = ((decoded.height - side) / 2).round();
  final square = img.copyCrop(decoded,
      x: cropX, y: cropY, width: side, height: side);

  final resized =
      img.copyResize(square, width: targetSize, height: targetSize);
  final gray = img.grayscale(resized);
  final blurred = img.gaussianBlur(gray, radius: 1);

  final w = blurred.width;
  final h = blurred.height;

  // Sobel edge magnitude.
  final mag = Uint8List(w * h);
  int maxMag = 1;
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final tl = blurred.getPixel(x - 1, y - 1).r.toInt();
      final tc = blurred.getPixel(x, y - 1).r.toInt();
      final tr = blurred.getPixel(x + 1, y - 1).r.toInt();
      final ml = blurred.getPixel(x - 1, y).r.toInt();
      final mr = blurred.getPixel(x + 1, y).r.toInt();
      final bl = blurred.getPixel(x - 1, y + 1).r.toInt();
      final bc = blurred.getPixel(x, y + 1).r.toInt();
      final br = blurred.getPixel(x + 1, y + 1).r.toInt();

      final gx = (tr + 2 * mr + br) - (tl + 2 * ml + bl);
      final gy = (bl + 2 * bc + br) - (tl + 2 * tc + tr);
      var m = (gx.abs() + gy.abs());
      if (m > 255) m = 255;
      mag[y * w + x] = m;
      if (m > maxMag) maxMag = m;
    }
  }

  // Build the rendered sketch image (PNG output).
  final outImg = img.Image(width: w, height: h);
  // Pack TSPL bits — width must be a multiple of 8.
  final widthBytes = (w + 7) ~/ 8;
  final packed = Uint8List(widthBytes * h); // initialised to 0x00 = all black
  // Start fully white (TSPL: bit 1 = white, bit 0 = black).
  packed.fillRange(0, packed.length, 0xFF);

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final m = mag[y * w + x];
      // Edge → black ink. Invert + threshold for a clean line drawing.
      final isEdge = m >= edgeThreshold;
      final pixel = isEdge ? 0 : 255;
      outImg.setPixelRgba(x, y, pixel, pixel, pixel, 255);
      if (isEdge) {
        // Clear the bit (= black) for this pixel in the packed buffer.
        final byteIdx = y * widthBytes + (x >> 3);
        final bit = 7 - (x & 7);
        packed[byteIdx] &= ~(1 << bit);
      }
    }
  }

  return Sketch(
    png: Uint8List.fromList(img.encodePng(outImg)),
    tsplBitmap: packed,
    tsplWidthBytes: widthBytes,
    tsplHeight: h,
  );
}
