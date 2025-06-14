import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/models/history_item.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
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

class _ExcelToPdfScreenState extends State<ExcelToPdfScreen> {
  String? _selectedFile;
  String? _fileName;
  bool _isProcessing = false;

  Future<void> _selectFile() async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = result.files.single.path;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _convertToPdf() async {
    if (_selectedFile == null) return;
    setState(() {
      _isProcessing = true;
    });
    try {
      final bytes = File(_selectedFile!).readAsBytesSync();
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
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'Excel_to_PDF_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
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
      // Add to history
      Provider.of<HistoryProvider>(context, listen: false).addHistoryItem(
        HistoryItem(
          title: p.basename(filePath),
          filePath: filePath,
          operation: 'excel_to_pdf',
          timestamp: DateTime.now(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context).translate('pdf_created_success')),
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
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: \\${e.toString()}'),
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
      title: loc.translate('excel_to_pdf'),
      icon: Icons.table_chart,
      actionButtonLabel: loc.translate('convert'),
      isActionButtonEnabled: _selectedFile != null && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _convertToPdf,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                loc.translate('excel_to_pdf_instructions'),
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
                  label: Text(loc.translate('select_excel_file')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
