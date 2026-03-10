import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/modern_theme.dart';
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
        const SnackBar(content: Text("Please find 'ActivLock' and turn it ON")),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final textColor = isDark ? ModernTheme.slate50 : ModernTheme.slate900;
    final subTextColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [ModernTheme.primaryBlue, ModernTheme.accentPink]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [ModernTheme.primaryBlue, ModernTheme.accentPink],
              ).createShader(bounds),
              child: const Text(
                'ACTIVLOCK',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings').then((_) => _loadDashboardData()),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ModernTheme.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_moderator),
        label: const Text("PROTECT"),
        onPressed: () => Navigator.pushNamed(context, '/app_selection').then((_) => _loadDashboardData()),
      ),
      body: WakandaBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            color: ModernTheme.primaryBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isAccessibilityEnabled)
                    _buildAccessibilityWarning(),

                  const SizedBox(height: 10),
                  _buildSectionTitle("ACTIVITY SUMMARY", ModernTheme.primaryBlue),
                  const SizedBox(height: 12),
                  _buildActivityGrid(),

                  const SizedBox(height: 32),
                  _buildSectionTitle("ACTIVE PROTOCOLS", ModernTheme.accentPink),
                  const SizedBox(height: 12),
                  
                  if (lockedApps.isEmpty)
                    _buildEmptyState(textColor, subTextColor)
                  else
                    ...lockedApps.map((app) => _buildAppCard(app, textColor, subTextColor, isDark)).toList(),
                  
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(color: color, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12),
    );
  }

  Widget _buildAccessibilityWarning() {
    return GlassContainer(
      color: Colors.red,
      opacity: 0.1,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: _openAccessibilitySettings,
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Accessibility Service Required\nTap to enable protection",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.redAccent, size: 14),
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
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildStatCard("SQUATS", _totalStats['totalSquats']?.toString() ?? "0", Icons.accessibility_new_rounded, ModernTheme.primaryBlue),
            _buildStatCard("PUSHUPS", _totalStats['totalPushups']?.toString() ?? "0", Icons.fitness_center_rounded, ModernTheme.accentPink),
            _buildStatCard("STEPS", _totalStats['totalSteps']?.toString() ?? "0", Icons.directions_walk_rounded, ModernTheme.accentCyan),
            _buildStatCard("UNLOCKS", _totalStats['unlocks']?.toString() ?? "0", Icons.lock_open_rounded, Colors.orangeAccent),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => Navigator.pushNamed(context, '/intruder_logs').then((_) => _loadDashboardData()),
          child: GlassContainer(
            opacity: 0.1,
            color: ModernTheme.accentPink,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.camera_front_rounded, color: ModernTheme.accentPink),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "INTRUDER LOGS (${_totalStats['intruderCount'] ?? 0})",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.3), size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassContainer(
      opacity: 0.05,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAppCard(dynamic app, Color textColor, Color subTextColor, bool isDark) {
    final screenTime = _screenTimeMap[app.packageName] ?? Duration.zero;
    final timeStr = _formatDuration(screenTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        opacity: isDark ? 0.05 : 0.6,
        color: isDark ? Colors.white : Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ModernTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_person_outlined, color: ModernTheme.primaryBlue),
          ),
          title: Text(
            app.appName,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(app.packageName, style: TextStyle(fontSize: 10, color: subTextColor)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 12, color: ModernTheme.accentCyan.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text("Screen Time: $timeStr", style: TextStyle(fontSize: 11, color: ModernTheme.accentCyan, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("${app.usedUnlocks}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
              const Text("UNLOCKS", style: TextStyle(fontSize: 8, color: Colors.grey)),
            ],
          ),
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
          GlassContainer(
            color: ModernTheme.primaryBlue,
            opacity: 0.1,
            padding: const EdgeInsets.all(30),
            child: Icon(Icons.shield_outlined, size: 60, color: ModernTheme.primaryBlue.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'NO ACTIVE PROTOCOLS',
            style: TextStyle(fontWeight: FontWeight.w800, color: textColor.withOpacity(0.8)),
          ),
          const SizedBox(height: 8),
          Text('Start by securing an application', style: TextStyle(color: subTextColor)),
        ],
      ),
    );
  }
}
