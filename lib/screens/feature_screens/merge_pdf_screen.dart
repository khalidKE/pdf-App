import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/models/history_item.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf_utility_pro/utils/constants.dart';
import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/file_provider.dart';
import 'package:pdf_utility_pro/models/file_item.dart' as myfile;
import 'package:pdf_merger/pdf_merger.dart';
import 'package:pdf_utility_pro/providers/history_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_utility_pro/widgets/banner_ad_widget.dart';
import 'package:pdf_utility_pro/utils/permission_handler.dart';
class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({Key? key}) : super(key: key);

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> with SingleTickerProviderStateMixin {
  List<File> _selectedFiles = [];
  List<String> _fileNames = [];
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  final TextEditingController _filenameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  Future<void> _selectFiles() async {
    final hasPermission = await AppPermissionHandler.requestStoragePermission(context: context);
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission is required.'), backgroundColor: Colors.red),
      );
      return;
    }
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles = result.files.map((f) {
          final bytes = f.bytes;
          if (bytes != null) {
            final tempFile = File('${Directory.systemTemp.path}/${f.name}');
            tempFile.writeAsBytesSync(bytes);
            return tempFile;
          } else {
            return File(f.path!);
          }
        }).toList();
        _fileNames = result.files.map((f) => f.name).toList();
      });
    }
  }

  Future<void> _mergePdfs() async {
    if (_selectedFiles.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least two PDF files to merge.'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    final String? fileName = await _showFileNameDialog();
    if (fileName == null || fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF merge cancelled. File name cannot be empty.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fullFileName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
      final outputPath = '${appDir.path}/$fullFileName';

      final response = await PdfMerger.mergeMultiplePDF(
        paths: _selectedFiles.map((f) => f.path).toList(),
        outputDirPath: outputPath,
      );

      if (response.status == "success") {
        final mergedPath = response.response!;
        final file = File(mergedPath);

        if (!await file.exists()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Merged file not found at $mergedPath'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
          setState(() {
            _isProcessing = false;
          });
          return;
        }

        final fileProvider = Provider.of<FileProvider>(context, listen: false);
        final fileItem = myfile.FileItem(
          name: fullFileName,
          path: mergedPath,
          size: file.lengthSync(),
          dateModified: file.lastModifiedSync(),
          type: myfile.FileType.pdf,
        );
        fileProvider.addRecentFile(fileItem);

        Provider.of<HistoryProvider>(context, listen: false).addHistoryItem(
          HistoryItem(
            title: p.basename(outputPath),
            filePath: outputPath,
            operation: 'Merge PDF',
            timestamp: DateTime.now(),
          ),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF merged successfully'),
            backgroundColor: AppConstants.successColor,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReadPdfScreen(filePath: mergedPath),
                  ),
                );
              },
            ),
          ),
        );

        setState(() {
          _selectedFiles = [];
          _fileNames = [];
          _filenameController.clear();
        });
      } else {
        throw Exception('Merge failed: ${response.message}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<String?> _showFileNameDialog() async {
    _filenameController.text = 'Merged_PDF_';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter File Name'),
        content: TextField(
          controller: _filenameController,
          decoration: const InputDecoration(
            hintText: 'e.g., CombinedDocument.pdf',
            labelText: 'File Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.of(context).pop(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(null);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(_filenameController.text.trim());
            },
            child: const Text('Merge'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _filenameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return FeatureScreenTemplate(
      title: 'Merge PDF',
      icon: Icons.merge_type,
      actionButtonLabel: 'Merge',
      isActionButtonEnabled: _selectedFiles.length >= 2 && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _mergePdfs,
      body: Column(
        children: [
          const AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 500),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select multiple PDF files to merge them into a single PDF document. You can reorder the files by dragging them.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          AnimatedScale(
            scale: _scaleAnimation.value,
            duration: const Duration(milliseconds: 500),
            child: ElevatedButton.icon(
              onPressed: _selectFiles,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Select PDF Files'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedFiles.isEmpty
                ? Center(
                    child: Text(
                      'No pdf files selected',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  )
                : SlideTransition(
                    position: _slideAnimation,
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _selectedFiles.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = _selectedFiles.removeAt(oldIndex);
                          _selectedFiles.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        return Card(
                          key: Key('$index'),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.picture_as_pdf),
                            title: Text(_fileNames[index]),
                            subtitle:
                                Text('${index + 1} of ${_selectedFiles.length}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  _selectedFiles.removeAt(index);
                                  _fileNames.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
