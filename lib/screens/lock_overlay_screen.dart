import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../providers/app_providers.dart';
import '../models/locked_app.dart';
import '../models/exercise_type.dart';
import '../theme/modern_theme.dart';
import '../theme/wakanda_background.dart';
import '../widgets/glass_container.dart';

class LockOverlayScreen extends ConsumerStatefulWidget {
  final String? lockedPackageName;
  const LockOverlayScreen({super.key, required this.lockedPackageName});

  @override
  ConsumerState<LockOverlayScreen> createState() => _LockOverlayScreenState();
}

class _LockOverlayScreenState extends ConsumerState<LockOverlayScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _showPin = false;
  int _failedPinAttempts = 0;
  CameraController? _cameraController;
  bool _isCapturing = false;

  final Map<String, int> _stats = {'unlocks': 0, 'emergency': 0, 'maxUnlocks': 3, 'maxEmergency': 1};
  bool _canUnlock = false;
  bool _canEmergency = false;
  
  String _pinCode = "";
  ExerciseType _exerciseType = ExerciseType.squat;
  int _targetReps = 10;
  int _maxExceptions = 3;
  int _unlockDuration = 15;
  bool _needsPattern = false;
  String? _lockPattern;

  @override
  void initState() {
    super.initState();
    _loadAppConfig();
    _loadLimits();
    _initCamera();
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

  Future<void> _captureIntruder(String reason) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCapturing) return;
    _isCapturing = true;
    try {
      final XFile photo = await _cameraController!.takePicture();
      await ref.read(logServiceProvider).addLog(
        widget.lockedPackageName ?? "Unknown", 
        photo.path, 
        reason
      );
    } catch (e) {
      debugPrint("Capture Error: $e");
    } finally {
      _isCapturing = false;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _loadAppConfig() {
    final lockedApps = ref.read(lockedAppsProvider);
    final currentApp = lockedApps.firstWhere(
            (app) => app.packageName == widget.lockedPackageName,
        orElse: () => LockedApp(packageName: "", appName: "")
    );

    setState(() {
      _pinCode = currentApp.pinCode ?? "";
      _exerciseType = currentApp.exerciseType;
      _targetReps = currentApp.targetReps;
      _maxExceptions = currentApp.dailyExceptions;
      _unlockDuration = currentApp.unlockDurationMinutes;
      _needsPattern = currentApp.needsPattern;
      _lockPattern = currentApp.lockPattern;
    });
  }

  Future<void> _loadLimits() async {
    final lockedApps = ref.read(lockedAppsProvider);
    final currentApp = lockedApps.firstWhere(
            (app) => app.packageName == widget.lockedPackageName,
        orElse: () => LockedApp(packageName: "", appName: "")
    );
    
    final int usedU = currentApp.usedUnlocks;
    final int limitU = currentApp.dailyUnlockLimit;
    final canU = usedU < limitU;
    
    final int usedE = currentApp.usedExceptions;
    final int limitE = currentApp.dailyExceptions;
    final canE = usedE < limitE;

    if (mounted) {
      setState(() {
        _stats['unlocks'] = usedU;
        _stats['maxUnlocks'] = limitU;
        _stats['emergency'] = usedE;
        _stats['maxEmergency'] = limitE;
        _canUnlock = canU;
        _canEmergency = canE;
      });
    }
  }

  void _unlockWithPin() async {
    final inputPin = _pinController.text;
    
    bool isValid = false;
    if (_pinCode.isNotEmpty) {
      isValid = inputPin == _pinCode;
    } else {
       isValid = await ref.read(settingsServiceProvider).verifyPin(inputPin);
    }

    if (isValid) {
      if (_canEmergency) {
        if (widget.lockedPackageName != null) {
           await ref.read(appLockServiceProvider).incrementException(widget.lockedPackageName!);
        }
        _performUnlock();
      } else {
        _showSnack('Emergency limit reached!');
      }
    } else {
      _failedPinAttempts++;
      _showSnack('Invalid Access Code!');
      if (_failedPinAttempts >= 3) {
        _captureIntruder("PIN Failed ($_failedPinAttempts attempts)");
      }
    }
  }

  void _startActivity(ExerciseType type) async {
    if (!_canUnlock) {
      _showSnack('Daily unlock limit reached!');
      return;
    }

    final routeName = type == ExerciseType.steps ? '/steps_challenge' : '/workout';
    final args = type == ExerciseType.steps 
      ? {
          'package': widget.lockedPackageName,
          'targetSteps': _targetReps,
          'unlockDuration': _unlockDuration,
          'needsPattern': _needsPattern,
          'lockPattern': _lockPattern,
        }
      : {
          'package': widget.lockedPackageName,
          'type': type,
          'targetReps': _targetReps,
          'unlockDuration': _unlockDuration,
          'needsPattern': _needsPattern,
          'lockPattern': _lockPattern,
        };

    final result = await Navigator.pushNamed(
        context,
        routeName,
        arguments: args
    );

    if (result == true) {
      if (widget.lockedPackageName != null) {
          await ref.read(appLockServiceProvider).incrementUnlock(widget.lockedPackageName!);
      }
      _performUnlock();
    }
  }

  void _performUnlock() {
    if (widget.lockedPackageName != null) {
      ref.read(appLockServiceProvider).unlockAppTemporary(
          widget.lockedPackageName!,
          duration: Duration(minutes: _unlockDuration)
      );
    }
    SystemNavigator.pop();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: ModernTheme.accentPink,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
      child: Scaffold(
        body: WakandaBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassContainer(
                blur: 20,
                opacity: 0.1,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ModernTheme.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_reset_rounded, size: 50, color: ModernTheme.primaryBlue),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'SECURED AREA',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unlocks: ${_stats['unlocks']}/${_stats['maxUnlocks']}',
                      style: TextStyle(color: _canUnlock ? ModernTheme.accentCyan : ModernTheme.accentPink, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 40),

                    if (_canUnlock) ...[
                      Text('COMPLETE ${_targetReps} ${_exerciseType == ExerciseType.steps ? 'STEPS' : 'REPS'}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_exerciseType == ExerciseType.squat)
                            _ActivityButton(
                                icon: Icons.accessibility_new_rounded,
                                label: "SQUATS",
                                onTap: () => _startActivity(ExerciseType.squat)
                            ),
                          if (_exerciseType == ExerciseType.pushup)
                             _ActivityButton(
                                icon: Icons.fitness_center_rounded,
                                label: "PUSHUPS",
                                onTap: () => _startActivity(ExerciseType.pushup)
                            ),
                          if (_exerciseType == ExerciseType.steps)
                             _ActivityButton(
                                icon: Icons.directions_walk_rounded,
                                label: "STEPS",
                                onTap: () => _startActivity(ExerciseType.steps)
                            ),
                        ],
                      ),
                    ] else ...[
                      const Icon(Icons.block_flipped, color: ModernTheme.accentPink, size: 40),
                      const SizedBox(height: 10),
                      const Text(
                        'LIMIT REACHED',
                        style: TextStyle(color: ModernTheme.accentPink, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],

                    const SizedBox(height: 40),
                    if (_showPin) ...[
                      TextField(
                        controller: _pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 18),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '••••',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: ModernTheme.accentPink),
                          onPressed: _unlockWithPin,
                          child: const Text('BYPASS'),
                        ),
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: () {
                          if (_canEmergency) {
                            setState(() { _showPin = true; });
                          } else {
                            _showSnack('No bypasses remaining!');
                          }
                        },
                        child: Text(
                            'EMERGENCY BYPASS (${_stats['emergency']}/${_stats['maxEmergency']})',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActivityButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        decoration: BoxDecoration(
          color: ModernTheme.primaryBlue.withOpacity(0.1),
          border: Border.all(color: ModernTheme.primaryBlue.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: ModernTheme.primaryBlue, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}