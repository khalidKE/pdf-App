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
import 'package:pdf_utility_pro/screens/feature_screens/add_watermark_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/add_signature_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/pdf_scanner_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/extract_text_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/view_files_screen.dart';
import 'package:pdf_utility_pro/utils/constants.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class FeatureGrid extends StatelessWidget {
  const FeatureGrid({Key? key}) : super(key: key);

  List<Feature> _getFeatures(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return [
      Feature(
        title: loc.translate('image_to_pdf'),
        description: loc.translate('image_to_pdf_desc'),
        icon: Icons.image,
        color: AppConstants.primaryColor,
        screen: const ImageToPdfScreen(),
        category: 'convert',
      ),
      Feature(
        title: loc.translate('text_to_pdf'),
        description: loc.translate('text_to_pdf_desc'),
        icon: Icons.text_fields,
        color: AppConstants.secondaryColor,
        screen: const TextToPdfScreen(),
        category: 'convert',
      ),
      Feature(
        title: loc.translate('qr_barcode'),
        description: loc.translate('qr_barcode_desc'),
        icon: Icons.qr_code,
        color: AppConstants.accentColor,
        screen: const QrBarcodeScreen(),
        category: 'generate',
      ),
      Feature(
        title: loc.translate('excel_to_pdf'),
        description: loc.translate('excel_to_pdf_desc'),
        icon: Icons.table_chart,
        color: AppConstants.infoColor,
        screen: const ExcelToPdfScreen(),
        category: 'convert',
      ),
      Feature(
        title: loc.translate('word_to_pdf'),
        description: loc.translate('word_to_pdf_desc'),
        icon: Icons.description,
        color: AppConstants.primaryColor,
        screen: const WordToPdfScreen(),
        category: 'convert',
      ),
      Feature(
        title: loc.translate('merge_pdf'),
        description: loc.translate('merge_pdf_desc'),
        icon: Icons.merge_type,
        color: AppConstants.secondaryColor,
        screen: const MergePdfScreen(),
        category: 'organize',
      ),
      Feature(
        title: loc.translate('split_pdf'),
        description: loc.translate('split_pdf_desc'),
        icon: Icons.call_split,
        color: AppConstants.accentColor,
        screen: const SplitPdfScreen(),
        category: 'organize',
      ),
      Feature(
        title: loc.translate('add_watermark'),
        description: loc.translate('add_watermark_desc'),
        icon: Icons.water_drop,
        color: AppConstants.primaryColor,
        screen: const AddWatermarkScreen(),
        category: 'edit',
      ),
      Feature(
        title: loc.translate('add_signature'),
        description: loc.translate('add_signature_desc'),
        icon: Icons.draw,
        color: AppConstants.secondaryColor,
        screen: const AddSignatureScreen(),
        category: 'edit',
      ),
      Feature(
        title: loc.translate('pdf_scanner'),
        description: loc.translate('pdf_scanner_desc'),
        icon: Icons.document_scanner,
        color: AppConstants.accentColor,
        screen: const PdfScannerScreen(),
        category: 'scan',
      ),
      Feature(
        title: loc.translate('extract_text'),
        description: loc.translate('extract_text_desc'),
        icon: Icons.text_snippet,
        color: AppConstants.infoColor,
        screen: const ExtractTextScreen(),
        category: 'extract',
      ),
      Feature(
        title: loc.translate('read_pdf'),
        description: loc.translate('read_pdf_desc'),
        icon: Icons.menu_book,
        color: AppConstants.primaryColor,
        screen: const ReadPdfScreen(filePath: ''),
        category: 'view',
      ),
      Feature(
        title: loc.translate('view_files'),
        description: loc.translate('view_files_desc'),
        icon: Icons.folder_open,
        color: AppConstants.secondaryColor,
        screen: const ViewFilesScreen(),
        category: 'view',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final features = _getFeatures(context);
    final categories = features.map((f) => f.category).toSet().toList();
    
    return DefaultTabController(
      length: categories.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: categories.map((category) => Tab(
              text: category.toUpperCase(),
            )).toList(),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
            ),
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
          ),
          Expanded(
            child: TabBarView(
              children: categories.map((category) {
                final categoryFeatures = features.where((f) => f.category == category).toList();
                return AnimationLimiter(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: AppConstants.defaultGridSpacing,
                      mainAxisSpacing: AppConstants.defaultGridSpacing,
                    ),
                    itemCount: categoryFeatures.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        duration: AppConstants.mediumAnimationDuration,
                        columnCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        child: ScaleAnimation(
                          child: FadeInAnimation(
                            child: FeatureCard(feature: categoryFeatures[index]),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
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
      elevation: AppConstants.defaultCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => feature.screen),
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Tooltip(
          message: feature.description,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  decoration: BoxDecoration(
                    color: feature.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  child: Icon(
                    feature.icon,
                    color: feature.color,
                    size: AppConstants.defaultIconSize * 1.5,
                  ),
                ),
                const SizedBox(height: AppConstants.defaultSpacing * 1.2),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        feature.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppConstants.defaultSpacing / 2),
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
                      const SizedBox(height: 4),
                      if (feature.subtitle != null && feature.subtitle!.isNotEmpty)
                        Text(
                          feature.subtitle!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
