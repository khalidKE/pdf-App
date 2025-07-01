import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/services/ads_service.dart';
import 'package:pdf_utility_pro/widgets/banner_ad_widget.dart';
import 'package:pdf_utility_pro/widgets/native_ad_widget.dart';

class GlobalExitHandler extends StatelessWidget {
  final Widget child;
  const GlobalExitHandler({Key? key, required this.child}) : super(key: key);

  Future<bool> _onWillPop(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Are you sure you want to exit?'),
            const SizedBox(height: 16),
            
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.white,
                ),
                // This NativeAdWidget uses the real native ad unit ID for the exit ad
                child: const NativeAdWidget(height: 100),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      // Show interstitial ad before exit
      await AdsService().showInterstitialAd();
      // Wait a moment to ensure ad is closed
      await Future.delayed(const Duration(milliseconds: 300));
      return true; // Allow exit
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: child,
    );
  }
} 