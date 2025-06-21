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
import 'package:pdf_utility_pro/utils/constants.dart'; // Import AppConstants for snackbar colors

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
  final TextEditingController _filenameController = TextEditingController(); // Added controller

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
                  AppConstants.warningColor);
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
            _showSnackBar('Please select a valid PDF file', AppConstants.errorColor);
          }
        } else {
          _showSnackBar('Selected file does not exist', AppConstants.errorColor);
        }
      }
    } catch (e) {
      _handleError('Error selecting file: ${e.toString()}');
    }
  }

  Future<void> _extractText() async {
    if (_selectedFile == null) {
      _showSnackBar('Please select a PDF file first', AppConstants.warningColor);
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

        _showSnackBar('Text extracted successfully!', AppConstants.successColor);
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
      _showSnackBar('No text to copy', AppConstants.warningColor);
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: _extractedText));
      _showSnackBar('Text copied to clipboard!', AppConstants.successColor);
    } catch (e) {
      _handleError('Error copying text: ${e.toString()}');
    }
  }

  Future<void> _exportText() async {
    if (_extractedText.isEmpty) {
      _showSnackBar('No text to export', AppConstants.warningColor);
      return;
    }

    // Show dialog to get filename
    final String? fileName = await _showFileNameDialog();
    if (fileName == null || fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text export cancelled. File name cannot be empty.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final fullFileName = fileName.endsWith('.txt') ? fileName : '$fileName.txt';
      final file = File('${directory.path}/$fullFileName');

      await file.writeAsString(_extractedText);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Extracted text from ${_fileName ?? 'PDF'}',
        subject: 'PDF Text Extraction',
      );

      _showSnackBar('Text exported successfully!', AppConstants.successColor);
      _filenameController.clear(); // Clear filename after creation
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
      curve: Curves.easeIn,
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  void _handleError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<String?> _showFileNameDialog() async {
    _filenameController.text = _fileName?.replaceAll('.pdf', '') ?? 'Extracted_Text_'; // Default name suggestion
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter File Name'),
        content: TextField(
          controller: _filenameController,
          decoration: const InputDecoration(
            hintText: 'e.g., MyExtractedText.txt',
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
              Navigator.of(context).pop(null); // Return null on cancel
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(_filenameController.text.trim());
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _mainScrollController.dispose();
    _filenameController.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScreenTemplate(
      title: 'Extract Text',
      icon: Icons.text_snippet,
      actionButtonLabel: 'Extract Text',
      isActionButtonEnabled: _selectedFile != null && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _extractText,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a PDF file to extract all text content from it.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_selectedFile == null)
              Expanded(
                child: Center(
                  child: AnimatedScale(
                    scale: _scaleAnimation.value,
                    duration: const Duration(milliseconds: 600),
                    child: ElevatedButton.icon(
                      onPressed: _selectFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select PDF File'),
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
                  controller: _mainScrollController,
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
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedFile = null;
                                  _fileName = null;
                                  _extractedText = '';
                                  _searchController.clear();
                                  _searchMatches.clear();
                                  _currentMatchIndex = 0;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_extractedText.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Extracted Text',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                height: 200,
                                child: Scrollbar(
                                  controller: _scrollController,
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    child: RichText(
                                      text: TextSpan(
                                        children: _buildTextSpans(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _copyText,
                                      icon: const Icon(Icons.copy),
                                      label: const Text('Copy Text'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _exportText,
                                      icon: const Icon(Icons.share),
                                      label: const Text('Export Text'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Search in Extracted Text',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  labelText: 'Search',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                          },
                                        )
                                      : null,
                                ),
                              ),
                              if (_searchMatches.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                          '${_currentMatchIndex + 1} of ${_searchMatches.length}'),
                                      IconButton(
                                        icon: const Icon(Icons.arrow_upward),
                                        onPressed: () => _navigateSearch(false),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.arrow_downward),
                                        onPressed: () => _navigateSearch(true),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 24),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _buildTextSpans() {
    final List<TextSpan> spans = [];
    int lastIndex = 0;

    if (_searchQuery.isEmpty || _extractedText.isEmpty) {
      spans.add(TextSpan(text: _extractedText));
      return spans;
    }

    for (int i = 0; i < _searchMatches.length; i++) {
      final matchIndex = _searchMatches[i];
      final isCurrentMatch = (i == _currentMatchIndex);

      // Add text before the current match
      if (matchIndex > lastIndex) {
        spans.add(TextSpan(text: _extractedText.substring(lastIndex, matchIndex)));
      }

      // Add the matched text with highlight
      spans.add(TextSpan(
        text: _extractedText.substring(matchIndex, matchIndex + _searchQuery.length),
        style: TextStyle(
          backgroundColor: isCurrentMatch ? Colors.yellow : Colors.blue.withOpacity(0.3),
          fontWeight: isCurrentMatch ? FontWeight.bold : FontWeight.normal,
          color: Colors.black,
        ),
      ));

      lastIndex = matchIndex + _searchQuery.length;
    }

    // Add any remaining text after the last match
    if (lastIndex < _extractedText.length) {
      spans.add(TextSpan(text: _extractedText.substring(lastIndex)));
    }

    return spans;
  }
}
//ed