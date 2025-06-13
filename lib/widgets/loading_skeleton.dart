import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pdf_utility_pro/utils/constants.dart';

class LoadingSkeleton extends StatelessWidget {
  final bool isGrid;
  final int itemCount;
  final double? width;
  final double? height;
  
  const LoadingSkeleton({
    Key? key,
    this.isGrid = true,
    this.itemCount = 6,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[300]!
          : Colors.grey[800]!,
      highlightColor: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[100]!
          : Colors.grey[700]!,
      child: isGrid
          ? GridView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: AppConstants.defaultGridSpacing,
                mainAxisSpacing: AppConstants.defaultGridSpacing,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) => _buildGridItem(context),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: itemCount,
              itemBuilder: (context, index) => _buildListItem(context),
            ),
    );
  }

  Widget _buildGridItem(BuildContext context) {
    return Card(
      elevation: AppConstants.defaultCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: AppConstants.defaultIconSize * 2,
              height: AppConstants.defaultIconSize * 2,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
            ),
            const SizedBox(height: AppConstants.defaultSpacing * 1.5),
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppConstants.defaultSpacing),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context) {
    return Card(
      elevation: AppConstants.defaultCardElevation,
      margin: const EdgeInsets.only(bottom: AppConstants.defaultSpacing),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Container(
              width: AppConstants.defaultIconSize * 2,
              height: AppConstants.defaultIconSize * 2,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
            ),
            const SizedBox(width: AppConstants.defaultSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultSpacing),
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingSkeletonScreen extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final bool isGrid;
  final int itemCount;
  
  const LoadingSkeletonScreen({
    Key? key,
    required this.child,
    required this.isLoading,
    this.isGrid = true,
    this.itemCount = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? LoadingSkeleton(
            isGrid: isGrid,
            itemCount: itemCount,
          )
        : child;
  }
} 