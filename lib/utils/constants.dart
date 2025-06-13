import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'PDF Utility Pro';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Professional PDF Tools';

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03A9F4);
  static const Color accentColor = Color(0xFF00BCD4);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color infoColor = Color(0xFF2196F3);

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 350);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Sizes
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultIconSize = 24.0;
  static const double defaultButtonHeight = 48.0;
  static const double defaultCardElevation = 2.0;

  // File Types
  static const List<String> supportedImageTypes = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp'
  ];
  static const List<String> supportedDocumentTypes = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'txt'
  ];
  static const List<String> supportedPdfTypes = ['pdf'];

  // File Size Limits
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxPdfSize = 50 * 1024 * 1024; // 50MB
  static const int maxRecentFiles = 20;

  // Cache Settings
  static const int maxCacheSize = 500 * 1024 * 1024; // 500MB
  static const Duration cacheDuration = Duration(days: 7);

  // API Settings
  static const int apiTimeout = 30; // seconds
  static const int maxRetries = 3;

  // UI Settings
  static const double minTouchTargetSize = 48.0;
  static const double defaultSpacing = 8.0;
  static const double defaultGridSpacing = 16.0;
  static const int defaultGridCrossAxisCount = 2;

  // Feature Flags
  static const bool enableCloudSync = true;
  static const bool enableOCR = true;
  static const bool enableBatchProcessing = true;
  static const bool enableFileSharing = true;
  static const bool enableBackupRestore = true;

  // Error Messages
  static const String genericError = 'An error occurred. Please try again.';
  static const String networkError =
      'Network error. Please check your connection.';
  static const String fileTooLargeError =
      'File size exceeds the maximum limit.';
  static const String unsupportedFileError = 'Unsupported file type.';
  static const String permissionDeniedError =
      'Permission denied. Please grant required permissions.';

  // Success Messages
  static const String fileSavedSuccess = 'File saved successfully.';
  static const String fileDeletedSuccess = 'File deleted successfully.';
  static const String fileSharedSuccess = 'File shared successfully.';
  static const String backupCreatedSuccess = 'Backup created successfully.';
  static const String backupRestoredSuccess = 'Backup restored successfully.';

  // Loading Messages
  static const String processingFile = 'Processing file...';
  static const String uploadingFile = 'Uploading file...';
  static const String downloadingFile = 'Downloading file...';
  static const String creatingBackup = 'Creating backup...';
  static const String restoringBackup = 'Restoring backup...';

  // Tooltips
  static const String addToFavoritesTooltip = 'Add to favorites';
  static const String removeFromFavoritesTooltip = 'Remove from favorites';
  static const String shareFileTooltip = 'Share file';
  static const String deleteFileTooltip = 'Delete file';
  static const String editFileTooltip = 'Edit file';
  static const String viewFileTooltip = 'View file';

  // File Operations
  static const List<String> supportedOperations = [
    'convert',
    'merge',
    'split',
    'compress',
    'encrypt',
    'decrypt',
    'rotate',
    'crop',
    'watermark',
    'sign',
    'annotate',
    'extract',
    'ocr',
  ];

  // Directory Names
  static const String outputDirName = 'PDFUtilityProFiles';
  static const String tempDirName = 'PDFUtilityProTemp';
}
