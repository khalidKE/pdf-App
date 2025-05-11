import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';

class ViewFilesScreen extends StatefulWidget {
  const ViewFilesScreen({Key? key}) : super(key: key);

  @override
  State<ViewFilesScreen> createState() => _ViewFilesScreenState();
}

class _ViewFilesScreenState extends State<ViewFilesScreen> {
  String _currentPath = '/storage/emulated/0';
  final List<FileSystemEntity> _mockFiles = [
    MockFile('document.pdf', FileType.pdf),
    MockFile('image.jpg', FileType.image),
    MockFile('spreadsheet.xlsx', FileType.excel),
    MockFile('presentation.pptx', FileType.powerpoint),
    MockFile('text.txt', FileType.text),
    MockFolder('Downloads'),
    MockFolder('Documents'),
    MockFolder('Pictures'),
  ];
  
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('view_files')),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              // Handle sort options
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Text(loc.translate('sort_by_name')),
              ),
              PopupMenuItem(
                value: 'date',
                child: Text(loc.translate('sort_by_date')),
              ),
              PopupMenuItem(
                value: 'size',
                child: Text(loc.translate('sort_by_size')),
              ),
              PopupMenuItem(
                value: 'type',
                child: Text(loc.translate('sort_by_type')),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                const Icon(Icons.folder),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentPath,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _mockFiles.length,
              itemBuilder: (context, index) {
                final file = _mockFiles[index];
                return ListTile(
                  leading: Icon(
                    file is MockFolder
                        ? Icons.folder
                        : _getIconForFileType((file as MockFile).type),
                  ),
                  title: Text(file.name),
                  subtitle: file is MockFolder
                      ? Text(loc.translate('folder'))
                      : Text(_getFileTypeString((file as MockFile).type, loc)),
                  trailing: file is MockFolder
                      ? const Icon(Icons.arrow_forward_ios, size: 16)
                      : IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            _showFileOptions(context, file as MockFile);
                          },
                        ),
                  onTap: () {
                    if (file is MockFolder) {
                      setState(() {
                        _currentPath = '$_currentPath/${file.name}';
                      });
                    } else {
                      // Open file logic
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Create new folder or upload file
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.create_new_folder),
                  title: Text(loc.translate('new_folder')),
                  onTap: () {
                    Navigator.pop(context);
                    // Create new folder logic
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: Text(loc.translate('upload_file')),
                  onTap: () {
                    Navigator.pop(context);
                    // Upload file logic
                  },
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _showFileOptions(BuildContext context, MockFile file) {
    final loc = AppLocalizations.of(context);
    
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
            leading: const Icon(Icons.edit),
            title: Text(loc.translate('rename')),
            onTap: () {
              Navigator.pop(context);
              // Rename file logic
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
  }
  
  IconData _getIconForFileType(FileType type) {
    switch (type) {
      case FileType.pdf:
        return Icons.picture_as_pdf;
      case FileType.image:
        return Icons.image;
      case FileType.excel:
        return Icons.table_chart;
      case FileType.powerpoint:
        return Icons.slideshow;
      case FileType.text:
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  String _getFileTypeString(FileType type, AppLocalizations loc) {
    switch (type) {
      case FileType.pdf:
        return 'PDF';
      case FileType.image:
        return loc.translate('image_file');
      case FileType.excel:
        return 'Excel';
      case FileType.powerpoint:
        return 'PowerPoint';
      case FileType.text:
        return loc.translate('text_file');
      default:
        return loc.translate('file');
    }
  }
}

abstract class FileSystemEntity {
  final String name;
  
  FileSystemEntity(this.name);
}

class MockFolder extends FileSystemEntity {
  MockFolder(String name) : super(name);
}

class MockFile extends FileSystemEntity {
  final FileType type;
  
  MockFile(String name, this.type) : super(name);
}

enum FileType {
  pdf,
  image,
  excel,
  powerpoint,
  text,
}
