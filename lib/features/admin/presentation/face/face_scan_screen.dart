import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mobile_app/core/face/face_embedder.dart';
import 'package:mobile_app/features/admin/domain/attendance_model.dart';
import 'package:mobile_app/features/face/domain/face_model.dart';
import 'package:mobile_app/features/face/providers/face_provider.dart';

class FaceScanScreen extends ConsumerStatefulWidget {
  const FaceScanScreen({super.key, required this.params});

  final FaceScanParams params;

  @override
  ConsumerState<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends ConsumerState<FaceScanScreen> {
  CameraController? _cam;
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.2,
    ),
  );

  bool _initialised = false;
  bool _processing = false;
  OverlayEntry? _toast;
  int _scannedCount = 0;

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
      // Convert to img.Image
      final plane = frame.planes.first;
      final raw = FaceEmbedder.fromBytes(
        bytes: plane.bytes,
        width: frame.width,
        height: frame.height,
        isBgra: true,
      );

      // Quick ML Kit face check using the raw camera bytes
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

      final embedding = FaceEmbedder.instance.getEmbedding(raw);
      await ref.read(faceVerifyNotifierProvider.notifier).verify(
            embedding: embedding,
            date: widget.params.date,
            attendanceType: widget.params.attendanceType,
            classId: widget.params.classId,
            sectionId: widget.params.sectionId,
            academicYearId: widget.params.academicYearId,
          );

      if (!mounted) return;
      final result = ref.read(faceVerifyNotifierProvider).result;
      if (result != null && result.matched) {
        setState(() => _scannedCount++);
        _showToast(result);
        ref.read(faceVerifyNotifierProvider.notifier).clearResult();
        // Pause processing for 3s to avoid duplicate marks
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

    final subtitle = [
      widget.params.className,
      if (widget.params.sectionName != null) widget.params.sectionName!,
      widget.params.date,
      widget.params.attendanceType,
    ].join(' · ');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Face Attendance', style: TextStyle(fontSize: 16)),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            tooltip: 'Switch camera',
            onPressed: _toggleCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_initialised && _cam != null)
            Positioned.fill(
              child: CameraPreview(_cam!),
            )
          else
            const Center(
                child: CircularProgressIndicator(color: Colors.white)),

          // Oval guide overlay
          Center(
            child: CustomPaint(
              size: const Size(220, 290),
              painter: _OvalFramePainter(color: cs.primary),
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
                        '$_scannedCount marked',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      const Text(
                        'Auto-detecting faces…',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Done'),
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

  Future<void> _toggleCamera() async {
    final cameras = await availableCameras();
    if (cameras.length < 2 || _cam == null) return;
    final current = _cam!.description;
    final next = cameras.firstWhere(
      (c) => c.lensDirection != current.lensDirection,
      orElse: () => cameras.first,
    );
    await _cam!.stopImageStream();
    await _cam!.dispose();
    _cam = CameraController(next, ResolutionPreset.medium,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.bgra8888);
    await _cam!.initialize();
    if (mounted) {
      setState(() {});
      _cam!.startImageStream(_onFrame);
    }
  }
}

// ── Verify result toast ───────────────────────────────────────────────────────

class _VerifyToast extends StatelessWidget {
  const _VerifyToast({required this.result});

  final FaceVerifyResult result;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green.shade700,
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
              const Icon(Icons.face_retouching_natural_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      result.name ?? 'Unknown',
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
