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
import 'package:pdf_utility_pro/utils/font_loader.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'dart:convert';
import 'package:pdf_utility_pro/widgets/banner_ad_widget.dart';

String _extractTextFromDocx(String filePath) {
  try {
    final inputStream = InputFileStream(filePath);
    final archive = ZipDecoder().decodeBuffer(inputStream);
    inputStream.close();

    final documentFile = archive.files.firstWhere(
      (file) => file.name == 'word/document.xml',
      orElse: () => ArchiveFile('', 0, <int>[]),
    );

    if (documentFile.isFile && documentFile.content.isNotEmpty) {
      // استخدم utf8.decode بدل fromCharCodes
      final xmlString =
          utf8.decode(documentFile.content as List<int>, allowMalformed: true);
      final document = XmlDocument.parse(xmlString);

      final paragraphs = document.findAllElements('w:p');
      final buffer = StringBuffer();

      for (final p in paragraphs) {
        final texts = p.findAllElements('w:t');
        for (final t in texts) {
          buffer.write(t.text);
        }
        buffer.write('\n');
      }
      return buffer.toString().trim();
    }
    return '';
  } catch (e) {
    print('Error extracting text from DOCX: $e');
    return '';
  }
}

class WordToPdfScreen extends StatefulWidget {
  const WordToPdfScreen({Key? key}) : super(key: key);

  @override
  State<WordToPdfScreen> createState() => _WordToPdfScreenState();
}

