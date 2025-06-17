import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/models/feature.dart';
import 'package:pdf_utility_pro/screens/feature_screens/image_to_pdf_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/text_to_pdf_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/qr_barcode_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/excel_to_pdf_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/word_to_pdf_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/merge_pdf_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/split_pdf_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/add_watermark_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/add_signature_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/extract_text_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/view_files_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/compress_pdf_screen.dart';
import 'package:pdf_utility_pro/screens/feature_screens/protect_pdf_screen.dart';
import 'package:pdf_utility_pro/utils/constants.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class FeatureGrid extends StatelessWidget {
  const FeatureGrid({Key? key}) : super(key: key);

  List<Feature> _getFeatures(BuildContext context) {

    return [
      Feature(
        title: 'Image to PDF',
        description: 'Convert images to PDF',
        icon: Icons.image,
        color: AppConstants.primaryColor,
        screen: const ImageToPdfScreen(),
        category: 'convert',
      ),
      Feature(
        title: 'Text to PDF',
        description: 'Convert text to PDF',
        icon: Icons.text_fields,
        color: AppConstants.secondaryColor,
        screen: const TextToPdfScreen(),
        category: 'convert',
      ),
      Feature(
        title: 'QR & Barcodes',
        description: 'Create and scan codes',
        icon: Icons.qr_code,
        color: AppConstants.accentColor,
        screen: const QrBarcodeScreen(),
        category: 'generate',
      ),
      Feature(
        title: 'Excel to PDF',
        description: 'Convert Excel files to PDF',
        icon: Icons.table_chart,
        color: AppConstants.infoColor,
        screen: const ExcelToPdfScreen(),
        category: 'convert',
      ),
      Feature(
        title: 'Word to PDF',
        description: 'Convert Word files to PDF',
        icon: Icons.description,
        color: AppConstants.primaryColor,
        screen: const WordToPdfScreen(),
        category: 'convert',
      ),
      Feature(
        title: 'Merge PDF',
        description: 'Combine multiple PDF files',
        icon: Icons.merge_type,
        color: AppConstants.secondaryColor,
        screen: const MergePdfScreen(),
        category: 'organize',
      ),
      Feature(
        title: 'Split PDF',
        description: 'Divide PDF into parts',
        icon: Icons.call_split,
        color: AppConstants.accentColor,
        screen: const SplitPdfScreen(),
        category: 'organize',
      ),
      Feature(
        title: 'Add Watermark',
        description: 'Add watermark to PDF',
        icon: Icons.water_drop,
        color: AppConstants.primaryColor,
        screen: const AddWatermarkScreen(),
        category: 'edit',
      ),
      Feature(
        title: 'Add Signature',
        description: 'Sign PDF with drawing',
        icon: Icons.draw,
        color: AppConstants.secondaryColor,
        screen: const AddSignatureScreen(),
        category: 'edit',
      ),
      Feature(
        title: 'Extract Text',
        description: 'Extract text from PDF or image',
        icon: Icons.text_snippet,
        color: AppConstants.infoColor,
        screen: const ExtractTextScreen(),
        category: 'extract',
      ),
      Feature(
        title: 'View Files',
        description: 'Browse files on device',
        icon: Icons.folder_open,
        color: AppConstants.secondaryColor,
        screen: const ViewFilesScreen(),
        category: 'view',
      ),
      Feature(
        title: 'Protect PDF',
        description: 'Add password to PDF',
        icon: Icons.lock,
        color: AppConstants.errorColor,
        screen: const ProtectPdfScreen(),
        category: 'security',
        isNew: true,
      ),
      Feature(
        title: 'Compress PDF',
        description: 'Reduce PDF file size',
        icon: Icons.compress,
        color: AppConstants.successColor,
        screen: const CompressPdfScreen(),
        category: 'utility',
        isNew: true,
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
            tabs: categories
                .map((category) => Tab(
                      text: category.toUpperCase(),
                    ))
                .toList(),
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
                final categoryFeatures =
                    features.where((f) => f.category == category).toList();
                return AnimationLimiter(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 600 ? 3 : 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: AppConstants.defaultGridSpacing,
                      mainAxisSpacing: AppConstants.defaultGridSpacing,
                    ),
                    itemCount: categoryFeatures.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        duration: AppConstants.mediumAnimationDuration,
                        columnCount:
                            MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        child: ScaleAnimation(
                          child: FadeInAnimation(
                            child:
                                FeatureCard(feature: categoryFeatures[index]),
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
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  decoration: BoxDecoration(
                    color: feature.color.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.defaultBorderRadius),
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
                      if (feature.subtitle != null &&
                          feature.subtitle!.isNotEmpty)
                        Text(
                          feature.subtitle!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.7),
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
