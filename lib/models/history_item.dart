class HistoryItem {
  final String title;
  final String filePath;
  final String operation;
  final DateTime timestamp;

  HistoryItem({
    required this.title,
    required this.filePath,
    required this.operation,
    required this.timestamp,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        title: json['title'],
        filePath: json['filePath'],
        operation: json['operation'],
        timestamp: DateTime.parse(json['timestamp']),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'filePath': filePath,
        'operation': operation,
        'timestamp': timestamp.toIso8601String(),
      };
}
