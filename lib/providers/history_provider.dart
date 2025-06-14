import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/history_item.dart';

class HistoryProvider with ChangeNotifier {
  List<HistoryItem> _historyItems = [];

  List<HistoryItem> get historyItems => _historyItems;

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('history_items');
    if (historyJson != null) {
      final List decoded = jsonDecode(historyJson);
      _historyItems = decoded.map((e) => HistoryItem.fromJson(e)).toList();
    } else {
      _historyItems = [];
    }
    notifyListeners();
  }

  Future<void> addHistoryItem(HistoryItem item) async {
    _historyItems.insert(0, item);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> removeHistoryItem(int index) async {
    _historyItems.removeAt(index);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _historyItems.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('history_items');
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_historyItems.map((e) => e.toJson()).toList());
    await prefs.setString('history_items', encoded);
  }
}
