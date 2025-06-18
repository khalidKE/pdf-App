import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pdf_utility_pro/services/ads_service.dart';

class BannerAdWidget extends StatefulWidget {
  final double? height;
  final EdgeInsets? margin;
  final bool showBorder;

  const BannerAdWidget({
    Key? key,
    this.height,
    this.margin,
    this.showBorder = false,
  }) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isFailed = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: AdsService().bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _isFailed = true;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFailed) return const SizedBox.shrink(); // Hide everything if failed

    if (!_isLoaded || _bannerAd == null) {
      // Show nothing while loading
      return const SizedBox.shrink();
    }

    return Container(
      height: widget.height ?? 50,
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
      decoration: widget.showBorder
          ? BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: ClipRRect(
        borderRadius: widget.showBorder ? BorderRadius.circular(8) : BorderRadius.zero,
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
} 