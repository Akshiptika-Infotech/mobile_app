import 'dart:typed_data';

/// TSPL (TSC Printer Language) command builder for thermal label printers.
///
/// Compatible with Helett H30C Lite and most Chinese-branded thermal
/// label printers (4×6 inch, 203 DPI, 812×1218 dots).
///
/// Usage:
/// ```dart
/// final bytes = TsplBuilder()
///   .box(15, 15, 797, 1203)
///   .centerText(20, 'VISITOR PASS', font: 5)
///   .text(30, 100, 'Name: John Doe', font: 3)
///   .qrCode(30, 900, 'VIS-1234')
///   .print()
///   .build();
/// ```
class TsplBuilder {
  TsplBuilder({
    this.width = 812,
    this.height = 1218,
    double widthMm = 101.6,
    double heightMm = 152.4,
    double gapMm = 2.0,
  }) {
    _buf.writeln('SIZE $widthMm mm,$heightMm mm');
    _buf.writeln('GAP $gapMm mm,0 mm');
    _buf.writeln('DIRECTION 1');
    _buf.writeln('CLS');
  }

  final int width;
  final int height;
  final StringBuffer _buf = StringBuffer();

  // Built-in font character widths in dots (at xMult=1)
  static const Map<int, int> _fontWidths = {
    1: 8,
    2: 12,
    3: 16,
    4: 24,
    5: 32,
  };

  // Built-in font character heights in dots (at yMult=1)
  static const Map<int, int> _fontHeights = {
    1: 12,
    2: 20,
    3: 24,
    4: 32,
    5: 48,
  };

  static int fontHeight(int font, {int yMult = 1}) =>
      (_fontHeights[font] ?? 24) * yMult;

  // ── Text ──────────────────────────────────────────────────────────────────

  /// Print text at (x, y).
  /// font: 1=tiny 2=small 3=medium 4=large 5=xlarge
  /// xMult/yMult: character scale 1–10
  TsplBuilder text(int x, int y, String data,
      {int font = 3, int rotation = 0, int xMult = 1, int yMult = 1}) {
    if (data.isEmpty) return this;
    final safe = data.replaceAll('"', "'");
    _buf.writeln('TEXT $x,$y,"$font",$rotation,$xMult,$yMult,"$safe"');
    return this;
  }

  /// Print horizontally centered text within the label width.
  TsplBuilder centerText(int y, String data,
      {int font = 3, int xMult = 1, int yMult = 1}) {
    if (data.isEmpty) return this;
    final charW = (_fontWidths[font] ?? 16) * xMult;
    final textW = data.length * charW;
    final x = ((width - textW) / 2).round().clamp(0, width);
    return text(x, y, data, font: font, xMult: xMult, yMult: yMult);
  }

  // ── Shapes ────────────────────────────────────────────────────────────────

  /// Draw a rectangle outline from (x1,y1) to (x2,y2).
  TsplBuilder box(int x1, int y1, int x2, int y2, {int thickness = 3}) {
    _buf.writeln('BOX $x1,$y1,$x2,$y2,$thickness');
    return this;
  }

  /// Draw a filled rectangle. Width and height are in dots.
  TsplBuilder bar(int x, int y, int w, int h) {
    if (w <= 0 || h <= 0) return this;
    _buf.writeln('BAR $x,$y,$w,$h');
    return this;
  }

  // ── Barcode / QR ─────────────────────────────────────────────────────────

  /// Print a QR code.
  /// ecc: L=7%, M=15%, Q=25%, H=30% error correction
  /// cellWidth: dot size of each QR module (larger = bigger QR)
  TsplBuilder qrCode(int x, int y, String data,
      {int cellWidth = 5, String ecc = 'M'}) {
    final safe = data.replaceAll('"', '');
    _buf.writeln('QRCODE $x,$y,$ecc,$cellWidth,A,0,"$safe"');
    return this;
  }

  /// Print a Code128 barcode.
  TsplBuilder barcode128(int x, int y, String data, {int height = 80}) {
    final safe = data.replaceAll('"', '');
    _buf.writeln('BARCODE $x,$y,"128",$height,1,0,2,2,"$safe"');
    return this;
  }

  // ── Print ─────────────────────────────────────────────────────────────────

  TsplBuilder print({int copies = 1}) {
    _buf.writeln('PRINT $copies,1');
    return this;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  /// Returns the TSPL command string as raw bytes (ASCII).
  Uint8List build() => Uint8List.fromList(_buf.toString().codeUnits);

  String buildString() => _buf.toString();
}
