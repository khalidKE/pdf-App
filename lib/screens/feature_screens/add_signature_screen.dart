import 'dart:ui';
import 'package:flutter/material.dart';
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
import 'package:pdfx/pdfx.dart';
import 'package:signature/signature.dart';

class AddSignatureScreen extends StatefulWidget {
  const AddSignatureScreen({super.key});

  @override
  State<AddSignatureScreen> createState() => _AddSignatureScreenState();
}

class _AddSignatureScreenState extends State<AddSignatureScreen> {
  String? _selectedFile;
  String? _fileName;
  bool _isProcessing = false;
  bool _hasSignature = false;
  PdfDocument? _pdfDoc;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void initState() {
    super.initState();
    // Add listener to detect signature changes
    _signatureController.addListener(() {
      setState(() {
        _hasSignature = !_signatureController.isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _pdfDoc?.close();
    super.dispose();
  }

  Future<void> _selectFile() async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final doc = await PdfDocument.openFile(result.files.single.path!);
        setState(() {
          _selectedFile = result.files.single.path;
          _fileName = result.files.single.name;
          _pdfDoc = doc;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context).translate('error_opening_pdf')),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      setState(() {
        _selectedFile = null;
        _fileName = null;
        _pdfDoc = null;
      });
    }
  }

  void _clearSignature() {
    _signatureController.clear();
    setState(() {
      _hasSignature = false;
    });
  }

  Future<void> _addSignature() async {
    if (_selectedFile == null || _pdfDoc == null || !_hasSignature) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final signatureImageBytes = await _signatureController.toPngBytes(
        height: 100,
        width: 300,
      );

      if (signatureImageBytes == null || signatureImageBytes.isEmpty) {
        throw Exception('Failed to generate signature image');
      }

      final signaturePdfImage = pw.MemoryImage(signatureImageBytes);
      final dir = await getApplicationDocumentsDirectory();
      final pdfDoc = pw.Document();

      for (int i = 1; i <= _pdfDoc!.pagesCount; i++) {
        final page = await _pdfDoc!.getPage(i);
        try {
          final pageImage = await page.render(
            width: page.width.toDouble(),
            height: page.height.toDouble(),
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );

          if (pageImage?.bytes == null) {
            continue;
          }

          final img = pw.MemoryImage(pageImage!.bytes);
          pdfDoc.addPage(
            pw.Page(
              pageFormat: pdf.PdfPageFormat(
                page.width.toDouble(),
                page.height.toDouble(),
              ),
              build: (pw.Context context) {
                return pw.Stack(
                  children: [
                    pw.Image(img, fit: pw.BoxFit.contain),
                    pw.Positioned(
                      right: 30,
                      bottom: 30,
                      child: pw.Image(
                        signaturePdfImage,
                        width: 150,
                        height: 50,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        } finally {
          await page.close();
        }
      }

      final fileName = 'Signed_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdfDoc.save());

      // Add to recent files
      if (mounted) {
        final fileProvider = Provider.of<FileProvider>(context, listen: false);
        final fileItem = FileItem(
          name: fileName,
          path: filePath,
          size: file.lengthSync(),
          dateModified: file.lastModifiedSync(),
          type: FileType.pdf,
        );
        fileProvider.addRecentFile(fileItem);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('signature_added_success')),
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
      }

      setState(() {
        _selectedFile = null;
        _fileName = null;
        _signatureController.clear();
        _hasSignature = false;
        _pdfDoc = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context).translate('error_adding_signature')}: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      await _pdfDoc?.close();
      _pdfDoc = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return FeatureScreenTemplate(
      title: loc.translate('add_signature'),
      icon: Icons.draw,
      actionButtonLabel: loc.translate('add_signature'),
      isActionButtonEnabled:
          _selectedFile != null && _hasSignature && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _addSignature,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              loc.translate('signature_instructions'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: _selectedFile == null
                ? Center(
                    child: ElevatedButton.icon(
                      onPressed: _selectFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(loc.translate('select_pdf_file')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 4,
                          child: ListTile(
                            leading: const Icon(Icons.picture_as_pdf),
                            title: Text(
                              _fileName ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedFile = null;
                                  _fileName = null;
                                  _signatureController.clear();
                                  _hasSignature = false;
                                  _pdfDoc?.close();
                                  _pdfDoc = null;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.translate('draw_signature'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Signature(
                            controller: _signatureController,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
          if (_selectedFile != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _clearSignature,
                icon: const Icon(Icons.clear),
                label: Text(loc.translate('clear_signature')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 176, 68, 56),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
