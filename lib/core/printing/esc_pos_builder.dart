import 'dart:typed_data';
import 'dart:convert';

/// ESC/POS command builder for 58mm / 80mm thermal printers.
///
/// Usage:
/// ```dart
/// final bytes = EscPosBuilder()
///   .initialize()
///   .boldOn().centerAlign().textLn('MY SHOP').boldOff()
///   .leftAlign()
///   .item('Tea', '₹10', width: 32)
///   .divider(width: 32)
///   .boldOn().totalLine('TOTAL', '₹10', width: 32).boldOff()
///   .feed(3).cut()
///   .build();
/// ```
class EscPosBuilder {
  final List<int> _bytes = [];

  // ── ESC/POS control bytes ──────────────────────────────────────────────────
  // ignore: constant_identifier_names
  static const int ESC = 0x1B;
  // ignore: constant_identifier_names
  static const int GS  = 0x1D;
  // ignore: constant_identifier_names
  static const int LF  = 0x0A;
  // ignore: constant_identifier_names
  static const int HT  = 0x09;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Initialize printer (ESC @).
  EscPosBuilder initialize() {
    _bytes.addAll([ESC, 0x40]);
    return this;
  }

  Uint8List build() => Uint8List.fromList(_bytes);

  // ── Alignment ─────────────────────────────────────────────────────────────

  /// ESC a 0 — left align.
  EscPosBuilder leftAlign() {
    _bytes.addAll([ESC, 0x61, 0x00]);
    return this;
  }

  /// ESC a 1 — center align.
  EscPosBuilder centerAlign() {
    _bytes.addAll([ESC, 0x61, 0x01]);
    return this;
  }

  /// ESC a 2 — right align.
  EscPosBuilder rightAlign() {
    _bytes.addAll([ESC, 0x61, 0x02]);
    return this;
  }

  // ── Font style ────────────────────────────────────────────────────────────

  /// ESC E 1 — bold on.
  EscPosBuilder boldOn() {
    _bytes.addAll([ESC, 0x45, 0x01]);
    return this;
  }

  /// ESC E 0 — bold off.
  EscPosBuilder boldOff() {
    _bytes.addAll([ESC, 0x45, 0x00]);
    return this;
  }

  /// ESC ! — double-height + double-width on.
  EscPosBuilder doubleSize() {
    _bytes.addAll([ESC, 0x21, 0x38]);
    return this;
  }

  /// ESC ! 0 — normal size.
  EscPosBuilder normalSize() {
    _bytes.addAll([ESC, 0x21, 0x00]);
    return this;
  }

  // ── Text ──────────────────────────────────────────────────────────────────

  /// Print raw text (Latin-1).
  EscPosBuilder text(String s) {
    _bytes.addAll(latin1.encode(s));
    return this;
  }

  /// Print text + newline.
  EscPosBuilder textLn(String s) => text(s).lf();

  /// Print newline.
  EscPosBuilder lf() {
    _bytes.add(LF);
    return this;
  }

  // ── Divider ───────────────────────────────────────────────────────────────

  /// Print a horizontal divider of dashes.
  EscPosBuilder divider({int width = 32}) {
    _bytes.addAll(latin1.encode('-' * width));
    _bytes.add(LF);
    return this;
  }

  // ── Receipt helpers ───────────────────────────────────────────────────────

  /// Print an item line: "Label          price"
  EscPosBuilder item(String label, String price, {int width = 32}) {
    final spaces = width - label.length - price.length;
    final line = label + (' ' * spaces.clamp(1, width)) + price;
    _bytes.addAll(latin1.encode(line));
    _bytes.add(LF);
    return this;
  }

  /// Print a bold total line.
  EscPosBuilder totalLine(String label, String amount, {int width = 32}) {
    return item(label, amount, width: width);
  }

  // ── Paper feed & cut ──────────────────────────────────────────────────────

  /// Feed n lines.
  EscPosBuilder feed(int lines) {
    _bytes.addAll([ESC, 0x64, lines]);
    return this;
  }

  /// Full paper cut (GS V 0).
  EscPosBuilder cut() {
    _bytes.addAll([GS, 0x56, 0x00]);
    return this;
  }

  /// Partial cut (GS V 1).
  EscPosBuilder partialCut() {
    _bytes.addAll([GS, 0x56, 0x01]);
    return this;
  }

  // ── QR Code (ESC/POS GS ( k) ──────────────────────────────────────────────

  /// Print a QR code containing [data].
  /// [size] 1–16 (module size, default 4).
  EscPosBuilder qrCode(String data, {int size = 4}) {
    final dataBytes = utf8.encode(data);
    final dataLen = dataBytes.length + 3;
    final pL = dataLen & 0xFF;
    final pH = (dataLen >> 8) & 0xFF;

    // Model: GS ( k 4 0 49 65 50 0  → model 2
    _bytes.addAll([GS, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]);
    // Size: GS ( k 3 0 49 67 n
    _bytes.addAll([GS, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, size]);
    // Error correction: GS ( k 3 0 49 69 48 (level L)
    _bytes.addAll([GS, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x30]);
    // Store data: GS ( k pL pH 49 80 48 <data>
    _bytes.addAll([GS, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30]);
    _bytes.addAll(dataBytes);
    // Print: GS ( k 3 0 49 81 48
    _bytes.addAll([GS, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);
    return this;
  }

  // ── Barcode (Code128) ─────────────────────────────────────────────────────

  /// Print a Code128 barcode.
  EscPosBuilder barcode128(String data, {int height = 80}) {
    final dataBytes = latin1.encode(data);
    // GS h n — barcode height
    _bytes.addAll([GS, 0x68, height]);
    // GS H 2 — print HRI below barcode
    _bytes.addAll([GS, 0x48, 0x02]);
    // GS k 73 n <data> — Code128
    _bytes.addAll([GS, 0x6B, 0x49, dataBytes.length]);
    _bytes.addAll(dataBytes);
    _bytes.add(LF);
    return this;
  }
}
