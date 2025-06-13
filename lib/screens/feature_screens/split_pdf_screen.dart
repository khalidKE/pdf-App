import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';

class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({Key? key}) : super(key: key);

  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  String? _selectedFile;
  final TextEditingController _pagesController = TextEditingController();
  bool _isProcessing = false;
  
  void _selectFile() {
    // Mock file selection
    setState(() {
      _selectedFile = 'document.pdf';
    });
  }
  
  void _splitPdf() async {
    if (_selectedFile == null || _pagesController.text.trim().isEmpty) return;
    
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
        content: Text(AppLocalizations.of(context).translate('pdf_split_success')),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  @override
  void dispose() {
    _pagesController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return FeatureScreenTemplate(
      title: loc.translate('split_pdf'),
      icon: Icons.call_split,
      actionButtonLabel: loc.translate('split'),
      isActionButtonEnabled: _selectedFile != null && 
                            _pagesController.text.trim().isNotEmpty && 
                            !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _splitPdf,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('split_pdf_instructions'),
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
                                _pagesController.clear();
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        loc.translate('split_options'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pagesController,
                        decoration: InputDecoration(
                          labelText: loc.translate('pages_to_split'),
                          hintText: loc.translate('pages_hint'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.translate('pages_format_help'),
                        style: Theme.of(context).textTheme.bodySmall,
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
