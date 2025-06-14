import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/history_provider.dart';
import 'package:pdf_utility_pro/models/history_item.dart';
import 'package:path/path.dart' as p;

class ExtractTextScreen extends StatefulWidget {
  const ExtractTextScreen({super.key});

  @override
  State<ExtractTextScreen> createState() => _ExtractTextScreenState();
}

class _ExtractTextScreenState extends State<ExtractTextScreen> {
  String? _selectedFile;
  String? _fileName;
  String? _extractedText;
  bool _isProcessing = false;

  Future<void> _selectFile() async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = result.files.single.path;
          _fileName = result.files.single.name;
          _extractedText =
              null; // Reset extracted text when selecting a new file
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context).translate('error_selecting_file')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _extractText() async {
    if (_selectedFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final file = File(_selectedFile!);
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(document).extractText();
      document.dispose();

      if (text.trim().isEmpty) {
        throw Exception('No text found in the PDF');
      }

      setState(() {
        _extractedText = text.trim();
        _isProcessing = false;
      });

      // بعد نجاح الاستخراج:
      Provider.of<HistoryProvider>(context, listen: false).addHistoryItem(
        HistoryItem(
          title: p.basename(_selectedFile!),
          filePath: _selectedFile!,
          operation: 'Extract Text',
          timestamp: DateTime.now(),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context).translate('text_extracted_success')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context).translate('error_extracting_text')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyText() async {
    if (_extractedText == null) return;

    try {
      await Clipboard.setData(ClipboardData(text: _extractedText!));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('text_copied')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context).translate('error_copying_text')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return FeatureScreenTemplate(
      title: loc.translate('Extract Text'),
      icon: Icons.text_snippet,
      actionButtonLabel: _extractedText == null
          ? loc.translate('Extract Text')
          : loc.translate('copy_text'),
      isActionButtonEnabled: _selectedFile != null && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _extractedText == null ? _extractText : _copyText,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate(
                  'Select a PDF file or image to extract text from it.'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (_selectedFile == null)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _selectFile,
                  icon: const Icon(Icons.upload_file),
                  label: Text(loc.translate('Select File')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
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
                              _extractedText = null;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_extractedText != null) ...[
                      Text(
                        loc.translate('extracted_text'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _extractedText!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
