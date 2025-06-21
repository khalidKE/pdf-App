import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/models/history_item.dart';
import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf_utility_pro/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/file_provider.dart';
import 'package:pdf_utility_pro/models/file_item.dart';
import 'package:pdfx/pdfx.dart';
import 'package:pdf_utility_pro/providers/history_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_utility_pro/utils/permission_handler.dart';

class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({Key? key}) : super(key: key);

  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  String? _selectedFile;
  String? _fileName;
  final TextEditingController _pagesController = TextEditingController();
  bool _isProcessing = false;
  final TextEditingController _filenameController = TextEditingController();

  Future<void> _selectFile() async {
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
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final pickedFile = result.files.single;
      final fileBytes = pickedFile.bytes ?? await File(pickedFile.path!).readAsBytes();
      final fileName = pickedFile.name;
      final tempFile = File('${Directory.systemTemp.path}/$fileName');
      await tempFile.writeAsBytes(fileBytes);
      setState(() {
        _selectedFile = tempFile.path;
        _fileName = fileName;
      });
    }
  }

  List<int> _parsePages(String input) {
    final List<int> pages = [];
    final parts =
        input.replaceAll(':', '-').split(',').map((part) => part.trim());
    for (var part in parts) {
      if (part.contains('-')) {
        final range = part.split('-');
        if (range.length == 2) {
          final start = int.tryParse(range[0]);
          final end = int.tryParse(range[1]);
          if (start != null && end != null && start > 0 && end >= start) {
            pages.addAll(List.generate(end - start + 1, (i) => start + i));
          }
        }
      } else {
        final page = int.tryParse(part);
        if (page != null && page > 0) {
          pages.add(page);
        }
      }
    }
    return pages.toSet().toList()..sort();
  }

  Future<void> _splitPdf() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PDF file first.'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    if (_pagesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter pages to split.'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    final String? fileName = await _showFileNameDialog();
    if (fileName == null || fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF split cancelled. File name cannot be empty.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final pages = _parsePages(_pagesController.text.trim());
      if (pages.isEmpty) throw Exception('No valid pages specified.');

      final doc = await PdfDocument.openFile(_selectedFile!);
      final outputPdf = pw.Document();
      final appDir = await getApplicationDocumentsDirectory();

      for (final pageNum in pages) {
        if (pageNum < 1 || pageNum > doc.pagesCount) continue;

        final page = await doc.getPage(pageNum);
        final image = await page.render(
          width: page.width,
          height: page.height,
          format: PdfPageImageFormat.png,
        );
        await page.close();

        if (image?.bytes != null) {
          final img = pw.MemoryImage(image!.bytes);
          outputPdf.addPage(
            pw.Page(
              pageFormat: pdf.PdfPageFormat(
                page.width.toDouble(),
                page.height.toDouble(),
              ),
              build: (pw.Context context) => pw.Center(child: pw.Image(img)),
            ),
          );
        }
      }

      final fullFileName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
      final outputPath = '${appDir.path}/$fullFileName';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(await outputPdf.save());

      await doc.close();

      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      final fileItem = FileItem(
        name: fullFileName,
        path: outputPath,
        size: outputFile.lengthSync(),
        dateModified: outputFile.lastModifiedSync(),
        type: FileType.pdf,
      );
      fileProvider.addRecentFile(fileItem);

      Provider.of<HistoryProvider>(context, listen: false).addHistoryItem(
        HistoryItem(
          title: p.basename(outputPath),
          filePath: outputPath,
          operation: 'Split PDF',
          timestamp: DateTime.now(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF split successfully'),
          backgroundColor: AppConstants.successColor,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReadPdfScreen(filePath: outputPath),
                ),
              );
            },
          ),
        ),
      );

      setState(() {
        _selectedFile = null;
        _fileName = null;
        _pagesController.clear();
        _filenameController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<String?> _showFileNameDialog() async {
    _filenameController.text = _fileName?.replaceAll('.pdf', '') ?? 'Split_PDF_';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter File Name'),
        content: TextField(
          controller: _filenameController,
          decoration: const InputDecoration(
            hintText: 'e.g., MySplitDocument.pdf',
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
            child: const Text('Split'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pagesController.dispose();
    _filenameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScreenTemplate(
      title: 'Split PDF',
      icon: Icons.call_split,
      actionButtonLabel: 'Split',
      isActionButtonEnabled: _selectedFile != null && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _splitPdf,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a PDF file and specify the page range to split',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (_selectedFile == null)
              Expanded(
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _selectFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select pdf file'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf),
                          title: Text(
                            _fileName ?? _selectedFile!,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                                _fileName = null;
                                _pagesController.clear();
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'split pages',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pagesController,
                        decoration: InputDecoration(
                          labelText: 'pages to split',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter page numbers or ranges (e.g., 1,3-5,7)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
