import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_app/features/admin/domain/attendance_model.dart';
import 'package:mobile_app/features/admin/providers/qr_scan_provider.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key, required this.params});

  final QrScanParams params;

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  OverlayEntry? _toast;

  @override
  void dispose() {
    _controller.dispose();
    _toast?.remove();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final payload = QrPayload.parse(raw);
    if (payload == null) return; // not a SICS QR — ignore
    ref.read(qrScanNotifierProvider(widget.params).notifier).scan(raw);
  }

  void _showToast(QrScanResult result) {
    _toast?.remove();
    _toast = OverlayEntry(
      builder: (_) => _ScanToast(result: result),
    );
    Overlay.of(context).insert(_toast!);
    Future.delayed(const Duration(seconds: 2), () {
      _toast?.remove();
      _toast = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scanState = ref.watch(qrScanNotifierProvider(widget.params));

    // Show toast when a new result arrives
    ref.listen(qrScanNotifierProvider(widget.params), (prev, next) {
      if (next.lastResult != null &&
          next.lastResult != prev?.lastResult) {
        _showToast(next.lastResult!);
      }
    });

    final subtitle = [
      widget.params.className,
      if (widget.params.sectionName != null) widget.params.sectionName!,
      widget.params.date,
    ].join(' · ');

    final loc = GoRouterState.of(context).matchedLocation;
    final routePrefix = loc.startsWith('/teacher') ? '/teacher' : '/admin';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('QR Scanner', style: TextStyle(fontSize: 16)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_rounded),
            tooltip: 'Toggle flashlight',
          ),
          TextButton(
            onPressed: () =>
                context.push('$routePrefix/attendance/qr-live',
                    extra: widget.params),
            child: const Text('Live List',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Scan frame overlay
          Center(
            child: CustomPaint(
              size: const Size(260, 260),
              painter: _ScanFramePainter(color: cs.primary),
            ),
          ),

          // Bottom info bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${scanState.scannedCount} scanned',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      if (scanState.offlineQueue.isNotEmpty)
                        Text(
                          '${scanState.offlineQueue.length} queued (offline)',
                          style: TextStyle(
                              color: Colors.orange.shade300,
                              fontSize: 12),
                        ),
                      if (scanState.error != null &&
                          scanState.offlineQueue.isEmpty)
                        Text(
                          scanState.error!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 12),
                          maxLines: 1,
                        ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      context.pop();
                      context.push('/admin/attendance/qr-live',
                          extra: widget.params);
                    },
                    icon: const Icon(Icons.list_alt_rounded, size: 18),
                    label: const Text('Finish'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scan result toast overlay ─────────────────────────────────────────────────

class _ScanToast extends StatelessWidget {
  const _ScanToast({required this.result});
  final QrScanResult result;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black38, blurRadius: 12, offset: Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      result.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    Text(
                      result.admissionNumber != null
                          ? '${result.admissionNumber} · PRESENT ✓'
                          : 'Staff · PRESENT ✓',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Corner-frame scan painter ─────────────────────────────────────────────────

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 32.0;
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawLine(const Offset(0, len), Offset.zero, paint);
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    // Top-right
    canvas.drawLine(Offset(w - len, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, h - len), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(len, h), paint);
    // Bottom-right
    canvas.drawLine(Offset(w - len, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h - len), Offset(w, h), paint);
  }

  @override
  bool shouldRepaint(_ScanFramePainter old) => old.color != color;
}
