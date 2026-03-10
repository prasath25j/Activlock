class IntruderLog {
  final String id;
  final String packageName;
  final DateTime timestamp;
  final String imagePath;
  final String? reason; // e.g., "Pattern Failed", "PIN Failed"

  IntruderLog({
    required this.id,
    required this.packageName,
    required this.timestamp,
    required this.imagePath,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packageName': packageName,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'reason': reason,
    };
  }

  factory IntruderLog.fromJson(Map<String, dynamic> json) {
    return IntruderLog(
      id: json['id'],
      packageName: json['packageName'],
      timestamp: DateTime.parse(json['timestamp']),
      imagePath: json['imagePath'],
      reason: json['reason'],
    );
  }
}
