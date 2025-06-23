import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf_utility_pro/models/history_item.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';
import 'package:pdf_utility_pro/widgets/banner_ad_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/file_provider.dart';
import 'package:pdf_utility_pro/models/file_item.dart';
import 'package:pdf_utility_pro/utils/permission_handler.dart';
import 'dart:io';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pdf_utility_pro/utils/constants.dart';
import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';
import 'package:pdf_utility_pro/providers/history_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_utility_pro/services/ads_service.dart';

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({Key? key}) : super(key: key);

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> with SingleTickerProviderStateMixin {
  List<File> _selectedImages = [];
  List<String> _imageNames = [];
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();
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
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  Future<void> _selectImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();

    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((e) => File(e.path)));
        _imageNames.addAll(images.map((e) => e.name));
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImages.add(File(photo.path));
          _imageNames.add(photo.name);
        });
      }
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera access denied'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _createPdf() async {
    if (_selectedImages.isEmpty) return;

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
      final pdf = pw.Document();

      for (var imageFile in _selectedImages) {
        final image = pw.MemoryImage(
          imageFile.readAsBytesSync(),
        );

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image),
              );
            },
          ),
        );
      }

      final appDir = await AppPermissionHandler.getAppDirectory();

      final fullFileName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
      final filePath = '$appDir/$fullFileName';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

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
          operation: 'Image to PDF',
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

      // Show rewarded ad after success
      await AdsService().showRewardedAd(
        onRewarded: () {},
        onFailed: () {},
      );

      setState(() {
        _selectedImages.clear();
        _imageNames.clear();
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
    _filenameController.text = 'Image_to_PDF_';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter File Name'),
        content: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: TextField(
            controller: _filenameController,
            decoration: const InputDecoration(
              hintText: 'e.g., MyDocument.pdf',
              labelText: 'File Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (value) {
              Navigator.of(context).pop(value);
            },
          ),
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
            child: const Text('Create'),
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
      title: 'Image to PDF',
      icon: Icons.image,
      actionButtonLabel: 'Create Pdf',
      isActionButtonEnabled: _selectedImages.isNotEmpty && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _createPdf,
      processingIndicator: SpinKitRing(
        color: Theme.of(context).colorScheme.primary,
        size: 24.0,
      ),
      body: Column(
        children: [
          const AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 500),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select images from your device or take photos with your camera to convert them into a PDF document.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          AnimatedScale(
            scale: _scaleAnimation.value,
            duration: const Duration(milliseconds: 500),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _selectImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Select Images'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_selectedImages.isNotEmpty)
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Images',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              final imageFile = _selectedImages[index];
                              final imageName = _imageNames[index];
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      imageFile,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedImages.removeAt(index);
                                          _imageNames.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        imageName,
                                        style: const TextStyle(color: Colors.white, fontSize: 10),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // const BannerAdWidget(),
        ],
      ),
    );
  }
}
