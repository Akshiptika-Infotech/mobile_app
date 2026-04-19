import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/face/face_embedder.dart';
import 'package:mobile_app/features/face/domain/face_model.dart';
import 'package:mobile_app/features/face/providers/face_provider.dart';

/// Security guard screen: continuously scans faces for gate entry/exit.
class FaceVerifyScreen extends ConsumerStatefulWidget {
  const FaceVerifyScreen({super.key});

  @override
  ConsumerState<FaceVerifyScreen> createState() => _FaceVerifyScreenState();
}

class _FaceVerifyScreenState extends ConsumerState<FaceVerifyScreen> {
  CameraController? _cam;
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.2,
    ),
  );

  bool _initialised = false;
  bool _processing = false;
  String _attendanceType = 'ENTRY';
  final String _date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  OverlayEntry? _toast;
  int _verifiedCount = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    FaceEmbedder.instance.init();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cam = CameraController(front, ResolutionPreset.medium,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.bgra8888);
    await _cam!.initialize();
    if (!mounted) return;
    setState(() => _initialised = true);
    _cam!.startImageStream(_onFrame);
  }

  @override
  void dispose() {
    _cam?.stopImageStream();
    _cam?.dispose();
    _detector.close();
    _toast?.remove();
    super.dispose();
  }

  Future<void> _onFrame(CameraImage frame) async {
    if (_processing || !FaceEmbedder.instance.isReady) return;
    _processing = true;

    try {
      final plane = frame.planes.first;
      final inputImage = InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(frame.width.toDouble(), frame.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
      final faces = await _detector.processImage(inputImage);
      if (faces.isEmpty) {
        _processing = false;
        return;
      }

      final raw = FaceEmbedder.fromBytes(
        bytes: plane.bytes,
        width: frame.width,
        height: frame.height,
        isBgra: true,
      );
      final embedding = FaceEmbedder.instance.getEmbedding(raw);

      await ref.read(faceVerifyNotifierProvider.notifier).verify(
            embedding: embedding,
            date: _date,
            attendanceType: _attendanceType,
          );

      if (!mounted) return;
      final result = ref.read(faceVerifyNotifierProvider).result;
      if (result != null && result.matched) {
        setState(() => _verifiedCount++);
        _showToast(result);
        ref.read(faceVerifyNotifierProvider.notifier).clearResult();
        await Future.delayed(const Duration(seconds: 3));
      }
    } catch (_) {
      // Ignore frame errors
    } finally {
      _processing = false;
    }
  }

  void _showToast(FaceVerifyResult result) {
    _toast?.remove();
    _toast = OverlayEntry(builder: (_) => _VerifyToast(result: result));
    Overlay.of(context).insert(_toast!);
    Future.delayed(const Duration(seconds: 2), () {
      _toast?.remove();
      _toast = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gate Face Scan', style: TextStyle(fontSize: 16)),
            Text(_date,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          // Entry / Exit toggle
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: ['ENTRY', 'EXIT'].map((type) {
                final selected = _attendanceType == type;
                return GestureDetector(
                  onTap: () => setState(() => _attendanceType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? cs.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_initialised && _cam != null)
            Positioned.fill(child: CameraPreview(_cam!))
          else
            const Center(
                child: CircularProgressIndicator(color: Colors.white)),

          // Oval guide
          Center(
            child: CustomPaint(
              size: const Size(220, 290),
              painter: _OvalFramePainter(color: cs.primary),
            ),
          ),

          // Status label
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Look straight into camera · $_attendanceType',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),

          // Bottom bar
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
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_verifiedCount verified',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      const Text('Auto-scanning…',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
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

// ── Verify result toast ───────────────────────────────────────────────────────

class _VerifyToast extends StatelessWidget {
  const _VerifyToast({required this.result});

  final FaceVerifyResult result;

  @override
  Widget build(BuildContext context) {
    final isEntry = result.status == 'ENTRY' || result.type == 'ENTRY';
    final color = isEntry ? Colors.green.shade700 : Colors.blue.shade700;

    return Positioned(
      top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black38,
                  blurRadius: 12,
                  offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isEntry
                    ? Icons.login_rounded
                    : Icons.logout_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      result.name ?? 'Verified',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    Text(
                      result.admissionNumber != null
                          ? '${result.admissionNumber} · ${result.status ?? "OK"} ✓'
                          : 'Staff · ${result.status ?? "OK"} ✓',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (result.similarity != null)
                Text(
                  '${(result.similarity! * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Oval frame painter ────────────────────────────────────────────────────────

class _OvalFramePainter extends CustomPainter {
  const _OvalFramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawOval(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_OvalFramePainter old) => old.color != color;
}
