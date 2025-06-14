import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';

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
        SnackBar(
          content: Text(AppLocalizations.of(context)
              .translate('storage_permission_denied')),
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
          content: Text(
              '${AppLocalizations.of(context).translate('error_loading_directory')}: $e'),
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
          content: Text(
              '${AppLocalizations.of(context).translate('error_loading_files')}: $e'),
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
        title: Text(AppLocalizations.of(context).translate('new_folder')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).translate('folder_name'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(AppLocalizations.of(context).translate('create')),
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
          SnackBar(
            content:
                Text(AppLocalizations.of(context).translate('folder_created')),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context).translate('error_creating_folder')}: $e'),
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
          SnackBar(
            content:
                Text(AppLocalizations.of(context).translate('file_uploaded')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context).translate('error_uploading_file')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFileOptions(BuildContext context, File file) {
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
              if (file.path.endsWith('.pdf')) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReadPdfScreen(filePath: file.path),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.translate('unsupported_file_type')),
                    backgroundColor: Colors.red,
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
              Share.shareXFiles([XFile(file.path)]);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(loc.translate('rename')),
            onTap: () {
              Navigator.pop(context);
              _renameFile(file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: Text(loc.translate('delete')),
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
        title: Text(AppLocalizations.of(context).translate('rename')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).translate('file_name'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(AppLocalizations.of(context).translate('rename')),
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
          SnackBar(
            content:
                Text(AppLocalizations.of(context).translate('file_renamed')),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context).translate('error_renaming_file')}: $e'),
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
        title: Text(AppLocalizations.of(context).translate('delete_file')),
        content: Text(AppLocalizations.of(context).translate('confirm_delete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).translate('delete')),
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
          SnackBar(
            content:
                Text(AppLocalizations.of(context).translate('file_deleted')),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context).translate('error_deleting_file')}: $e'),
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
        name.endsWith('.png')) return Icons.image;
    if (name.endsWith('.xlsx') || name.endsWith('.xls'))
      return Icons.table_chart;
    if (name.endsWith('.ppt') || name.endsWith('.pptx')) return Icons.slideshow;
    if (name.endsWith('.txt')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  String _getFileTypeString(FileSystemEntity entity, AppLocalizations loc) {
    if (entity is Directory) return loc.translate('folder');
    final name = entity.path.toLowerCase();
    if (name.endsWith('.pdf')) return 'PDF';
    if (name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png')) return loc.translate('image_file');
    if (name.endsWith('.xlsx') || name.endsWith('.xls')) return 'Excel';
    if (name.endsWith('.ppt') || name.endsWith('.pptx')) return 'PowerPoint';
    if (name.endsWith('.txt')) return loc.translate('text_file');
    return loc.translate('file');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('View Files')),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: FileSearchDelegate(_files, loc),
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
                    _currentPath ?? loc.translate('loading'),
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
                            SnackBar(
                              content: Text(loc
                                  .translate('cannot_access_parent_directory')),
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
                    ? Center(child: Text(loc.translate('no_files_found')))
                    : ListView.builder(
                        itemCount: _filteredFiles.length,
                        itemBuilder: (context, index) {
                          final file = _filteredFiles[index];
                          return ListTile(
                            leading: Icon(_getIconForFile(file)),
                            title: Text(file.path.split('/').last),
                            subtitle: Text(_getFileTypeString(file, loc)),
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
                                  SnackBar(
                                    content: Text(
                                        loc.translate('unsupported_file_type')),
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
                  title: Text(loc.translate('new_folder')),
                  onTap: () {
                    Navigator.pop(context);
                    _createFolder();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: Text(loc.translate('upload_file')),
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
  final AppLocalizations loc;

  FileSearchDelegate(this.files, this.loc);

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
          subtitle: Text(_getFileTypeString(file, loc)),
          onTap: () {
            close(context, file.path);
            if (file is Directory) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewFilesScreen(),
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
        name.endsWith('.png')) return Icons.image;
    if (name.endsWith('.xlsx') || name.endsWith('.xls'))
      return Icons.table_chart;
    if (name.endsWith('.ppt') || name.endsWith('.pptx')) return Icons.slideshow;
    if (name.endsWith('.txt')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  String _getFileTypeString(FileSystemEntity entity, AppLocalizations loc) {
    if (entity is Directory) return loc.translate('folder');
    final name = entity.path.toLowerCase();
    if (name.endsWith('.pdf')) return 'PDF';
    if (name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png')) return loc.translate('image_file');
    if (name.endsWith('.xlsx') || name.endsWith('.xls')) return 'Excel';
    if (name.endsWith('.ppt') || name.endsWith('.pptx')) return 'PowerPoint';
    if (name.endsWith('.txt')) return loc.translate('text_file');
    return loc.translate('file');
  }
}
