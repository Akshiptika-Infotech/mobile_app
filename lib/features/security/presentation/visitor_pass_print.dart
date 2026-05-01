import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/core/imaging/sketchify.dart';
import 'package:mobile_app/core/printing/tspl_builder.dart';
import 'package:mobile_app/core/printing/usb_printer_service.dart';
import 'package:mobile_app/features/security/domain/security_model.dart';

/// Prints a visitor gate pass.
///
/// Strategy (in order):
/// 1. Detect USB printer via OTG (checks all connected USB devices for printer
///    interface class 7).
/// 2. Request Android USB permission if not already granted.
/// 3. Send ZPL directly to the Helett H30C Lite bulk-OUT endpoint — no dialog.
/// 4. If no USB printer found, fall back to Android system print dialog (PDF).
///
/// Throws [UsbPrinterException] if a printer is found but permission is denied
/// or the send fails (so the caller can show a specific error).
Future<void> printVisitorPass(BuildContext context, Visitor visitor) async {
  final config = AppConfigScope.of(context);

  // Pre-fetch the visitor photo and convert it to a printable pencil-sketch.
  // Done once and reused for both the TSPL and PDF paths so the user only
  // pays the network/processing cost once.
  final sketch = await _fetchSketch(visitor.imagePath);

  // ── 1. Try direct USB ZPL print ──────────────────────────────────────────
  UsbPrinterDevice? device;
  try {
    device = await UsbPrinterService.instance.firstPrinter();
  } catch (_) {
    // USB enumeration failed → treat as no printer
    device = null;
  }

  if (device != null) {
    // Ensure we have permission (prompts user if needed)
    final permitted = await UsbPrinterService.instance.ensurePermission(device);

    if (permitted == null) {
      // Permission denied — surface a clear error instead of silently falling
      // back, because the user explicitly connected a printer.
      throw UsbPrinterException.noPermission();
    }

    final tsplBytes = _buildTsplPass(visitor, config.appName, sketch);
    await UsbPrinterService.instance.printBytes(permitted, tsplBytes);
    return; // ✅ Printed directly — no dialog shown
  }

  // ── 2. Fallback: system PDF print dialog ─────────────────────────────────
  // Only reached when no USB printer is detected at all.
  if (!context.mounted) return;

  final pdfBytes = await _buildPassDoc(visitor, config.appName, sketch);
  const format = PdfPageFormat(
    4 * PdfPageFormat.inch,
    6 * PdfPageFormat.inch,
  );

  final shortId = visitor.id.length > 6
      ? visitor.id.substring(visitor.id.length - 6).toUpperCase()
      : visitor.id.toUpperCase();

  await Printing.layoutPdf(
    onLayout: (_) async => pdfBytes,
    name: 'VisitorPass_$shortId',
    format: format,
  );
}

// ── Photo → sketch helper ─────────────────────────────────────────────────────

Future<Sketch?> _fetchSketch(String? imageUrl) async {
  if (imageUrl == null || imageUrl.isEmpty) return null;
  try {
    final uri = Uri.parse(imageUrl);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    final req = await client.getUrl(uri);
    final res = await req.close();
    if (res.statusCode != 200) {
      client.close(force: true);
      return null;
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in res) {
      builder.add(chunk);
    }
    client.close(force: true);
    return sketchify(builder.toBytes(), targetSize: 192);
  } catch (_) {
    return null;
  }
}

// ── TSPL label for Helett H30C Lite (203 DPI, 4×6 inch = 812×1218 dots) ─────
//
// Layout (fixed positions for consistent output):
//   [10–245]  header box: school name (font3×2) + "VISITOR PASS" (font4×2)
//   [245–250] thick divider
//   [258–330] visitor name  (font4 xMult=2 yMult=2 → 48w×64h per char)
//   [335]     thin divider
//   [345–...]  info rows: label font2, value font4 — row height 75
//   [...]     thin divider
//   [fixed 720] QR code (cellWidth=11, ~270 dots) + ID beside it
//   [1158]    footer divider + text

