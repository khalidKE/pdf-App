import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/history_provider.dart';
import 'package:pdf_utility_pro/models/history_item.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExtractTextScreen extends StatefulWidget {
  const ExtractTextScreen({super.key});

  @override
  State<ExtractTextScreen> createState() => _ExtractTextScreenState();
}

class _ExtractTextScreenState extends State<ExtractTextScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedFile;
  String? _fileName;
  bool _isProcessing = false;
  String _extractedText = '';
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();
  int _currentMatchIndex = 0;
  List<int> _searchMatches = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _searchController.addListener(_onSearchChanged);
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
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Validate file exists and is a PDF
        if (await file.exists()) {
          final extension = p.extension(file.path).toLowerCase();
          if (extension == '.pdf') {
            // Check file size (limit to 50MB)
            final fileSize = await file.length();
            if (fileSize > 50 * 1024 * 1024) {
              _showSnackBar('File too large. Please select a PDF under 50MB.',
                  Colors.orange);
              return;
            }

            setState(() {
              _selectedFile = file;
              _fileName = result.files.single.name;
              _extractedText = '';
              _searchQuery = '';
              _searchController.clear();
              _searchMatches.clear();
              _currentMatchIndex = 0;
            });
          } else {
            _showSnackBar('Please select a valid PDF file', Colors.red);
          }
        } else {
          _showSnackBar('Selected file does not exist', Colors.red);
        }
      }
    } catch (e) {
      _handleError('Error selecting file: ${e.toString()}');
    }
  }

  Future<void> _extractText() async {
    if (_selectedFile == null) {
      _showSnackBar('Please select a PDF file first', Colors.orange);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final file = _selectedFile!;
      final bytes = await file.readAsBytes();

      // Create PDF document
      PdfDocument? document;
      try {
        document = PdfDocument(inputBytes: bytes);

        // Extract text
        final textExtractor = PdfTextExtractor(document);
        final extractedText = textExtractor.extractText();

        if (extractedText.trim().isEmpty) {
          throw Exception(
              'No text found in the PDF. The PDF might contain only images or be password protected.');
        }

        setState(() {
          _extractedText = extractedText.trim();
        });

        // Add to history
        if (mounted) {
          Provider.of<HistoryProvider>(context, listen: false).addHistoryItem(
            HistoryItem(
              title: p.basename(file.path),
              filePath: file.path,
              operation: 'Extract Text',
              timestamp: DateTime.now(),
            ),
          );
        }

        _showSnackBar('Text extracted successfully!', Colors.green);
      } finally {
        document?.dispose();
      }
    } catch (e) {
      _handleError('Error extracting text: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _copyText() async {
    if (_extractedText.isEmpty) {
      _showSnackBar('No text to copy', Colors.orange);
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: _extractedText));
      _showSnackBar('Text copied to clipboard!', Colors.green);
    } catch (e) {
      _handleError('Error copying text: ${e.toString()}');
    }
  }

  Future<void> _exportText() async {
    if (_extractedText.isEmpty) {
      _showSnackBar('No text to export', Colors.orange);
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final fileName = _fileName?.replaceAll('.pdf', '') ?? 'extracted_text';
      final file = File('${directory.path}/${fileName}_extracted.txt');

      await file.writeAsString(_extractedText);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Extracted text from ${_fileName ?? 'PDF'}',
        subject: 'PDF Text Extraction',
      );

      _showSnackBar('Text exported successfully!', Colors.green);
    } catch (e) {
      _handleError('Error exporting text: ${e.toString()}');
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    setState(() {
      _searchQuery = query;
      _searchMatches.clear();
      _currentMatchIndex = 0;

      if (query.isNotEmpty && _extractedText.isNotEmpty) {
        final lowerText = _extractedText.toLowerCase();
        final lowerQuery = query.toLowerCase();

        int index = -1;
        while ((index = lowerText.indexOf(lowerQuery, index + 1)) != -1) {
          _searchMatches.add(index);
        }
      }
    });
  }

  void _navigateSearch(bool next) {
    if (_searchMatches.isEmpty) return;

    setState(() {
      if (next) {
        _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatches.length;
      } else {
        _currentMatchIndex = (_currentMatchIndex - 1 + _searchMatches.length) %
            _searchMatches.length;
      }
    });

    // Scroll to the match position
    _scrollToMatch();
  }

  void _scrollToMatch() {
    if (_searchMatches.isEmpty) return;

    final position = _searchMatches[_currentMatchIndex];
    final lines = _extractedText.substring(0, position).split('\n').length;
    final approximateOffset = lines * 20.0; // Approximate line height

    _scrollController.animateTo(
      approximateOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _extractedText = '';
      _searchQuery = '';
      _searchController.clear();
      _searchMatches.clear();
      _currentMatchIndex = 0;
    });
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _handleError(String message) {
    debugPrint('ExtractTextScreen Error: $message');
    _showSnackBar(message, Colors.red);
  }

  Widget _buildHighlightedText() {
    if (_searchQuery.isEmpty || _searchMatches.isEmpty) {
      return SelectableText(
        _extractedText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
        textAlign: TextAlign.justify,
      );
    }

    // Build highlighted text
    final spans = <TextSpan>[];
    int lastIndex = 0;

    for (int i = 0; i < _searchMatches.length; i++) {
      final matchIndex = _searchMatches[i];

      // Add text before match
      if (matchIndex > lastIndex) {
        spans.add(TextSpan(
          text: _extractedText.substring(lastIndex, matchIndex),
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: _extractedText.substring(
            matchIndex, matchIndex + _searchQuery.length),
        style: TextStyle(
          backgroundColor: i == _currentMatchIndex
              ? Colors.orange.withOpacity(0.7)
              : Colors.yellow.withOpacity(0.5),
          fontWeight: FontWeight.bold,
        ),
      ));

      lastIndex = matchIndex + _searchQuery.length;
    }

    // Add remaining text
    if (lastIndex < _extractedText.length) {
      spans.add(TextSpan(
        text: _extractedText.substring(lastIndex),
      ));
    }

    return SelectableText.rich(
      TextSpan(
        children: spans,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
      ),
      textAlign: TextAlign.justify,
    );
  }

  double _getTextContainerHeight(String text, double width) {
    if (text.isEmpty) return 200;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    textPainter.layout(maxWidth: width - 32); // Subtract padding
    final textHeight = textPainter.size.height;
    textPainter.dispose();

    // Add padding and limit max height
    final containerHeight = textHeight + 32; // Add padding
    final maxHeight =
        MediaQuery.of(context).size.height * 0.6; // Max 60% of screen height

    return containerHeight > maxHeight ? maxHeight : containerHeight;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return FeatureScreenTemplate(
      title: 'Extract Text from PDF',
      icon: Icons.text_snippet_outlined,
      actionButtonLabel: _extractedText.isEmpty ? 'Extract Text' : 'Copy Text',
      isActionButtonEnabled: _selectedFile != null && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _extractedText.isEmpty ? _extractText : _copyText,
      body: SingleChildScrollView(
        controller: _mainScrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a PDF file to extract text from it. The extracted text can be copied, searched, and exported.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            if (_selectedFile == null)
              Center(
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: ElevatedButton.icon(
                        onPressed: _selectFile,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Select PDF File'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File info card
                    SizedBox(
                      width: screenWidth - 32, // Fixed width based on screen
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf_outlined),
                          title: Text(
                            _fileName ?? p.basename(_selectedFile!.path),
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          subtitle: FutureBuilder<int>(
                            future: _selectedFile!.length(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final sizeKB = snapshot.data! / 1024;
                                return Text(
                                  '${sizeKB.toStringAsFixed(1)} KB',
                                  style: Theme.of(context).textTheme.bodySmall,
                                );
                              }
                              return const Text('Calculating size...');
                            },
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Clear Selection',
                            onPressed: _clearSelection,
                          ),
                        ),
                      ),
                    ),

                    // Export button when text is extracted
                    if (_extractedText.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: screenWidth - 32, // Fixed width based on screen
                        child: OutlinedButton.icon(
                          onPressed: _exportText,
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Export Text'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Search and text display
                    if (_extractedText.isNotEmpty) ...[
                      const SizedBox(height: 16),

                      // Search bar
                      SizedBox(
                        width: screenWidth - 32, // Fixed width based on screen
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search in extracted text...',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),

                            // Search navigation
                            if (_searchMatches.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_currentMatchIndex + 1}/${_searchMatches.length}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_up),
                                tooltip: 'Previous Match',
                                onPressed: () => _navigateSearch(false),
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down),
                                tooltip: 'Next Match',
                                onPressed: () => _navigateSearch(true),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Text display header
                      SizedBox(
                        width: screenWidth - 32, // Fixed width based on screen
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Extracted Text',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '${_extractedText.length} characters',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Text display container with fixed width and dynamic height
                      Container(
                        width: screenWidth - 32, // Fixed width based on screen
                        height: _getTextContainerHeight(
                            _extractedText, screenWidth - 32),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: _buildHighlightedText(),
                        ),
                      ),

                      // Add some bottom spacing
                      SizedBox(height: screenHeight * 0.1),
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
