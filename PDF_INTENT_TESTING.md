# PDF Intent Handling Testing Guide

This guide explains how to test the PDF intent handling feature that allows the app to appear in the "Open with" dialog when users try to open PDF files.

## What was implemented:

1. **Android Manifest Changes**: Added intent filters to handle PDF files
2. **MainActivity.kt**: Added code to handle incoming PDF file intents
3. **Flutter Integration**: Created PdfIntentHandler utility and integrated with SplashScreen and HomeScreen

## How to test:

### Method 1: Using File Manager
1. Install the app on your Android device
2. Open any file manager (like Files by Google)
3. Navigate to a PDF file
4. Long press on the PDF file
5. Select "Open with" or "Share"
6. You should see "PDF Utility Pro" in the list of available apps
7. Select it to open the PDF in the app

### Method 2: Using Share Intent
1. Open any app that can share PDF files (like Gmail, WhatsApp, etc.)
2. Share a PDF file
3. In the share dialog, you should see "PDF Utility Pro" as an option
4. Select it to open the PDF in the app

### Method 3: Using ADB (for developers)
```bash
# Test with a local PDF file
adb shell am start -a android.intent.action.VIEW -d "file:///sdcard/test.pdf" -t "application/pdf" com.pdf_tools.pdf_utility_pro

# Test with content URI (if you have a PDF in Downloads)
adb shell am start -a android.intent.action.VIEW -d "content://com.android.providers.downloads.documents/document/123" -t "application/pdf" com.pdf_tools.pdf_utility_pro
```

## Expected Behavior:

1. **When app is closed**: App should open and directly show the PDF in the reader
2. **When app is in background**: App should come to foreground and show the PDF in the reader
3. **When app is already open**: App should navigate to the PDF reader with the new file

## Debugging:

Check the Android logs for debugging information:
```bash
adb logcat | grep "MainActivity"
```

Look for log messages like:
- "onNewIntent called with action: android.intent.action.VIEW"
- "Extracted file path: /path/to/file.pdf"
- "Flutter requested PDF file path: /path/to/file.pdf"

## Troubleshooting:

1. **App doesn't appear in "Open with" dialog**:
   - Make sure the app is installed
   - Check that the intent filters are properly configured in AndroidManifest.xml
   - Verify the app has the necessary permissions

2. **PDF doesn't open when selected**:
   - Check the Android logs for error messages
   - Verify the PDF file path is being extracted correctly
   - Make sure the ReadPdfScreen can handle the file path

3. **Permission issues**:
   - Ensure the app has READ_EXTERNAL_STORAGE permission
   - For Android 13+, ensure READ_MEDIA_DOCUMENTS permission is granted

## Files Modified:

- `android/app/src/main/AndroidManifest.xml` - Added intent filters
- `android/app/src/main/kotlin/com/example/pdf_utility_pro/MainActivity.kt` - Added intent handling
- `lib/utils/pdf_intent_handler.dart` - Created Flutter utility
- `lib/screens/splash_screen.dart` - Added PDF file checking
- `lib/screens/home_screen.dart` - Added PDF file checking for active app

## Notes:

- The app handles both file:// and content:// URIs
- For content URIs that can't be resolved directly, the file is copied to the app's cache directory
- The feature works with single PDF files and the first file from multiple file selections
- The app will appear in the "Open with" dialog for any PDF file on the device 