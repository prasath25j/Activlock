import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';
import '../models/exercise_type.dart';

class UsageService {
  static const String _keyLastResetDate = 'last_reset_date';
  static const String _keyDailyUnlockCount = 'daily_unlock_count';
  static const String _keyDailyEmergencyCount = 'daily_emergency_count';

  static const String _keyTotalSquats = 'total_squats';
  static const String _keyTotalPushups = 'total_pushups';
  static const String _keyTotalSteps = 'total_steps_unlock';

  Future<void> _checkAndResetDailyCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_keyLastResetDate);
    final todayStr = DateTime.now().toIso8601String().split('T').first;

    if (lastDateStr != todayStr) {
      // It's a new day, reset counters
      await prefs.setString(_keyLastResetDate, todayStr);
      await prefs.setInt(_keyDailyUnlockCount, 0);
      await prefs.setInt(_keyDailyEmergencyCount, 0);
    }
  }

  // --- LOGIC ---

  Future<void> incrementUnlockCount({ExerciseType? type, int reps = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyDailyUnlockCount) ?? 0;
    await prefs.setInt(_keyDailyUnlockCount, count + 1);

    if (type != null && reps > 0) {
      if (type == ExerciseType.squat) {
        final current = prefs.getInt(_keyTotalSquats) ?? 0;
        await prefs.setInt(_keyTotalSquats, current + reps);
      } else if (type == ExerciseType.pushup) {
        final current = prefs.getInt(_keyTotalPushups) ?? 0;
        await prefs.setInt(_keyTotalPushups, current + reps);
      } else if (type == ExerciseType.steps) {
        final current = prefs.getInt(_keyTotalSteps) ?? 0;
        await prefs.setInt(_keyTotalSteps, current + reps);
      }
    }
  }

  Future<void> incrementEmergencyCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyDailyEmergencyCount) ?? 0;
    await prefs.setInt(_keyDailyEmergencyCount, count + 1);
  }

  Future<Map<String, int>> getStats() async {
    await _checkAndResetDailyCounts();
    final prefs = await SharedPreferences.getInstance();
    return {
      'unlocks': prefs.getInt(_keyDailyUnlockCount) ?? 0,
      'emergency': prefs.getInt(_keyDailyEmergencyCount) ?? 0,
      'totalSquats': prefs.getInt(_keyTotalSquats) ?? 0,
      'totalPushups': prefs.getInt(_keyTotalPushups) ?? 0,
      'totalSteps': prefs.getInt(_keyTotalSteps) ?? 0,
    };
  }

  Future<Map<String, Duration>> getAppScreenTime(List<String> packageNames) async {
    DateTime endDate = DateTime.now();
    DateTime startDate = DateTime(endDate.year, endDate.month, endDate.day);

    Map<String, Duration> screenTimeMap = {};

    try {
      bool hasPermission = await UsageStats.checkUsagePermission() ?? false;
      if (!hasPermission) {
        await UsageStats.grantUsagePermission();
        hasPermission = await UsageStats.checkUsagePermission() ?? false;
      }

      if (hasPermission) {
        List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);
        for (var info in usageStats) {
          final pkgName = info.packageName;
          if (pkgName != null && packageNames.contains(pkgName)) {
            final duration = Duration(milliseconds: int.parse(info.totalTimeInForeground ?? '0'));
            if (screenTimeMap.containsKey(pkgName)) {
              screenTimeMap[pkgName] = screenTimeMap[pkgName]! + duration;
            } else {
              screenTimeMap[pkgName] = duration;
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching usage stats: $e");
    }

    return screenTimeMap;
  }
}
