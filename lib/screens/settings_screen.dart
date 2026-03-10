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
  bool _isSleepModeEnabled = true;
  TimeOfDay _sleepStartTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _sleepEndTime = const TimeOfDay(hour: 7, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = ref.read(settingsServiceProvider);
    final enabled = await settings.isSleepModeEnabled();
    final start = await settings.getSleepStartTime();
    final end = await settings.getSleepEndTime();

    if (mounted) {
      setState(() {
        _isSleepModeEnabled = enabled;
        _sleepStartTime = start;
        _sleepEndTime = end;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _sleepStartTime : _sleepEndTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: ModernTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: ModernTheme.slate800,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final settings = ref.read(settingsServiceProvider);
      if (isStart) {
        await settings.setSleepStartTime(picked);
        setState(() => _sleepStartTime = picked);
      } else {
        await settings.setSleepEndTime(picked);
        setState(() => _sleepEndTime = picked);
      }
    }
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

              // --- SECTION 2: SLEEP MODE ---
              _buildSectionTitle("SLEEP PROTOCOL", Colors.deepPurpleAccent),
              const SizedBox(height: 12),
              GlassContainer(
                opacity: 0.05,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Sleep Mode", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text("Prevent all usage during sleep hours", style: TextStyle(color: Colors.white54, fontSize: 11)),
                      value: _isSleepModeEnabled,
                      activeColor: Colors.deepPurpleAccent,
                      onChanged: (val) async {
                        await ref.read(settingsServiceProvider).setSleepModeEnabled(val);
                        setState(() => _isSleepModeEnabled = val);
                      },
                    ),
                    if (_isSleepModeEnabled) ...[
                      const Divider(color: Colors.white10, height: 24),
                      _buildTimeTile("Start Time", _sleepStartTime, () => _selectTime(true)),
                      const SizedBox(height: 12),
                      _buildTimeTile("End Time", _sleepEndTime, () => _selectTime(false)),
                    ],
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
                        "Note: Multi-stage security protocols (Pattern Lock) are now configured individually for each application.",
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

  Widget _buildTimeTile(String label, TimeOfDay time, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.deepPurpleAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
        ),
        child: Text(
          time.format(context),
          style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900),
        ),
      ),
      onTap: onTap,
    );
  }
}
