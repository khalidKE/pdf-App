import 'package:flutter/material.dart';

class FeatureScreenTemplate extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget body;
  final String actionButtonLabel;
  final VoidCallback onActionButtonPressed;
  final bool isActionButtonEnabled;
  final bool isProcessing;
  final Widget? processingIndicator;
  
  const FeatureScreenTemplate({
    Key? key,
    required this.title,
    required this.icon,
    required this.body,
    required this.actionButtonLabel,
    required this.onActionButtonPressed,
    this.isActionButtonEnabled = true,
    this.isProcessing = false,
    this.processingIndicator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: body,
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
              child: SizedBox(
                width: double.infinity,
              height: 48,
                child: ElevatedButton(
                  onPressed: isActionButtonEnabled ? onActionButtonPressed : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isProcessing
                      ? processingIndicator ?? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          actionButtonLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
