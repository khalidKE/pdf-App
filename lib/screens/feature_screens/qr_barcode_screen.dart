import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:screenshot/screenshot.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:flutter/services.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:pdf_utility_pro/utils/constants.dart'; // Import AppConstants for snackbar colors
import 'package:pdf_utility_pro/widgets/banner_ad_widget.dart';

class QrBarcodeScreen extends StatefulWidget {
  const QrBarcodeScreen({Key? key}) : super(key: key);

  @override
  State<QrBarcodeScreen> createState() => _QrBarcodeScreenState();
}

class _QrBarcodeScreenState extends State<QrBarcodeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  String _qrData = '';
  bool _showQr = true;
  final ScreenshotController _screenshotController = ScreenshotController();
  String? _scanResult;
  final TextEditingController _filenameController = TextEditingController(); // Added controller

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _filenameController.dispose(); // Dispose the controller
    super.dispose();
  }

  Future<void> _saveImage() async {
    final image = await _screenshotController.capture();
    if (image == null) return;

    // Show dialog to get filename
    final String? fileName = await _showFileNameDialog();
    if (fileName == null || fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image saving cancelled. File name cannot be empty.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    try {
      const platform = MethodChannel('com.pdfutilitypro/media_store');
      // Pass the filename to the platform method
      final result = await platform.invokeMethod('saveImageToGallery', {
        'imageBytes': image,
        'fileName': fileName + ('${_showQr ? '_qr' : '_barcode'}.png'), // Add type suffix and extension
      });
      debugPrint('Save image result: $result');

      if (result == true) {
        debugPrint('Showing success dialog');
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Image saved successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        _filenameController.clear(); // Clear filename after saving
      } else {
        debugPrint('Showing failure dialog');
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Failed'),
            content: const Text('Failed to save image.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Exception when saving image: $e');
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  Future<String?> _showFileNameDialog() async {
    _filenameController.text = _showQr ? 'QR_Code_' : 'Barcode_'; // Default name suggestion
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter File Name'),
        content: TextField(
          controller: _filenameController,
          decoration: const InputDecoration(
            hintText: 'e.g., MyCode.png',
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR & Barcodes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Generate'),
            Tab(text: 'Scan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGenerateTab(context),
          _buildScanTab(context),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildGenerateTab(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(
                    height: 24,
                  ),
                  TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      labelText: 'Enter data',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _textController.clear();
                          setState(() {
                            _qrData = '';
                          });
                        },
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _qrData = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        child: ElevatedButton.icon(
                          onPressed: _qrData.isNotEmpty
                              ? () {
                                  setState(() {
                                    _showQr = true;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.qr_code),
                          label: const Text('QR'),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton.icon(
                          onPressed: _qrData.isNotEmpty
                              ? () {
                                  setState(() {
                                    _showQr = false;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.view_week),
                          label: const Text('Barcode'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_qrData.isEmpty)
                    Center(
                      child: Text(
                        'Enter data to generate',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Screenshot(
                            controller: _screenshotController,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _showQr
                                  ? QrImageView(
                                      data: _qrData,
                                    )
                                  : bw.BarcodeWidget(
                                      barcode: bw.Barcode.code128(),
                                      data: _qrData,
                                      width: 180,
                                      height: 80,
                                      drawText: false,
                                      backgroundColor: Colors.white,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _saveImage,
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanTab(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                setState(() {
                  _scanResult = barcodes.first.rawValue;
                });
              }
            },
          ),
        ),
        if (_scanResult != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: () => _launchURL(_scanResult!),
              child: Text(
                'Scan result: $_scanResult',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
      ],
    );
  }
}
