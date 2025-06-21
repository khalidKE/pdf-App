import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/models/history_item.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
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

class ExcelToPdfScreen extends StatefulWidget {
  const ExcelToPdfScreen({Key? key}) : super(key: key);

  @override
  State<ExcelToPdfScreen> createState() => _ExcelToPdfScreenState();
}

class _ExcelToPdfScreenState extends State<ExcelToPdfScreen> with SingleTickerProviderStateMixin {
  File? _selectedFile;
  String? _fileName;
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

  Future<void> _selectFile() async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _convertToPdf() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an Excel file first'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

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
      final bytes = await _selectedFile!.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final pdf = pw.Document();
      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table]!;
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(table,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  pw.SizedBox(height: 12),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      for (var row in sheet.rows)
                        pw.TableRow(
                          children: [
                            for (var cell in row)
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(cell?.value?.toString() ?? ''),
                              ),
                          ],
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 24),
                ],
              );
            },
          ),
        );
      }
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
      // Add to history
      Provider.of<HistoryProvider>(context, listen: false).addHistoryItem(
        HistoryItem(
          title: p.basename(filePath),
          filePath: filePath,
          operation: 'Excel to PDF',
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
    _filenameController.text = _fileName?.replaceAll('.xls', '').replaceAll('.xlsx', '') ?? 'Excel_to_PDF_';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter File Name'),
        content: TextField(
          controller: _filenameController,
          decoration: const InputDecoration(
            hintText: 'e.g., MyReport.pdf',
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
    _animationController.dispose();
    _filenameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScreenTemplate(
      title: 'Excel to PDF',
      icon: Icons.table_chart,
      actionButtonLabel: 'Convert',
      isActionButtonEnabled: _selectedFile != null && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _convertToPdf,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Select an Excel file from your device to convert it into a PDF document.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Icon(
                Icons.table_chart,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 32),
              if (_selectedFile != null)
                SlideTransition(
                  position: _slideAnimation,
                  child: Card(
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
                  ),
                )
              else
                AnimatedScale(
                  scale: _scaleAnimation.value,
                  duration: const Duration(milliseconds: 500),
                  child: ElevatedButton.icon(
                    onPressed: _selectFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select Excel File'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
//ed