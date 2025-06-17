import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf_utility_pro/utils/permission_handler.dart';

class ViewFilesScreen extends StatefulWidget {
  const ViewFilesScreen({super.key});

  @override
  State<ViewFilesScreen> createState() => _ViewFilesScreenState();
}

class _ViewFilesScreenState extends State<ViewFilesScreen>
    with SingleTickerProviderStateMixin {
  String? _currentPath;
  List<FileSystemEntity> _files = [];
  List<FileSystemEntity> _filteredFiles = [];
  bool _isLoading = true;
  String _sortBy = 'name';
  bool _sortAscending = true;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDirectory();
    _searchController.addListener(_filterFiles);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeDirectory() async {
    if (!await AppPermissionHandler.requestStoragePermission()) {
      if (!mounted) return;
      _showSnackBar(
          'Storage permission denied. Please grant permission to access files.',
          Colors.red);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final appDirPath = await AppPermissionHandler.getAppDirectory();
      setState(() {
        _currentPath = appDirPath;
        _loadFiles();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error loading directory: ${e.toString()}', Colors.red);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadFiles() {
    if (_currentPath == null) return;
    final dir = Directory(_currentPath!);
    setState(() {
      _isLoading = true;
    });

    try {
      final entities = dir.listSync(recursive: false, followLinks: false);
      setState(() {
        // Only show files, not directories
        _files = entities.where((e) => e is File).toList();
        _filterFiles();
        _sortFiles();
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error loading files: ${e.toString()}', Colors.red);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterFiles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFiles = _files.where((file) {
        final name = file.path.split('/').last.toLowerCase();
        return name.contains(query);
      }).toList();
      _sortFiles();
    });
  }

  void _sortFiles() {
    _filteredFiles.sort((a, b) {
      final aName = a.path.split('/').last.toLowerCase();
      final bName = b.path.split('/').last.toLowerCase();

      switch (_sortBy) {
        case 'name':
          return _sortAscending
              ? aName.compareTo(bName)
              : bName.compareTo(aName);
        case 'date':
          try {
            final aStat = a.statSync();
            final bStat = b.statSync();
            return _sortAscending
                ? aStat.modified.compareTo(bStat.modified)
                : bStat.modified.compareTo(aStat.modified);
          } catch (e) {
            return 0;
          }
        case 'size':
          if (a is File && b is File) {
            try {
              final aStat = a.statSync();
              final bStat = b.statSync();
              return _sortAscending
                  ? aStat.size.compareTo(bStat.size)
                  : bStat.size.compareTo(aStat.size);
            } catch (e) {
              return 0;
            }
          }
          return 0;
        default:
          return 0;
      }
    });
  }

  Future<void> _uploadFile() async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: fp.FileType.any,
      );

      if (result != null && _currentPath != null) {
        int successCount = 0;
        int failCount = 0;

        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            try {
              final file = File(platformFile.path!);
              final newPath = '$_currentPath/${platformFile.name}';

              if (await File(newPath).exists()) {
                final overwrite = await _showOverwriteDialog(platformFile.name);
                if (!overwrite) continue;
              }

              await file.copy(newPath);
              successCount++;
            } catch (e) {
              failCount++;
            }
          }
        }

        _loadFiles();
        if (!mounted) return;

        if (successCount > 0) {
          _showSnackBar(
            '$successCount file${successCount > 1 ? 's' : ''} uploaded successfully',
            Colors.green,
          );
        }
        if (failCount > 0) {
          _showSnackBar(
            '$failCount file${failCount > 1 ? 's' : ''} failed to upload',
            Colors.red,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error uploading files: ${e.toString()}', Colors.red);
    }
  }

  Future<bool> _showOverwriteDialog(String fileName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Already Exists'),
        content: Text(
            'A file named "$fileName" already exists. Do you want to overwrite it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Overwrite'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showFileOptions(BuildContext context, File file) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(_getIconForFile(file), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.path.split('/').last,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _getFileInfo(file),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            _buildOptionTile(
              icon: Icons.open_in_new,
              title: 'Open',
              onTap: () {
                Navigator.pop(context);
                _openFile(file);
              },
            ),
            _buildOptionTile(
              icon: Icons.share,
              title: 'Share',
              onTap: () {
                Navigator.pop(context);
                _shareFile(file);
              },
            ),
            _buildOptionTile(
              icon: Icons.edit,
              title: 'Rename',
              onTap: () {
                Navigator.pop(context);
                _renameFile(file);
              },
            ),
            _buildOptionTile(
              icon: Icons.info_outline,
              title: 'Properties',
              onTap: () {
                Navigator.pop(context);
                _showFileProperties(file);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete,
              title: 'Delete',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _deleteFile(file);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  void _openFile(File file) {
    if (file.path.endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReadPdfScreen(filePath: file.path),
        ),
      );
    } else {
      _showSnackBar('Unsupported file type for opening', Colors.orange);
    }
  }

  void _shareFile(File file) {
    Share.shareXFiles([XFile(file.path)]);
  }

  void _showFileProperties(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Properties'),
        content: FutureBuilder<FileStat>(
          future: file.stat(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final stat = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPropertyRow('Name', file.path.split('/').last),
                  _buildPropertyRow('Type', _getFileTypeString(file)),
                  _buildPropertyRow('Size', _formatFileSize(stat.size)),
                  _buildPropertyRow('Modified', _formatDate(stat.modified)),
                  _buildPropertyRow('Created', _formatDate(stat.accessed)),
                  _buildPropertyRow('Path', file.path),
                ],
              );
            }
            return const CircularProgressIndicator();
          },
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

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _renameFile(File file) async {
    final currentName = file.path.split('/').last;
    final controller = TextEditingController(text: currentName);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'File Name',
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
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (result != null &&
        result.isNotEmpty &&
        result != currentName &&
        _currentPath != null) {
      try {
        final newPath = '$_currentPath/$result';
        if (await File(newPath).exists()) {
          _showSnackBar('A file with this name already exists', Colors.orange);
          return;
        }
        await file.rename(newPath);
        _loadFiles();
        if (!mounted) return;
        _showSnackBar('File renamed successfully', Colors.green);
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('Error renaming file: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _deleteFile(File file) async {
    final fileName = file.path.split('/').last;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text(
            'Are you sure you want to delete "$fileName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await file.delete();
        _loadFiles();
        if (!mounted) return;
        _showSnackBar('File deleted successfully', Colors.green);
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('Error deleting file: ${e.toString()}', Colors.red);
      }
    }
  }

  IconData _getIconForFile(FileSystemEntity entity) {
    final name = entity.path.toLowerCase();

    // Document files
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (name.endsWith('.doc') || name.endsWith('.docx'))
      return Icons.description;
    if (name.endsWith('.txt')) return Icons.text_snippet;

    // Spreadsheet files
    if (name.endsWith('.xlsx') || name.endsWith('.xls'))
      return Icons.table_chart;

    // Presentation files
    if (name.endsWith('.ppt') || name.endsWith('.pptx')) return Icons.slideshow;

    // Image files
    if (name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.gif') ||
        name.endsWith('.bmp') ||
        name.endsWith('.webp')) {
      return Icons.image;
    }

    // Video files
    if (name.endsWith('.mp4') ||
        name.endsWith('.avi') ||
        name.endsWith('.mov') ||
        name.endsWith('.mkv')) {
      return Icons.video_file;
    }

    // Audio files
    if (name.endsWith('.mp3') ||
        name.endsWith('.wav') ||
        name.endsWith('.flac') ||
        name.endsWith('.aac')) {
      return Icons.audio_file;
    }

    // Archive files
    if (name.endsWith('.zip') ||
        name.endsWith('.rar') ||
        name.endsWith('.7z') ||
        name.endsWith('.tar')) {
      return Icons.archive;
    }

    return Icons.insert_drive_file;
  }

  String _getFileTypeString(FileSystemEntity entity) {
    final extension = entity.path.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'PDF Document';
      case 'doc':
      case 'docx':
        return 'Word Document';
      case 'xls':
      case 'xlsx':
        return 'Excel Spreadsheet';
      case 'ppt':
      case 'pptx':
        return 'PowerPoint Presentation';
      case 'txt':
        return 'Text File';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return 'Image File';
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return 'Video File';
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
        return 'Audio File';
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
        return 'Archive File';
      default:
        return 'File';
    }
  }

  String _getFileInfo(File file) {
    try {
      final stat = file.statSync();
      return '${_formatFileSize(stat.size)} • ${_formatDate(stat.modified)}';
    } catch (e) {
      return 'Unknown size';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildFileList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        final file = _filteredFiles[index];
        return ListTile(
          leading: Icon(_getIconForFile(file)),
          title: Text(
            file.path.split('/').last,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(_getFileTypeString(file)),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showFileOptions(context, file as File),
          ),
          onTap: () => _openFile(file as File),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Manager'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: FileSearchDelegate(_files),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = true;
                }
                _sortFiles();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    const Icon(Icons.sort_by_alpha),
                    const SizedBox(width: 8),
                    const Text('Sort by Name'),
                    if (_sortBy == 'name') ...[
                      const Spacer(),
                      Icon(_sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 8),
                    const Text('Sort by Date'),
                    if (_sortBy == 'date') ...[
                      const Spacer(),
                      Icon(_sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'size',
                child: Row(
                  children: [
                    const Icon(Icons.data_usage),
                    const SizedBox(width: 8),
                    const Text('Sort by Size'),
                    if (_sortBy == 'size') ...[
                      const Spacer(),
                      Icon(_sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search files...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No files found matching your search'
                                  : 'No files found',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildFileList(),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: const Text('Upload Files'),
                    onTap: () {
                      Navigator.pop(context);
                      _uploadFile();
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FileSearchDelegate extends SearchDelegate<String> {
  final List<FileSystemEntity> files;

  FileSearchDelegate(this.files);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = files.where((file) {
      final name = file.path.split('/').last.toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    if (results.isEmpty) {
      return const Center(
        child: Text('No files found'),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final file = results[index];
        return ListTile(
          leading: Icon(_getIconForFile(file)),
          title: Text(file.path.split('/').last),
          subtitle: Text(_getFileTypeString(file)),
          onTap: () {
            close(context, file.path);
            if (file.path.endsWith('.pdf')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReadPdfScreen(filePath: file.path),
                ),
              );
            }
          },
        );
      },
    );
  }

  IconData _getIconForFile(FileSystemEntity entity) {
    final name = entity.path.toLowerCase();
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png')) {
      return Icons.image;
    }
    if (name.endsWith('.xlsx') || name.endsWith('.xls'))
      return Icons.table_chart;
    if (name.endsWith('.ppt') || name.endsWith('.pptx')) return Icons.slideshow;
    if (name.endsWith('.txt')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  String _getFileTypeString(FileSystemEntity entity) {
    final extension = entity.path.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'PDF Document';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return 'Image File';
      case 'doc':
      case 'docx':
        return 'Word Document';
      case 'xls':
      case 'xlsx':
        return 'Excel File';
      case 'ppt':
      case 'pptx':
        return 'PowerPoint Presentation';
      case 'txt':
        return 'Text File';
      default:
        return 'File';
    }
  }
}
