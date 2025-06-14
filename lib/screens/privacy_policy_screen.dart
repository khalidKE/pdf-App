import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/utils/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('Privacy Policy')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('Privacy Policy_title'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.translate('last_updated').replaceAll('{0}', '01/01/2023'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Text(
              loc.translate('privacy_intro'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              loc.translate('information_collection_title'),
              loc.translate('information_collection_content'),
            ),
            _buildSection(
              context,
              loc.translate('information_usage_title'),
              loc.translate('information_usage_content'),
            ),
            _buildSection(
              context,
              loc.translate('data_security_title'),
              loc.translate('data_security_content'),
            ),
            _buildSection(
              context,
              loc.translate('third_party_title'),
              loc.translate('third_party_content'),
            ),
            _buildSection(
              context,
              loc.translate('childrens_privacy_title'),
              loc.translate('childrens_privacy_content'),
            ),
            _buildSection(
              context,
              loc.translate('changes_to_policy_title'),
              loc.translate('changes_to_policy_content'),
            ),
            _buildSection(
              context,
              loc.translate('contact_us_title'),
              loc.translate('contact_us_content'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
