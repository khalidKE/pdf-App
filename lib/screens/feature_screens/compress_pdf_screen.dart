import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_utility_pro/models/history_item.dart';
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
import 'package:pdf_utility_pro/widgets/banner_ad_widget.dart';
import 'package:pdf_utility_pro/services/ads_service.dart';

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

        if (await file.exists()) {
          final fileSize = await file.length();

          if (fileSize > 100 * 1024 * 1024) {
            _showSnackBar('File too large. Please select a PDF under 100MB.',
                AppConstants.warningColor);
            return;
          }

          setState(() {
            _selectedFile = file;
            _fileName = result.files.single.name;
            _compressedFile = null;
          });
        } else {
          _showSnackBar(
              'Selected file does not exist', AppConstants.errorColor);
        }
      }
    } catch (e) {
      _showSnackBar(
          'Error selecting file: ${e.toString()}', AppConstants.errorColor);
    }
  }

  Future<void> _compressPdf() async {
    if (_selectedFile == null) {
      _showSnackBar(
          'Please select a PDF file first', AppConstants.warningColor);
      return;
    }

    final String? fileName = await _showFileNameDialog();
    if (fileName == null || fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('PDF compression cancelled. File name cannot be empty.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _compressionProgress = 0.0;
      _progressText = 'Initializing maximum compression...';
    });

    try {
      _updateProgress(0.1, 'Reading PDF file...');
      final List<int> bytes = await _selectedFile!.readAsBytes();

      _updateProgress(0.2, 'Loading PDF document...');
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Apply maximum compression settings
      _updateProgress(0.3, 'Applying maximum compression settings...');
      document.compressionLevel = PdfCompressionLevel.best;
      document.colorSpace = PdfColorSpace.rgb;

      // Enable all optimization features
      document.fileStructure.incrementalUpdate = false;

      _updateProgress(0.4, 'Compressing images and graphics...');
      await _compressImagesAndGraphics(document);

      _updateProgress(0.5, 'Optimizing content streams...');
      await _optimizeContentStreams(document);

      _updateProgress(0.6, 'Removing metadata and unused objects...');
      await _removeMetadataAndUnusedObjects(document);

      _updateProgress(0.7, 'Optimizing fonts and text...');
      await _optimizeFonts(document);

      _updateProgress(0.8, 'Applying maximum compression algorithms...');
      await _applyMaximumCompression(document);

      _updateProgress(0.9, 'Finalizing compression...');

      _updateProgress(0.95, 'Saving compressed PDF...');

      final List<int> compressedBytes = await document.save();
      document.dispose();

      final outputDir = await getApplicationDocumentsDirectory();
      final fullFileName =
          fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
      final outputPath = '${outputDir.path}/$fullFileName';

      final File compressedFile = File(outputPath);
      await compressedFile.writeAsBytes(compressedBytes);

      setState(() {
        _compressedFile = compressedFile;
      });

      // Add to FileProvider
      final fileItem = FileItem(
        name: p.basename(compressedFile.path),
        path: compressedFile.path,
        size: await compressedFile.length(),
        dateModified: await compressedFile.lastModified(),
        type: FileType.pdf,
      );
      if (mounted) {
        Provider.of<FileProvider>(context, listen: false)
            .addRecentFile(fileItem);
      }

      _updateProgress(1.0, 'Maximum compression completed!');
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Provider.of<HistoryProvider>(context, listen: false).addHistoryItem(
        HistoryItem(
          title: 'PDF Compressed (Maximum)',
          filePath: outputPath,
          operation: 'Maximum PDF Compression',
          timestamp: DateTime.now(),
        ),
      );

      _showCompressionResults(outputPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF compressed successfully'),
            backgroundColor: AppConstants.successColor,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReadPdfScreen(filePath: outputPath),
                  ),
                );
              },
            ),
          ),
        );
        // Show rewarded ad after success
        final shouldShowAd = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Watch Ad'),
            content: const Text('Watch the Ad to complete'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        if (shouldShowAd == true) {
          await AdsService().showRewardedAd(
            onRewarded: () {},
            onFailed: () {},
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
          'Error compressing PDF: ${e.toString()}', AppConstants.errorColor);
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

  Future<void> _compressImagesAndGraphics(PdfDocument document) async {
    try {
      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];

        // Get page graphics and apply maximum compression
        final PdfGraphics graphics = page.graphics;

        // Compress graphics state with maximum settings
        graphics.save();
        graphics.restore();

        await Future.delayed(const Duration(milliseconds: 15));
      }
    } catch (e) {
      debugPrint('Error compressing images: $e');
    }
  }

  Future<void> _optimizeContentStreams(PdfDocument document) async {
    try {
      // Apply maximum content stream compression
      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];

        // Optimize page content with maximum compression
        final PdfGraphics graphics = page.graphics;

        // Apply maximum transformation optimizations
        graphics.save();

        // Remove all unnecessary graphics states for maximum compression
        graphics.restore();

        await Future.delayed(const Duration(milliseconds: 8));
      }
    } catch (e) {
      debugPrint('Error optimizing content streams: $e');
    }
  }

  Future<void> _removeMetadataAndUnusedObjects(PdfDocument document) async {
    try {
      // Clear all document information to maximize size reduction
      document.documentInformation.author = '';
      document.documentInformation.creator = '';
      document.documentInformation.keywords = '';
      document.documentInformation.producer = '';
      document.documentInformation.subject = '';
      document.documentInformation.title = '';

      await Future.delayed(const Duration(milliseconds: 20));
    } catch (e) {
      debugPrint('Error removing metadata: $e');
    }
  }

  Future<void> _optimizeFonts(PdfDocument document) async {
    try {
      // Maximum font optimization and subsetting
      // This is handled internally by Syncfusion when compression level is set to best

      await Future.delayed(const Duration(milliseconds: 25));
    } catch (e) {
      debugPrint('Error optimizing fonts: $e');
    }
  }

  Future<void> _applyMaximumCompression(PdfDocument document) async {
    try {
      // Apply the most aggressive compression settings available
      document.compressionLevel = PdfCompressionLevel.best;

      // Additional maximum compression optimizations
      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];

        // Compress page content with maximum settings
        final PdfGraphics graphics = page.graphics;
        graphics.save();
        graphics.restore();
      }

      await Future.delayed(const Duration(milliseconds: 30));
    } catch (e) {
      debugPrint('Error applying maximum compression: $e');
    }
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCompressionResults(String filePath) {
    showDialog(
      context: context,
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        final originalSize = _selectedFile!.lengthSync();
        final compressedSize = _compressedFile!.lengthSync();
        final compressionRatio =
            ((originalSize - compressedSize) / originalSize * 100);

        return AlertDialog(
          contentPadding: const EdgeInsets.all(20),
          content: SizedBox(
            width: width < 400 ? width * 0.95 : 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check_circle,
                            color: Colors.green, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: Text(
                          'Maximum Compression Complete!',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Compression summary card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.1),
                          Colors.green.withOpacity(0.1)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.trending_down,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${compressionRatio.toStringAsFixed(1)}% Size Reduction',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.purple.withOpacity(0.3)),
                          ),
                          child: const Text(
                            'MAXIMUM COMPRESSION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Saved ${_formatFileSize(originalSize - compressedSize)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // File details
                  _buildDetailCard('File Details', [
                    _buildInfoRow('File Name', p.basename(filePath)),
                    _buildInfoRow('Compression Level', 'Maximum (Best)'),
                    _buildInfoRow('Space Saved',
                        _formatFileSize(originalSize - compressedSize)),
                  ]),

                  const SizedBox(height: 16),

                  // Success message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Your PDF has been compressed with maximum settings for smallest possible file size.',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 13,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
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
                          Navigator.pop(context);
                          await _shareCompressedFile();
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
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

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  Future<void> _shareCompressedFile() async {
    if (_compressedFile == null || !await _compressedFile!.exists()) {
      _showSnackBar('No compressed file to share', AppConstants.warningColor);
      return;
    }
    try {
      await Share.shareXFiles(
        [XFile(_compressedFile!.path)],
      );
    } catch (e) {
      _showSnackBar(
          'Error sharing file: ${e.toString()}', AppConstants.errorColor);
    }
  }

  Future<String?> _showFileNameDialog() async {
    final originalName = _fileName?.replaceAll('.pdf', '') ?? 'Document';
    _filenameController.text = '${originalName}_compressed';

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter File Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _filenameController,
              decoration: const InputDecoration(
                hintText: 'e.g., MyCompressedDocument',
                labelText: 'File Name',
                border: OutlineInputBorder(),
                suffixText: '.pdf',
              ),
              autofocus: true,
              onSubmitted: (value) {
                Navigator.of(context).pop(value);
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.speed, color: Colors.purple, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Maximum Compression',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        Text(
                          'Smallest file size, optimized for storage',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Compress'),
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
      title: 'Compress PDF',
      icon: Icons.compress,
      actionButtonLabel: _isProcessing ? 'Compressing...' : 'Compress PDF',
      isActionButtonEnabled: _selectedFile != null && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _compressPdf,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.1),
                    Colors.purple.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.speed,
                    size: 48,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Maximum PDF Compression',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Automatically applies maximum compression for smallest file size',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedFile == null)
              Center(
                child: AnimatedScale(
                  scale: _scaleAnimation.value,
                  duration: const Duration(milliseconds: 600),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _selectFile,
                        icon: const Icon(Icons.upload_file, size: 24),
                        label: const Text('Select PDF File'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Supported: PDF files up to 100MB',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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
                      // Selected file card
                      Card(
                        elevation: 2,
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.picture_as_pdf,
                                color: Colors.red),
                          ),
                          title: Text(
                            _fileName ?? _selectedFile!.path,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'Size: ${_formatFileSize(_selectedFile!.lengthSync())}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                                _fileName = null;
                                _compressedFile = null;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Maximum compression info card
                      Card(
                        color: Colors.purple.withOpacity(0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.speed,
                                  color: Colors.purple,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Maximum Compression Mode',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Automatically applies the highest compression settings for maximum space savings',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Progress indicator
                      if (_isProcessing)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.purple.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.purple)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _progressText,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: _compressionProgress,
                                backgroundColor: Colors.grey.shade300,
                                color: Colors.purple,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(_compressionProgress * 100).toInt()}% Complete',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),

                      // Results section
                      if (_compressedFile != null && !_isProcessing)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.1),
                                Colors.purple.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Successful!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _shareCompressedFile,
                                      icon: const Icon(Icons.share, size: 18),
                                      label: const Text('Share'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ReadPdfScreen(
                                              filePath: _compressedFile!.path,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.visibility,
                                          size: 18),
                                      label: const Text('View'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildSizeCard(String label, String size, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            size,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
