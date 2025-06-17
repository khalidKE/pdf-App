import 'package:flutter/services.dart';

class PdfIntentHandler {
  static const MethodChannel _channel = MethodChannel('com.pdfutilitypro/pdf_handler');

  /// Get the PDF file path if the app was opened with a PDF file
  static Future<String?> getPdfFilePath() async {
    try {
      final String? filePath = await _channel.invokeMethod('getPdfFilePath');
      return filePath;
    } on PlatformException catch (e) {
      print('Error getting PDF file path: ${e.message}');
      return null;
    }
  }

  /// Check if the app was opened with a PDF file
  static Future<bool> hasPdfFile() async {
    final filePath = await getPdfFilePath();
    return filePath != null && filePath.isNotEmpty;
  }
} 