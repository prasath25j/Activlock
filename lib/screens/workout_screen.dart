import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:io';
import '../models/exercise_type.dart';
import '../services/pose_detection_service.dart';
import '../theme/arctic_theme.dart';
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

  Size? _imageSize;
  InputImageRotation _rotation = InputImageRotation.rotation270deg;

  @override
  void initState() {
    super.initState();
    _poseService.setExerciseType(widget.exerciseType);
    _initializeCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInstructions());
  }

  void _showInstructions() {
    if (_isDisposed) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ArcticTheme.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: ArcticTheme.frostBlue),
            const SizedBox(width: 12),
            Text(
              "${widget.exerciseType.name.toUpperCase()} PROTOCOL", 
              style: const TextStyle(color: ArcticTheme.deepNavy, fontWeight: FontWeight.w900, fontSize: 16)
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _instructionStep("1. Position camera to face you."),
            const SizedBox(height: 10),
            _instructionStep("2. Ensure full body is visible."),
            const SizedBox(height: 10),
            _instructionStep("3. Target: ${widget.targetReps} Repetitions"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("COMMENCE", style: TextStyle(color: ArcticTheme.frostBlue, fontWeight: FontWeight.w900)),
          )
        ],
      ),
    );
  }

  Widget _instructionStep(String text) {
    return Text(text, style: const TextStyle(color: ArcticTheme.softSlate, fontSize: 14, fontWeight: FontWeight.w600));
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
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      if (!mounted || _isDisposed) return;
      _rotation = _getRotation(camera.sensorOrientation);
      _controller!.startImageStream(_processCameraImage);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  InputImageRotation _getRotation(int orientation) {
    switch (orientation) {
      case 90: return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default: return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _toggleCamera() async {
    await _stopCamera();
    setState(() {
      _lensDirection = _lensDirection == CameraLensDirection.front ? CameraLensDirection.back : CameraLensDirection.front;
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
          _feedback = _poseService.feedback;
        });
        if (_reps >= widget.targetReps) _handleSuccess();
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _handleSuccess() async {
    if (_isDisposed) return;
    _isDisposed = true;

    if (widget.needsPattern) {
      final bool? patternVerified = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PatternScreen(
            mode: PatternMode.verify,
            packageName: widget.lockedPackageName,
            initialPattern: widget.lockPattern,
            onComplete: (pattern) => Navigator.pop(context, true),
          ),
        ),
      );
      if (patternVerified != true) {
        _isDisposed = false;
        return; 
      }
    }

    await _stopCamera();
    await ref.read(usageServiceProvider).incrementUnlockCount(type: widget.exerciseType, reps: widget.targetReps);
    if (mounted) Navigator.pop(context, true);
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _rotation, 
        format: Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopCamera().then((_) => _controller?.dispose());
    _poseService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: ArcticTheme.iceWhite, body: Center(child: CircularProgressIndicator(color: ArcticTheme.frostBlue)));
    }

    final size = MediaQuery.of(context).size;
    final isVisible = _poseService.isBodyVisible;
    final progress = (_reps / widget.targetReps).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(child: FittedBox(fit: BoxFit.cover, child: SizedBox(width: _controller!.value.previewSize!.height, height: _controller!.value.previewSize!.width, child: CameraPreview(_controller!)))),

          if (_poseService.rawPose != null && _imageSize != null)
            SizedBox.expand(child: CustomPaint(painter: PosePainter(_imageSize!, _poseService.rawPose!, _rotation, isFrontCamera: _lensDirection == CameraLensDirection.front))),

          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.5)], stops: const [0.0, 0.5, 1.0])))),

          Positioned(
            top: 50, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ArcticIconButton(icon: Icons.close_rounded, onPressed: () => Navigator.pop(context, false)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: ArcticTheme.frostDecoration, child: Text(widget.exerciseType.name.toUpperCase(), style: const TextStyle(color: ArcticTheme.deepNavy, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 12))),
                _ArcticIconButton(icon: _lensDirection == CameraLensDirection.front ? Icons.camera_rear_rounded : Icons.camera_front_rounded, onPressed: _toggleCamera),
              ],
            ),
          ),

          if (!isVisible)
            Center(child: Container(padding: const EdgeInsets.all(24), decoration: ArcticTheme.frostDecoration.copyWith(border: Border.all(color: ArcticTheme.alertRed, width: 2)), child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.person_search_rounded, color: ArcticTheme.alertRed, size: 40), SizedBox(height: 12), Text("NOT IN FRAME", style: TextStyle(color: ArcticTheme.deepNavy, fontWeight: FontWeight.w900, fontSize: 16)), Text("Step back for tracking", style: TextStyle(color: ArcticTheme.softSlate, fontSize: 12, fontWeight: FontWeight.bold))]))),

          Positioned(
            bottom: 40, left: 20, right: 20,
            child: Container(
              decoration: ArcticTheme.frostDecoration,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(_feedback.toUpperCase(), style: TextStyle(fontSize: 16, color: isVisible ? ArcticTheme.frostBlue : ArcticTheme.softSlate, fontWeight: FontWeight.w900, letterSpacing: 2.0), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(alignment: Alignment.center, children: [SizedBox(width: 70, height: 70, child: CircularProgressIndicator(value: progress, strokeWidth: 8, backgroundColor: Colors.black12, color: ArcticTheme.frostBlue)), Text("$_reps", style: const TextStyle(color: ArcticTheme.deepNavy, fontSize: 24, fontWeight: FontWeight.w900))]),
                      const SizedBox(width: 24),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("PROGRESS", style: TextStyle(color: ArcticTheme.softSlate, fontSize: 10, fontWeight: FontWeight.w900)), Text("$_reps / ${widget.targetReps}", style: const TextStyle(color: ArcticTheme.deepNavy, fontSize: 22, fontWeight: FontWeight.w900)), Text("${(progress * 100).toInt()}% READY", style: const TextStyle(color: ArcticTheme.frostBlue, fontSize: 11, fontWeight: FontWeight.w800))]),
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

class _ArcticIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _ArcticIconButton({required this.icon, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Container(decoration: ArcticTheme.frostDecoration, child: IconButton(icon: Icon(icon, color: ArcticTheme.deepNavy, size: 24), onPressed: onPressed));
  }
}

class PosePainter extends CustomPainter {
  final Size imageSize;
  final Pose pose;
  final InputImageRotation rotation;
  final bool isFrontCamera;

  PosePainter(this.imageSize, this.pose, this.rotation, {required this.isFrontCamera});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 4.0..color = ArcticTheme.frostBlue.withOpacity(0.6)..strokeCap = StrokeCap.round;
    final jointPaint = Paint()..style = PaintingStyle.fill..color = ArcticTheme.deepNavy;

    final connections = [[PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder], [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow], [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist], [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow], [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist], [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip], [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip], [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip], [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee], [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle], [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee], [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle]];

    for (final connection in connections) {
      final start = pose.landmarks[connection[0]]!;
      final end = pose.landmarks[connection[1]]!;
      if (start.likelihood > 0.5 && end.likelihood > 0.5) canvas.drawLine(_translatePoint(start.x, start.y, size), _translatePoint(end.x, end.y, size), paint);
    }

    for (final landmark in pose.landmarks.values) {
      if (landmark.type.index > 10 && landmark.likelihood > 0.5) canvas.drawCircle(_translatePoint(landmark.x, landmark.y, size), 5, jointPaint);
    }
  }

  Offset _translatePoint(double x, double y, Size screenSize) {
    final double scaleX = screenSize.width / imageSize.height;
    final double scaleY = screenSize.height / imageSize.width;
    final double screenX = x * scaleX;
    final double screenY = y * scaleY;
    return isFrontCamera ? Offset(screenSize.width - screenX, screenY) : Offset(screenX, screenY);
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) => oldDelegate.pose != pose;
}
