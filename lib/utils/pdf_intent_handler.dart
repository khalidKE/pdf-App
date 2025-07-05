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
    try {
      if (Platform.isAndroid) {
        final pdfPath = await _channel.invokeMethod<String>('getPdfFilePath');
        return pdfPath != null && pdfPath.isNotEmpty;
      }
    } catch (e) {
      print('Error checking for PDF file: $e');
    }
    return false;
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

  static Future<String?> getPdfPath() async {
    try {
      if (Platform.isAndroid) {
        return await _channel.invokeMethod<String>('getPdfFilePath');
      }
    } catch (e) {
      print('Error getting PDF path: $e');
    }
    return null;
  }
} 