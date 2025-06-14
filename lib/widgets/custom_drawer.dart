import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/screens/privacy_policy_screen.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pdf_utility_pro/providers/theme_provider.dart';
import 'package:pdf_utility_pro/providers/language_provider.dart';
import 'package:pdf_utility_pro/screens/history_screen.dart';
import 'package:pdf_utility_pro/screens/about_screen.dart';
import 'package:pdf_utility_pro/screens/home_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final loc = AppLocalizations.of(context);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 64,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.translate(' Pdf Utility Pro'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: Text(loc.translate('home')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(loc.translate('history')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HistoryScreen()),
                    );
                  },
                ),
                // ListTile(
                //   leading: const Icon(Icons.settings),
                //   title: Text(loc.translate('settings')),
                //   onTap: () {
                //     Navigator.pop(context);
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(builder: (context) => const SettingsScreen()),
                //     );
                //   },
                // ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: Text(loc.translate('theme')),
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
                        child: Text(loc.translate('system theme')),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text(loc.translate('light theme')),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text(loc.translate('dark theme')),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: Text(loc.translate('Privacy Policy')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: Text(loc.translate('About Us')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AboutScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
