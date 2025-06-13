import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/file_provider.dart';
import 'package:pdf_utility_pro/models/file_item.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class RecentFilesList extends StatelessWidget {
  const RecentFilesList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);
    final recentFiles = fileProvider.recentFiles;
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: recentFiles.length,
      itemBuilder: (context, index) {
        final file = recentFiles[index];
        return _buildFileCard(context, file, fileProvider);
      },
    );
  }
  
  Widget _buildFileCard(BuildContext context, FileItem file, FileProvider fileProvider) {
    final loc = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final isFavorite = fileProvider.isFavorite(file.path);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () {
          if (file.type == FileType.pdf) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReadPdfScreen(filePath: file.path),
              ),
            );
          } else {
            // Handle other file types
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  file.icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${file.formattedSize} • ${dateFormat.format(file.dateModified)}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                    ),
                    onPressed: () {
                      fileProvider.toggleFavorite(file);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showFileOptions(context, file, fileProvider);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showFileOptions(BuildContext context, FileItem file, FileProvider fileProvider) {
    final loc = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(loc.translate('open')),
              onTap: () {
                Navigator.pop(context);
                if (file.type == FileType.pdf) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReadPdfScreen(filePath: file.path),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(loc.translate('share')),
              onTap: () {
                Navigator.pop(context);
                Share.shareXFiles([XFile(file.path)], text: file.name);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text(loc.translate('delete')),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, file, fileProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(loc.translate('details')),
              onTap: () {
                Navigator.pop(context);
                _showFileDetails(context, file);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _confirmDelete(BuildContext context, FileItem file, FileProvider fileProvider) {
    final loc = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('confirm_delete')),
        content: Text(loc.translate('delete_file_confirm').replaceAll('{0}', file.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Delete the file
              final fileObj = File(file.path);
              fileObj.deleteSync();
              
              // Remove from recent files
              fileProvider.removeRecentFile(file.path);
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.translate('file_deleted')),
                ),
              );
            },
            child: Text(
              loc.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showFileDetails(BuildContext context, FileItem file) {
    final loc = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('file_details')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, loc.translate('name'), file.name),
            _buildDetailRow(context, loc.translate('type'), _getFileTypeString(file.type, loc)),
            _buildDetailRow(context, loc.translate('size'), file.formattedSize),
            _buildDetailRow(context, loc.translate('location'), file.path),
            _buildDetailRow(context, loc.translate('modified'), dateFormat.format(file.dateModified)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.translate('close')),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
  
  String _getFileTypeString(FileType type, AppLocalizations loc) {
    switch (type) {
      case FileType.pdf:
        return 'PDF';
      case FileType.image:
        return loc.translate('image_file');
      case FileType.excel:
        return 'Excel';
      case FileType.word:
        return 'Word';
      case FileType.text:
        return loc.translate('text_file');
      case FileType.other:
        return loc.translate('file');
    }
  }
}
