import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _notificationsEnabled = true;
  String _defaultSavePath = '';
  bool _autoSave = true;
  int _defaultPdfQuality = 2; // 0: Low, 1: Medium, 2: High
  
  bool get notificationsEnabled => _notificationsEnabled;
  String get defaultSavePath => _defaultSavePath;
  bool get autoSave => _autoSave;
  int get defaultPdfQuality => _defaultPdfQuality;
  
  SettingsProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _defaultSavePath = prefs.getString('default_save_path') ?? '';
    _autoSave = prefs.getBool('auto_save') ?? true;
    _defaultPdfQuality = prefs.getInt('default_pdf_quality') ?? 2;
    
    notifyListeners();
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setString('default_save_path', _defaultSavePath);
    await prefs.setBool('auto_save', _autoSave);
    await prefs.setInt('default_pdf_quality', _defaultPdfQuality);
  }
  
  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    _saveSettings();
    notifyListeners();
  }
  
  void setDefaultSavePath(String path) {
    _defaultSavePath = path;
    _saveSettings();
    notifyListeners();
  }
  
  void setAutoSave(bool value) {
    _autoSave = value;
    _saveSettings();
    notifyListeners();
  }
  
  void setDefaultPdfQuality(int quality) {
    _defaultPdfQuality = quality;
    _saveSettings();
    notifyListeners();
  }
}
