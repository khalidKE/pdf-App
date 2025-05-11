import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf_utility_pro/utils/constants.dart';

class AppPermissionHandler {
  static Future<void> initializePermissions() async {
    // Create necessary directories
    await _createAppDirectories();
  }
  
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS doesn't need explicit permission for app document directory
      return true;
    }
    return false;
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
