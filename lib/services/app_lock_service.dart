import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/locked_app.dart';
import 'settings_service.dart';

class AppLockService {
  // Channel to talk to MainActivity.kt
  static const MethodChannel _channel = MethodChannel('com.activlock/native');

  /// Checks if the user has enabled the Accessibility Service in Android Settings
  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isAccessibilityServiceEnabled');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to check accessibility service: '${e.message}'.");
      return false;
    }
  }

  /// Opens the specific Android Accessibility Settings page
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      debugPrint("Failed to open settings: '${e.message}'.");
    }
  }

  /// Checks and requests the SYSTEM_ALERT_WINDOW permission
  Future<void> checkOverlayPermission() async {
    final status = await Permission.systemAlertWindow.status;
    if (!status.isGranted) {
      await Permission.systemAlertWindow.request();
    }
  }

  /// Saves the list of locked apps.
  /// It saves TWO lists:
  /// 1. 'native_locked_apps': A simple comma-separated string for the Android Service (efficient).
  /// 2. 'locked_apps_ui_list': A full JSON list for the Flutter UI (includes names, icons, etc).
  Future<void> saveLockedApps(List<LockedApp> apps) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Native List (Package Names only)
    final lockedPackageNames = apps.where((app) => app.isLocked).map((app) => app.packageName).toList();
    final nativeString = lockedPackageNames.join(',');
    await prefs.setString('native_locked_apps', nativeString);

    // 2. UI List (Full JSON)
    final appsJson = apps.map((app) => jsonEncode(app.toJson())).toList();
    await prefs.setStringList('locked_apps_ui_list', appsJson);
  }

  /// Removes an app from the locked_apps_ui_list and updates the native service.
  Future<void> removeApp(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final appsJson = prefs.getStringList('locked_apps_ui_list') ?? [];

    final updatedList = appsJson.where((str) {
      final app = LockedApp.fromJson(jsonDecode(str));
      return app.packageName != packageName;
    }).toList();

    await prefs.setStringList('locked_apps_ui_list', updatedList);
    
    // Notify native
    try {
      final List<String> packageNames = updatedList
          .map((str) => LockedApp.fromJson(jsonDecode(str)).packageName)
          .toList();
      await _channel.invokeMethod('updateLockedApps', {'packages': packageNames});
    } on PlatformException catch (e) {
      debugPrint("Failed to update native service: '${e.message}'.");
    }
  }

  /// Increments the used exceptions count for a specific app
  Future<void> incrementException(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final appsJson = prefs.getStringList('locked_apps_ui_list') ?? [];
    List<LockedApp> apps = appsJson.map((str) => LockedApp.fromJson(jsonDecode(str))).toList();

    int index = apps.indexWhere((a) => a.packageName == packageName);
    if (index != -1) {
      apps[index] = apps[index].copyWith(
        usedExceptions: apps[index].usedExceptions + 1,
        lastResetDate: DateTime.now(),
      );
      await saveLockedApps(apps);
    }
  }

  /// Increments the regular unlock count for a specific app
  Future<void> incrementUnlock(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final appsJson = prefs.getStringList('locked_apps_ui_list') ?? [];
    List<LockedApp> apps = appsJson.map((str) => LockedApp.fromJson(jsonDecode(str))).toList();

    int index = apps.indexWhere((a) => a.packageName == packageName);
    if (index != -1) {
      apps[index] = apps[index].copyWith(
        usedUnlocks: apps[index].usedUnlocks + 1,
        lastResetDate: DateTime.now(),
      );
      await saveLockedApps(apps);
    }
  }

  /// Retrieves the list of locked apps for the UI, handling daily resets
  Future<List<LockedApp>> getLockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    final appsJson = prefs.getStringList('locked_apps_ui_list') ?? [];

    List<LockedApp> apps = appsJson.map((str) => LockedApp.fromJson(jsonDecode(str))).toList();

    final now = DateTime.now();
    bool needsSave = false;

    List<LockedApp> updatedApps = [];
    for (var app in apps) {
      if (app.lastResetDate == null || !_isSameDay(app.lastResetDate!, now)) {
        // Reset counters for a new day
        updatedApps.add(app.copyWith(
          usedExceptions: 0,
          usedUnlocks: 0,
          lastResetDate: now,
        ));
        needsSave = true;
      } else {
        updatedApps.add(app);
      }
    }

    if (needsSave) {
      await saveLockedApps(updatedApps);
      return updatedApps;
    }

    return apps;
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  /// Adds or updates an app in the lock list
  Future<void> addLockedApp(LockedApp app) async {
    final currentApps = await getLockedApps();
    
    final index = currentApps.indexWhere((a) => a.packageName == app.packageName);
    if (index != -1) {
      // Update existing
      currentApps[index] = app;
    } else {
      // Add new
      currentApps.add(app);
    }
    await saveLockedApps(currentApps);
  }

  /// Removes an app from the lock list
  Future<void> removeLockedApp(String packageName) async {
    final currentApps = await getLockedApps();
    currentApps.removeWhere((a) => a.packageName == packageName);
    await saveLockedApps(currentApps);
  }

  /// Temporarily unlocks an app by setting an expiry timestamp.
  /// The native accessibility service will check this timestamp.
  Future<void> unlockAppTemporary(String packageName, {Duration duration = const Duration(minutes: 15)}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Calculate expiry time
    final expiry = DateTime.now().add(duration).millisecondsSinceEpoch;
    
    // Store expiry in SharedPreferences (Accessibility service will read this)
    await prefs.setInt('unlock_expiry_$packageName', expiry);
    
    // Ensure the app is in the native lock list (if it was removed by old logic)
    final currentApps = await getLockedApps();
    await saveLockedApps(currentApps);
  }

  /// Checks if Sleep Mode is currently active
  Future<bool> isSleepModeActive() async {
    final settings = SettingsService();
    if (!await settings.isSleepModeEnabled()) return false;

    final start = await settings.getSleepStartTime();
    final end = await settings.getSleepEndTime();
    final now = TimeOfDay.fromDateTime(DateTime.now());

    final nowTotal = now.hour * 60 + now.minute;
    final startTotal = start.hour * 60 + start.minute;
    final endTotal = end.hour * 60 + end.minute;

    if (startTotal <= endTotal) {
      // Same day (e.g., 10 PM to 11 PM)
      return nowTotal >= startTotal && nowTotal < endTotal;
    } else {
      // Spans midnight (e.g., 10 PM to 7 AM)
      return nowTotal >= startTotal || nowTotal < endTotal;
    }
  }
}
