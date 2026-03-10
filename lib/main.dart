import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/modern_theme.dart';
import 'models/exercise_type.dart';
import 'screens/dashboard_screen.dart';
import 'providers/app_providers.dart';
import 'screens/app_selection_screen.dart';
import 'screens/lock_overlay_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/steps_challenge_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ActivLockApp()));
}

class ActivLockApp extends ConsumerStatefulWidget {
  const ActivLockApp({super.key});

  @override
  ConsumerState<ActivLockApp> createState() => _ActivLockAppState();
}

class _ActivLockAppState extends ConsumerState<ActivLockApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static const MethodChannel _channel = MethodChannel('com.activlock/native');
  String? _lastLockedPackage; // To prevent double navigation
  bool? _isFirstLaunch;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
    _configureMethodChannel();
  }

  Future<void> _checkFirstLaunch() async {
    final first = await ref.read(settingsServiceProvider).isFirstLaunch();
    if (mounted) {
      setState(() => _isFirstLaunch = first);
    }
  }

  void _configureMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "navigateToLockScreen") {
        final packageName = call.arguments as String?;
        if (packageName != null && packageName != _lastLockedPackage) {
          _lastLockedPackage = packageName;
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/lock_screen',
                  (route) => false,
              arguments: packageName
          );
        }
      }
    });

    // Check if we missed a lock request during startup
    _checkPendingLockRequest();
  }

  Future<void> _checkPendingLockRequest() async {
    try {
      final String? pendingPackage = await _channel.invokeMethod('getPendingLockedPackage');
      if (pendingPackage != null && pendingPackage.isNotEmpty && pendingPackage != _lastLockedPackage) {
        debugPrint("Found pending lock request for: $pendingPackage");
        _lastLockedPackage = pendingPackage;
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/lock_screen',
                (route) => false,
            arguments: pendingPackage
        );
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to check pending lock: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    if (_isFirstLaunch == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'ActivLock',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ModernTheme.lightTheme,
      darkTheme: ModernTheme.themeData,
      navigatorKey: navigatorKey,
      initialRoute: _isFirstLaunch! ? '/onboarding' : '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          _lastLockedPackage = null;
          return MaterialPageRoute(builder: (_) => const DashboardScreen());
        }
        else if (settings.name == '/onboarding') {
          _lastLockedPackage = null;
          return MaterialPageRoute(builder: (_) => const OnboardingScreen());
        }
        else if (settings.name == '/app_selection') {
          return MaterialPageRoute(builder: (_) => const AppSelectionScreen());
        }
        else if (settings.name == '/settings') {
          return MaterialPageRoute(builder: (_) => const SettingsScreen());
        }
        else if (settings.name == '/lock_screen') {
          final args = settings.arguments;
          final packageName = args is String ? args : null;
          return MaterialPageRoute(builder: (_) => LockOverlayScreen(lockedPackageName: packageName));
        }
        else if (settings.name == '/workout') {
          final args = settings.arguments;
          String? packageName;
          ExerciseType type = ExerciseType.squat;
          int targetReps = 10;
          int unlockDuration = 15;
          bool needsPattern = false;
          String? lockPattern;

          if (args is Map<String, dynamic>) {
            packageName = args['package'];
            if (args['type'] is ExerciseType) {
              type = args['type'];
            }
            if (args['targetReps'] is int) {
              targetReps = args['targetReps'];
            }
            if (args['unlockDuration'] is int) {
              unlockDuration = args['unlockDuration'];
            }
            if (args['needsPattern'] is bool) {
              needsPattern = args['needsPattern'];
            }
            if (args['lockPattern'] is String) {
              lockPattern = args['lockPattern'];
            }
          } else if (args is String) {
            packageName = args;
          }

          return MaterialPageRoute(builder: (_) => WorkoutScreen(
              lockedPackageName: packageName,
              exerciseType: type,
              targetReps: targetReps,
              unlockDuration: unlockDuration,
              needsPattern: needsPattern,
              lockPattern: lockPattern,
          ));
        }
        else if (settings.name == '/steps_challenge') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(builder: (_) => StepsChallengeScreen(
            lockedPackageName: args['package'],
            targetSteps: args['targetSteps'],
            unlockDuration: args['unlockDuration'],
            needsPattern: args['needsPattern'] ?? false,
            lockPattern: args['lockPattern'],
          ));
        }
        return null;
      },
    );
  }
}
