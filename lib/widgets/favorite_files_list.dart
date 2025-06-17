import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/file_provider.dart';
import 'package:pdf_utility_pro/models/file_item.dart';
import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class FavoriteFilesList extends StatelessWidget {
  const FavoriteFilesList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);
    final favoriteFiles = fileProvider.favoriteFiles;
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: favoriteFiles.length,
      itemBuilder: (context, index) {
        final file = favoriteFiles[index];
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
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.favorite,
                  color: Colors.red,
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
              title: Text('open'),
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
              title: Text('share'),
              onTap: () {
                Navigator.pop(context);
                Share.shareXFiles([XFile(file.path)], text: file.name);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: Text('remove_from_favorites'),
              onTap: () {
                Navigator.pop(context);
                fileProvider.toggleFavorite(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text('details'),
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
  
  void _showFileDetails(BuildContext context, FileItem file) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('file_details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'name', file.name),
            _buildDetailRow(context, 'type', _getFileTypeString(file.type)),
            _buildDetailRow(context, 'size', file.formattedSize),
            _buildDetailRow(context, 'location', file.path),
            _buildDetailRow(context, 'modified', dateFormat.format(file.dateModified)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'),
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
