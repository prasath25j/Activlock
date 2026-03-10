import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/exercise_type.dart';
import '../providers/app_providers.dart';
import '../theme/arctic_theme.dart';
import '../theme/wakanda_background.dart';
import 'pattern_screen.dart';

class StepsChallengeScreen extends ConsumerStatefulWidget {
  final String? lockedPackageName;
  final int targetSteps;
  final int unlockDuration;
  final bool needsPattern;
  final String? lockPattern;

  const StepsChallengeScreen({
    super.key,
    this.lockedPackageName,
    required this.targetSteps,
    required this.unlockDuration,
    this.needsPattern = false,
    this.lockPattern,
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
      _status = 'Protocol Active';
    });

    if (_currentSteps >= widget.targetSteps) {
      _handleSuccess();
    }
  }

  void _onDone() => debugPrint("Finished tracking steps");

  void _onError(error) {
    setState(() {
      _status = 'Hardware Unavailable';
    });
  }

  void _handleSuccess() async {
    if (_isUnlocked) return;
    _isUnlocked = true;

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
        _isUnlocked = false;
        return;
      }
    }

    _subscription?.cancel();
    
    await ref.read(usageServiceProvider).incrementUnlockCount(
      type: ExerciseType.steps,
      reps: widget.targetSteps,
    );

    if (!mounted) return;
    _performUnlock();
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
            child: Container(
              decoration: ArcticTheme.frostDecoration,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ArcticTheme.frostBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_walk_rounded, size: 48, color: ArcticTheme.frostBlue),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "STEP CHALLENGE",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: ArcticTheme.deepNavy),
                  ),
                  const SizedBox(height: 8),
                  Text(_status, style: const TextStyle(color: ArcticTheme.softSlate, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 48),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          backgroundColor: ArcticTheme.iceWhite,
                          color: ArcticTheme.frostBlue,
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            "$_currentSteps",
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: ArcticTheme.deepNavy),
                          ),
                          Text(
                            "OF ${widget.targetSteps}",
                            style: const TextStyle(fontSize: 14, color: ArcticTheme.softSlate, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "${(progress * 100).toInt()}% COMPLETED",
                    style: const TextStyle(color: ArcticTheme.frostBlue, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("ABORT", style: TextStyle(color: ArcticTheme.softSlate, fontWeight: FontWeight.w800)),
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
