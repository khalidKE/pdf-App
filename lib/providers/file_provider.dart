import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf_utility_pro/models/file_item.dart';
import 'package:pdf_utility_pro/utils/permission_handler.dart';
import 'package:pdf_utility_pro/utils/constants.dart';
import 'dart:io';
import 'dart:convert';

class FileProvider extends ChangeNotifier {
  List<FileItem> _recentFiles = [];
  List<FileItem> _favoriteFiles = [];

  List<FileItem> get recentFiles => _recentFiles;
  List<FileItem> get favoriteFiles => _favoriteFiles;

  FileProvider() {
    loadFiles();
  }

  Future<void> loadFiles() async {
    // Made this public
    final prefs = await SharedPreferences.getInstance();

    // Load recent files
    final recentFilesJson = prefs.getStringList('recent_files') ?? [];
    _recentFiles =
        recentFilesJson
            .map((json) => FileItem.fromJson(jsonDecode(json)))
            .where((file) => File(file.path).existsSync())
            .toList();

    // Load favorite files
    final favoriteFilesJson = prefs.getStringList('favorite_files') ?? [];
    _favoriteFiles =
        favoriteFilesJson
            .map((json) => FileItem.fromJson(jsonDecode(json)))
            .where((file) => File(file.path).existsSync())
            .toList();

    notifyListeners();
  }

  Future<void> _saveFiles() async {
    final prefs = await SharedPreferences.getInstance();

    final recentFilesJson =
        _recentFiles.map((file) => jsonEncode(file.toJson())).toList();
    await prefs.setStringList('recent_files', recentFilesJson);

    final favoriteFilesJson =
        _favoriteFiles.map((file) => jsonEncode(file.toJson())).toList();
    await prefs.setStringList('favorite_files', favoriteFilesJson);
  }

  void addRecentFile(FileItem file) {
    _recentFiles.removeWhere((item) => item.path == file.path);
    _recentFiles.insert(0, file);
    if (_recentFiles.length > AppConstants.maxRecentFiles) {
      _recentFiles = _recentFiles.sublist(0, AppConstants.maxRecentFiles);
    }
    _saveFiles();
    notifyListeners();
  }

  void removeRecentFile(String path) {
    _recentFiles.removeWhere((file) => file.path == path);
    _saveFiles();
    notifyListeners();
  }

  void clearRecentFiles() {
    _recentFiles.clear();
    _saveFiles();
    notifyListeners();
  }

  void toggleFavorite(FileItem file) {
    final isFavorite = _favoriteFiles.any((item) => item.path == file.path);
    if (isFavorite) {
      _favoriteFiles.removeWhere((item) => item.path == file.path);
    } else {
      _favoriteFiles.add(file);
    }
    _saveFiles();
    notifyListeners();
  }

  bool isFavorite(String path) {
    return _favoriteFiles.any((file) => file.path == path);
  }

  Future<String> getUniqueFilePath(String fileName) async {
    final appDir = await AppPermissionHandler.getAppDirectory();
    final filePath = '$appDir/$fileName';
    final file = File(filePath);
    if (!await file.exists()) return filePath;

    final lastDotIndex = fileName.lastIndexOf('.');
    final name =
        lastDotIndex != -1 ? fileName.substring(0, lastDotIndex) : fileName;
    final extension =
        lastDotIndex != -1 ? fileName.substring(lastDotIndex) : '';

    int counter = 1;
    String newPath;
    do {
      newPath = '$appDir/${name}_$counter$extension';
      counter++;
    } while (await File(newPath).exists());

    return newPath;
  }

  Future<List<FileItem>> getFilesInDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) return [];

    final files = await directory.list().toList();
    return files.where((entity) => entity is File).map((file) {
      final fileEntity = file as File;
      return FileItem(
        name: fileEntity.path.split('/').last,
        path: fileEntity.path,
        size: fileEntity.lengthSync(),
        dateModified: fileEntity.lastModifiedSync(),
        type: _getFileType(fileEntity.path),
      );
    }).toList();
  }

  FileType _getFileType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return FileType.pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return FileType.image;
      case 'xlsx':
      case 'xls':
        return FileType.excel;
      case 'docx':
      case 'doc':
        return FileType.word;
      case 'txt':
        return FileType.text;
      default:
        return FileType.other;
    }
  }

  void renameRecentFile(String oldPath, String newPath, String newName) {
    final index = _recentFiles.indexWhere((file) => file.path == oldPath);
    if (index != -1) {
      final oldFile = _recentFiles[index];
      _recentFiles[index] = oldFile.copyWith(
        path: newPath,
        name: newName,
        dateModified: DateTime.now(),
      );
      _saveFiles();
      notifyListeners();
    }
  }
}
