import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PDF Utility Pro',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your complete PDF solution for all your document needs.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Features:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('• Convert images to PDF'),
            const Text('• Convert text to PDF'),
            const Text('• Convert Word documents to PDF'),
            const Text('• Convert Excel files to PDF'),
            const Text('• Merge multiple PDF files'),
            const Text('• Split PDF files'),
            const Text('• Add watermarks to PDF'),
            const Text('• Add signatures to PDF'),
            const Text('• Extract text from PDF'),
            const Text('• Protect PDF with password'),
            const Text('• Compress PDF files'),
            const Text('• Generate QR codes and barcodes'),
            const SizedBox(height: 24),
            const Text(
              'Contact Us:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _launchURL('mailto:khalidelabd.fcai.usc@gmail.com'),
              child: const Text(
                'Developer',
                style: TextStyle(
                  color: Colors.blue,
                ),
              ),
            ),
            InkWell(
              onTap: () => _launchURL('mailto:abuelhassan179@gmail.com'),
              child: const Text(
                'Owner',
                style: TextStyle(
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
