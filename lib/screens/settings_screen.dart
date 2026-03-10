import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/modern_theme.dart';
import '../theme/wakanda_background.dart';
import '../widgets/glass_container.dart';

import 'package:local_auth/local_auth.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isBiometricEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricHardware();
  }

  Future<void> _checkBiometricHardware() async {
    bool canCheck = false;
    List<BiometricType> types = [];
    try {
      canCheck = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (canCheck) {
        types = await _auth.getAvailableBiometrics();
      }
    } catch (e) {
      debugPrint("Biometric Check Error: $e");
    }

    if (mounted) {
      setState(() {
        _canCheckBiometrics = canCheck;
        _availableBiometrics = types;
      });
    }
  }

  Future<void> _testBiometrics() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Testing biometric sensor for ActivLock',
        biometricOnly: true,
      );
      if (authenticated) {
        _showSnack("Biometric Sensor Verified!", isError: false);
      }
    } catch (e) {
      _showSnack("Verification Failed: $e", isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? ModernTheme.accentPink : ModernTheme.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
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

              // --- SECTION 2: SECURITY & BIOMETRICS ---
              _buildSectionTitle("SECURITY & BIOMETRICS", ModernTheme.accentCyan),
              const SizedBox(height: 12),
              GlassContainer(
                opacity: 0.05,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.fingerprint_rounded, color: _canCheckBiometrics ? ModernTheme.accentCyan : Colors.redAccent),
                      title: Text(
                        _canCheckBiometrics ? "Hardware Supported" : "Hardware Not Detected",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _canCheckBiometrics 
                          ? "Available: ${_availableBiometrics.map((e) => e.name.toUpperCase()).join(', ')}"
                          : "Please set up fingerprints in Android Settings",
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      trailing: _canCheckBiometrics 
                        ? TextButton(
                            onPressed: _testBiometrics, 
                            child: const Text("TEST", style: TextStyle(color: ModernTheme.accentCyan))
                          )
                        : null,
                    ),
                    if (_canCheckBiometrics) ...[
                      const Divider(color: Colors.white10, height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Global Biometrics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text("Use system fingerprints for multi-stage verification", style: TextStyle(color: Colors.white54, fontSize: 11)),
                        value: _isBiometricEnabled,
                        activeColor: ModernTheme.accentCyan,
                        onChanged: (val) => setState(() => _isBiometricEnabled = val),
                      ),
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
                        "Note: Security constraints are now configured individually for each application.",
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
