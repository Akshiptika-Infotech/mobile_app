import 'dart:convert';
import 'dart:typed_data';

/// ZPL (Zebra Printer Language) command builder for 4×6 label printers.
///
/// Helett H30C Lite: 203 DPI, 4×6 inch (812×1218 dots).
///
/// Usage:
/// ```dart
/// final bytes = ZplBuilder(width: 812, height: 1218)
///   .header()
///   .boldText(100, 60, 'VISITOR PASS', fontSize: 45)
///   .text(100, 130, 'Name: Munish', fontSize: 30)
///   .box(20, 20, 792, 1198) // border
///   .footer()
///   .build();
/// ```
class ZplBuilder {
  ZplBuilder({this.width = 812, this.height = 1218, this.dpi = 203});

  /// Label width in dots (4 inch × 203 DPI = 812).
  final int width;

  /// Label height in dots (6 inch × 203 DPI = 1218).
  final int height;

  final int dpi;

  final _buf = StringBuffer();

  // ── Label structure ───────────────────────────────────────────────────────

  ZplBuilder header() {
    _buf.writeln('^XA'); // Start label
    _buf.writeln('^CI28'); // UTF-8 encoding
    _buf.writeln('^LH0,0'); // Label home (origin)
    _buf.writeln('^PW$width'); // Print width
    _buf.writeln('^LL$height'); // Label length
    _buf.writeln('^MNN'); // No media sensor (continuous)
    return this;
  }

  ZplBuilder footer({int copies = 1}) {
    _buf.writeln('^PQ$copies'); // Print quantity
    _buf.writeln('^XZ'); // End label
    return this;
  }

  // ── Text ──────────────────────────────────────────────────────────────────

  /// Print text at position (x, y).
  /// [fontSize] maps to ZPL scalable font size in dots.
  ZplBuilder text(int x, int y, String value, {int fontSize = 25, bool bold = false}) {
    if (value.isEmpty) return this;
    final font = bold ? 'B' : '0';
    _buf.writeln('^FO$x,$y^A${font}N,$fontSize,$fontSize^FD${_esc(value)}^FS');
    return this;
  }

  /// Print centered text within the label width.
  ZplBuilder centerText(int y, String value, {int fontSize = 25, bool bold = false}) {
    final font = bold ? 'B' : '0';
    // Use ^FB (Field Block) to center
    final blockWidth = width - 40;
    _buf.writeln('^FO20,$y^A${font}N,$fontSize,$fontSize^FB$blockWidth,1,0,C^FD${_esc(value)}^FS');
    return this;
  }

  // ── Shapes ────────────────────────────────────────────────────────────────

  /// Draw a rectangle outline.
  ZplBuilder box(int x, int y, int w, int h, {int thickness = 2}) {
    _buf.writeln('^FO$x,$y^GB$w,$h,$thickness^FS');
    return this;
  }

  /// Draw a filled rectangle.
  ZplBuilder filledBox(int x, int y, int w, int h) {
    _buf.writeln('^FO$x,$y^GB$w,$h,$h^FS');
    return this;
  }

  /// Draw a horizontal line.
  ZplBuilder hLine(int x, int y, int length, {int thickness = 2}) {
    _buf.writeln('^FO$x,$y^GB$length,$thickness,$thickness^FS');
    return this;
  }

  // ── Barcode / QR ─────────────────────────────────────────────────────────

  /// Print a QR code.
  ZplBuilder qrCode(int x, int y, String data, {int magnification = 4}) {
    _buf.writeln('^FO$x,$y^BQN,2,$magnification^FD QA,${_esc(data)}^FS');
    return this;
  }

  /// Print a Code128 barcode.
  ZplBuilder barcode128(int x, int y, String data, {int height = 80}) {
    _buf.writeln('^FO$x,$y^BCN,$height,Y,N^FD${_esc(data)}^FS');
    return this;
  }

  // ── Raster image (GFA) ────────────────────────────────────────────────────

  /// Embed a 1-bit raster image (monochrome bitmap rows).
  /// [pixelRows] is a list of byte arrays, one per row (width/8 bytes per row).
  ZplBuilder rasterImage(int x, int y, int imgWidth, int imgHeight,
      List<Uint8List> pixelRows) {
    final bytesPerRow = (imgWidth / 8).ceil();
    final totalBytes = bytesPerRow * imgHeight;
    final sb = StringBuffer();
    for (final row in pixelRows) {
      for (final b in row) {
        sb.write(b.toRadixString(16).padLeft(2, '0').toUpperCase());
      }
    }
    final hexData = sb.toString();
    _buf.writeln('^FO$x,$y^GFA,$totalBytes,$totalBytes,$bytesPerRow,$hexData^FS');
    return this;
  }

  // ── Reverse (white-on-black) text ────────────────────────────────────────

  /// Print white text on a pre-drawn filledBox background (uses ^FR reverse).
  ZplBuilder reverseText(int x, int y, String value,
      {int fontSize = 25, bool bold = false}) {
    if (value.isEmpty) return this;
    final font = bold ? 'B' : '0';
    _buf.writeln('^FO$x,$y^FR^A${font}N,$fontSize,$fontSize^FD${_esc(value)}^FS');
    return this;
  }

  /// Print centered white-on-black text using ^FB field block.
  ZplBuilder reverseCenterText(int y, String value,
      {int fontSize = 25, bool bold = false, int? blockWidth}) {
    if (value.isEmpty) return this;
    final font = bold ? 'B' : '0';
    final bw = blockWidth ?? (width - 40);
    _buf.writeln(
        '^FO20,$y^FR^A${font}N,$fontSize,$fontSize^FB$bw,1,0,C^FD${_esc(value)}^FS');
    return this;
  }

  // ── Raw ZPL escape hatch ──────────────────────────────────────────────────

  /// Append arbitrary ZPL. Use only for commands not covered by the builder.
  ZplBuilder raw(String zpl) {
    _buf.writeln(zpl);
    return this;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  Uint8List build() => Uint8List.fromList(utf8.encode(_buf.toString()));

  String buildString() => _buf.toString();

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Escape ZPL special characters.
  static String _esc(String s) =>
      s.replaceAll('^', '').replaceAll('~', '').replaceAll('\\', '');
}
