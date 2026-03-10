import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/arctic_theme.dart';
import '../theme/wakanda_background.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    const textColor = ArcticTheme.deepNavy;

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
              _buildSectionTitle("VISUAL INTERFACE", ArcticTheme.frostBlue),
              const SizedBox(height: 12),
              Container(
                decoration: ArcticTheme.frostDecoration,
                child: ListTile(
                  title: const Text("Theme Mode", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Arctic Frost (Light Only)", style: TextStyle(color: ArcticTheme.softSlate, fontSize: 12)),
                  trailing: const Icon(Icons.ac_unit_rounded, color: ArcticTheme.frostBlue),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Information Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: ArcticTheme.frostDecoration,
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: ArcticTheme.frostBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Note: Security constraints are configured individually for each application.",
                        style: TextStyle(color: ArcticTheme.softSlate, fontSize: 11, fontWeight: FontWeight.w600),
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
