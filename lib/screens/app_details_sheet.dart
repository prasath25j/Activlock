import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/locked_app.dart';
import '../providers/app_providers.dart';
import '../theme/modern_theme.dart';
import '../widgets/glass_container.dart';
import 'app_configuration_screen.dart';

class AppDetailsSheet extends ConsumerWidget {
  final LockedApp app;

  const AppDetailsSheet({super.key, required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : ModernTheme.slate900;
    final subTextColor = isDark ? Colors.white60 : Colors.black54;

    return GlassContainer(
      blur: 25,
      opacity: isDark ? 0.2 : 0.8, // More solid in light mode for contrast
      color: isDark ? ModernTheme.slate800 : Colors.white,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ModernTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.shield_rounded, color: ModernTheme.primaryBlue, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.appName,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5),
                    ),
                    Text(
                      app.packageName,
                      style: TextStyle(fontSize: 12, color: subTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          _buildInfoRow(context, Icons.fitness_center_rounded, "Protocol", app.exerciseType.name.toUpperCase(), ModernTheme.primaryBlue),
          _buildInfoRow(context, Icons.repeat_rounded, "Target", "${app.targetReps} Reps", ModernTheme.accentCyan),
          _buildInfoRow(context, Icons.bolt_rounded, "Emergency Bypasses", "${app.usedExceptions}/${app.dailyExceptions}", ModernTheme.accentPink),
          _buildInfoRow(context, Icons.lock_open_rounded, "Daily Unlocks", "${app.usedUnlocks}/${app.dailyUnlockLimit}", Colors.orangeAccent),

          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppConfigurationScreen(
                          packageName: app.packageName,
                          appName: app.appName,
                          isEditing: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text("ADJUST"),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    ref.read(lockedAppsProvider.notifier).removeApp(app.packageName);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                  tooltip: "Remove Protection",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color.withOpacity(0.8)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }
}
