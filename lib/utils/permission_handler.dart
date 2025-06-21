import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf_utility_pro/utils/constants.dart';
import 'package:flutter/material.dart';

class AppPermissionHandler {
  static Future<void> initializePermissions() async {
    // Create necessary directories
    await _createAppDirectories();
  }
  
  static Future<bool> requestStoragePermission({BuildContext? context}) async {
    if (Platform.isAndroid) {
      // Android 11+
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        if (context != null) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Storage Permission Required'),
              content: const Text('Please enable storage permission from app settings to save files to your device.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        } else {
          await openAppSettings();
        }
        return false;
      }
      // Fallback for older Android
      if (await Permission.storage.isGranted) {
        return true;
      }
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        return true;
      } else if (storageStatus.isPermanentlyDenied) {
        if (context != null) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Storage Permission Required'),
              content: const Text('Please enable storage permission from app settings to save files to your device.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        } else {
          await openAppSettings();
        }
        return false;
      }
      return false;
    }
    // iOS: always true (handled by picker)
    return true;
  }
  
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
  
  static Future<String> getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final appDir = Directory('${directory.path}/${AppConstants.outputDirName}');
    
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    
    return appDir.path;
  }
  
  static Future<String> getTempDirectory() async {
    final directory = await getTemporaryDirectory();
    final tempDir = Directory('${directory.path}/${AppConstants.tempDirName}');
    
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    
    return tempDir.path;
  }
  
  static Future<void> _createAppDirectories() async {
    // Create output directory
    await getAppDirectory();
    
    // Create temp directory
    await getTempDirectory();
  }
  
  static Future<void> cleanTempDirectory() async {
    try {
      final tempDirPath = await getTempDirectory();
      final tempDir = Directory(tempDirPath);
      
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        await tempDir.create(recursive: true);
      }
    } catch (e) {
      print('Error cleaning temp directory: $e');
    }
  }
}

