import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/locked_app.dart';
import '../models/exercise_type.dart';
import '../providers/app_providers.dart';
import '../theme/modern_theme.dart';
import '../theme/wakanda_background.dart';
import '../widgets/glass_container.dart';

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
    // Validation for PIN (if changed or new)
    if (_pinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PINs do not match!"), backgroundColor: Colors.red));
      return;
    }
    if (_pinController.text.isNotEmpty && _pinController.text.length < 4) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN must be at least 4 digits"), backgroundColor: Colors.red));
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
      lastResetDate: existingReset,
    );

    ref.read(lockedAppsProvider.notifier).addApp(app);
    Navigator.of(context).pop();
  }

  Widget _buildStepContent(int stepIndex, Color textColor, Color subTextColor, Color inputFillColor, bool isDark) {
    switch (stepIndex) {
      case 0: // PIN
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isEditing) _buildSubTitle("Security Code"),
            const SizedBox(height: 10),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              style: TextStyle(color: textColor, letterSpacing: 5),
              decoration: InputDecoration(
                labelText: "Enter 4-digit PIN",
                labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: Icon(Icons.lock_outline, color: ModernTheme.primaryBlue.withOpacity(0.7)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              style: TextStyle(color: textColor, letterSpacing: 5),
              decoration: InputDecoration(
                labelText: "Confirm PIN",
                labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: Icon(Icons.lock_clock_outlined, color: ModernTheme.primaryBlue.withOpacity(0.7)),
              ),
            ),
          ],
        );
      case 1: // EXERCISE
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isEditing) _buildSubTitle("Scanning Protocol"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: inputFillColor, borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ExerciseType>(
                  value: _selectedExercise,
                  dropdownColor: isDark ? ModernTheme.slate800 : Colors.white,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  isExpanded: true,
                  onChanged: (val) => setState(() => _selectedExercise = val!),
                  items: ExerciseType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.name.toUpperCase()))).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSliderRow(_selectedExercise == ExerciseType.steps ? "Target Steps" : "Target Reps", _targetReps, textColor, ModernTheme.primaryBlue),
            Slider(
              value: _targetReps.toDouble(),
              min: 5, 
              max: _selectedExercise == ExerciseType.steps ? 5000 : 100, 
              divisions: _selectedExercise == ExerciseType.steps ? 999 : 19,
              activeColor: ModernTheme.primaryBlue,
              inactiveColor: ModernTheme.primaryBlue.withOpacity(0.1),
              onChanged: (val) => setState(() => _targetReps = val.round()),
            ),
          ],
        );
      case 2: // LIMITS
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isEditing) _buildSubTitle("Usage Restrictions"),
            const SizedBox(height: 10),
            _buildSliderRow("Max Daily Unlocks", _dailyUnlockLimit, textColor, ModernTheme.accentCyan),
            Slider(
              value: _dailyUnlockLimit.toDouble(),
              min: 1, max: 100, divisions: 99,
              activeColor: ModernTheme.accentCyan,
              inactiveColor: ModernTheme.accentCyan.withOpacity(0.1),
              onChanged: (val) => setState(() => _dailyUnlockLimit = val.round()),
            ),
            const SizedBox(height: 20),
            _buildSliderRow("Unlock Duration (mins)", _unlockDuration, textColor, Colors.orangeAccent),
            Slider(
              value: _unlockDuration.toDouble(),
              min: 1, max: 120, divisions: 119,
              activeColor: Colors.orangeAccent,
              inactiveColor: Colors.orangeAccent.withOpacity(0.1),
              onChanged: (val) => setState(() => _unlockDuration = val.round()),
            ),
            const SizedBox(height: 20),
            _buildSliderRow("Emergency Bypasses", _maxExceptions, textColor, ModernTheme.accentPink),
            Slider(
              value: _maxExceptions.toDouble(),
              min: 0, max: 20, divisions: 20,
              activeColor: ModernTheme.accentPink,
              inactiveColor: ModernTheme.accentPink.withOpacity(0.1),
              onChanged: (val) => setState(() => _maxExceptions = val.round()),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSubTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Text(title, style: const TextStyle(color: ModernTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildSliderRow(String label, int value, Color textColor, Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        Text("$value", style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 18)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? ModernTheme.slate50 : ModernTheme.slate900;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;
    final inputFillColor = isDark ? ModernTheme.slate800.withOpacity(0.5) : Colors.grey[100]!;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text(widget.isEditing ? "ADJUST PROTOCOL" : "CONFIGURE SECURITY"),
      ),
      body: WakandaBackground(
        child: SafeArea(
          child: widget.isEditing
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildStepContent(0, textColor, subTextColor, inputFillColor, isDark),
                            const Divider(height: 40, color: Colors.white10),
                            _buildStepContent(1, textColor, subTextColor, inputFillColor, isDark),
                            const Divider(height: 40, color: Colors.white10),
                            _buildStepContent(2, textColor, subTextColor, inputFillColor, isDark),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
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
                    colorScheme: ColorScheme.dark(
                      primary: ModernTheme.primaryBlue,
                      onSurface: textColor.withOpacity(0.8),
                    ),
                  ),
                  child: Stepper(
                    type: StepperType.vertical,
                    currentStep: _currentStep,
                    onStepContinue: _currentStep < 2 ? _nextStep : _finishSetup,
                    onStepCancel: _currentStep > 0 ? _prevStep : null,
                    elevation: 0,
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: details.onStepContinue,
                                child: Text(_currentStep == 2 ? "ACTIVATE" : "NEXT"),
                              ),
                            ),
                            if (_currentStep > 0) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(color: ModernTheme.primaryBlue.withOpacity(0.5)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: details.onStepCancel,
                                  child: const Text("BACK", style: TextStyle(color: ModernTheme.primaryBlue)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    steps: [
                      _buildStep("Access PIN", "Security Code", 0, textColor, subTextColor, inputFillColor, isDark),
                      _buildStep("Scanning Protocol", "Activity Rules", 1, textColor, subTextColor, inputFillColor, isDark),
                      _buildStep("Usage Restrictions", "Limits & Bypasses", 2, textColor, subTextColor, inputFillColor, isDark),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Step _buildStep(String title, String subtitle, int index, Color textColor, Color subTextColor, Color inputFillColor, bool isDark) {
    return Step(
      title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: subTextColor, fontSize: 12)),
      isActive: _currentStep >= index,
      state: _currentStep > index ? StepState.complete : StepState.indexed,
      content: GlassContainer(
        padding: const EdgeInsets.all(16),
        opacity: 0.05,
        child: _buildStepContent(index, textColor, subTextColor, inputFillColor, isDark),
      ),
    );
  }
}
