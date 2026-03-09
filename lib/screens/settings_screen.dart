import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/modern_theme.dart';
import '../theme/wakanda_background.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = true;

  // Limit Values
  int _dailyUnlockLimit = 3;
  int _emergencyLimit = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final usage = ref.read(usageServiceProvider);
    final dLimit = await usage.getMaxDailyUnlocks();
    final eLimit = await usage.getMaxEmergencyUsage();

    if (mounted) {
      setState(() {
        _dailyUnlockLimit = dLimit;
        _emergencyLimit = eLimit;
        _isLoading = false;
      });
    }
  }

  void _handleSaveLimits() async {
    final usage = ref.read(usageServiceProvider);
    await usage.setMaxDailyUnlocks(_dailyUnlockLimit);
    await usage.setMaxEmergencyUsage(_emergencyLimit);
    _showSnack("Global Limits Updated!");
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? ModernTheme.accentPink : ModernTheme.primaryBlue,
      ),
    );
  }

  Widget _buildLimitSlider(String label, int value, int min, int max, Color accentColor, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("$value", style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: accentColor,
          inactiveColor: accentColor.withOpacity(0.1),
          onChanged: (val) => onChanged(val.toInt()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: ModernTheme.primaryBlue)));
    }

    final textColor = isDark ? ModernTheme.slate50 : ModernTheme.slate900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("SETTINGS"),
      ),
      body: WakandaBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 110, left: 16, right: 16, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION 1: APPEARANCE ---
              _buildSectionTitle("VISUAL INTERFACE", ModernTheme.primaryBlue),
              const SizedBox(height: 12),
              GlassContainer(
                opacity: 0.05,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SwitchListTile(
                  title: Text("Dark Mode", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  subtitle: Text("Toggle between light and dark themes", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)),
                  value: isDark,
                  activeColor: ModernTheme.primaryBlue,
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).toggleTheme(val);
                  },
                ),
              ),
              
              const SizedBox(height: 32),

              // --- SECTION 2: LIMITS ---
              _buildSectionTitle("GLOBAL CONSTRAINTS", ModernTheme.accentPink),
              const SizedBox(height: 12),
              GlassContainer(
                opacity: 0.05,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildLimitSlider("Daily Activity Unlocks", _dailyUnlockLimit, 1, 50, ModernTheme.accentCyan, (val) {
                      setState(() => _dailyUnlockLimit = val);
                    }),
                    const SizedBox(height: 20),
                    _buildLimitSlider("Emergency Bypasses", _emergencyLimit, 0, 10, ModernTheme.accentPink, (val) {
                      setState(() => _emergencyLimit = val);
                    }),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleSaveLimits,
                        child: const Text("SAVE GLOBAL LIMITS"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              // Information Note
              GlassContainer(
                color: ModernTheme.primaryBlue,
                opacity: 0.05,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: ModernTheme.primaryBlue.withOpacity(0.7)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Note: These are global defaults. You can override them for specific apps in their individual settings.",
                        style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 14),
      ),
    );
  }
}
