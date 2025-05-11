import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:pdf_utility_pro/models/history_item.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    // Mock history data
    final List<HistoryItem> historyItems = [
      HistoryItem(
        title: 'document.pdf',
        operation: loc.translate('image_to_pdf'),
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        filePath: '/path/to/document.pdf',
      ),
      HistoryItem(
        title: 'report.pdf',
        operation: loc.translate('merge_pdf'),
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        filePath: '/path/to/report.pdf',
      ),
      HistoryItem(
        title: 'scan.pdf',
        operation: loc.translate('pdf_scanner'),
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        filePath: '/path/to/scan.pdf',
      ),
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('history')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // Implement clear history
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(loc.translate('clear_history')),
                  content: Text(loc.translate('clear_history_confirm')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(loc.translate('cancel')),
                    ),
                    TextButton(
                      onPressed: () {
                        // Clear history logic
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loc.translate('history_cleared')),
                          ),
                        );
                      },
                      child: Text(loc.translate('clear')),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: historyItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.translate('no_history'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: historyItems.length,
              itemBuilder: (context, index) {
                final item = historyItems[index];
                return ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.operation} • ${_formatTimestamp(item.timestamp, context)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.open_in_new),
                              title: Text(loc.translate('open')),
                              onTap: () {
                                Navigator.pop(context);
                                // Open file logic
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.share),
                              title: Text(loc.translate('share')),
                              onTap: () {
                                Navigator.pop(context);
                                // Share file logic
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete),
                              title: Text(loc.translate('delete')),
                              onTap: () {
                                Navigator.pop(context);
                                // Delete file logic
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    // Open file logic
                  },
                );
              },
            ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp, BuildContext context) {
    final loc = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return loc.translate('just_now');
    } else if (difference.inHours < 1) {
      return loc.translate('minutes_ago').replaceAll('{0}', difference.inMinutes.toString());
    } else if (difference.inDays < 1) {
      return loc.translate('hours_ago').replaceAll('{0}', difference.inHours.toString());
    } else if (difference.inDays < 7) {
      return loc.translate('days_ago').replaceAll('{0}', difference.inDays.toString());
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
