import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mobile_app/core/face/face_embedder.dart';
import 'package:mobile_app/features/face/providers/face_provider.dart';

class FaceRegisterScreen extends ConsumerStatefulWidget {
  const FaceRegisterScreen({
    super.key,
    required this.type,
    this.name,
    this.admissionNumber,
    this.identifier,
  });

  final String type; // 'student' | 'staff'
  final String? name;
  final String? admissionNumber;
  final String? identifier;

  @override
  ConsumerState<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends ConsumerState<FaceRegisterScreen> {
  CameraController? _cam;
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.3,
    ),
  );

  bool _initialised = false;
  bool _capturing = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initEmbedder();
  }

  Future<void> _initEmbedder() async {
    try {
      await FaceEmbedder.instance.init();
    } catch (_) {
      // Non-fatal: will surface error message when capture is attempted.
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _statusMessage = 'No camera available');
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cam = CameraController(front, ResolutionPreset.high,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.bgra8888);
      await _cam!.initialize();
      if (mounted) setState(() => _initialised = true);
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _statusMessage = e.description ?? 'Camera unavailable');
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = 'Camera error: $e');
    }
  }

  @override
  void dispose() {
    _cam?.dispose();
    _detector.close();
    super.dispose();
  }

  bool get _hasIdentifier =>
      widget.admissionNumber != null || widget.identifier != null;

  Future<void> _capture() async {
    if (_capturing || _cam == null || !_initialised) return;
    if (!_hasIdentifier) {
      setState(() =>
          _statusMessage = 'No student/staff selected.\nGo back and tap Register on a person.');
      return;
    }
    setState(() {
      _capturing = true;
      _statusMessage = 'Detecting face…';
      _isError = false;
    });

    try {
      // Take a picture
      final xFile = await _cam!.takePicture();
      final inputImage = InputImage.fromFilePath(xFile.path);

      // Detect faces
      final faces = await _detector.processImage(inputImage);
      if (!mounted) return;
      if (faces.isEmpty) {
        setState(() {
          _capturing = false;
          _statusMessage = 'No face detected — try again';
          _isError = true;
        });
        return;
      }

      setState(() { _statusMessage = 'Computing embedding…'; _isError = false; });

      // Get embedding (embedder already initialised in initState)
      final img = await FaceEmbedder.fromImageFile(xFile.path);
      if (!mounted) return;
      if (img == null) {
        setState(() {
          _capturing = false;
          _statusMessage = 'Failed to process image';
          _isError = true;
        });
        return;
      }

      final embedding = FaceEmbedder.instance.getEmbedding(img);

      // Register via notifier
      setState(() => _statusMessage = 'Registering…');
      await ref.read(faceRegisterNotifierProvider.notifier).register(
            type: widget.type,
            admissionNumber: widget.admissionNumber,
            identifier: widget.identifier,
            embedding: embedding,
          );

      if (!mounted) return;
      final result = ref.read(faceRegisterNotifierProvider).result;
      if (result != null && result.ok) {
        setState(() {
          _capturing = false;
          _statusMessage = null;
        });
        _showSuccess(result.name);
      } else {
        setState(() {
          _capturing = false;
          _statusMessage =
              ref.read(faceRegisterNotifierProvider).error ?? 'Registration failed';
          _isError = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _statusMessage = e.toString();
        _isError = true;
      });
    }
  }

  void _showSuccess(String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded,
            color: Colors.green, size: 48),
        title: const Text('Registered!'),
        content: Text('$name has been successfully enrolled.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx); // close dialog
              ref.read(faceRegisterNotifierProvider.notifier).reset();
              if (mounted) context.pop(); // back to enrollment list
            },
            child: const Text('Done'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx); // close dialog only
              ref.read(faceRegisterNotifierProvider.notifier).reset();
              if (mounted) setState(() => _statusMessage = null);
            },
            child: const Text('Register Another'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final notifierState = ref.watch(faceRegisterNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Face Registration', style: TextStyle(fontSize: 16)),
            if (widget.name != null)
              Text(widget.name!,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_initialised && _cam != null)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _cam!.value.aspectRatio,
                child: CameraPreview(_cam!),
              ),
            )
          else
            const Center(
                child: CircularProgressIndicator(color: Colors.white)),

          // Face oval guide
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = MediaQuery.of(context).size;
                final w = (size.width * 0.55).clamp(180.0, 320.0);
                final h = w * 1.35;
                return CustomPaint(
                  size: Size(w, h),
                  painter: _OvalFramePainter(color: cs.primary),
                );
              },
            ),
          ),

          // Instruction text
          Positioned(
            top: 40,
            left: 24,
            right: 24,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusMessage ??
                    (!_hasIdentifier
                        ? 'No person selected.\nGo back and tap Register on a specific person.'
                        : 'Position your face inside the oval\nthen press Capture'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: (!_hasIdentifier || _isError) ? Colors.redAccent : Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  32, 24, 32, 24 + MediaQuery.of(context).padding.bottom),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Capture button
                  GestureDetector(
                    onTap: (_capturing || notifierState.isSubmitting)
                        ? null
                        : _capture,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (_capturing || notifierState.isSubmitting)
                            ? Colors.white38
                            : Colors.white,
                        border: Border.all(
                            color: cs.primary, width: 3),
                      ),
                      child: (_capturing || notifierState.isSubmitting)
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.camera_alt_rounded,
                              color: Colors.black, size: 32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Capture',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
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

    canvas.drawOval(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_OvalFramePainter old) => old.color != color;
}
