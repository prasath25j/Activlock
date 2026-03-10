import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyUserPin = 'user_pin';
  static const String _keyIsFirstLaunch = 'is_first_launch';

  // Sleep Mode Keys
  static const String _keySleepModeEnabled = 'sleep_mode_enabled';
  static const String _keySleepStartHour = 'sleep_start_hour';
  static const String _keySleepStartMin = 'sleep_start_min';
  static const String _keySleepEndHour = 'sleep_end_hour';
  static const String _keySleepEndMin = 'sleep_end_min';

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsFirstLaunch) ?? true;
  }

  Future<void> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsFirstLaunch, false);
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserPin, pin);
  }

  Future<bool> verifyPin(String inputPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_keyUserPin);
    return storedPin == inputPin || (storedPin == null && inputPin == "1234");
  }

  Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyUserPin);
  }

  // --- Sleep Mode Methods ---

  Future<bool> isSleepModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySleepModeEnabled) ?? true;
  }

  Future<void> setSleepModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySleepModeEnabled, enabled);
  }

  Future<TimeOfDay> getSleepStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    return TimeOfDay(
      hour: prefs.getInt(_keySleepStartHour) ?? 22, // Default 10 PM
      minute: prefs.getInt(_keySleepStartMin) ?? 0,
    );
  }

  Future<void> setSleepStartTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySleepStartHour, time.hour);
    await prefs.setInt(_keySleepStartMin, time.minute);
  }

  Future<TimeOfDay> getSleepEndTime() async {
    final prefs = await SharedPreferences.getInstance();
    return TimeOfDay(
      hour: prefs.getInt(_keySleepEndHour) ?? 7, // Default 7 AM
      minute: prefs.getInt(_keySleepEndMin) ?? 0,
    );
  }

  Future<void> setSleepEndTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySleepEndHour, time.hour);
    await prefs.setInt(_keySleepEndMin, time.minute);
  }
}
