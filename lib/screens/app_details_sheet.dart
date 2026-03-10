import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/locked_app.dart';
import '../providers/app_providers.dart';
import '../theme/arctic_theme.dart';
import 'app_configuration_screen.dart';

class AppDetailsSheet extends ConsumerWidget {
  final LockedApp app;

  const AppDetailsSheet({super.key, required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: ArcticTheme.pureWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
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
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ArcticTheme.frostBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.shield_rounded, color: ArcticTheme.frostBlue, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.appName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ArcticTheme.deepNavy, letterSpacing: -0.5),
                    ),
                    Text(
                      app.packageName,
                      style: const TextStyle(fontSize: 12, color: ArcticTheme.softSlate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          _buildInfoRow(Icons.fitness_center_rounded, "Protocol", app.exerciseType.name.toUpperCase(), ArcticTheme.frostBlue),
          _buildInfoRow(Icons.repeat_rounded, "Target", "${app.targetReps} ${app.exerciseType.name == 'steps' ? 'Steps' : 'Reps'}", Colors.teal),
          _buildInfoRow(Icons.bolt_rounded, "Bypasses Used", "${app.usedExceptions}/${app.dailyExceptions}", ArcticTheme.alertRed),
          _buildInfoRow(Icons.lock_open_rounded, "Unlocks Today", "${app.usedUnlocks}/${app.dailyUnlockLimit}", Colors.orange),

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
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text("ADJUST"),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: ArcticTheme.alertRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: () {
                    ref.read(lockedAppsProvider.notifier).removeApp(app.packageName);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_sweep_rounded, color: ArcticTheme.alertRed),
                  tooltip: "Remove Protection",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color.withOpacity(0.8)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: ArcticTheme.softSlate, fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      ),
    );
  }
}
