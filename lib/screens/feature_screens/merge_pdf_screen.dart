import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
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

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({Key? key}) : super(key: key);

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  List<String> _selectedFiles = [];
  bool _isProcessing = false;

  Future<void> _selectFiles() async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles = result.files.map((f) => f.path!).toList();
      });
    }
  }

  Future<void> _mergePdfs() async {
    if (_selectedFiles.length < 2) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'Merged_PDF_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final outputPath = '${dir.path}/$fileName';

      // بعض نسخ pdf_merger تتوقع outputDirPath هو المسار الكامل للملف وليس فقط المجلد
      final response = await PdfMerger.mergeMultiplePDF(
        paths: _selectedFiles,
        outputDirPath: outputPath,
      );

      if (response.status == "success") {
        final mergedPath = response.response!;
        final file = File(mergedPath);

        // تحقق من وجود الملف فعلياً قبل المتابعة
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
          name: fileName,
          path: mergedPath,
          size: file.lengthSync(),
          dateModified: file.lastModifiedSync(),
          type: myfile.FileType.pdf,
        );
        fileProvider.addRecentFile(fileItem);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('pdf_merged_success'),
            ),
            backgroundColor: AppConstants.successColor,
            action: SnackBarAction(
              label: AppLocalizations.of(context).translate('open'),
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return FeatureScreenTemplate(
      title: loc.translate('merge_pdf'),
      icon: Icons.merge_type,
      actionButtonLabel: loc.translate('merge'),
      isActionButtonEnabled: _selectedFiles.length >= 2 && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _mergePdfs,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              loc.translate('merge_pdf_instructions'),
              textAlign: TextAlign.center,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _selectFiles,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(loc.translate('select_pdf_files')),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedFiles.isEmpty
                ? Center(
                    child: Text(
                      loc.translate('no_pdf_files_selected'),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  )
                : ReorderableListView.builder(
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
                          title: Text(_selectedFiles[index].split('/').last),
                          subtitle:
                              Text('${index + 1} of ${_selectedFiles.length}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _selectedFiles.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
