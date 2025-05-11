import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';

class EditPdfScreen extends StatefulWidget {
  const EditPdfScreen({Key? key}) : super(key: key);

  @override
  State<EditPdfScreen> createState() => _EditPdfScreenState();
}

class _EditPdfScreenState extends State<EditPdfScreen> {
  String? _selectedFile;
  bool _isProcessing = false;
  
  void _selectFile() {
    // Mock file selection
    setState(() {
      _selectedFile = 'document.pdf';
    });
  }
  
  void _editPdf() async {
    if (_selectedFile == null) return;
    
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
        content: Text(AppLocalizations.of(context).translate('pdf_edited_success')),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return FeatureScreenTemplate(
      title: loc.translate('edit_pdf'),
      icon: Icons.edit_document,
      actionButtonLabel: loc.translate('save_changes'),
      isActionButtonEnabled: _selectedFile != null && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _editPdf,
      body: _selectedFile == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loc.translate('edit_pdf_instructions'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _selectFile,
                    icon: const Icon(Icons.upload_file),
                    label: Text(loc.translate('select_pdf_file')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFile!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildEditOption(
                        context,
                        Icons.text_fields,
                        loc.translate('edit_text'),
                        loc.translate('edit_text_desc'),
                      ),
                      _buildEditOption(
                        context,
                        Icons.image,
                        loc.translate('edit_images'),
                        loc.translate('edit_images_desc'),
                      ),
                      _buildEditOption(
                        context,
                        Icons.delete,
                        loc.translate('delete_pages'),
                        loc.translate('delete_pages_desc'),
                      ),
                      _buildEditOption(
                        context,
                        Icons.rotate_right,
                        loc.translate('rotate_pages'),
                        loc.translate('rotate_pages_desc'),
                      ),
                      _buildEditOption(
                        context,
                        Icons.swap_vert,
                        loc.translate('reorder_pages'),
                        loc.translate('reorder_pages_desc'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildEditOption(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Handle edit option tap
        },
      ),
    );
  }
}
