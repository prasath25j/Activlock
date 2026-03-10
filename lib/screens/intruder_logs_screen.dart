import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../models/intruder_log.dart';
import '../theme/modern_theme.dart';
import '../theme/wakanda_background.dart';
import '../widgets/glass_container.dart';

class IntruderLogsScreen extends ConsumerStatefulWidget {
  const IntruderLogsScreen({super.key});

  @override
  ConsumerState<IntruderLogsScreen> createState() => _IntruderLogsScreenState();
}

class _IntruderLogsScreenState extends ConsumerState<IntruderLogsScreen> {
  List<IntruderLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await ref.read(logServiceProvider).getLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  void _clearAll() async {
    await ref.read(logServiceProvider).clearAllLogs();
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : ModernTheme.slate900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("INTRUDER LOGS", style: TextStyle(color: textColor, fontWeight: FontWeight.w900)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (_logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: ModernTheme.accentPink),
              onPressed: _clearAll,
              tooltip: "Clear All",
            )
        ],
      ),
      body: WakandaBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_front_rounded, size: 60, color: isDark ? Colors.white24 : Colors.black12),
                        const SizedBox(height: 16),
                        Text("NO INTRUDERS DETECTED", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 110, 16, 20),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GlassContainer(
                          opacity: isDark ? 0.1 : 0.2,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(log.imagePath),
                                  width: double.infinity,
                                  height: 250,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 200,
                                    color: isDark ? Colors.white10 : Colors.black12,
                                    child: const Icon(Icons.broken_image, color: Colors.white24),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log.packageName,
                                          style: const TextStyle(color: ModernTheme.accentCyan, fontWeight: FontWeight.w900, fontSize: 14),
                                        ),
                                        Text(
                                          DateFormat('MMM dd, yyyy • hh:mm a').format(log.timestamp),
                                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: isDark ? Colors.white38 : Colors.black38),
                                    onPressed: () async {
                                      await ref.read(logServiceProvider).deleteLog(log.id);
                                      _loadLogs();
                                    },
                                  )
                                ],
                              ),
                              const Divider(color: Colors.black12),
                              Text(
                                "Reason: ${log.reason}",
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
