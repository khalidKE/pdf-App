import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/services/ads_service.dart';

class AppOpenAdsManager {
  static final AppOpenAdsManager _instance = AppOpenAdsManager._internal();
  factory AppOpenAdsManager() => _instance;
  AppOpenAdsManager._internal();

  bool _isShowingAd = false;
  DateTime? _lastAdShowTime;
  static const int _minimumAdInterval = 4; // Minimum 4 hours between ads

  bool get isShowingAd => _isShowingAd;

  Future<void> showAdIfAvailable() async {
    if (_isShowingAd) {
      debugPrint('App open ad is already showing');
      return;
    }

    if (!_canShowAd()) {
      debugPrint('App open ad cannot be shown yet');
      return;
    }

    final adsService = AdsService();
    if (!adsService.isAppOpenAdReady) {
      debugPrint('App open ad not ready');
      return;
    }

    _isShowingAd = true;
    _lastAdShowTime = DateTime.now();

    try {
      await adsService.showAppOpenAd();
    } catch (e) {
      debugPrint('Error showing app open ad: $e');
    } finally {
      _isShowingAd = false;
    }
  }

  bool _canShowAd() {
    if (_lastAdShowTime == null) {
      return true;
    }

    final timeSinceLastAd = DateTime.now().difference(_lastAdShowTime!);
    return timeSinceLastAd.inHours >= _minimumAdInterval;
  }

  void reset() {
    _isShowingAd = false;
    _lastAdShowTime = null;
  }
} 