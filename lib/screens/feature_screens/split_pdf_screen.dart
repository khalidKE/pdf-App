import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
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

  Future<void> _selectFile() async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = result.files.single.path;
        _fileName = result.files.single.name;
      });
    }
  }

  List<int> _parsePages(String input) {
    final List<int> pages = [];
    final parts = input.split(',');
    for (var part in parts) {
      if (part.contains('-')) {
        final range = part.split('-');
        if (range.length == 2) {
          final start = int.tryParse(range[0].trim());
          final end = int.tryParse(range[1].trim());
          if (start != null && end != null && start <= end) {
            pages.addAll(List.generate(end - start + 1, (i) => start + i));
          }
        }
      } else {
        final page = int.tryParse(part.trim());
        if (page != null) pages.add(page);
      }
    }
    return pages;
  }

  Future<void> _splitPdf() async {
    if (_selectedFile == null || _pagesController.text.trim().isEmpty) return;
    setState(() {
      _isProcessing = true;
    });
    try {
      final pages = _parsePages(_pagesController.text.trim());
      if (pages.isEmpty) throw Exception('No valid pages specified.');
      final doc = await PdfDocument.openFile(_selectedFile!);
      final dir = await getApplicationDocumentsDirectory();
      final splitFiles = <String>[];
      for (final pageNum in pages) {
        if (pageNum < 1 || pageNum > doc.pagesCount) continue;
        final page = await doc.getPage(pageNum);
        final pageImage = await page.render(
          width: page.width,
          height: page.height,
          format: PdfPageImageFormat.png,
        );
        final bytes = pageImage?.bytes;
        if (bytes == null) {
          await page.close();
          continue;
        }
        final img = pw.MemoryImage(bytes);
        final pdfDoc = pw.Document();
        pdfDoc.addPage(
          pw.Page(
            pageFormat: pdf.PdfPageFormat(
                page.width.toDouble(), page.height.toDouble()),
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(img));
            },
          ),
        );
        final fileName =
            'Split_Page_${pageNum}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(await pdfDoc.save());
        splitFiles.add(filePath);
        await page.close();
      }
      await doc.close();
      if (splitFiles.isEmpty) throw Exception('No pages were split.');
      // Add to recent files
      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      for (final filePath in splitFiles) {
        final file = File(filePath);
        final fileItem = FileItem(
          name: filePath.split('/').last,
          path: filePath,
          size: file.lengthSync(),
          dateModified: file.lastModifiedSync(),
          type: FileType.pdf,
        );
        fileProvider.addRecentFile(fileItem);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context).translate('pdf_split_success')),
          backgroundColor: AppConstants.successColor,
          action: SnackBarAction(
            label: AppLocalizations.of(context).translate('open'),
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ReadPdfScreen(filePath: splitFiles.first),
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

  @override
  void dispose() {
    _pagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return FeatureScreenTemplate(
      title: loc.translate('split_pdf'),
      icon: Icons.call_split,
      actionButtonLabel: loc.translate('split'),
      isActionButtonEnabled: _selectedFile != null &&
          _pagesController.text.trim().isNotEmpty &&
          !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _splitPdf,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('split_pdf_instructions'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_selectedFile == null)
              Expanded(
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _selectFile,
                    icon: const Icon(Icons.upload_file),
                    label: Text(loc.translate('select_pdf_file')),
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
                        loc.translate('split_options'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pagesController,
                        decoration: InputDecoration(
                          labelText: loc.translate('pages_to_split'),
                          hintText: loc.translate('pages_hint'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.translate('pages_format_help'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
