import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class FontLoader {
  static Future<pw.Font> getFont() async {
    final fontData = await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
    return pw.Font.ttf(fontData);
  }
} 