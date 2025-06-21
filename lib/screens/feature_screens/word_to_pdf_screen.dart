import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/models/history_item.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf_utility_pro/utils/constants.dart';
import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/file_provider.dart';
import 'package:pdf_utility_pro/models/file_item.dart';
import 'package:archive/archive_io.dart';
import 'package:pdf_utility_pro/providers/history_provider.dart';
import 'package:path/path.dart' as p;

String _extractTextFromDocx(String filePath) {
  final inputStream = InputFileStream(filePath);
  final archive = ZipDecoder().decodeBuffer(inputStream);
  final documentFile = archive.files.firstWhere(
    (file) => file.name == 'word/document.xml',
    orElse: () => ArchiveFile('', 0, <int>[]),
  );
  if (documentFile.isFile) {
    final xmlString = String.fromCharCodes(documentFile.content as List<int>);
    // Remove XML tags for a simple text extraction
    final text = xmlString.replaceAll(RegExp(r'<[^>]+>'), ' ');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  return '';
}

class WordToPdfScreen extends StatefulWidget {
  const WordToPdfScreen({Key? key}) : super(key: key);

  @override
  State<WordToPdfScreen> createState() => _WordToPdfScreenState();
}

class _WordToPdfScreenState extends State<WordToPdfScreen> {
  String? _selectedFile;
  String? _fileName;
  bool _isProcessing = false;
  final TextEditingController _filenameController = TextEditingController();

  Future<void> _selectFile() async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['docx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = result.files.single.path;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _convertToPdf() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Word file first'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    // Show dialog to get filename
    final String? fileName = await _showFileNameDialog();
    if (fileName == null || fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF creation cancelled. File name cannot be empty.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });
    try {
      final text = _extractTextFromDocx(_selectedFile!);
      if (text.isEmpty) {
        throw Exception('Could not extract text from Word file.');
      }
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Text(text),
            );
          },
        ),
      );
      final appDir = await getApplicationDocumentsDirectory();
      final fullFileName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
      final filePath = '${appDir.path}/$fullFileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      // Add to recent files
      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      final fileItem = FileItem(
        name: fullFileName,
        path: filePath,
        size: file.lengthSync(),
        dateModified: file.lastModifiedSync(),
        type: FileType.pdf,
      );
      fileProvider.addRecentFile(fileItem);
      Provider.of<HistoryProvider>(context, listen: false).addHistoryItem(
        HistoryItem(
          title: p.basename(filePath),
          filePath: filePath,
          operation: 'Word to PDF',
          timestamp: DateTime.now(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF created successfully'),
          backgroundColor: AppConstants.successColor,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReadPdfScreen(filePath: filePath),
                ),
              );
            },
          ),
        ),
      );
      setState(() {
        _selectedFile = null;
        _fileName = null;
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
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<String?> _showFileNameDialog() async {
    _filenameController.text = _fileName?.replaceAll('.docx', '').replaceAll('.doc', '') ?? 'Word_to_PDF_';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter File Name'),
        content: TextField(
          controller: _filenameController,
          decoration: const InputDecoration(
            hintText: 'e.g., MyDocument.pdf',
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
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _filenameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScreenTemplate(
      title: 'Word to PDF',
      icon: Icons.description,
      actionButtonLabel: 'Convert',
      isActionButtonEnabled: _selectedFile != null && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _convertToPdf,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Select a Word document to convert it into a PDF',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.description,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 32),
            if (_selectedFile != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(_fileName ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                        _fileName = null;
                      });
                    },
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _selectFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Select word file'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
// ed