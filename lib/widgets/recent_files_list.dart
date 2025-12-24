import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/file_provider.dart';
import 'package:pdf_utility_pro/models/file_item.dart';
import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf_utility_pro/providers/history_provider.dart';
import 'package:pdf_utility_pro/models/history_item.dart';

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
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final isFavorite = fileProvider.isFavorite(file.path);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () async {
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
              title: const Text('Open'),
              onTap: () async {
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
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                Share.shareXFiles([XFile(file.path)], text: file.name);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () async {
                Navigator.pop(context);
                await _showRenameDialog(context, file, fileProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, file, fileProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Details'),
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
  
  Future<void> _showRenameDialog(BuildContext context, FileItem file, FileProvider fileProvider) async {
    final TextEditingController _renameController = TextEditingController(text: file.name.replaceAll('.pdf', ''));
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: _renameController,
          decoration: const InputDecoration(
            labelText: 'New File Name',
            hintText: 'Enter new file name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _renameController.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != file.name) {
      final newName = result.endsWith('.pdf') ? result : result + '.pdf';
      final newPath = file.path.replaceAll(file.name, newName);
      final fileObj = File(file.path);
      try {
        await fileObj.rename(newPath);
        fileProvider.renameRecentFile(file.path, newPath, newName);

        // Add to history
        final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
        historyProvider.addHistoryItem(
          HistoryItem(
            title: 'Renamed "${file.name}" to "$newName"',
            filePath: newPath,
            operation: 'Rename File',
            timestamp: DateTime.now(),
          ),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File renamed to $newName')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rename file: $e')),
        );
      }
    }
  }
  
  void _confirmDelete(BuildContext context, FileItem file, FileProvider fileProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${file.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
                const SnackBar(
                  content: Text('File deleted successfully'),
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showFileDetails(BuildContext context, FileItem file) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'Name', file.name),
            _buildDetailRow(context, 'Type', _getFileTypeString(file.type)),
            _buildDetailRow(context, 'Size', file.formattedSize),
            _buildDetailRow(context, 'Location', file.path),
            _buildDetailRow(context, 'Modified', dateFormat.format(file.dateModified)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
  
  String _getFileTypeString(FileType type) {
    switch (type) {
      case FileType.pdf:
        return 'PDF';
      case FileType.image:
        return 'Image File';
      case FileType.excel:
        return 'Excel';
      case FileType.word:
        return 'Word';
      case FileType.text:
        return 'Text File';
      case FileType.other:
        return 'File';
    }
  }
}
