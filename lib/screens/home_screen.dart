import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/widgets/feature_grid.dart';
import 'package:pdf_utility_pro/widgets/custom_drawer.dart';
import 'package:pdf_utility_pro/widgets/recent_files_list.dart';
import 'package:pdf_utility_pro/widgets/favorite_files_list.dart';
import 'package:pdf_utility_pro/widgets/banner_ad_widget.dart';
import 'package:pdf_utility_pro/widgets/native_ad_widget.dart';
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/file_provider.dart';
import 'package:pdf_utility_pro/screens/feature_screens/read_pdf_screen.dart';
import 'package:pdf_utility_pro/utils/pdf_intent_handler.dart';
import 'package:pdf_utility_pro/services/app_open_ads_manager.dart';
import 'package:pdf_utility_pro/services/ads_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  DateTime? _lastRewardedAdTime;
  static const int _rewardedAdCooldownSeconds = 60;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _tabController.addListener(_onTabChanged);

    // Show App Open Ad on first launch (never during app use)
    AppOpenAdsManager().showAdIfAvailable();

    // Check for PDF file intent and load files when the screen is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FileProvider>(
        context,
        listen: false,
      ).loadFiles(); // call public method
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // App open ad will NOT be shown on resume, only on first app open
  }

  void _onTabChanged() async {
    if (_tabController.indexIsChanging) {
      final now = DateTime.now();
      if (_lastRewardedAdTime == null ||
          now.difference(_lastRewardedAdTime!).inSeconds >
              _rewardedAdCooldownSeconds) {
        final shouldShowAd = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Watch Ad'),
            content: const Text('Watch the Ad to complete'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        if (shouldShowAd == true) {
          await AdsService().showRewardedAd(
            onRewarded: () {},
            onFailed: () {},
          );
          _lastRewardedAdTime = now;
        }
      }
    }
  }

  Future<bool> _onWillPop() async {
    // Show interstitial ad immediately when dialog appears
    await AdsService().showInterstitialAd();
    // Wait a moment to ensure ad is closed or started
    await Future.delayed(const Duration(milliseconds: 300));

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you want to exit now?'),
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
    return shouldExit == true;
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(
                'PDF Nest',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // Implement search functionality
                    showSearch(
                      context: context,
                      delegate: AppSearchDelegate(),
                    );
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Tools'),
                  Tab(text: 'Recent'),
                  Tab(text: 'Favorites'),
                ],
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3,
              ),
            ),
            drawer: const CustomDrawer(),
            body: TabBarView(
              controller: _tabController,
              children: const [
                Column(
                  children: [
                    Expanded(child: FeatureGrid()),
                    // BannerAdWidget and NativeAdWidget use the correct ad unit IDs as per requirements
                    BannerAdWidget(),
                    NativeAdWidget(height: 120),
                  ],
                ),
                Column(
                  children: [
                    Expanded(child: RecentFilesTab()),
                    BannerAdWidget(),
                    NativeAdWidget(height: 120),
                  ],
                ),
                Column(
                  children: [
                    Expanded(child: FavoritesTab()),
                    BannerAdWidget(),
                    NativeAdWidget(height: 120),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      // Fallback UI in case of errors
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading application'),
              const SizedBox(height: 8),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class RecentFilesTab extends StatelessWidget {
  const RecentFilesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);

    return fileProvider.recentFiles.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No recent files',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          )
        : const RecentFilesList();
  }
}

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);

    return fileProvider.favoriteFiles.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite,
                  size: 64,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No favorites',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          )
        : const FavoriteFilesList();
  }
}

class AppSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);

    if (query.isEmpty) {
      return const Center(
        child: Text('Search for files'),
      );
    }

    final recentResults = fileProvider.recentFiles
        .where((file) => file.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    final favoriteResults = fileProvider.favoriteFiles
        .where((file) => file.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (recentResults.isEmpty && favoriteResults.isEmpty) {
      return const Center(
        child: Text('No search results'),
      );
    }

    return ListView(
      children: [
        if (recentResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Recent Files',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          ...recentResults.map((file) => ListTile(
                leading: Icon(file.icon),
                title: Text(file.name),
                subtitle: Text(
                    '${file.formattedSize} • ${_formatDate(file.dateModified)}'),
                onTap: () {
                  // Open file
                },
              )),
        ],
        if (favoriteResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'favorites',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          ...favoriteResults.map((file) => ListTile(
                leading: Icon(file.icon),
                title: Text(file.name),
                subtitle: Text(
                    '${file.formattedSize} • ${_formatDate(file.dateModified)}'),
                onTap: () {
                  // Open file
                },
              )),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
