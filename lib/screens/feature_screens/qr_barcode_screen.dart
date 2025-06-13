import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';

class QrBarcodeScreen extends StatefulWidget {
  const QrBarcodeScreen({Key? key}) : super(key: key);

  @override
  State<QrBarcodeScreen> createState() => _QrBarcodeScreenState();
}

class _QrBarcodeScreenState extends State<QrBarcodeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  String _qrData = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('qr_barcode')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.translate('generate')),
            Tab(text: loc.translate('scan')),
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
    );
  }
  
  Widget _buildGenerateTab(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: loc.translate('enter_data'),
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
                          // Generate QR code
                        }
                      : null,
                  icon: const Icon(Icons.qr_code),
                  label: Text(loc.translate('generate_qr')),
                ),
              ),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: _qrData.isNotEmpty
                      ? () {
                          // Generate barcode
                        }
                      : null,
                  icon: const Icon(Icons.view_week),
                  label: Text(loc.translate('generate_barcode')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _qrData.isEmpty
                ? Center(
                    child: Text(
                      loc.translate('enter_data_to_generate'),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.qr_code,
                              size: 100,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Save QR code
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.translate('qr_saved')),
                              ),
                            );
                          },
                          icon: const Icon(Icons.save),
                          label: Text(loc.translate('save')),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScanTab(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 100,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            loc.translate('scan_instructions'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Implement QR/barcode scanning
            },
            icon: const Icon(Icons.camera_alt),
            label: Text(loc.translate('start_scanning')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
