import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../providers/app_providers.dart';
import '../theme/arctic_theme.dart';
import '../theme/wakanda_background.dart';
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
    
    const textColor = ArcticTheme.deepNavy;
    const subTextColor = ArcticTheme.softSlate;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text('SELECT TARGET'),
      ),
      body: WakandaBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: ArcticTheme.frostBlue))
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 110, 16, 20),
          itemCount: _installedApps.length,
          itemBuilder: (context, index) {
            final app = _installedApps[index];
            final isLocked = lockedApps.any((a) => a.packageName == app.packageName);
            final displayName = app.name;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: isLocked 
                  ? ArcticTheme.frostDecoration.copyWith(
                      border: Border.all(color: ArcticTheme.frostBlue, width: 1.5)
                    )
                  : ArcticTheme.frostDecoration,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: app.icon != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(app.icon!, width: 44, height: 44)
                        )
                      : const Icon(Icons.android_rounded, color: ArcticTheme.frostBlue, size: 32),
                  title: Text(
                      displayName,
                      style: const TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15
                      )
                  ),
                  subtitle: Text(app.packageName, style: const TextStyle(fontSize: 10, color: subTextColor)),
                  trailing: Switch(
                    value: isLocked,
                    activeColor: ArcticTheme.frostBlue,
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
