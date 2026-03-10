import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/arctic_theme.dart';
import '../theme/wakanda_background.dart';
import '../widgets/glass_container.dart';
import 'app_details_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with WidgetsBindingObserver {
  bool _isAccessibilityEnabled = false;
  Map<String, int> _totalStats = {};
  Map<String, Duration> _screenTimeMap = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
    _loadDashboardData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkAllPermissions();
        _loadDashboardData();
      });
    }
  }

  Future<void> _checkAllPermissions() async {
    final isEnabled = await ref.read(appLockServiceProvider).isAccessibilityServiceEnabled();
    if (mounted) {
      setState(() {
        _isAccessibilityEnabled = isEnabled;
      });
    }
  }

  Future<void> _loadDashboardData() async {
    final usageService = ref.read(usageServiceProvider);
    final logService = ref.read(logServiceProvider);
    
    final stats = await usageService.getStats();
    final logs = await logService.getLogs();
    stats['intruderCount'] = logs.length;
    
    final lockedApps = ref.read(lockedAppsProvider);
    final packageNames = lockedApps.map((a) => a.packageName).toList();
    final screenTime = await usageService.getAppScreenTime(packageNames);

    if (mounted) {
      setState(() {
        _totalStats = stats;
        _screenTimeMap = screenTime;
        _isLoadingStats = false;
      });
    }
  }

  void _openAccessibilitySettings() async {
    await ref.read(appLockServiceProvider).openAccessibilitySettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Find 'ActivLock' and turn it ON")),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lockedApps = ref.watch(lockedAppsProvider);
    
    const textColor = ArcticTheme.deepNavy;
    const subTextColor = ArcticTheme.softSlate;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ArcticTheme.frostBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'ACTIVLOCK',
              style: TextStyle(color: ArcticTheme.deepNavy, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: ArcticTheme.softSlate),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: ArcticTheme.softSlate),
            onPressed: () => Navigator.pushNamed(context, '/settings').then((_) => _loadDashboardData()),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ArcticTheme.deepNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_moderator),
        label: const Text("PROTECT"),
        onPressed: () => Navigator.pushNamed(context, '/app_selection').then((_) => _loadDashboardData()),
      ),
      body: WakandaBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            color: ArcticTheme.frostBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isAccessibilityEnabled)
                    _buildAccessibilityWarning(),

                  const SizedBox(height: 10),
                  _buildSectionTitle("ACTIVITY SUMMARY"),
                  const SizedBox(height: 12),
                  _buildActivityGrid(),

                  const SizedBox(height: 32),
                  _buildSectionTitle("ACTIVE PROTOCOLS"),
                  const SizedBox(height: 12),
                  
                  if (lockedApps.isEmpty)
                    _buildEmptyState(textColor, subTextColor)
                  else
                    ...lockedApps.map((app) => _buildAppCard(app, textColor, subTextColor)).toList(),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: ArcticTheme.deepNavy, fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 13),
    );
  }

  Widget _buildAccessibilityWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: ArcticTheme.alertRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ArcticTheme.alertRed.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: _openAccessibilitySettings,
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: ArcticTheme.alertRed),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Service Inactive\nTap to enable protection",
                style: TextStyle(color: ArcticTheme.alertRed, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: ArcticTheme.alertRed, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityGrid() {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard("SQUATS", _totalStats['totalSquats']?.toString() ?? "0", Icons.accessibility_new_rounded, ArcticTheme.frostBlue),
            _buildStatCard("PUSHUPS", _totalStats['totalPushups']?.toString() ?? "0", Icons.fitness_center_rounded, Colors.indigoAccent),
            _buildStatCard("STEPS", _totalStats['totalSteps']?.toString() ?? "0", Icons.directions_walk_rounded, Colors.teal),
            _buildStatCard("UNLOCKS", _totalStats['unlocks']?.toString() ?? "0", Icons.lock_open_rounded, Colors.amber),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => Navigator.pushNamed(context, '/intruder_logs').then((_) => _loadDashboardData()),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: ArcticTheme.frostDecoration,
            child: Row(
              children: [
                const Icon(Icons.camera_front_rounded, color: ArcticTheme.alertRed),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "INTRUDER LOGS (${_totalStats['intruderCount'] ?? 0})",
                    style: const TextStyle(color: ArcticTheme.deepNavy, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: ArcticTheme.softSlate, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ArcticTheme.frostDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ArcticTheme.deepNavy)),
          Text(label, style: const TextStyle(fontSize: 10, color: ArcticTheme.softSlate, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAppCard(dynamic app, Color textColor, Color subTextColor) {
    final screenTime = _screenTimeMap[app.packageName] ?? Duration.zero;
    final timeStr = _formatDuration(screenTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: ArcticTheme.frostDecoration,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ArcticTheme.frostBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_rounded, color: ArcticTheme.frostBlue, size: 24),
          ),
          title: Text(
            app.appName,
            style: const TextStyle(fontWeight: FontWeight.w800, color: ArcticTheme.deepNavy),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(app.packageName, style: const TextStyle(fontSize: 10, color: ArcticTheme.softSlate)),
              const SizedBox(height: 4),
              Text("Usage: $timeStr", style: const TextStyle(fontSize: 11, color: ArcticTheme.frostBlue, fontWeight: FontWeight.w700)),
            ],
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: ArcticTheme.softSlate),
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => AppDetailsSheet(app: app),
            ).then((_) => _loadDashboardData());
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
    }
    return "${duration.inMinutes}m";
  }

  Widget _buildEmptyState(Color textColor, Color subTextColor) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: ArcticTheme.frostBlue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_outlined, size: 60, color: ArcticTheme.frostBlue.withOpacity(0.3)),
          ),
          const SizedBox(height: 24),
          const Text(
            'SAFE & SECURE',
            style: TextStyle(fontWeight: FontWeight.w900, color: ArcticTheme.deepNavy, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text('Protect an application to start', style: TextStyle(color: ArcticTheme.softSlate)),
        ],
      ),
    );
  }
}
