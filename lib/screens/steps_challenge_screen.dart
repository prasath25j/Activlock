import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:local_auth/local_auth.dart';
import '../models/exercise_type.dart';
import '../providers/app_providers.dart';
import '../theme/modern_theme.dart';
import '../theme/wakanda_background.dart';
import '../widgets/glass_container.dart';

class StepsChallengeScreen extends ConsumerStatefulWidget {
  final String? lockedPackageName;
  final int targetSteps;
  final int unlockDuration;
  final bool needsBiometric;

  const StepsChallengeScreen({
    super.key,
    this.lockedPackageName,
    required this.targetSteps,
    required this.unlockDuration,
    this.needsBiometric = false,
  });

  @override
  ConsumerState<StepsChallengeScreen> createState() => _StepsChallengeScreenState();
}

class _StepsChallengeScreenState extends ConsumerState<StepsChallengeScreen> {
  late Stream<StepCount> _stepCountStream;
  StreamSubscription<StepCount>? _subscription;
  int _initialSteps = -1;
  int _currentSteps = 0;
  String _status = 'Initializing...';
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _initPedometer();
  }

  Future<void> _initPedometer() async {
    final status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      _stepCountStream = Pedometer.stepCountStream;
      _subscription = _stepCountStream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );
    } else {
      setState(() {
        _status = 'Permission Denied';
      });
    }
  }

  void _onData(StepCount event) {
    if (_initialSteps == -1) {
      _initialSteps = event.steps;
    }
    if (_isUnlocked) return;

    setState(() {
      _currentSteps = event.steps - _initialSteps;
      _status = 'Tracking Steps';
    });

    if (_currentSteps >= widget.targetSteps) {
      _handleSuccess();
    }
  }

  void _onDone() => debugPrint("Finished tracking steps");

  void _onError(error) {
    setState(() {
      _status = 'Step Count Not Available';
    });
  }

  void _handleSuccess() async {
    if (_isUnlocked) return;

    // 1. Multi-Stage Verification
    if (widget.needsBiometric) {
      final LocalAuthentication auth = LocalAuthentication();
      try {
        final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
        final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

        if (canAuthenticate) {
          final bool didAuthenticate = await auth.authenticate(
            localizedReason: 'Verification required to unlock app',
            biometricOnly: true,
          );
          if (!didAuthenticate) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Biometric verification failed. Try again.")),
              );
            }
            return;
          }
        }
      } catch (e) {
        debugPrint("Biometric Error: $e");
      }
    }

    _isUnlocked = true;
    _subscription?.cancel();
    
    await ref.read(usageServiceProvider).incrementUnlockCount(
      type: ExerciseType.steps,
      reps: widget.targetSteps,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ModernTheme.slate800,
        title: const Text("GOAL REACHED!", style: TextStyle(color: ModernTheme.accentCyan, fontWeight: FontWeight.bold)),
        content: Text("Protocol complete. Access granted for ${widget.unlockDuration} minutes.", style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performUnlock();
            },
            child: const Text("OPEN APP", style: TextStyle(color: ModernTheme.primaryBlue)),
          )
        ],
      ),
    );
  }

  void _performUnlock() {
    if (widget.lockedPackageName != null) {
      ref.read(appLockServiceProvider).unlockAppTemporary(
          widget.lockedPackageName!,
          duration: Duration(minutes: widget.unlockDuration)
      );
    }
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentSteps / widget.targetSteps).clamp(0.0, 1.0);

    return Scaffold(
      body: WakandaBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GlassContainer(
              blur: 20,
              opacity: 0.1,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_walk_rounded, size: 60, color: ModernTheme.primaryBlue),
                  const SizedBox(height: 24),
                  const Text(
                    "STEP CHALLENGE",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(_status, style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  const SizedBox(height: 40),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          color: ModernTheme.accentCyan,
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            "$_currentSteps",
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          Text(
                            "OF ${widget.targetSteps}",
                            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "${(progress * 100).toInt()}% COMPLETE",
                    style: const TextStyle(color: ModernTheme.accentCyan, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 20),
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
