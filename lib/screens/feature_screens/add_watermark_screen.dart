import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/models/history_item.dart';
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
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:pdf_utility_pro/utils/permission_handler.dart';
import 'package:pdf_utility_pro/utils/font_loader.dart';
import 'package:pdf_utility_pro/widgets/banner_ad_widget.dart';
import 'package:pdf_utility_pro/services/ads_service.dart';

class AddWatermarkScreen extends StatefulWidget {
  const AddWatermarkScreen({Key? key}) : super(key: key);

  @override
  State<AddWatermarkScreen> createState() => _AddWatermarkScreenState();
}

class _AddWatermarkScreenState extends State<AddWatermarkScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedFile;
  String? _fileName;
  bool _isProcessing = false;
  final TextEditingController _watermarkTextController =
      TextEditingController();
  final TextEditingController _filenameController = TextEditingController();

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

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
    _scaleAnimation =
        Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

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
        _selectedFile = tempFile;
        _fileName = fileName;
      });
    }
  }

  Future<void> _addWatermark() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PDF file first.'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    if (_watermarkTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter watermark text.'),
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
          content: Text('Watermark creation cancelled. File name cannot be empty.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });
    try {
      final font = await FontLoader.getFont();
      final doc = await pdfx.PdfDocument.openFile(_selectedFile!.path);
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDoc = pw.Document();

      bool isRtl(String text) {
        return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
      }

      final textDirection = isRtl(_watermarkTextController.text)
          ? pw.TextDirection.rtl
          : pw.TextDirection.ltr;

      for (int i = 1; i <= doc.pagesCount; i++) {
        final page = await doc.getPage(i);
        final pageImage = await page.render(
          width: page.width,
          height: page.height,
          format: pdfx.PdfPageImageFormat.png,
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
                        opacity: 0.3,
                        child: pw.Text(
                          _watermarkTextController.text,
                          textDirection: textDirection,
                          style: pw.TextStyle(
                            font: font,
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
      final fullFileName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
      final filePath = '${appDir.path}/$fullFileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdfDoc.save());
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
          operation: 'Add Watermark',
          timestamp: DateTime.now(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Watermark added successfully'),
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
      setState(() {
        _selectedFile = null;
        _fileName = null;
        _watermarkTextController.clear();
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
    _filenameController.text = _fileName?.replaceAll('.pdf', '') ?? 'Watermarked_PDF_';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter File Name'),
        content: TextField(
          controller: _filenameController,
          decoration: const InputDecoration(
            hintText: 'e.g., MyWatermarkedDoc.pdf',
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
            child: const Text('Add Watermark'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _watermarkTextController.dispose();
    _animationController.dispose();
    _filenameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScreenTemplate(
      title: 'Add Watermark',
      icon: Icons.water_drop,
      actionButtonLabel: 'Add Watermark',
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
            const Text(
              'Select a PDF file and add a text watermark to it.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_selectedFile == null)
              Expanded(
                child: Center(
                  child: AnimatedScale(
                    scale: _scaleAnimation.value,
                    duration: const Duration(milliseconds: 500),
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
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.picture_as_pdf),
                            title: Text(
                              _fileName ?? _selectedFile!.path,
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
                          'Watermark text',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _watermarkTextController,
                          decoration: InputDecoration(
                            labelText: 'Enter watermark text',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          maxLines: 2,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The watermark will be placed diagonally across each page.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}
