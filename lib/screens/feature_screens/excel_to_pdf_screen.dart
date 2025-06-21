import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/models/history_item.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:excel/excel.dart' as excel;
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
import 'package:pdf_utility_pro/utils/font_loader.dart';

class ExcelToPdfScreen extends StatefulWidget {
  const ExcelToPdfScreen({Key? key}) : super(key: key);

  @override
  State<ExcelToPdfScreen> createState() => _ExcelToPdfScreenState();
}

class _ExcelToPdfScreenState extends State<ExcelToPdfScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedFile;
  String? _fileName;
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  final TextEditingController _filenameController = TextEditingController();
  double _conversionProgress = 0.0;
  int _totalSheets = 0;
  int _processedSheets = 0;
  String _currentSheet = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  Future<void> _selectFile() async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Validate file exists and has correct extension
        if (await file.exists()) {
          final extension = p.extension(file.path).toLowerCase();
          if (extension == '.xlsx' || extension == '.xls') {
            // Check file size (limit to 50MB)
            final fileSize = await file.length();
            if (fileSize > 50 * 1024 * 1024) {
              _showSnackBar(
                'File too large. Please select an Excel file under 50MB.',
                AppConstants.warningColor,
              );
              return;
            }

            setState(() {
              _selectedFile = file;
              _fileName = result.files.single.name;
              _conversionProgress = 0.0;
              _totalSheets = 0;
              _processedSheets = 0;
              _currentSheet = '';
            });

            _animationController.reset();
            _animationController.forward();
          } else {
            _showSnackBar(
              'Please select a valid Excel file (.xlsx or .xls)',
              AppConstants.errorColor,
            );
          }
        } else {
          _showSnackBar(
            'Selected file does not exist',
            AppConstants.errorColor,
          );
        }
      }
    } catch (e) {
      _handleError('Error selecting file: ${e.toString()}');
    }
  }

  Future<void> _convertToPdf() async {
    if (_selectedFile == null) {
      _showSnackBar(
        'Please select an Excel file first',
        AppConstants.warningColor,
      );
      return;
    }

    // Show dialog to get filename
    final String? fileName = await _showFileNameDialog();
    if (fileName == null || fileName.trim().isEmpty) {
      _showSnackBar(
        'PDF creation cancelled. File name cannot be empty.',
        AppConstants.errorColor,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _conversionProgress = 0.0;
      _processedSheets = 0;
    });

    try {
      final bytes = await _selectedFile!.readAsBytes();

      // Decode Excel file
      excel.Excel? excelFile;
      try {
        excelFile = excel.Excel.decodeBytes(bytes);
      } catch (e) {
        throw Exception(
            'Failed to read Excel file. The file might be corrupted or password protected.');
      }

      if (excelFile.tables.isEmpty) {
        throw Exception('The Excel file contains no worksheets.');
      }

      _totalSheets = excelFile.tables.length;
      final pdf = pw.Document();
      final font = await FontLoader.getFont();

      int sheetIndex = 0;
      for (var tableName in excelFile.tables.keys) {
        setState(() {
          _currentSheet = tableName;
          _processedSheets = sheetIndex;
          _conversionProgress = sheetIndex / _totalSheets;
        });

        final sheet = excelFile.tables[tableName]!;

        if (sheet.rows.isEmpty) {
          // Skip empty sheets
          sheetIndex++;
          continue;
        }

        // Process sheet data
        final processedRows = _processSheetData(sheet);

        if (processedRows.isNotEmpty) {
          await _addSheetToPdf(pdf, tableName, processedRows, font);
        }

        sheetIndex++;

        // Allow UI to update
        await Future.delayed(const Duration(milliseconds: 50));
      }

      if (pdf.document.pdfPageList.pages.isEmpty) {
        throw Exception('No data found in the Excel file to convert.');
      }

      // Save PDF file
      final appDir = await getApplicationDocumentsDirectory();
      final fullFileName = fileName.trim().endsWith('.pdf')
          ? fileName.trim()
          : '${fileName.trim()}.pdf';
      final filePath = '${appDir.path}/$fullFileName';
      final file = File(filePath);

      await file.writeAsBytes(await pdf.save());

      // Add to recent files and history
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
            operation: 'Excel to PDF',
            timestamp: DateTime.now(),
          ),
        );

        _showSnackBar(
          'PDF created successfully from $_totalSheets sheet${_totalSheets > 1 ? 's' : ''}!',
          AppConstants.successColor,
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
        );

        // Reset state
        setState(() {
          _selectedFile = null;
          _fileName = null;
          _filenameController.clear();
          _conversionProgress = 0.0;
          _totalSheets = 0;
          _processedSheets = 0;
          _currentSheet = '';
        });
      }
    } catch (e) {
      _handleError('Error converting Excel to PDF: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _conversionProgress = 0.0;
        });
      }
    }
  }

  List<List<String>> _processSheetData(excel.Sheet sheet) {
    final List<List<String>> processedRows = [];

    for (var row in sheet.rows) {
      final List<String> processedRow = [];
      bool hasData = false;

      for (var cell in row) {
        String cellValue = '';
        if (cell != null && cell.value != null) {
          // Handle different data types
          if (cell.value is excel.SharedString) {
            cellValue = cell.value.toString();
          } else if (cell.value is int || cell.value is double) {
            cellValue = cell.value.toString();
          } else if (cell.value is bool) {
            cellValue = cell.value.toString().toUpperCase();
          } else {
            cellValue = cell.value.toString();
          }
          hasData = true;
        }
        processedRow.add(cellValue);
      }

      // Only add rows that have some data
      if (hasData) {
        processedRows.add(processedRow);
      }
    }

    return processedRows;
  }

  Future<void> _addSheetToPdf(
      pw.Document pdf, String sheetName, List<List<String>> rows, pw.Font font) async {
    // Calculate optimal column widths
    final maxColumns = rows.isNotEmpty
        ? rows.map((row) => row.length).reduce((a, b) => a > b ? a : b)
        : 0;
    if (maxColumns == 0) return;

    // Split large tables across multiple pages if needed
    const maxRowsPerPage = 25;
    final chunks = <List<List<String>>>[];

    for (int i = 0; i < rows.length; i += maxRowsPerPage) {
      final end =
          (i + maxRowsPerPage < rows.length) ? i + maxRowsPerPage : rows.length;
      chunks.add(rows.sublist(i, end));
    }

    for (int chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
      final chunk = chunks[chunkIndex];
      final isFirstPage = chunkIndex == 0;
      final pageTitle = chunks.length > 1
          ? '$sheetName (Page ${chunkIndex + 1}/${chunks.length})'
          : sheetName;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Sheet title
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 16),
                  child: pw.Text(
                    pageTitle,
                    style: pw.TextStyle(
                      font: font,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                      color: PdfColors.blue800,
                    ),
                  ),
                ),

                // Table
                pw.Expanded(
                  child: pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey400,
                      width: 0.5,
                    ),
                    columnWidths: _calculateColumnWidths(maxColumns),
                    children: chunk.map((row) {
                      final isHeaderRow =
                          isFirstPage && chunk.indexOf(row) == 0;
                      return pw.TableRow(
                        decoration: isHeaderRow
                            ? const pw.BoxDecoration(color: PdfColors.grey200)
                            : null,
                        children:
                            _buildTableCells(row, maxColumns, isHeaderRow, font),
                      );
                    }).toList(),
                  ),
                ),

                // Footer with sheet info
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 16),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Generated by PDF Utility Pro',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        'Sheet: $sheetName',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  Map<int, pw.TableColumnWidth> _calculateColumnWidths(int columnCount) {
    final Map<int, pw.TableColumnWidth> widths = {};
    final availableWidth = 1.0;
    final columnWidth = availableWidth / columnCount;

    for (int i = 0; i < columnCount; i++) {
      widths[i] = pw.FlexColumnWidth(columnWidth);
    }

    return widths;
  }

  List<pw.Widget> _buildTableCells(
      List<String> row, int maxColumns, bool isHeader, pw.Font font) {
    final List<pw.Widget> cells = [];

    bool isRtl(String text) {
      return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    }

    for (int i = 0; i < maxColumns; i++) {
      final cellValue = i < row.length ? row[i] : '';
      final textDirection = isRtl(cellValue) ? pw.TextDirection.rtl : pw.TextDirection.ltr;

      cells.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            cellValue,
            textDirection: textDirection,
            textAlign: textDirection == pw.TextDirection.rtl ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHeader ? PdfColors.black : PdfColors.grey800,
            ),
            maxLines: 3,
            overflow: pw.TextOverflow.clip,
          ),
        ),
      );
    }

    return cells;
  }

  Future<String?> _showFileNameDialog() async {
    _filenameController.text =
        _fileName?.replaceAll('.xlsx', '').replaceAll('.xls', '') ??
            'Excel_to_PDF_${DateTime.now().millisecondsSinceEpoch}';

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Export PDF File',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Choose a name for your PDF file:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 20),

                    // Text Field
                    TextField(
                      controller: _filenameController,
                      decoration: InputDecoration(
                        hintText: 'e.g., MyReport',
                        labelText: 'File Name',
                        suffixText: '.pdf',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(Icons.edit),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          Navigator.of(context).pop(value.trim());
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(null),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final fileName = _filenameController.text.trim();
                            if (fileName.isNotEmpty) {
                              Navigator.of(context).pop(fileName);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Convert'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, Color backgroundColor,
      {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        action: action,
      ),
    );
  }

  void _handleError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppConstants.errorColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _removeSelectedFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _conversionProgress = 0.0;
      _totalSheets = 0;
      _processedSheets = 0;
      _currentSheet = '';
    });
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
      actionButtonLabel: _isProcessing
          ? 'Converting... ${(_conversionProgress * 100).toInt()}%'
          : 'Convert to PDF',
      isActionButtonEnabled: _selectedFile != null && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _convertToPdf,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Select an Excel file (.xlsx, .xls) to convert it into a PDF document.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedFile == null)
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.table_chart,
                              size: 80,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: _selectFile,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Select Excel File'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Supported formats: .xlsx, .xls\nMax file size: 50MB',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SlideTransition(
                        position: _slideAnimation,
                        child: Card(
                          elevation: 2,
                          child: ListTile(
                            leading: Icon(
                              Icons.table_chart,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              _fileName ?? p.basename(_selectedFile!.path),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: _totalSheets > 0
                                ? Text(
                                    '$_totalSheets worksheet${_totalSheets > 1 ? 's' : ''}')
                                : const Text('Ready to convert'),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _removeSelectedFile,
                              tooltip: 'Remove file',
                            ),
                          ),
                        ),
                      ),
                      if (_isProcessing) ...[
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  'Converting Excel to PDF...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                if (_currentSheet.isNotEmpty)
                                  Text(
                                    'Processing: $_currentSheet',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                const SizedBox(height: 16),
                                LinearProgressIndicator(
                                  value: _conversionProgress,
                                  backgroundColor: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Sheet $_processedSheets of $_totalSheets',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      '${(_conversionProgress * 100).toInt()}% complete',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 24),
                        const Text(
                          'File selected successfully! Click "Convert to PDF" to proceed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'The PDF will be created in landscape format for better table display. Each worksheet will be converted to separate pages.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
