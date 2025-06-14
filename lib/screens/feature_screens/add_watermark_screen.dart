import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/models/history_item.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf_utility_pro/utils/constants.dart';
import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/file_provider.dart';
import 'package:pdf_utility_pro/models/file_item.dart';
import 'package:pdf_utility_pro/providers/history_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';

class AddWatermarkScreen extends StatefulWidget {
  const AddWatermarkScreen({Key? key}) : super(key: key);

  @override
  State<AddWatermarkScreen> createState() => _AddWatermarkScreenState();
}

class _AddWatermarkScreenState extends State<AddWatermarkScreen> {
  String? _selectedFile;
  String? _fileName;
  final TextEditingController _watermarkTextController =
      TextEditingController();
  double _opacity = 0.3;
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

  Future<void> _addWatermark() async {
    if (_selectedFile == null || _watermarkTextController.text.trim().isEmpty)
      return;
    setState(() {
      _isProcessing = true;
    });
    try {
      final doc = await PdfDocument.openFile(_selectedFile!);
      final dir = await getApplicationDocumentsDirectory();
      final pdfDoc = pw.Document();
      for (int i = 1; i <= doc.pagesCount; i++) {
        final page = await doc.getPage(i);
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
        pdfDoc.addPage(
          pw.Page(
            pageFormat: pdf.PdfPageFormat(
                page.width.toDouble(), page.height.toDouble()),
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  pw.Center(child: pw.Image(img)),
                  pw.Positioned(
                    left: 0,
                    right: 0,
                    top: page.height / 2 - 30,
                    child: pw.Center(
                      child: pw.Opacity(
                        opacity: _opacity,
                        child: pw.Text(
                          _watermarkTextController.text,
                          style: pw.TextStyle(
                            fontSize: 36,
                            color: pdf.PdfColors.red,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
        await page.close();
      }
      await doc.close();
      final fileName =
          'Watermarked_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdfDoc.save());
      // Add to recent files
      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      final fileItem = FileItem(
        name: fileName,
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
          operation: 'Add Watermark',
          timestamp: DateTime.now(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)
              .translate('watermark_added_success')),
          backgroundColor: AppConstants.successColor,
          action: SnackBarAction(
            label: AppLocalizations.of(context).translate('open'),
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
        _watermarkTextController.clear();
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
    _watermarkTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return FeatureScreenTemplate(
      title: loc.translate('Add Watermark'),
      icon: Icons.water_drop,
      actionButtonLabel: loc.translate('Add Watermark'),
      isActionButtonEnabled: _selectedFile != null &&
          _watermarkTextController.text.trim().isNotEmpty &&
          !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _addWatermark,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate(
                  'Select a PDF file and add a text watermark to it.'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_selectedFile == null)
              Expanded(
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _selectFile,
                    icon: const Icon(Icons.upload_file),
                    label: Text(loc.translate('Select pdf file')),
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
                                _watermarkTextController.clear();
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        loc.translate('watermark_text'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _watermarkTextController,
                        decoration: InputDecoration(
                          labelText: loc.translate('enter_watermark_text'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
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
