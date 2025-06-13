import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';

class AddWatermarkScreen extends StatefulWidget {
  const AddWatermarkScreen({Key? key}) : super(key: key);

  @override
  State<AddWatermarkScreen> createState() => _AddWatermarkScreenState();
}

class _AddWatermarkScreenState extends State<AddWatermarkScreen> {
  String? _selectedFile;
  final TextEditingController _watermarkTextController = TextEditingController();
  double _opacity = 0.3;
  bool _isProcessing = false;
  
  void _selectFile() {
    // Mock file selection
    setState(() {
      _selectedFile = 'document.pdf';
    });
  }
  
  void _addWatermark() async {
    if (_selectedFile == null || _watermarkTextController.text.trim().isEmpty) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    // Simulate processing
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isProcessing = false;
    });
    
    if (!mounted) return;
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).translate('watermark_added_success')),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  @override
  void dispose() {
    _watermarkTextController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return FeatureScreenTemplate(
      title: loc.translate('add_watermark'),
      icon: Icons.water_drop,
      actionButtonLabel: loc.translate('add_watermark'),
      isActionButtonEnabled: _selectedFile != null && 
                            _watermarkTextController.text.trim().isNotEmpty && 
                            !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _addWatermark,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('watermark_instructions'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_selectedFile == null)
              Expanded(
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _selectFile,
                    icon: const Icon(Icons.upload_file),
                    label: Text(loc.translate('select_pdf_file')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf),
                          title: Text(
                            _selectedFile!,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                                _watermarkTextController.clear();
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        loc.translate('watermark_text'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _watermarkTextController,
                        decoration: InputDecoration(
                          labelText: loc.translate('enter_watermark_text'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        loc.translate('watermark_options'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      // Add watermark options here
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
