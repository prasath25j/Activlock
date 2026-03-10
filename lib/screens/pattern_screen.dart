import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pattern_lock/pattern_lock.dart';
import 'package:camera/camera.dart';
import '../theme/modern_theme.dart';
import '../providers/app_providers.dart';

enum PatternMode { setup, verify }

class PatternScreen extends ConsumerStatefulWidget {
  final PatternMode mode;
  final String? initialPattern;
  final String? packageName; // Required for logging
  final Function(String) onComplete;

  const PatternScreen({
    super.key,
    required this.mode,
    this.initialPattern,
    this.packageName,
    required this.onComplete,
  });

  @override
  ConsumerState<PatternScreen> createState() => _PatternScreenState();
}

class _PatternScreenState extends ConsumerState<PatternScreen> {
  String? _firstPattern;
  String _message = "";
  bool _isError = false;
  int _failedAttempts = 0;
  
  CameraController? _cameraController;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _message = widget.mode == PatternMode.setup 
        ? "Draw your security pattern" 
        : "Draw pattern to unlock";
    
    if (widget.mode == PatternMode.verify) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
      _cameraController = CameraController(front, ResolutionPreset.low, enableAudio: false);
      await _cameraController!.initialize();
    } catch (e) {
      debugPrint("Intruder Camera Error: $e");
    }
  }

  void _onPatternComplete(List<int> pattern) {
    if (pattern.length < 3) {
      setState(() {
        _message = "Pattern too short (min 3 points)";
        _isError = true;
      });
      return;
    }

    final patternString = pattern.join(",");

    if (widget.mode == PatternMode.setup) {
      if (_firstPattern == null) {
        setState(() {
          _firstPattern = patternString;
          _message = "Draw again to confirm";
          _isError = false;
        });
      } else {
        if (_firstPattern == patternString) {
          widget.onComplete(patternString);
        } else {
          setState(() {
            _firstPattern = null;
            _message = "Patterns did not match. Try again.";
            _isError = true;
          });
        }
      }
    } else {
      // Verify Mode
      if (widget.initialPattern == patternString) {
        widget.onComplete(patternString);
      } else {
        _failedAttempts++;
        setState(() {
          _message = "Incorrect pattern. Try again.";
          _isError = true;
        });

        // Capture after 2 failed attempts
        if (_failedAttempts >= 2) {
          _captureIntruder();
        }
      }
    }
  }

  Future<void> _captureIntruder() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCapturing) return;
    
    _isCapturing = true;
    try {
      final XFile photo = await _cameraController!.takePicture();
      await ref.read(logServiceProvider).addLog(
        widget.packageName ?? "Unknown", 
        photo.path, 
        "Pattern Failed ($_failedAttempts attempts)"
      );
      debugPrint("Intruder Captured!");
    } catch (e) {
      debugPrint("Capture Error: $e");
    } finally {
      _isCapturing = false;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.slate900,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ModernTheme.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.mode == PatternMode.setup ? Icons.lock_reset_rounded : Icons.lock_outline_rounded,
                      size: 40,
                      color: ModernTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.mode == PatternMode.setup ? "PATTERN SETUP" : "SECURITY CHECK",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _message,
                    style: TextStyle(
                      color: _isError ? ModernTheme.accentPink : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  RepaintBoundary(
                    child: SizedBox(
                      height: 300,
                      width: 300,
                      child: PatternLock(
                        notSelectedColor: Colors.white12,
                        selectedColor: ModernTheme.primaryBlue,
                        pointRadius: 10,
                        showInput: true,
                        dimension: 3,
                        onInputComplete: _onPatternComplete,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("CANCEL", style: TextStyle(color: Colors.white.withOpacity(0.3))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
