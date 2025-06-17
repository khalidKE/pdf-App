import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';

import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class ViewFilesScreen extends StatefulWidget {
  const ViewFilesScreen({super.key});

  @override
  State<ViewFilesScreen> createState() => _ViewFilesScreenState();
}

class _ViewFilesScreenState extends State<ViewFilesScreen> {
  String? _currentPath;
  List<FileSystemEntity> _files = [];
  List<FileSystemEntity> _filteredFiles = [];
  bool _isLoading = true;
  String _sortBy = 'name';
  bool _sortAscending = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeDirectory();
    _searchController.addListener(_filterFiles);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeDirectory() async {
    if (!await _requestPermissions()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission denied'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      setState(() {
        _currentPath = dir.path;
        _loadFiles();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading directory: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        return await Permission.manageExternalStorage.request().isGranted;
      }
      return status.isGranted;
    }
    return true;
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
        _files = entities.where((e) => e is File || e is Directory).toList();
        _filterFiles();
        _sortFiles();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading files: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;

      if (aIsDir && !bIsDir) return -1;
      if (!aIsDir && bIsDir) return 1;

      switch (_sortBy) {
        case 'name':
          return _sortAscending
              ? aName.compareTo(bName)
              : bName.compareTo(aName);
        case 'date':
          final aStat = a.statSync();
          final bStat = b.statSync();
          return _sortAscending
              ? aStat.modified.compareTo(bStat.modified)
              : bStat.modified.compareTo(aStat.modified);
        case 'size':
          if (a is File && b is File) {
            final aStat = a.statSync();
            final bStat = b.statSync();
            return _sortAscending
                ? aStat.size.compareTo(bStat.size)
                : bStat.size.compareTo(aStat.size);
          }
          return 0;
        default:
          return 0;
      }
    });
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && _currentPath != null) {
      try {
        final newFolder = Directory('$_currentPath/$result');
        await newFolder.create();
        _loadFiles();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Folder created successfully'),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadFile() async {
    try {
      final result = await fp.FilePicker.platform.pickFiles();
      if (result != null &&
          result.files.single.path != null &&
          _currentPath != null) {
        final file = File(result.files.single.path!);
        final newPath = '$_currentPath/${result.files.single.name}';
        await file.copy(newPath);
        _loadFiles();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFileOptions(BuildContext context, File file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Open'),
            onTap: () {
              Navigator.pop(context);
              if (file.path.endsWith('.pdf')) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReadPdfScreen(filePath: file.path),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Unsupported file type'),
                    backgroundColor: Colors.red,
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
              Share.shareXFiles([XFile(file.path)]);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _renameFile(file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(context);
              _deleteFile(file);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _renameFile(File file) async {
    final controller = TextEditingController(text: file.path.split('/').last);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'File Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && _currentPath != null) {
      try {
        final newPath = '$_currentPath/$result';
        await file.rename(newPath);
        _loadFiles();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File renamed successfully'),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error renaming file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File deleted successfully'),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getIconForFile(FileSystemEntity entity) {
    if (entity is Directory) return Icons.folder;
    final name = entity.path.toLowerCase();
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png')) {
      return Icons.image;
    }
    if (name.endsWith('.xlsx') || name.endsWith('.xls')) {
      return Icons.table_chart;
    }
    if (name.endsWith('.ppt') || name.endsWith('.pptx')) return Icons.slideshow;
    if (name.endsWith('.txt')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  String _getFileTypeString(FileSystemEntity entity) {
    if (entity is Directory) {
      return 'Folder';
    }
    
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
      case 'txt':
        return 'Text File';
      default:
        return 'File';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Files'),
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
              const PopupMenuItem(
                value: 'name',
                child: Text('Sort by Name'),
              ),
              const PopupMenuItem(
                value: 'date',
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem(
                value: 'size',
                child: Text('Sort by Size'),
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
                    _currentPath ?? 'Loading',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_currentPath != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (_currentPath != null) {
                        final parentPath = Directory(_currentPath!).parent.path;
                        // Prevent navigating to restricted directories like /data/user/0/
                        if (!parentPath.contains('/data/user/0/') &&
                            parentPath != _currentPath) {
                          setState(() {
                            _currentPath = parentPath;
                            _loadFiles();
                          });
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cannot access parent directory'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFiles.isEmpty
                    ? const Center(child: Text('No files found'))
                    : ListView.builder(
                        itemCount: _filteredFiles.length,
                        itemBuilder: (context, index) {
                          final file = _filteredFiles[index];
                          return ListTile(
                            leading: Icon(_getIconForFile(file)),
                            title: Text(file.path.split('/').last),
                            subtitle: Text(_getFileTypeString(file)),
                            trailing: file is Directory
                                ? const Icon(Icons.arrow_forward_ios, size: 16)
                                : IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () =>
                                        _showFileOptions(context, file as File),
                                  ),
                            onTap: () {
                              if (file is Directory) {
                                setState(() {
                                  _currentPath = file.path;
                                  _loadFiles();
                                });
                              } else if (file.path.endsWith('.pdf')) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ReadPdfScreen(filePath: file.path),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Unsupported file type'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
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
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.create_new_folder),
                  title: const Text('New Folder'),
                  onTap: () {
                    Navigator.pop(context);
                    _createFolder();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Upload File'),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadFile();
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
    final results = files.where((file) {
      final name = file.path.split('/').last.toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

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
            if (file is Directory) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ViewFilesScreen(),
                ),
              ).then((_) {
                // Update path after returning
                (context as Element).markNeedsBuild();
              });
            } else if (file.path.endsWith('.pdf')) {
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

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }

  IconData _getIconForFile(FileSystemEntity entity) {
    if (entity is Directory) return Icons.folder;
    final name = entity.path.toLowerCase();
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png')) {
      return Icons.image;
    }
    if (name.endsWith('.xlsx') || name.endsWith('.xls')) {
      return Icons.table_chart;
    }
    if (name.endsWith('.ppt') || name.endsWith('.pptx')) return Icons.slideshow;
    if (name.endsWith('.txt')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  String _getFileTypeString(FileSystemEntity entity) {
    if (entity is Directory) {
      return 'Folder';
    }
    
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
      case 'txt':
        return 'Text File';
      default:
        return 'File';
    }
  }
}
