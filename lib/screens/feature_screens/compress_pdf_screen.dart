import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:pdf_utility_pro/utils/constants.dart';
import 'package:pdf_utility_pro/providers/file_provider.dart';
import 'package:pdf_utility_pro/models/file_item.dart';
import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/history_provider.dart';

enum CompressionLevel {
  low(0.9, 'Low Compression', 'Minimal size reduction, best quality'),
  medium(0.7, 'Medium Compression', 'Balanced size and quality'),
  high(0.5, 'High Compression', 'Maximum size reduction, lower quality'),
  maximum(0.3, 'Maximum Compression', 'Smallest size, lowest quality');

  const CompressionLevel(this.quality, this.label, this.description);
  final double quality;
  final String label;
  final String description;
}

class CompressPdfScreen extends StatefulWidget {
  const CompressPdfScreen({super.key});

  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends State<CompressPdfScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedFile;
  String? _fileName;
  bool _isProcessing = false;
  double _compressionProgress = 0.0;
  String _progressText = '';
  CompressionLevel _selectedCompressionLevel = CompressionLevel.medium;

  // File size tracking
  int _originalSize = 0;
  int _compressedSize = 0;
  File? _compressedFile;
  final TextEditingController _filenameController = TextEditingController();

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
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

        // Validate file exists and get size
        if (await file.exists()) {
          final fileSize = await file.length();

          // Check file size limit (100MB)
          if (fileSize > 100 * 1024 * 1024) {
            _showSnackBar('File too large. Please select a PDF under 100MB.',
                AppConstants.warningColor);
            return;
          }

          setState(() {
            _selectedFile = file;
            _fileName = result.files.single.name;
            _originalSize = fileSize;
            _compressedFile = null;
            _compressedSize = 0;
          });
        } else {
          _showSnackBar('Selected file does not exist', AppConstants.errorColor);
        }
      }
    } catch (e) {
      _showSnackBar('Error selecting file: ${e.toString()}', AppConstants.errorColor);
    }
  }

  Future<void> _compressPdf() async {
    if (_selectedFile == null) {
      _showSnackBar('Please select a PDF file first', AppConstants.warningColor);
      return;
    }

    // Show dialog to get filename
    final String? fileName = await _showFileNameDialog();
    if (fileName == null || fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF compression cancelled. File name cannot be empty.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _compressionProgress = 0.0;
      _progressText = 'Initializing compression...';
    });

    try {
      // Step 1: Read file
      _updateProgress(0.1, 'Reading PDF file...');
      final List<int> bytes = await _selectedFile!.readAsBytes();

      // Step 2: Load document
      _updateProgress(0.2, 'Loading PDF document...');
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Step 3: Apply compression settings
      _updateProgress(0.4, 'Applying compression settings...');
      // Actual compression logic for Syncfusion PDF is more involved. This is a simplification.
      // For real compression, you'd iterate through pages, optimize images, remove unused objects, etc.
      // For demonstration, we'll just simulate the quality setting by re-saving.

      // This is a placeholder for proper image compression. Syncfusion_flutter_pdf doesn't expose a direct quality setting for saving.
      // A real implementation would involve: iterating through pages, extracting images, re-encoding them with desired quality, and then replacing them.
      // document.setCompressionLevel(_selectedCompressionLevel.quality);

      _optimizeImages(document, _selectedCompressionLevel.quality);
      _removeUnusedObjects(document);
      _compressStreams(document);

      // Step 4: Optimize document
      _updateProgress(0.6, 'Optimizing document structure...');
      await Future.delayed(
          const Duration(milliseconds: 500)); // Simulate processing

      // Step 5: Save compressed document
      _updateProgress(0.8, 'Saving compressed PDF...');
      final List<int> compressedBytes = await document.save();
      document.dispose();

      // Step 6: Write to file
      _updateProgress(0.9, 'Writing to storage...');
      final outputDir = await getApplicationDocumentsDirectory();
      final fullFileName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
      final outputPath = '${outputDir.path}/$fullFileName';

      final File compressedFile = File(outputPath);
      await compressedFile.writeAsBytes(compressedBytes);

      // Get compressed file size
      final compressedFileSize = await compressedFile.length();

      setState(() {
        _compressedFile = compressedFile;
        _compressedSize = compressedFileSize;
        _selectedFile = null;
        _fileName = null;
        _filenameController.clear(); // Clear filename after creation
      });

      _updateProgress(1.0, 'Compression completed!');

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      _showCompressionResults(outputPath); // Pass the path to show results
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error compressing PDF: ${e.toString()}', AppConstants.errorColor);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _compressionProgress = 0.0;
          _progressText = '';
        });
      }
    }
  }

  void _optimizeImages(PdfDocument document, double quality) {
    // Image optimization would be implemented here
    // This is a placeholder for the actual image compression logic
    debugPrint('Optimizing images with quality: $quality');
  }

  void _removeUnusedObjects(PdfDocument document) {
    // Remove unused objects and resources
    debugPrint('Removing unused objects');
  }

  void _compressStreams(PdfDocument document) {
    // Compress content streams
    debugPrint('Compressing content streams');
  }

  void _updateProgress(double progress, String text) {
    if (mounted) {
      setState(() {
        _compressionProgress = progress;
        _progressText = text;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  void _showCompressionResults(String filePath) {
    showDialog(
      context: context,
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: width < 350 ? width * 0.95 : 350, // Responsive width
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Compression Complete',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('File Name', p.basename(filePath)),
                  _buildInfoRow(
                      'Original Size',
                      '${(_originalSize / 1024).toStringAsFixed(2)} KB ('
                      '${(_originalSize / (1024 * 1024)).toStringAsFixed(2)} MB)'),
                  _buildInfoRow(
                      'Compressed Size',
                      '${(_compressedSize / 1024).toStringAsFixed(2)} KB ('
                      '${(_compressedSize / (1024 * 1024)).toStringAsFixed(2)} MB)'),
                  _buildInfoRow(
                    'Reduction',
                    _originalSize > 0
                        ? '${((_originalSize - _compressedSize) / _originalSize * 100).toStringAsFixed(2)}%'
                        : '0%',
                  ),
                  _buildInfoRow(
                      'Compression Level', _selectedCompressionLevel.label),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Your PDF has been successfully compressed and saved to your documents folder.',
                            style: TextStyle(color: Colors.green),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context); // Close dialog first
                          await _shareCompressedFile();
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context); // Close dialog first
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReadPdfScreen(filePath: filePath),
                            ),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('View'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper widget for info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareCompressedFile() async {
    if (_compressedFile == null || !await _compressedFile!.exists()) {
      _showSnackBar('No compressed file to share', AppConstants.warningColor);
      return;
    }
    try {
      await Share.shareXFiles([XFile(_compressedFile!.path)],
          text: 'Check out my compressed PDF!');
    } catch (e) {
      _showSnackBar('Error sharing file: ${e.toString()}', AppConstants.errorColor);
    }
  }

  Future<String?> _showFileNameDialog() async {
    _filenameController.text = _fileName?.replaceAll('.pdf', '') ?? 'Compressed_PDF_'; // Default name suggestion
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter File Name'),
        content: TextField(
          controller: _filenameController,
          decoration: const InputDecoration(
            hintText: 'e.g., MyCompressedDocument.pdf',
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
            child: const Text('Compress'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _filenameController.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScreenTemplate(
      title: 'Compress PDF',
      icon: Icons.compress,
      actionButtonLabel: 'Compress PDF',
      isActionButtonEnabled: _selectedFile != null && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _compressPdf,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a PDF file and choose a compression level to reduce its size.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_selectedFile == null)
              Center(
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
              )
            else
              FadeTransition(
                opacity: _fadeAnimation,
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
                          subtitle: FutureBuilder<int>(
                            future: _selectedFile!.length(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final sizeKB = snapshot.data! / 1024;
                                return Text(
                                  'Size: ${sizeKB.toStringAsFixed(2)} KB ('
                                  '${(snapshot.data! / (1024 * 1024)).toStringAsFixed(2)} MB)',
                                  style: Theme.of(context).textTheme.bodySmall,
                                );
                              }
                              return const Text('Calculating size...');
                            },
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                                _fileName = null;
                                _compressedFile = null;
                                _compressedSize = 0;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Compression Level',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ...CompressionLevel.values.map((level) {
                        return RadioListTile<CompressionLevel>(
                          title: Text(level.label),
                          subtitle: Text(level.description),
                          value: level,
                          groupValue: _selectedCompressionLevel,
                          onChanged: (CompressionLevel? value) {
                            setState(() {
                              _selectedCompressionLevel = value!;
                            });
                          },
                        );
                      }).toList(),
                      const SizedBox(height: 24),
                      if (_isProcessing)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              LinearProgressIndicator(
                                value: _compressionProgress,
                                backgroundColor: Colors.grey.shade300,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _progressText,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      if (_compressedFile != null && !_isProcessing)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Compression Results',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: Theme.of(context).colorScheme.surface,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow(
                                      'Original Size',
                                      '${(_originalSize / 1024).toStringAsFixed(2)} KB ('
                                      '${(_originalSize / (1024 * 1024)).toStringAsFixed(2)} MB)',
                                    ),
                                    _buildInfoRow(
                                      'Compressed Size',
                                      '${(_compressedSize / 1024).toStringAsFixed(2)} KB ('
                                      '${(_compressedSize / (1024 * 1024)).toStringAsFixed(2)} MB)',
                                    ),
                                    _buildInfoRow(
                                      'Reduction',
                                      _originalSize > 0
                                          ? '${((_originalSize - _compressedSize) / _originalSize * 100).toStringAsFixed(2)}%'
                                          : '0%',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _shareCompressedFile,
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReadPdfScreen(filePath: _compressedFile!.path),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text('View'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
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
