import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/widgets/feature_grid.dart';
import 'package:pdf_utility_pro/widgets/custom_drawer.dart';
import 'package:pdf_utility_pro/widgets/recent_files_list.dart';
import 'package:pdf_utility_pro/widgets/favorite_files_list.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/language_provider.dart';
import 'package:pdf_utility_pro/providers/file_provider.dart';
import 'package:pdf_utility_pro/utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load files when the screen is first shown
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      final languageProvider = Provider.of<LanguageProvider>(context);
      final isRtl = languageProvider.isRTL;

      return Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context).translate(' Pdf Utility Pro'),
              style: const TextStyle(fontWeight: FontWeight.bold),
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
              tabs: [
                Tab(text: AppLocalizations.of(context).translate('Tools')),
                Tab(text: AppLocalizations.of(context).translate('Recent')),
                Tab(text: AppLocalizations.of(context).translate('Favorites')),
              ],
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
            ),
          ),
          drawer: const CustomDrawer(),
          body: TabBarView(
            controller: _tabController,
            children: const [
              FeatureGrid(),
              RecentFilesTab(),
              FavoritesTab(),
            ],
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
                  AppLocalizations.of(context).translate('No recent files'),
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
                  AppLocalizations.of(context).translate('No favorites'),
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
    final loc = AppLocalizations.of(context);

    if (query.isEmpty) {
      return Center(
        child: Text(loc.translate('search_hint')),
      );
    }

    final recentResults = fileProvider.recentFiles
        .where((file) => file.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    final favoriteResults = fileProvider.favoriteFiles
        .where((file) => file.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (recentResults.isEmpty && favoriteResults.isEmpty) {
      return Center(
        child: Text(loc.translate('no_search_results')),
      );
    }

    return ListView(
      children: [
        if (recentResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              loc.translate('recent_files'),
              style: const TextStyle(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              loc.translate('favorites'),
              style: const TextStyle(
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
