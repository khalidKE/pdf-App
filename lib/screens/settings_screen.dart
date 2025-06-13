import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/theme_provider.dart';
import 'package:pdf_utility_pro/providers/language_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    loc.translate('appearance'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(loc.translate('theme')),
                  subtitle: Text(loc.translate('theme_desc')),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeProvider.themeMode,
                    underline: Container(),
                    onChanged: (ThemeMode? newThemeMode) {
                      if (newThemeMode != null) {
                        themeProvider.setThemeMode(newThemeMode);
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text(loc.translate('system_theme')),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text(loc.translate('light_theme')),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text(loc.translate('dark_theme')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    loc.translate('notifications'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(loc.translate('enable_notifications')),
                  subtitle: Text(loc.translate('notifications_desc')),
                  value: true,
                  onChanged: (bool value) {
                    // Implement notification settings
                  },
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    loc.translate('storage'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(loc.translate('clear_cache')),
                  subtitle: Text(loc.translate('clear_cache_desc')),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Implement cache clearing
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.translate('cache_cleared')),
                        ),
                      );
                    },
                    child: Text(loc.translate('clear')),
                  ),
                ),
                ListTile(
                  title: Text(loc.translate('clear_history')),
                  subtitle: Text(loc.translate('clear_history_desc')),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Implement history clearing
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.translate('history_cleared')),
                        ),
                      );
                    },
                    child: Text(loc.translate('clear')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
