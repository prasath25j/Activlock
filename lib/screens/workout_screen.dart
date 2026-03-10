import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:io';
import '../models/exercise_type.dart';
import '../services/pose_detection_service.dart';
import '../theme/modern_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_container.dart';
import 'pattern_screen.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  final String? lockedPackageName;
  final ExerciseType exerciseType;
  final int targetReps;
  final int unlockDuration;
  final bool needsPattern;
  final String? lockPattern;

  const WorkoutScreen({
    super.key,
    this.lockedPackageName,
    required this.exerciseType,
    this.targetReps = 10,
    this.unlockDuration = 15,
    this.needsPattern = false,
    this.lockPattern,
  });

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  CameraController? _controller;
  CameraLensDirection _lensDirection = CameraLensDirection.front;
  final PoseDetectionService _poseService = PoseDetectionService();
  bool _isProcessing = false;
  int _reps = 0;
  String _status = "Prepare";
  String _feedback = "";
  bool _isDisposed = false;

  // For Painting
  Size? _imageSize;
  InputImageRotation _rotation = InputImageRotation.rotation270deg;

  @override
  void initState() {
    super.initState();
    _poseService.setExerciseType(widget.exerciseType);
    _initializeCamera();

    // Show Instructions Dialog after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInstructions());
  }

  void _showInstructions() {
    if (_isDisposed) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ModernTheme.slate800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: ModernTheme.primaryBlue),
            const SizedBox(width: 10),
            Text("${widget.exerciseType.name.toUpperCase()} SETUP", style: const TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _instructionStep("1. Place phone on the floor, leaning against a wall."),
            const SizedBox(height: 10),
            _instructionStep("2. Ensure the camera faces you."),
            const SizedBox(height: 10),
            _instructionStep("3. Step back until your WHOLE body is visible (Head to Toe)."),
            const SizedBox(height: 10),
            _instructionStep("4. Wait for the skeleton lines to appear."),
            const SizedBox(height: 10),
            _instructionStep("5. Target: ${widget.targetReps} Reps"),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("I'M READY"),
          )
        ],
      ),
    );
  }

  Widget _instructionStep(String text) {
    return Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14));
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.firstWhere(
          (camera) => camera.lensDirection == _lensDirection,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      if (!mounted || _isDisposed) return;

      final int sensorOrientation = camera.sensorOrientation;
      _rotation = _getRotation(sensorOrientation);
      
      _controller!.startImageStream(_processCameraImage);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  InputImageRotation _getRotation(int orientation) {
    switch (orientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _toggleCamera() async {
    await _stopCamera();
    setState(() {
      _lensDirection = _lensDirection == CameraLensDirection.front 
          ? CameraLensDirection.back 
          : CameraLensDirection.front;
      _controller = null; 
      _imageSize = null; 
    });
    await _initializeCamera();
  }

  Future<void> _stopCamera() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _isDisposed) return;
    _isProcessing = true;

    _imageSize ??= Size(image.width.toDouble(), image.height.toDouble());

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null || _isDisposed) {
        _isProcessing = false;
        return;
      }

      await _poseService.processImage(inputImage);

      if (mounted && !_isDisposed) {
        setState(() {
          _reps = _poseService.reps;
          _status = _poseService.state == ExerciseState.down ? "DOWN" : "UP";
          _feedback = _poseService.feedback;
        });

        if (_reps >= widget.targetReps) {
          _handleSuccess();
        }
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
    } finally {
      _isProcessing = false;
    }
  }

  void _handleSuccess() async {
    if (_isDisposed) return;
    _isDisposed = true; // Stop processing further frames immediately

    if (widget.needsPattern) {
      final bool? patternVerified = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PatternScreen(
            mode: PatternMode.verify,
            packageName: widget.lockedPackageName,
            initialPattern: widget.lockPattern,
            onComplete: (pattern) {
              Navigator.pop(context, true);
            },
          ),
        ),
      );

      if (patternVerified != true) {
        _isDisposed = false; // Resume processing if they cancelled
        return; 
      }
    }

    await _stopCamera();
    
    await ref.read(usageServiceProvider).incrementUnlockCount(
      type: widget.exerciseType,
      reps: widget.targetReps,
    );

    if (!mounted) return;

    // Return true to LockOverlayScreen to trigger _performUnlock()
    Navigator.pop(context, true);
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final format = Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _rotation, 
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopCamera().then((_) {
      _controller?.dispose();
    });
    _poseService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: ModernTheme.primaryBlue)));
    }

    final size = MediaQuery.of(context).size;
    final isVisible = _poseService.isBodyVisible;
    final progress = (_reps / widget.targetReps).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FULL SCREEN CAMERA
          SizedBox(
            width: size.width,
            height: size.height,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize!.height,
                height: _controller!.value.previewSize!.width,
                child: CameraPreview(_controller!),
              ),
            ),
          ),

          // 2. SKELETON PAINTER
          if (_poseService.rawPose != null && _imageSize != null)
            SizedBox(
              width: size.width,
              height: size.height,
              child: CustomPaint(
                painter: PosePainter(
                  _imageSize!,
                  _poseService.rawPose!,
                  _rotation,
                  isFrontCamera: _lensDirection == CameraLensDirection.front,
                ),
              ),
            ),

          // 3. MODERN OVERLAYS
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // 4. TOP BAR CONTROLS
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _GlassIconButton(
                  icon: Icons.close_rounded,
                  onPressed: () => Navigator.pop(context, false),
                ),
                GlassContainer(
                  blur: 10,
                  opacity: 0.1,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    widget.exerciseType.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      fontSize: 12,
                    ),
                  ),
                ),
                _GlassIconButton(
                  icon: _lensDirection == CameraLensDirection.front
                      ? Icons.camera_rear_rounded
                      : Icons.camera_front_rounded,
                  onPressed: _toggleCamera,
                ),
              ],
            ),
          ),

          // 5. CENTER FEEDBACK (GLASS ALERT)
          if (!isVisible)
            Center(
              child: GlassContainer(
                color: Colors.red,
                opacity: 0.2,
                blur: 15,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_search_rounded, color: Colors.white, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      "BODY NOT VISIBLE",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    Text(
                      "Step back until your full body is in frame",
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // 6. BOTTOM STATS PANEL
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: GlassContainer(
              blur: 20,
              opacity: 0.1,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    _feedback.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      color: isVisible ? ModernTheme.accentCyan : Colors.white54,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Progress Ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 8,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              color: ModernTheme.primaryBlue,
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                "$_reps",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "PROGRESS",
                            style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                          ),
                          Text(
                            "${(_reps)} / ${widget.targetReps}",
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: ModernTheme.primaryBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${(progress * 100).toInt()}% COMPLETE",
                              style: const TextStyle(color: ModernTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
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

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 10,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(8),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
        constraints: const BoxConstraints(),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

// ---- CUSTOM PAINTER (MODERN GLOW) ----
class PosePainter extends CustomPainter {
  final Size imageSize;
  final Pose pose;
  final InputImageRotation rotation;
  final bool isFrontCamera;

  PosePainter(this.imageSize, this.pose, this.rotation, {required this.isFrontCamera});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = ModernTheme.primaryBlue.withOpacity(0.5)
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..color = ModernTheme.primaryBlue.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    final jointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    final jointGlow = Paint()
      ..style = PaintingStyle.fill
      ..color = ModernTheme.accentCyan.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    // Connections (EXCLUDING HEAD/FACE)
    final connections = [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    ];

    for (final connection in connections) {
      final start = pose.landmarks[connection[0]]!;
      final end = pose.landmarks[connection[1]]!;

      if (start.likelihood > 0.5 && end.likelihood > 0.5) {
        final startP = _translatePoint(start.x, start.y, size);
        final endP = _translatePoint(end.x, end.y, size);
        
        // Draw glow then line
        canvas.drawLine(startP, endP, glowPaint);
        canvas.drawLine(startP, endP, paint);
      }
    }

    // Draw Joints (Filter out index 0-10 which are face landmarks)
    for (final landmark in pose.landmarks.values) {
      if (landmark.type.index > 10 && landmark.likelihood > 0.5) {
        final point = _translatePoint(landmark.x, landmark.y, size);
        canvas.drawCircle(point, 8, jointGlow);
        canvas.drawCircle(point, 4, jointPaint);
      }
    }
  }

  Offset _translatePoint(double x, double y, Size screenSize) {
    // Android Front Camera is usually Rotated 270deg.
    // So Width -> Height, Height -> Width
    final double imageW = imageSize.height;
    final double imageH = imageSize.width;

    final double scaleX = screenSize.width / imageW;
    final double scaleY = screenSize.height / imageH;

    // Map Coordinates
    final double screenX = x * scaleX;
    final double screenY = y * scaleY;

    if (isFrontCamera) {
      // Mirror only for front camera
      return Offset(screenSize.width - screenX, screenY);
    } else {
      // Normal for back camera
      return Offset(screenX, screenY);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.pose != pose || 
           oldDelegate.imageSize != imageSize || 
           oldDelegate.isFrontCamera != isFrontCamera;
  }
}
