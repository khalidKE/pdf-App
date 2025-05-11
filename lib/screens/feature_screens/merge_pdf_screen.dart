import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:pdf_utility_pro/widgets/feature_screen_template.dart';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({Key? key}) : super(key: key);

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  final List<String> _selectedFiles = [];
  bool _isProcessing = false;
  
  void _selectFiles() {
    // Mock file selection
    setState(() {
      _selectedFiles.add('document1.pdf');
      _selectedFiles.add('document2.pdf');
    });
  }
  
  void _mergePdfs() async {
    if (_selectedFiles.length < 2) return;
    
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
        content: Text(AppLocalizations.of(context).translate('pdf_merged_success')),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return FeatureScreenTemplate(
      title: loc.translate('merge_pdf'),
      icon: Icons.merge_type,
      actionButtonLabel: loc.translate('merge'),
      isActionButtonEnabled: _selectedFiles.length >= 2 && !_isProcessing,
      isProcessing: _isProcessing,
      onActionButtonPressed: _mergePdfs,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              loc.translate('merge_pdf_instructions'),
              textAlign: TextAlign.center,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _selectFiles,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(loc.translate('select_pdf_files')),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedFiles.isEmpty
                ? Center(
                    child: Text(
                      loc.translate('no_pdf_files_selected'),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _selectedFiles.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final item = _selectedFiles.removeAt(oldIndex);
                        _selectedFiles.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      return Card(
                        key: Key('$index'),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf),
                          title: Text(_selectedFiles[index]),
                          subtitle: Text('${index + 1} of ${_selectedFiles.length}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _selectedFiles.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
