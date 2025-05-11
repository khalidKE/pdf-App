import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/models/feature.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:pdf_utility_pro/screens/feature_screens/image_to_pdf_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/text_to_pdf_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/qr_barcode_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/excel_to_pdf_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/word_to_pdf_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/merge_pdf_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/split_pdf_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/edit_pdf_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/add_watermark_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/add_signature_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/pdf_scanner_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/extract_text_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/view_files_screen.dart';

class FeatureGrid extends StatelessWidget {
  const FeatureGrid({Key? key}) : super(key: key);

  List<Feature> _getFeatures(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return [
      Feature(
        title: loc.translate('image_to_pdf'),
        description: loc.translate('image_to_pdf_desc'),
        icon: Icons.image,
        color: Colors.blue,
        screen: const ImageToPdfScreen(),
      ),
      Feature(
        title: loc.translate('text_to_pdf'),
        description: loc.translate('text_to_pdf_desc'),
        icon: Icons.text_fields,
        color: Colors.green,
        screen: const TextToPdfScreen(),
      ),
      Feature(
        title: loc.translate('qr_barcode'),
        description: loc.translate('qr_barcode_desc'),
        icon: Icons.qr_code,
        color: Colors.purple,
        screen: const QrBarcodeScreen(),
      ),
      Feature(
        title: loc.translate('excel_to_pdf'),
        description: loc.translate('excel_to_pdf_desc'),
        icon: Icons.table_chart,
        color: Colors.teal,
        screen: const ExcelToPdfScreen(),
      ),
      Feature(
        title: loc.translate('word_to_pdf'),
        description: loc.translate('word_to_pdf_desc'),
        icon: Icons.description,
        color: Colors.indigo,
        screen: const WordToPdfScreen(),
      ),
      Feature(
        title: loc.translate('merge_pdf'),
        description: loc.translate('merge_pdf_desc'),
        icon: Icons.merge_type,
        color: Colors.orange,
        screen: const MergePdfScreen(),
      ),
      Feature(
        title: loc.translate('split_pdf'),
        description: loc.translate('split_pdf_desc'),
        icon: Icons.call_split,
        color: Colors.red,
        screen: const SplitPdfScreen(),
      ),
      Feature(
        title: loc.translate('edit_pdf'),
        description: loc.translate('edit_pdf_desc'),
        icon: Icons.edit_document,
        color: Colors.amber,
        screen: const EditPdfScreen(),
      ),
      Feature(
        title: loc.translate('add_watermark'),
        description: loc.translate('add_watermark_desc'),
        icon: Icons.water_drop,
        color: Colors.lightBlue,
        screen: const AddWatermarkScreen(),
      ),
      Feature(
        title: loc.translate('add_signature'),
        description: loc.translate('add_signature_desc'),
        icon: Icons.draw,
        color: Colors.deepPurple,
        screen: const AddSignatureScreen(),
      ),
      Feature(
        title: loc.translate('pdf_scanner'),
        description: loc.translate('pdf_scanner_desc'),
        icon: Icons.document_scanner,
        color: Colors.brown,
        screen: const PdfScannerScreen(),
      ),
      Feature(
        title: loc.translate('extract_text'),
        description: loc.translate('extract_text_desc'),
        icon: Icons.text_snippet,
        color: Colors.cyan,
        screen: const ExtractTextScreen(),
      ),
      Feature(
        title: loc.translate('read_pdf'),
        description: loc.translate('read_pdf_desc'),
        icon: Icons.menu_book,
        color: Colors.deepOrange,
        screen: const ReadPdfScreen(filePath: '',),
      ),
      Feature(
        title: loc.translate('view_files'),
        description: loc.translate('view_files_desc'),
        icon: Icons.folder_open,
        color: Colors.blueGrey,
        screen: const ViewFilesScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final features = _getFeatures(context);
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return FeatureCard(feature: feature);
      },
    );
  }
}

class FeatureCard extends StatelessWidget {
  final Feature feature;
  
  const FeatureCard({
    Key? key,
    required this.feature,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => feature.screen),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: feature.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature.icon,
                  color: feature.color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                feature.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feature.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
