import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/models/history_item.dart';
import 'package:pdf_utility_pro/utils/permission_handler.dart';
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
import 'package:pdf_utility_pro/providers/history_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_utility_pro/widgets/banner_ad_widget.dart';
import 'package:pdf_utility_pro/services/ads_service.dart';


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
  final TextEditingController _filenameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listener to detect signature changes
    _signatureController.addListener(() {
      setState(() {
        _hasSignature = _signatureController.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _pdfDoc?.close();
    _filenameController.dispose();
    super.dispose();
  }

  Future<void> _selectFile() async {
    final hasPermission = await AppPermissionHandler.requestStoragePermission(context: context);
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission is required.'), backgroundColor: Colors.red),
      );
      return;
    }
    try {
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
        final doc = await PdfDocument.openFile(tempFile.path);
        setState(() {
          _selectedFile = tempFile.path;
          _fileName = fileName;
          _pdfDoc = doc;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error opening PDF file'),
          backgroundColor: Colors.red,
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
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PDF file first.'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }
    if (_pdfDoc == null || !_hasSignature) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw a signature.'),
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
          content: Text('Signature adding cancelled. File name cannot be empty.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final signatureImageBytes = await _signatureController.toPngBytes(
        height: 200,
        width: 400,
      );

      if (signatureImageBytes == null || signatureImageBytes.isEmpty) {
        throw Exception('Failed to generate signature image');
      }

      final signaturePdfImage = pw.MemoryImage(signatureImageBytes);
      final appDir = await getApplicationDocumentsDirectory();
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

      final fullFileName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
      final filePath = '${appDir.path}/$fullFileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdfDoc.save());

      // Add to recent files
      if (mounted) {
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
            operation: 'Add Signature',
            timestamp: DateTime.now(),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Signature added successfully'),
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

        // Show rewarded ad after success
        await AdsService().showRewardedAd(
          onRewarded: () {},
          onFailed: () {},
        );
      }

      setState(() {
        _selectedFile = null;
        _fileName = null;
        _signatureController.clear();
        _hasSignature = false;
        _pdfDoc = null;
        _filenameController.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding signature: $e'),
            backgroundColor: Colors.red,
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

  Future<String?> _showFileNameDialog() async {
    _filenameController.text = _fileName?.replaceAll('.pdf', '') ?? 'Signed_PDF_';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter File Name'),
        content: TextField(
          controller: _filenameController,
          decoration: const InputDecoration(
            hintText: 'e.g., MySignedDocument.pdf',
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
            child: const Text('Add Signature'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Signature'),
      ),
      body: FeatureScreenTemplate(
        title: 'Add Signature',
        icon: Icons.draw,
        actionButtonLabel: 'Add Signature',
        isActionButtonEnabled:
            _selectedFile != null && _hasSignature && !_isProcessing,
        isProcessing: _isProcessing,
        onActionButtonPressed: _addSignature,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select a PDF file and draw your signature to add to it',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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
                                _signatureController.clear();
                                _hasSignature = false;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Draw your signature below',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Signature(controller: _signatureController, height: 200, width: 300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _clearSignature,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Signature'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
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
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
