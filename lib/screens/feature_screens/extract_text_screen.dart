import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';

class ExtractTextScreen extends StatefulWidget {
  const ExtractTextScreen({Key? key}) : super(key: key);

  @override
  State<ExtractTextScreen> createState() => _ExtractTextScreenState();
}

class _ExtractTextScreenState extends State<ExtractTextScreen> {
  String? _selectedFile;
  String? _extractedText;
  bool _isProcessing = false;
  
  void _selectFile() {
    // Mock file selection
    setState(() {
      _selectedFile = 'document.pdf';
    });
  }
  
  void _extractText() async {
    if (_selectedFile == null) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    // Simulate processing
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isProcessing = false;
      _extractedText = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
          'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
          'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris '
          'nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in '
          'reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.';
    });
  }
  
  void _copyText() {
    if (_extractedText == null) return;
    
    // Copy to clipboard logic would go here
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).translate('text_copied')),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return FeatureScreenTemplate(
      title: loc.translate('extract_text'),
      icon: Icons.text_snippet,
      actionButtonLabel: _extractedText == null 
          ? loc.translate('extract_text') 
          : loc.translate('copy_text'),
      isActionButtonEnabled: _selectedFile != null && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _extractedText == null ? _extractText : _copyText,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('extract_text_instructions'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_selectedFile == null)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _selectFile,
                  icon: const Icon(Icons.upload_file),
                  label: Text(loc.translate('select_file')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(_selectedFile!),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                            _extractedText = null;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_extractedText != null) ...[
                    Text(
                      loc.translate('extracted_text'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: Text(_extractedText!),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
