import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pdf_utility_pro/services/ads_service.dart';

class NativeAdWidget extends StatefulWidget {
  final double? height;
  final EdgeInsets? margin;
  final bool showBorder;

  const NativeAdWidget({
    Key? key,
    this.height,
    this.margin,
    this.showBorder = false,
  }) : super(key: key);

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isFailed = false;

  @override
  void initState() {
    super.initState();
    _nativeAd = AdsService().createNativeAd(
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('Native ad loaded successfully');
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native ad failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isFailed = true;
            });
          }
        },
        onAdOpened: (ad) {
          debugPrint('Native ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('Native ad closed');
        },
      ),
    );
    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFailed) return const SizedBox.shrink();
    if (!_isLoaded || _nativeAd == null) return const SizedBox.shrink();

    return Container(
      height: widget.height ?? 120,
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
      decoration: widget.showBorder
          ? BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: ClipRRect(
        borderRadius: widget.showBorder ? BorderRadius.circular(8) : BorderRadius.zero,
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
} 