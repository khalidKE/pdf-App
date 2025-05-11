import 'package:flutter/material.dart';

class AppConstants {
  // App info
  static const String appName = 'PDF Utility Pro';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // Colors
  static const Color primaryColor = Color(0xFF4A6572);
  static const Color accentColor = Color(0xFF4ECDC4);
  static const Color errorColor = Color(0xFFFF6B6B);
  static const Color warningColor = Color(0xFFFFD166);
  static const Color successColor = Color(0xFF06D6A0);
  
  // Feature colors
  static const Map<String, Color> featureColors = {
    'image_to_pdf': Color(0xFF5D9CEC),
    'text_to_pdf': Color(0xFF48CFAD),
    'qr_barcode': Color(0xFFAC92EC),
    'excel_to_pdf': Color(0xFF4ECDC4),
    'word_to_pdf': Color(0xFF5D9CEC),
    'merge_pdf': Color(0xFFFC6E51),
    'split_pdf': Color(0xFFED5565),
    'edit_pdf': Color(0xFFFFCE54),
    'add_watermark': Color(0xFF5D9CEC),
    'add_signature': Color(0xFF9C27B0),
    'pdf_scanner': Color(0xFF8D6E63),
    'extract_text': Color(0xFF00BCD4),
    'read_pdf': Color(0xFFFF7043),
    'view_files': Color(0xFF607D8B),
  };
  
  // File paths
  static const String tempDirName = 'pdf_utility_pro_temp';
  static const String outputDirName = 'PDF Utility Pro';
  
  // Animations
  static const String loadingAnimation = 'assets/animations/loading.json';
  static const String successAnimation = 'assets/animations/success.json';
  static const String errorAnimation = 'assets/animations/error.json';
  
  // Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
  
  // Sizes
  static const double borderRadius = 16.0;
  static const double iconSize = 24.0;
  static const double largeIconSize = 48.0;
  
  // Limits
  static const int maxRecentFiles = 20;
  static const int maxFileSize = 50 * 1024 * 1024; // 50 MB
}
