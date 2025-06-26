import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PdfIntentHandler {
  static const MethodChannel _channel = MethodChannel('com.pdfutilitypro/pdf_handler');

  static Future<String?> getPdfFilePath() async {
    try {
      final String? filePath = await _channel.invokeMethod('getPdfFilePath');
      return filePath;
    } on PlatformException catch (e) {
      print('Error getting PDF file path: ${e.message}');
      return null;
    }
  }

  static Future<bool> hasPdfFile() async {
    final filePath = await getPdfFilePath();
    return filePath != null && filePath.isNotEmpty;
  }

  static Future<String?> getAccessiblePdfFilePath() async {
    final filePath = await getPdfFilePath();
    if (filePath == null || filePath.isEmpty) return null;
    final file = File(filePath);
    if (await file.exists()) {
      final downloadsDir = '/storage/emulated/0/Download';
      final appDir = (await getApplicationDocumentsDirectory()).path;
      if (filePath.startsWith(downloadsDir) || filePath.startsWith(appDir)) {
        return filePath;
      }
      // Otherwise, copy to temp
      final tempDir = await getTemporaryDirectory();
      final tempPath = p.join(tempDir.path, p.basename(filePath));
      await file.copy(tempPath);
      return tempPath;
    }
    return null;
  }
} 