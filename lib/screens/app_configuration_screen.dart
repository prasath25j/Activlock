import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/locked_app.dart';
import '../models/exercise_type.dart';
import '../providers/app_providers.dart';
import '../theme/arctic_theme.dart';
import '../theme/wakanda_background.dart';
import 'pattern_screen.dart';

class AppConfigurationScreen extends ConsumerStatefulWidget {
  final String packageName;
  final String appName;
  final int initialStep;
  final bool isEditing; 

  const AppConfigurationScreen({
    super.key,
    required this.packageName,
    required this.appName,
    this.initialStep = 0,
    this.isEditing = false,
  });

  @override
  ConsumerState<AppConfigurationScreen> createState() => _AppConfigurationScreenState();
}

class _AppConfigurationScreenState extends ConsumerState<AppConfigurationScreen> {
  late int _currentStep;
  
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  
  ExerciseType _selectedExercise = ExerciseType.squat;
  int _targetReps = 15;
  
  int _maxExceptions = 3;
  int _dailyUnlockLimit = 10;
  int _unlockDuration = 15; // In minutes
  bool _needsPattern = false;
  String? _lockPattern;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _loadExistingSettings();
  }

  void _loadExistingSettings() {
    final apps = ref.read(lockedAppsProvider);
    try {
      final app = apps.firstWhere((a) => a.packageName == widget.packageName);
      _pinController.text = app.pinCode ?? "";
      _confirmPinController.text = app.pinCode ?? "";
      _selectedExercise = app.exerciseType;
      _targetReps = app.targetReps;
      _maxExceptions = app.dailyExceptions;
      _dailyUnlockLimit = app.dailyUnlockLimit;
      _unlockDuration = app.unlockDurationMinutes;
      _needsPattern = app.needsPattern;
      _lockPattern = app.lockPattern;
    } catch (e) {
      // Defaults
    }
  }

  void _nextStep() {
    setState(() => _currentStep++);
  }

  void _prevStep() {
    setState(() => _currentStep--);
  }

  void _finishSetup() {
    if (_pinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PINs do not match!"), backgroundColor: Colors.red));
      return;
    }
    if (_pinController.text.isNotEmpty && _pinController.text.length < 4) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN must be at least 4 digits"), backgroundColor: Colors.red));
      return;
    }
    if (_needsPattern && (_lockPattern == null || _lockPattern!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please set a pattern first!"), backgroundColor: Colors.red));
      return;
    }

    final existingApps = ref.read(lockedAppsProvider);
    int existingUsedEx = 0;
    int existingUsedUnlocks = 0;
    DateTime? existingReset;
    try {
       final oldApp = existingApps.firstWhere((a) => a.packageName == widget.packageName);
       existingUsedEx = oldApp.usedExceptions;
       existingUsedUnlocks = oldApp.usedUnlocks;
       existingReset = oldApp.lastResetDate;
    } catch (_) {}

    final app = LockedApp(
      packageName: widget.packageName,
      appName: widget.appName,
      isLocked: true,
      pinCode: _pinController.text,
      exerciseType: _selectedExercise,
      targetReps: _targetReps,
      dailyExceptions: _maxExceptions,
      usedExceptions: existingUsedEx,
      dailyUnlockLimit: _dailyUnlockLimit,
      usedUnlocks: existingUsedUnlocks,
      unlockDurationMinutes: _unlockDuration,
      needsPattern: _needsPattern,
      lockPattern: _lockPattern,
      lastResetDate: existingReset,
    );

    ref.read(lockedAppsProvider.notifier).addApp(app);
    Navigator.of(context).pop();
  }

  void _openPatternSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatternScreen(
          mode: PatternMode.setup,
          onComplete: (pattern) {
            setState(() {
              _lockPattern = pattern;
            });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pattern Configured!")));
          },
        ),
      ),
    );
  }

  Widget _buildStepContent(int stepIndex, Color textColor, Color subTextColor, Color inputFillColor) {
    switch (stepIndex) {
      case 0: // PIN
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isEditing) _buildSubTitle("Security PIN"),
            const SizedBox(height: 10),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              style: const TextStyle(color: ArcticTheme.deepNavy, letterSpacing: 5, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: "Security PIN",
                labelStyle: TextStyle(color: subTextColor),
                filled: true,
                fillColor: ArcticTheme.iceWhite,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: ArcticTheme.frostBlue),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              style: const TextStyle(color: ArcticTheme.deepNavy, letterSpacing: 5, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: "Confirm PIN",
                labelStyle: TextStyle(color: subTextColor),
                filled: true,
                fillColor: ArcticTheme.iceWhite,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.check_circle_outline_rounded, color: ArcticTheme.frostBlue),
              ),
            ),
          ],
        );
      case 1: // EXERCISE
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isEditing) _buildSubTitle("Physical Challenge"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: ArcticTheme.iceWhite, borderRadius: BorderRadius.circular(16)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ExerciseType>(
                  value: _selectedExercise,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: ArcticTheme.deepNavy, fontWeight: FontWeight.w800),
                  isExpanded: true,
                  onChanged: (val) => setState(() => _selectedExercise = val!),
                  items: ExerciseType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.name.toUpperCase()))).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSliderRow(_selectedExercise == ExerciseType.steps ? "Target Steps" : "Target Reps", _targetReps, textColor, ArcticTheme.frostBlue),
            Slider(
              value: _targetReps.toDouble(),
              min: 5, 
              max: _selectedExercise == ExerciseType.steps ? 5000 : 100, 
              activeColor: ArcticTheme.frostBlue,
              inactiveColor: ArcticTheme.frostBlue.withOpacity(0.1),
              onChanged: (val) => setState(() => _targetReps = val.round()),
            ),
          ],
        );
      case 2: // LIMITS
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isEditing) _buildSubTitle("Access Limits"),
            const SizedBox(height: 10),
            _buildSliderRow("Max Daily Unlocks", _dailyUnlockLimit, textColor, ArcticTheme.frostBlue),
            Slider(
              value: _dailyUnlockLimit.toDouble(),
              min: 1, max: 100, 
              activeColor: ArcticTheme.frostBlue,
              inactiveColor: ArcticTheme.frostBlue.withOpacity(0.1),
              onChanged: (val) => setState(() => _dailyUnlockLimit = val.round()),
            ),
            const SizedBox(height: 20),
            _buildSliderRow("Unlock Window (mins)", _unlockDuration, textColor, Colors.teal),
            Slider(
              value: _unlockDuration.toDouble(),
              min: 1, max: 120, 
              activeColor: Colors.teal,
              inactiveColor: Colors.teal.withOpacity(0.1),
              onChanged: (val) => setState(() => _unlockDuration = val.round()),
            ),
            const SizedBox(height: 20),
            _buildSliderRow("Emergency Bypasses", _maxExceptions, textColor, ArcticTheme.alertRed),
            Slider(
              value: _maxExceptions.toDouble(),
              min: 0, max: 20, 
              activeColor: ArcticTheme.alertRed,
              inactiveColor: ArcticTheme.alertRed.withOpacity(0.1),
              onChanged: (val) => setState(() => _maxExceptions = val.round()),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Multi-Stage Verification", style: TextStyle(color: ArcticTheme.deepNavy, fontWeight: FontWeight.w800, fontSize: 14)),
              subtitle: const Text("Require Pattern after exercise", style: TextStyle(color: ArcticTheme.softSlate, fontSize: 11)),
              value: _needsPattern,
              activeColor: ArcticTheme.frostBlue,
              onChanged: (val) => setState(() => _needsPattern = val),
            ),
            if (_needsPattern) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openPatternSetup,
                  icon: Icon(Icons.gesture_rounded, size: 18, color: _lockPattern != null ? Colors.teal : ArcticTheme.frostBlue),
                  label: Text(
                    _lockPattern != null ? "PATTERN SAVED" : "CONFIGURE PATTERN",
                    style: TextStyle(color: _lockPattern != null ? Colors.teal : ArcticTheme.frostBlue, fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _lockPattern != null ? Colors.teal : ArcticTheme.frostBlue, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSubTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Text(title, style: const TextStyle(color: ArcticTheme.frostBlue, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
    );
  }

  Widget _buildSliderRow(String label, int value, Color textColor, Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: ArcticTheme.deepNavy, fontWeight: FontWeight.w700, fontSize: 14)),
        Text("$value", style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 18)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const textColor = ArcticTheme.deepNavy;
    const subTextColor = ArcticTheme.softSlate;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text(widget.isEditing ? "ADJUST PROTOCOL" : "SETUP SECURITY"),
      ),
      body: WakandaBackground(
        child: SafeArea(
          child: widget.isEditing
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        decoration: ArcticTheme.frostDecoration,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildStepContent(0, textColor, subTextColor, ArcticTheme.iceWhite),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.black12)),
                            _buildStepContent(1, textColor, subTextColor, ArcticTheme.iceWhite),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.black12)),
                            _buildStepContent(2, textColor, subTextColor, ArcticTheme.iceWhite),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _finishSetup,
                          child: const Text("SAVE CHANGES"),
                        ),
                      ),
                    ],
                  ),
                )
              : Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(primary: ArcticTheme.frostBlue),
                  ),
                  child: Stepper(
                    type: StepperType.vertical,
                    currentStep: _currentStep,
                    onStepContinue: _currentStep < 2 ? _nextStep : _finishSetup,
                    onStepCancel: _currentStep > 0 ? _prevStep : null,
                    elevation: 0,
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: details.onStepContinue,
                                child: Text(_currentStep == 2 ? "FINISH" : "NEXT"),
                              ),
                            ),
                            if (_currentStep > 0) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: const BorderSide(color: ArcticTheme.frostBlue, width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: details.onStepCancel,
                                  child: const Text("BACK", style: TextStyle(color: ArcticTheme.frostBlue, fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    steps: [
                      _buildStep("ACCESS PIN", "Authentication", 0, textColor, subTextColor),
                      _buildStep("CHALLENGE", "Protocol Rules", 1, textColor, subTextColor),
                      _buildStep("RESTRICTIONS", "Limits & Logic", 2, textColor, subTextColor),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Step _buildStep(String title, String subtitle, int index, Color textColor, Color subTextColor) {
    return Step(
      title: Text(title, style: const TextStyle(color: ArcticTheme.deepNavy, fontWeight: FontWeight.w900, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: ArcticTheme.softSlate, fontSize: 11)),
      isActive: _currentStep >= index,
      state: _currentStep > index ? StepState.complete : StepState.indexed,
      content: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: ArcticTheme.frostDecoration,
        child: _buildStepContent(index, textColor, subTextColor, ArcticTheme.iceWhite),
      ),
    );
  }
}