Uint8List _buildTsplPass(Visitor visitor, String schoolName, Sketch? sketch) {
  const W = 812;
  const H = 1218;
  const m = 10; // margin
  const innerW = W - m * 2; // 792

  final code = visitor.id.length >= 6
      ? visitor.id.substring(visitor.id.length - 6).toUpperCase()
      : visitor.id.toUpperCase();

  final b = TsplBuilder(width: W, height: H);

  // ── Outer border (4-dot thick) ────────────────────────────────────────────
  b.box(m, m, W - m, H - m, thickness: 4);

  // ── Header box ────────────────────────────────────────────────────────────
  b.box(m, m, W - m, 245, thickness: 4);

  // School name  — font 3 × xMult2 × yMult2 = 32w × 48h per char
  b.centerText(18, schoolName, font: 3, xMult: 2, yMult: 2);
  // → bottom edge at ≈ 66

  // Thin inner rule between name and title
  b.bar(m + 8, 78, innerW - 16, 2);

  // "VISITOR PASS" — font 4 × xMult2 × yMult2 = 48w × 64h per char
  // "VISITOR PASS" = 12 chars → 576 dots wide, centered at x=118
  b.centerText(88, 'VISITOR PASS', font: 4, xMult: 2, yMult: 2);
  // → bottom edge at ≈ 152

  // Date / subtitle row
  b.centerText(165, 'OFFICIAL GATE PASS', font: 2);

  // ── Thick divider ─────────────────────────────────────────────────────────
  b.bar(m, 245, innerW, 5);

  // ── Visitor name — font4 × xMult2 × yMult2 = 48w × 64h per char ──────────
  b.centerText(258, visitor.name, font: 4, xMult: 2, yMult: 2);
  // → bottom ≈ 322

  // ── Thin divider ─────────────────────────────────────────────────────────
  b.bar(m, 335, innerW, 2);

  // ── Info rows ─────────────────────────────────────────────────────────────
  // label: font 2 (12w×20h), value: font 4 (24w×32h), row height = 75
  const col2X = W ~/ 2 + 8;
  var y = 345;
  const rowH = 75; // 20(label) + 32(value) + 23(gap)

  void infoRow(String label, String value) {
    if (value.isEmpty) return;
    b.text(m + 15, y, label, font: 2);
    b.text(m + 15, y + 23, value, font: 4);
    y += rowH;
  }

  void infoRow2Col(String l1, String v1, String l2, String v2) {
    if (v1.isNotEmpty) {
      b.text(m + 15, y, l1, font: 2);
      b.text(m + 15, y + 23, v1, font: 4);
    }
    if (v2.isNotEmpty) {
      b.text(col2X, y, l2, font: 2);
      b.text(col2X, y + 23, v2, font: 4);
    }
    y += rowH;
  }

  if (visitor.phone.isNotEmpty) infoRow('PHONE', visitor.phone);
  infoRow2Col('TIME IN', visitor.inTime, 'VALID UNTIL', visitor.validUntil);
  if (visitor.personToMeet.isNotEmpty) infoRow('PERSON TO MEET', visitor.personToMeet);
  if (visitor.purpose.isNotEmpty) infoRow('PURPOSE', visitor.purpose);
  if (visitor.vehicleNumber.isNotEmpty) infoRow('VEHICLE NO', visitor.vehicleNumber);

  // ── Divider above QR section ──────────────────────────────────────────────
  b.bar(m, y + 5, innerW, 2);

  // ── QR code (fixed at y=730) + Visitor ID + face sketch ───────────────────
  // cellWidth=11 → ~25 modules × 11 = 275 dots square (good scan size)
  const qrY = 730;
  const qrX = m + 15;
  const qrSize = 275; // approximate
  b.qrCode(qrX, qrY, 'VIS-$code', cellWidth: 11);

  // ID block to the right of QR
  const idX = qrX + qrSize + 15;
  b.text(idX, qrY + 40, 'VISITOR', font: 3);
  b.text(idX, qrY + 70, 'ID', font: 3);
  b.text(idX, qrY + 115, '#$code', font: 4);

  // Pencil-sketch portrait, vertically centred against the QR.
  if (sketch != null) {
    final sx = W - m - 15 - sketch.tsplWidthPx;
    final sy = qrY + (qrSize - sketch.tsplHeight) ~/ 2;
    b.bitmap(sx, sy, sketch.tsplWidthBytes, sketch.tsplHeight, sketch.tsplBitmap);
    // Frame so the sketch reads as an ID photo, not a stray smudge.
    b.box(sx - 4, sy - 4,
        sx + sketch.tsplWidthPx + 4, sy + sketch.tsplHeight + 4,
        thickness: 2);
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  b.bar(m, H - m - 55, innerW, 3);
  b.centerText(H - m - 45, 'Security Department  |  $schoolName', font: 2);

  return b.print().build();
}

// ── PDF pass (fallback when no USB printer detected) ──────────────────────────

Future<Uint8List> _buildPassDoc(
    Visitor visitor, String schoolName, Sketch? sketch) async {
  final pdf = pw.Document();

  const headerBlue = PdfColor.fromInt(0xFF1E3A8A);
  const badgeRed   = PdfColor.fromInt(0xFFDC2626);
  const lightRed   = PdfColor.fromInt(0xFFFEF2F2);
  const borderRed  = PdfColor.fromInt(0xFFFECACA);
  const textDark   = PdfColor.fromInt(0xFF111827);
  const textGrey   = PdfColor.fromInt(0xFF6B7280);
  const bgLight    = PdfColor.fromInt(0xFFF9FAFB);
  const borderGrey = PdfColor.fromInt(0xFFE5E7EB);
  const labelBlue  = PdfColor.fromInt(0xFF1E40AF);

  // Prefer the on-device pencil sketch; fall back to the original photo if
  // the sketch couldn't be generated (decode failure, no network, etc.).
  pw.ImageProvider? visitorPhoto;
  if (sketch != null) {
    visitorPhoto = pw.MemoryImage(sketch.png);
  } else if (visitor.imagePath != null && visitor.imagePath!.isNotEmpty) {
    try {
      visitorPhoto = await networkImage(visitor.imagePath!);
    } catch (_) {}
  }

  final visitorCode = visitor.id.length >= 6
      ? visitor.id.substring(visitor.id.length - 6).toUpperCase()
      : visitor.id.toUpperCase();

  pdf.addPage(pw.Page(
    pageFormat: const PdfPageFormat(4 * PdfPageFormat.inch, 6 * PdfPageFormat.inch),
    build: (ctx) => pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: headerBlue, width: 2)),
      child: pw.Column(children: [
        // ── Header band ───────────────────────────────────────────────────
        pw.Container(
          color: headerBlue,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: pw.Row(children: [
            pw.Container(
              width: 40, height: 40,
              decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(4)),
              alignment: pw.Alignment.center,
              child: pw.Text(
                schoolName.isNotEmpty ? schoolName[0] : 'S',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold, color: headerBlue)),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Text(schoolName,
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            ),
          ]),
        ),
        // ── VISITOR PASS badge ────────────────────────────────────────────
        pw.Container(
          color: badgeRed, width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          alignment: pw.Alignment.center,
          child: pw.Text('VISITOR PASS',
              style: pw.TextStyle(
                  fontSize: 15, fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white, letterSpacing: 4)),
        ),
        // ── Body ──────────────────────────────────────────────────────────
        pw.Expanded(child: pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
            // Photo + name
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
              pw.Container(
                width: 72, height: 72,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: headerBlue, width: 2.5),
                  color: const PdfColor.fromInt(0xFFE5E7EB),
                  image: visitorPhoto != null
                      ? pw.DecorationImage(image: visitorPhoto, fit: pw.BoxFit.cover)
                      : null,
                ),
                alignment: pw.Alignment.center,
                child: visitorPhoto == null
                    ? pw.Text(
                        visitor.name.isNotEmpty ? visitor.name[0].toUpperCase() : '?',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold, color: textGrey))
                    : null,
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(visitor.name,
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold, color: textDark)),
                  if (visitor.phone.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(visitor.phone,
                        style: const pw.TextStyle(fontSize: 12, color: textGrey)),
                  ],
                ],
              )),
            ]),
            pw.SizedBox(height: 12),
            pw.Divider(color: borderGrey),
            pw.SizedBox(height: 8),
            _infoRow2('TIME IN', visitor.inTime,
                'VALID UNTIL', visitor.validUntil.isNotEmpty ? visitor.validUntil : '-',
                textGrey, textDark,
                rightColor: visitor.validUntil.isNotEmpty ? badgeRed : textDark),
            pw.SizedBox(height: 8),
            if (visitor.personToMeet.isNotEmpty) ...[
              _infoRowFull('PERSON TO MEET', visitor.personToMeet, textGrey, textDark),
              pw.SizedBox(height: 8),
            ],
            if (visitor.purpose.isNotEmpty) ...[
              _infoRowFull('PURPOSE OF VISIT', visitor.purpose, textGrey, textDark),
              pw.SizedBox(height: 8),
            ],
            if (visitor.vehicleNumber.isNotEmpty) ...[
              _infoRow2('VEHICLE NO.', visitor.vehicleNumber, '', '', textGrey, textDark),
              pw.SizedBox(height: 8),
            ],
            if (visitor.email.isNotEmpty) ...[
              _infoRowFull('EMAIL', visitor.email, textGrey, textDark),
              pw.SizedBox(height: 8),
            ],
            pw.Spacer(),
            // Validity banner
            if (visitor.validUntil.isNotEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: pw.BoxDecoration(
                    color: lightRed,
                    border: pw.Border.all(color: borderRed),
                    borderRadius: pw.BorderRadius.circular(5)),
                child: pw.Column(children: [
                  pw.Text('GATE PASS VALID',
                      style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColor.fromInt(0xFF991B1B),
                          letterSpacing: 0.5)),
                  pw.SizedBox(height: 3),
                  pw.Text('${visitor.inTime}  to  ${visitor.validUntil}',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold, color: badgeRed)),
                ]),
              ),
          ]),
        )),
        // ── Footer ────────────────────────────────────────────────────────
        pw.Container(
          decoration: const pw.BoxDecoration(
              color: bgLight,
              border: pw.Border(top: pw.BorderSide(color: borderGrey, width: 1))),
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Security',
                  style: const pw.TextStyle(fontSize: 8, color: textGrey, letterSpacing: 0.5)),
              pw.Text(schoolName,
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold, color: labelBlue)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('VISITOR ID',
                  style: const pw.TextStyle(fontSize: 8, color: textGrey, letterSpacing: 0.5)),
              pw.Text('#$visitorCode',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold,
                      color: headerBlue, letterSpacing: 2)),
            ]),
          ]),
        ),
      ]),
    ),
  ));

  return pdf.save();
}

// ── PDF helper widgets ────────────────────────────────────────────────────────

pw.Widget _infoRow2(String l1, String v1, String l2, String v2,
    PdfColor lc, PdfColor vc, {PdfColor? rightColor}) {
  return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Expanded(child: _infoCell(l1, v1, lc, vc)),
    if (l2.isNotEmpty) pw.Expanded(child: _infoCell(l2, v2, lc, rightColor ?? vc)),
  ]);
}

pw.Widget _infoRowFull(String label, String value, PdfColor lc, PdfColor vc) =>
    pw.Row(children: [pw.Expanded(child: _infoCell(label, value, lc, vc))]);

pw.Widget _infoCell(String label, String value, PdfColor lc, PdfColor vc) =>
    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label,
          style: pw.TextStyle(fontSize: 8, color: lc, letterSpacing: 0.5)),
      pw.SizedBox(height: 2),
      pw.Text(value,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: vc)),
    ]);
