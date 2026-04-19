import 'package:flutter/services.dart';

import 'esc_pos_builder.dart';

/// Represents a detected USB printer device.
class UsbPrinterDevice {
  const UsbPrinterDevice({
    required this.name,
    required this.vendorId,
    required this.productId,
    required this.manufacturer,
    required this.product,
    required this.hasPermission,
  });

  final String name;
  final int vendorId;
  final int productId;
  final String manufacturer;
  final String product;
  final bool hasPermission;

  String get displayName {
    if (manufacturer.isNotEmpty || product.isNotEmpty) {
      return '$manufacturer $product'.trim();
    }
    return 'Printer (VID:${vendorId.toRadixString(16).toUpperCase()})';
  }

  factory UsbPrinterDevice.fromMap(Map<Object?, Object?> m) {
    return UsbPrinterDevice(
      name: (m['name'] ?? '').toString(),
      vendorId: (m['vendorId'] as int?) ?? 0,
      productId: (m['productId'] as int?) ?? 0,
      manufacturer: (m['manufacturer'] ?? '').toString(),
      product: (m['product'] ?? '').toString(),
      hasPermission: (m['hasPermission'] as bool?) ?? false,
    );
  }
}

/// Flutter-side service that talks to [UsbPrinterPlugin] via MethodChannel.
///
/// Singleton — use [UsbPrinterService.instance].
class UsbPrinterService {
  UsbPrinterService._();
  static final instance = UsbPrinterService._();

  static const _channel = MethodChannel('usb_thermal_printer');

  // ── Discovery ──────────────────────────────────────────────────────────────

  /// Returns all connected USB devices that look like printers.
  Future<List<UsbPrinterDevice>> listPrinters() async {
    final raw = await _channel.invokeMethod<List>('listPrinters') ?? [];
    return raw
        .cast<Map<Object?, Object?>>()
        .map(UsbPrinterDevice.fromMap)
        .toList();
  }

  /// Returns true if at least one printer is connected via USB/OTG.
  Future<bool> isPrinterConnected() async {
    return await _channel.invokeMethod<bool>('isPrinterConnected') ?? false;
  }

  /// Returns a diagnostic string listing all USB devices and their endpoints.
  Future<String> diagnose() async {
    return await _channel.invokeMethod<String>('diagnose') ?? 'No info';
  }

  /// Returns the first available printer, or null if none.
  Future<UsbPrinterDevice?> firstPrinter() async {
    final printers = await listPrinters();
    return printers.isEmpty ? null : printers.first;
  }

  // ── Permission ─────────────────────────────────────────────────────────────

  /// Requests Android USB permission for [device].
  /// Returns true if permission is granted.
  Future<bool> requestPermission(UsbPrinterDevice device) async {
    return await _channel.invokeMethod<bool>(
          'requestPermission',
          {'deviceName': device.name},
        ) ??
        false;
  }

  /// Ensures permission is granted, requesting it if needed.
  /// Returns the device with permission, or null on denial.
  Future<UsbPrinterDevice?> ensurePermission(UsbPrinterDevice device) async {
    if (device.hasPermission) return device;
    final granted = await requestPermission(device);
    if (!granted) return null;
    // Refresh device list to get updated permission state
    final printers = await listPrinters();
    return printers.firstWhere(
      (p) => p.name == device.name,
      orElse: () => device,
    );
  }

  // ── Raw printing ───────────────────────────────────────────────────────────

  /// Sends raw [bytes] (ESC/POS) to [device].
  Future<void> printBytes(UsbPrinterDevice device, Uint8List bytes) async {
    await _channel.invokeMethod<bool>(
      'printBytes',
      {'deviceName': device.name, 'data': bytes},
    );
  }

  // ── High-level helpers ─────────────────────────────────────────────────────

  /// Detect printer → request permission → send bytes.
  /// Throws [UsbPrinterException] on any failure.
  Future<void> print(Uint8List bytes) async {
    final device = await firstPrinter();
    if (device == null) throw UsbPrinterException.notFound();

    final permitted = await ensurePermission(device);
    if (permitted == null) throw UsbPrinterException.noPermission();

    await printBytes(permitted, bytes);
  }

  // ── Receipt builder ───────────────────────────────────────────────────────

  /// Builds and prints a formatted receipt.
  ///
  /// Example:
  /// ```dart
  /// await UsbPrinterService.instance.printReceipt(
  ///   title: 'SchoolFeePro Receipt',
  ///   schoolName: 'JMUKHISICS School',
  ///   items: [
  ///     ReceiptItem('Tuition Fee - Apr', 5000),
  ///     ReceiptItem('Transport Fee', 800),
  ///   ],
  ///   total: 5800,
  ///   receiptNo: 'RCP-2026-001',
  ///   studentName: 'Rahul Sharma',
  ///   qrData: 'https://jmukhisics.in/receipts/abc123',
  /// );
  /// ```
  Future<void> printReceipt({
    required String title,
    required String schoolName,
    required List<ReceiptItem> items,
    required double total,
    String? receiptNo,
    String? studentName,
    String? className,
    String? date,
    String? qrData,
    int printerWidth = 32, // chars: 32 for 58mm, 48 for 80mm
  }) async {
    final b = EscPosBuilder()
        .initialize()
        // ── Header ─────────────────────────────────────────────────────────
        .centerAlign()
        .doubleSize()
        .boldOn()
        .textLn(title)
        .normalSize()
        .boldOff()
        .textLn(schoolName)
        .lf();

    if (receiptNo != null) b.textLn('Receipt: $receiptNo');
    if (date != null) b.textLn(date);

    b.divider(width: printerWidth).leftAlign();

    if (studentName != null) {
      b.textLn('Student : $studentName');
    }
    if (className != null) {
      b.textLn('Class   : $className');
    }
    if (studentName != null || className != null) {
      b.divider(width: printerWidth);
    }

    // ── Items ─────────────────────────────────────────────────────────────
    for (final item in items) {
      b.item(
        item.label,
        'Rs.${item.amount.toStringAsFixed(0)}',
        width: printerWidth,
      );
    }

    b.divider(width: printerWidth);

    // ── Total ─────────────────────────────────────────────────────────────
    b
        .boldOn()
        .totalLine(
          'TOTAL',
          'Rs.${total.toStringAsFixed(0)}',
          width: printerWidth,
        )
        .boldOff()
        .divider(width: printerWidth);

    // ── QR code ───────────────────────────────────────────────────────────
    if (qrData != null && qrData.isNotEmpty) {
      b.centerAlign().lf().qrCode(qrData, size: 5).lf();
    }

    b.feed(3).cut();

    await print(b.build());
  }
}

// ── Supporting types ──────────────────────────────────────────────────────────

class ReceiptItem {
  const ReceiptItem(this.label, this.amount);
  final String label;
  final double amount;
}

class UsbPrinterException implements Exception {
  const UsbPrinterException(this.message, this.code);

  factory UsbPrinterException.notFound() =>
      const UsbPrinterException(
          'No USB thermal printer detected. Please connect via OTG.', 'NOT_FOUND');

  factory UsbPrinterException.noPermission() =>
      const UsbPrinterException(
          'USB permission denied. Please allow access to the printer.', 'NO_PERMISSION');

  final String message;
  final String code;

  @override
  String toString() => 'UsbPrinterException($code): $message';
}
