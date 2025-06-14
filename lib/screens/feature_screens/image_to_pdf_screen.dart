import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf_utility_pro/models/history_item.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
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

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({Key? key}) : super(key: key);

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final List<XFile> _selectedImages = [];
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _selectImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();

    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImages.add(photo);
        });
      }
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                    .translate('camera_access_denied') ??
                'Camera access denied.'),
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

    setState(() {
      _isProcessing = true;
    });

    try {
      // Create PDF document
      final pdf = pw.Document();

      // Add each image as a page
      for (var imageFile in _selectedImages) {
        final image = pw.MemoryImage(
          File(imageFile.path).readAsBytesSync(),
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

      // Get the app directory
      final appDir = await AppPermissionHandler.getAppDirectory();

      // Generate a unique filename
      final fileName =
          'Image to PDF_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '$appDir/$fileName';

      // Save the PDF
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
          operation: 'Image to PDF',
          timestamp: DateTime.now(),
        ),
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)
              .translate('pdf created successfully')),
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

      // Clear selected images
      setState(() {
        _selectedImages.clear();
      });
    } catch (e) {
      // Show error message
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

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return FeatureScreenTemplate(
      title: loc.translate('Image to PDF'),
      icon: Icons.image,
      actionButtonLabel: loc.translate('Create Pdf'),
      isActionButtonEnabled: _selectedImages.isNotEmpty && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _createPdf,
      processingIndicator: SpinKitRing(
        color: Theme.of(context).colorScheme.primary,
        size: 24.0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              loc.translate(
                  'Select images from your device or take photos with your camera to convert them into a PDF document.'),
              textAlign: TextAlign.center,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _selectImages,
                icon: const Icon(Icons.photo_library),
                label: Text(loc.translate('Select Images')),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: Text(loc.translate('Take Photo')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedImages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.translate('No images selected'),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return _buildImageCard(index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(int index) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(_selectedImages[index].path),
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => _removeImage(index),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: Colors.black.withOpacity(0.5),
              child: Text(
                'Image ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