class _WordToPdfScreenState extends State<WordToPdfScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedFile;
  String? _fileName;
  bool _isProcessing = false;
  final TextEditingController _filenameController = TextEditingController();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  double _conversionProgress = 0.0;
  String _currentStep = '';

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
        allowedExtensions: ['docx', 'doc'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Validate file exists and has correct extension
        if (await file.exists()) {
          final extension = p.extension(file.path).toLowerCase();
          if (extension == '.docx' || extension == '.doc') {
            // Check file size (limit to 25MB for Word documents)
            final fileSize = await file.length();
            if (fileSize > 25 * 1024 * 1024) {
              _showSnackBar(
                'File too large. Please select a Word file under 25MB.',
                AppConstants.warningColor,
              );
              return;
            }

            setState(() {
              _selectedFile = result.files.single.path;
              _fileName = result.files.single.name;
              _conversionProgress = 0.0;
              _currentStep = '';
            });

            _animationController.reset();
            _animationController.forward();
          } else {
            _showSnackBar(
              'Please select a valid Word file (.docx)',
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
        'Please select a Word file first',
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
      _currentStep = 'Reading Word document...';
    });

    try {
      // Extract text from the Word document
      setState(() {
        _conversionProgress = 0.2;
        _currentStep = 'Extracting text content...';
      });
      await Future.delayed(const Duration(milliseconds: 100));

      final text = _extractTextFromDocx(_selectedFile!);
      if (text.isEmpty) {
        throw Exception(
            'Could not extract text from Word file. The file might be empty, corrupted, or password protected.');
      }

      // Create PDF document
      setState(() {
        _conversionProgress = 0.4;
        _currentStep = 'Creating PDF document...';
      });
      await Future.delayed(const Duration(milliseconds: 100));

      // تحميل الخطوط
      final arabicFont = await FontLoader.getArabicFont();
      final latinFont = await FontLoader.getLatinFont();
      final pdf = pw.Document();

      // دالة لتحديد إذا كان النص عربي
      bool isArabic(String text) {
        return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
      }

      // دالة لإرجاع ستايل الخط المناسب
      pw.TextStyle getTextStyle(String text,
          {double fontSize = 12, PdfColor? color, pw.FontWeight? fontWeight}) {
        return pw.TextStyle(
          font: isArabic(text) ? arabicFont : latinFont,
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          lineSpacing: 1.5,
          height: 1.4,
        );
      }

      final textDirection =
          isArabic(text) ? pw.TextDirection.rtl : pw.TextDirection.ltr;
      final textAlign = textDirection == pw.TextDirection.rtl
          ? pw.TextAlign.right
          : pw.TextAlign.justify;

      // Split text into paragraphs for better formatting
      final paragraphs = text
          .split(RegExp(r'\n\s*\n'))
          .where((p) => p.trim().isNotEmpty)
          .toList();

      if (paragraphs.isEmpty) {
        // Fallback to word-based splitting
        final words = text.split(' ');
        final List<String> pages = [];
        String currentPage = '';

        for (String word in words) {
          if ((currentPage + word).length > 2500) {
            // Approximate characters per page
            pages.add(currentPage.trim());
            currentPage = word + ' ';
          } else {
            currentPage += word + ' ';
          }
        }
        if (currentPage.trim().isNotEmpty) {
          pages.add(currentPage.trim());
        }

        // Add pages to PDF
        setState(() {
          _conversionProgress = 0.6;
          _currentStep = 'Formatting PDF pages...';
        });
        await Future.delayed(const Duration(milliseconds: 100));

        for (int i = 0; i < pages.length; i++) {
          final pageText = pages[i];
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(32),
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header with page number
                    if (pages.length > 1)
                      pw.Container(
                        padding: const pw.EdgeInsets.only(bottom: 16),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              _fileName
                                      ?.replaceAll('.docx', '')
                                      .replaceAll('.doc', '') ??
                                  'Document',
                              style: getTextStyle(_fileName ?? 'Document',
                                  fontSize: 10),
                            ),
                            pw.Text(
                              'Page ${i + 1} of ${pages.length}',
                              style: getTextStyle('Page', fontSize: 10),
                            ),
                          ],
                        ),
                      ),

                    // Main content
                    pw.Expanded(
                      child: pw.Text(
                        pageText,
                        style: getTextStyle(pageText, fontSize: 12),
                        textAlign: isArabic(pageText)
                            ? pw.TextAlign.right
                            : pw.TextAlign.left,
                        textDirection: isArabic(pageText)
                            ? pw.TextDirection.rtl
                            : pw.TextDirection.ltr,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
      } else {
        // Process paragraphs for better formatting
        setState(() {
          _conversionProgress = 0.6;
          _currentStep = 'Formatting paragraphs...';
        });
        await Future.delayed(const Duration(milliseconds: 100));

        final List<String> pageContent = [];
        String currentPageContent = '';

        for (String paragraph in paragraphs) {
          final paragraphWithSpacing = paragraph.trim() + '\n\n';

          if ((currentPageContent + paragraphWithSpacing).length > 2500) {
            if (currentPageContent.isNotEmpty) {
              pageContent.add(currentPageContent.trim());
              currentPageContent = paragraphWithSpacing;
            } else {
              // Paragraph is too long, split it
              final words = paragraph.split(' ');
              String tempContent = '';
              for (String word in words) {
                if ((tempContent + word).length > 2500) {
                  pageContent.add(tempContent.trim());
                  tempContent = word + ' ';
                } else {
                  tempContent += word + ' ';
                }
              }
              currentPageContent = tempContent + '\n\n';
            }
          } else {
            currentPageContent += paragraphWithSpacing;
          }
        }

        if (currentPageContent.trim().isNotEmpty) {
          pageContent.add(currentPageContent.trim());
        }

        // Add formatted pages to PDF
        for (int i = 0; i < pageContent.length; i++) {
          final content = pageContent[i];
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(32),
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header with document title and page number
                    pw.Container(
                      padding: const pw.EdgeInsets.only(bottom: 20),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: PdfColors.grey300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              _fileName
                                      ?.replaceAll('.docx', '')
                                      .replaceAll('.doc', '') ??
                                  'Document',
                              style: getTextStyle(_fileName ?? 'Document',
                                      fontSize: 14)
                                  .copyWith(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue800,
                              ),
                              overflow: pw.TextOverflow.clip,
                              textAlign: isArabic(_fileName ?? '')
                                  ? pw.TextAlign.right
                                  : pw.TextAlign.left,
                              textDirection: isArabic(_fileName ?? '')
                                  ? pw.TextDirection.rtl
                                  : pw.TextDirection.ltr,
                            ),
                          ),
                          if (pageContent.length > 1)
                            pw.Text(
                              'Page ${i + 1} of ${pageContent.length}',
                              style: getTextStyle('Page', fontSize: 10),
                            ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 16),

                    // Main content
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: content
                            .split('\n')
                            .where((line) => line.trim().isNotEmpty)
                            .map((line) => pw.Text(
                                  line.trim(),
                                  style: getTextStyle(line, fontSize: 12)
                                      .copyWith(lineSpacing: 1.6),
                                  textAlign: isArabic(line)
                                      ? pw.TextAlign.right
                                      : pw.TextAlign.left,
                                  textDirection: isArabic(line)
                                      ? pw.TextDirection.rtl
                                      : pw.TextDirection.ltr,
                                  maxLines: 5 *
                                      1024, // large enough to avoid clipping
                                ))
                            .toList(),
                      ),
                    ),

                    // Footer
                    pw.Container(
                      padding: const pw.EdgeInsets.only(top: 16),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(
                            color: PdfColors.grey300,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Generated by PDF Utility Pro',
                            style: getTextStyle('Generated by PDF Utility Pro',
                                fontSize: 8),
                          ),
                          pw.Text(
                            DateTime.now().toString().split(' ')[0],
                            style: getTextStyle('Date', fontSize: 8),
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

      // Save PDF file
      setState(() {
        _conversionProgress = 0.8;
        _currentStep = 'Saving PDF file...';
      });
      await Future.delayed(const Duration(milliseconds: 100));

      final appDir = await getApplicationDocumentsDirectory();
      final fullFileName = fileName.trim().endsWith('.pdf')
          ? fileName.trim()
          : '${fileName.trim()}.pdf';
      final filePath = '${appDir.path}/$fullFileName';
      final file = File(filePath);

      await file.writeAsBytes(await pdf.save());

      // Add to recent files and history
      setState(() {
        _conversionProgress = 1.0;
        _currentStep = 'Finalizing...';
      });
      await Future.delayed(const Duration(milliseconds: 200));

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
            operation: 'Word to PDF',
            timestamp: DateTime.now(),
          ),
        );

        _showSnackBar(
          'PDF created successfully!',
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
          _currentStep = '';
        });
      }
    } catch (e) {
      _handleError('Error creating PDF: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _conversionProgress = 0.0;
          _currentStep = '';
        });
      }
    }
  }

  Future<String?> _showFileNameDialog() async {
    _filenameController.text =
        _fileName?.replaceAll('.docx', '').replaceAll('.doc', '') ??
            'Word_to_PDF_${DateTime.now().millisecondsSinceEpoch}';

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
                            'Enter File Name',
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
                        hintText: 'e.g., MyDocument',
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
      _currentStep = '';
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
      title: 'Word to PDF',
      icon: Icons.description,
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
              'Select a Word document (.docx, .doc) to convert it into a PDF',
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
                              Icons.description,
                              size: 80,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _selectFile,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Select Word File'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                textStyle: const TextStyle(fontSize: 16),
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
                              Icons.insert_drive_file,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              _fileName ?? 'Unknown file',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: const Text('Ready to convert'),
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
                                  'Converting Word to PDF...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                if (_currentStep.isNotEmpty)
                                  Text(
                                    _currentStep,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                const SizedBox(height: 16),
                                LinearProgressIndicator(
                                  value: _conversionProgress,
                                  backgroundColor: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(_conversionProgress * 100).toInt()}% complete',
                                  style: const TextStyle(fontSize: 12),
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
                            border: Border.all(color: Colors.blue.shade200),
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
                                'The PDF will preserve the document structure with proper formatting, headers, and page numbers.',
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
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}

class FontLoader {
  static Future<pw.Font> getArabicFont() async {
    final fontData =
        await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  static Future<pw.Font> getLatinFont() async {
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    return pw.Font.ttf(fontData);
  }
}
