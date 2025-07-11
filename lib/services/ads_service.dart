import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdsService {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  // تطبيق pdf
  // App ID: ca-app-pub-8639311525630636~8311642774

  // 1- اعلان فتح التطبيق يظهر عند فتح التطبيق فقط
  static const String _appOpenAdUnitId =
      'ca-app-pub-8639311525630636/1268556428';
  // 2- اعلان بانر يظهر اسفل الشاشة في صفحات التطبيق
  static const String _bannerAdUnitId =
      'ca-app-pub-8639311525630636/2649086703';
  // 3- اعلان بيني بمكافأة يظهر عند تنفيذ مهمة او التنقل بين صفحات التطبيق
  static const String _rewardedAdUnitId =
      'ca-app-pub-8639311525630636/7752576868';
  // 4- اعلان مدمج مع المحتوى يظهر على صفحة الخروج من التطبيق اسفل جملة هل تريد الخروج الان
  static const String _nativeAdUnitId =
      'ca-app-pub-8639311525630636/9827102099';

  // Get ad unit IDs - Always use real ads
  String get bannerAdUnitId => _bannerAdUnitId;
  String get rewardedAdUnitId => _rewardedAdUnitId;
  String get nativeAdUnitId => _nativeAdUnitId;
  String get appOpenAdUnitId => _appOpenAdUnitId;

  // Ad instances
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  AppOpenAd? _appOpenAd;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;
  bool _isAppOpenAdReady = false;

  // Initialize AdMob
  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      debugPrint('AdMob initialized successfully');

      // Load initial ads
      loadInterstitialAd();
      loadRewardedAd();
      loadAppOpenAd();
    } catch (e) {
      debugPrint('Error initializing AdMob: $e');
    }
  }

  // Banner Ad
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (ad) {
          debugPrint('Banner ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('Banner ad closed');
        },
      ),
    );
  }

  // Interstitial Ad (not used, kept for legacy)
  Future<void> loadInterstitialAd() async {
    // Not used in current app logic
  }

  Future<bool> showInterstitialAd() async {
    // Not used in current app logic
    return false;
  }

  // Rewarded Ad
  Future<void> loadRewardedAd() async {
    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
            debugPrint('Rewarded ad loaded successfully');

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                _isRewardedAdReady = false;
                ad.dispose();
                loadRewardedAd(); // Load next ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Rewarded ad failed to show: $error');
                _isRewardedAdReady = false;
                ad.dispose();
                loadRewardedAd(); // Load next ad
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad failed to load: $error');
            _isRewardedAdReady = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading rewarded ad: $e');
      _isRewardedAdReady = false;
    }
  }

  Future<bool> showRewardedAd({
    required Function() onRewarded,
    required Function() onFailed,
  }) async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      debugPrint('Rewarded ad not ready');
      onFailed();
      return false;
    }

    try {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          _isRewardedAdReady = false;
          ad.dispose();
          loadRewardedAd(); // Load next ad
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Rewarded ad failed to show: $error');
          _isRewardedAdReady = false;
          ad.dispose();
          loadRewardedAd(); // Load next ad
          onFailed();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          onRewarded();
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
      onFailed();
      return false;
    }
  }

  // App Open Ad
  Future<void> loadAppOpenAd() async {
    try {
      await AppOpenAd.load(
        adUnitId: appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _isAppOpenAdReady = true;
            debugPrint('App open ad loaded successfully');

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                _isAppOpenAdReady = false;
                ad.dispose();
                loadAppOpenAd(); // Load next ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('App open ad failed to show: $error');
                _isAppOpenAdReady = false;
                ad.dispose();
                loadAppOpenAd(); // Load next ad
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('App open ad failed to load: $error');
            _isAppOpenAdReady = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading app open ad: $e');
      _isAppOpenAdReady = false;
    }
  }

  Future<bool> showAppOpenAd() async {
    if (!_isAppOpenAdReady || _appOpenAd == null) {
      debugPrint('App open ad not ready');
      return false;
    }

    try {
      await _appOpenAd!.show();
      return true;
    } catch (e) {
      debugPrint('Error showing app open ad: $e');
      return false;
    }
  }

  // Native Ad
  NativeAd createNativeAd({
    required NativeAdListener listener,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: listener,
    );
  }

  // Check if ads are ready
  bool get isInterstitialAdReady => _isInterstitialAdReady;
  bool get isRewardedAdReady => _isRewardedAdReady;
  bool get isAppOpenAdReady => _isAppOpenAdReady;

  // Dispose ads
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _appOpenAd?.dispose();
  }
}
