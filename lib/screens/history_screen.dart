import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/providers/history_provider.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:pdf_utility_pro/models/history_item.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final historyProvider =
          Provider.of<HistoryProvider>(context, listen: false);
      historyProvider.loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final historyProvider = Provider.of<HistoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('history')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: historyProvider.historyItems.isEmpty
                ? null
                : () {
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
                              final historyProvider =
                                  Provider.of<HistoryProvider>(context,
                                      listen: false);
                              historyProvider.clearHistory();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text(loc.translate('history_cleared')),
                                  backgroundColor: Colors.green,
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
      body: historyProvider.historyItems.isEmpty
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
              itemCount: historyProvider.historyItems.length,
              itemBuilder: (context, index) {
                final item = historyProvider.historyItems[index];
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
                                _openFile(item.filePath);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.share),
                              title: Text(loc.translate('share')),
                              onTap: () {
                                Navigator.pop(context);
                                _shareFile(item.filePath, item.title);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete),
                              title: Text(loc.translate('delete')),
                              onTap: () {
                                Navigator.pop(context);
                                _deleteHistoryItem(index);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    _openFile(item.filePath);
                  },
                );
              },
            ),
    );
  }

  void _openFile(String filePath) {
    final historyProvider =
        Provider.of<HistoryProvider>(context, listen: false);
    historyProvider.addHistoryItem(
      HistoryItem(
        title: p.basename(filePath),
        filePath: filePath,
        operation: 'open_pdf',
        timestamp: DateTime.now(),
      ),
    );
    // ثم افتح الملف فعلياً أو انتقل لشاشة القراءة
    // Replace the following with your actual PDF viewer screen
    // For example:

    Navigator.push(context, MaterialPageRoute(builder: (context) => ReadPdfScreen(filePath: filePath)));
  }

  void _shareFile(String filePath, String title) {
    final file = File(filePath);
    if (file.existsSync()) {
      Share.shareXFiles([XFile(filePath)], text: title);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context).translate('file_not_found')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteHistoryItem(int index) {
    final historyProvider =
        Provider.of<HistoryProvider>(context, listen: false);
    historyProvider.removeHistoryItem(index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).translate('item_deleted')),
        backgroundColor: Colors.green,
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
      return loc
          .translate('minutes_ago')
          .replaceFirst('{0}', difference.inMinutes.toString());
    } else if (difference.inDays < 1) {
      return loc
          .translate('hours_ago')
          .replaceFirst('{0}', difference.inHours.toString());
    } else if (difference.inDays < 7) {
      return loc
          .translate('days_ago')
          .replaceFirst('{0}', difference.inDays.toString());
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
