class HistoryItem {
  final String title;
  final String operation;
  final DateTime timestamp;
  final String filePath;
  
  HistoryItem({
    required this.title,
    required this.operation,
    required this.timestamp,
    required this.filePath,
  });
}
