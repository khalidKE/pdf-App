import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  // Always use English locale
  final Locale _locale = const Locale('en', '');
  
  Locale get locale => _locale;
  
  // No need to load from preferences since we only support English
  LanguageProvider();
  
  // No need for setLocale since we only support English
  bool get isRTL => false; // Always false since we only support English
}
