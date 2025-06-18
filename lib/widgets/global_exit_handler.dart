import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/services/ads_service.dart';

class GlobalExitHandler extends StatelessWidget {
  final Widget child;
  const GlobalExitHandler({Key? key, required this.child}) : super(key: key);

  Future<bool> _onWillPop(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
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