import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/intruder_log.dart';

class LogService {
  static const String _keyLogs = 'intruder_logs_list';

  Future<void> addLog(String packageName, String tempImagePath, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Move image from temp to permanent storage
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = "intruder_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final savedPath = p.join(appDir.path, fileName);
    
    await File(tempImagePath).copy(savedPath);
    
    // 2. Create Log Entry
    final log = IntruderLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      packageName: packageName,
      timestamp: DateTime.now(),
      imagePath: savedPath,
      reason: reason,
    );

    // 3. Save to List
    final logsJson = prefs.getStringList(_keyLogs) ?? [];
    logsJson.add(jsonEncode(log.toJson()));
    await prefs.setStringList(_keyLogs, logsJson);
  }

  Future<List<IntruderLog>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getStringList(_keyLogs) ?? [];
    
    final logs = logsJson.map((s) => IntruderLog.fromJson(jsonDecode(s))).toList();
    // Sort by newest first
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  Future<void> deleteLog(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getStringList(_keyLogs) ?? [];
    
    final updatedJson = <String>[];
    for (var s in logsJson) {
      final log = IntruderLog.fromJson(jsonDecode(s));
      if (log.id == id) {
        // Delete image file
        try {
          final file = File(log.imagePath);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      } else {
        updatedJson.add(s);
      }
    }
    await prefs.setStringList(_keyLogs, updatedJson);
  }

  Future<void> clearAllLogs() async {
    final logs = await getLogs();
    for (var log in logs) {
      try {
        final file = File(log.imagePath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLogs);
  }
}
