import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../providers/app_providers.dart';
import '../theme/modern_theme.dart';
import '../theme/wakanda_background.dart';
import '../widgets/glass_container.dart';
import 'app_configuration_screen.dart';

class AppSelectionScreen extends ConsumerStatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  ConsumerState<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends ConsumerState<AppSelectionScreen> {
  List<AppInfo> _installedApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApps();
  }

  Future<void> _fetchApps() async {
    List<AppInfo> apps = [];
    try {
      apps = await InstalledApps.getInstalledApps(
        withIcon: true,
        excludeSystemApps: false,
        excludeNonLaunchableApps: true,
      );
    } catch (e) {
      debugPrint("Error fetching apps: $e");
    }

    const myPackage = 'com.example.activ_lock';

    if (mounted) {
      setState(() {
        _installedApps = apps.where((app) => app.packageName != myPackage).toList();
        _installedApps.sort((a, b) => (a.name).compareTo(b.name));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockedApps = ref.watch(lockedAppsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : ModernTheme.slate900;
    final subTextColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text('SELECT TARGET', style: TextStyle(color: textColor, fontWeight: FontWeight.w900)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: WakandaBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: ModernTheme.primaryBlue))
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 110, 16, 20),
          itemCount: _installedApps.length,
          itemBuilder: (context, index) {
            final app = _installedApps[index];
            final isLocked = lockedApps.any((a) => a.packageName == app.packageName);
            final displayName = app.name;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassContainer(
                opacity: isDark 
                    ? (isLocked ? 0.15 : 0.05) 
                    : (isLocked ? 0.25 : 0.1), // Much higher opacity for visibility in Light mode
                color: isLocked ? ModernTheme.primaryBlue : (isDark ? Colors.white : ModernTheme.slate900),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: app.icon != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(app.icon!, width: 44, height: 44)
                        )
                      : Icon(Icons.android_rounded, color: ModernTheme.primaryBlue, size: 32),
                  title: Text(
                      displayName,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: isLocked ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 15
                      )
                  ),
                  subtitle: Text(app.packageName, style: TextStyle(fontSize: 10, color: subTextColor)),
                  trailing: Switch(
                    value: isLocked,
                    activeColor: ModernTheme.primaryBlue,
                    onChanged: (val) {
                      if (val) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppConfigurationScreen(
                              packageName: app.packageName,
                              appName: displayName,
                            ),
                          ),
                        );
                      } else {
                        ref.read(lockedAppsProvider.notifier).removeApp(app.packageName);
                      }
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
