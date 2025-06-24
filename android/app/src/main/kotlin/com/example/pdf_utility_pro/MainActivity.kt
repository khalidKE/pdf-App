package com.pdf_tools.pdf_utility_pro

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pdfutilitypro/media_store"
    private val PDF_CHANNEL = "com.pdfutilitypro/pdf_handler"
    private var pdfFilePath: String? = null

    companion object {
        private const val TAG = "MainActivity"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveImageToGallery") {
                val args = call.arguments as HashMap<*, *>
                val imageBytes = args["imageBytes"] as ByteArray
                val fileName = args["fileName"] as String
                val success = saveImageToGallery(this, imageBytes, fileName)
                result.success(success)
            } else {
                result.notImplemented()
            }
        }

        // Handle PDF file intents
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PDF_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPdfFilePath" -> {
                    Log.d(TAG, "Flutter requested PDF file path: $pdfFilePath")
                    result.success(pdfFilePath)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent called with action: ${intent.action}")
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "onResume called")
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        Log.d(TAG, "Handling intent with action: ${intent.action}")

        when (intent.action) {
            Intent.ACTION_VIEW -> {
                val uri = intent.data
                Log.d(TAG, "ACTION_VIEW received with URI: $uri")
                if (uri != null) {
                    grantUriPermissionIfNeeded(uri)
                    pdfFilePath = getFilePathFromUri(uri)
                    Log.d(TAG, "Extracted file path: $pdfFilePath")
                }
            }

            Intent.ACTION_SEND -> {
                val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                Log.d(TAG, "ACTION_SEND received with URI: $uri")
                if (uri != null) {
                    grantUriPermissionIfNeeded(uri)
                    pdfFilePath = getFilePathFromUri(uri)
                    Log.d(TAG, "Extracted file path: $pdfFilePath")
                }
            }

            Intent.ACTION_SEND_MULTIPLE -> {
                val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                Log.d(TAG, "ACTION_SEND_MULTIPLE received with ${uris?.size} URIs")
                if (!uris.isNullOrEmpty()) {
                    grantUriPermissionIfNeeded(uris[0])
                    pdfFilePath = getFilePathFromUri(uris[0])
                    Log.d(TAG, "Extracted file path from first URI: $pdfFilePath")
                }
            }
        }
}

    private fun getFilePathFromUri(uri: Uri): String? {
        return try {
            Log.d(TAG, "Getting file path from URI: $uri (scheme: ${uri.scheme})")
            
            when (uri.scheme) {
                "file" -> {
                    val path = uri.path
                    Log.d(TAG, "File URI path: $path")
                    path
                }
                "content" -> {
                    Log.d(TAG, "Content URI detected, querying content resolver")
                    val cursor = contentResolver.query(uri, null, null, null, null)
                    cursor?.use {
                        if (it.moveToFirst()) {
                            val columnIndex = it.getColumnIndex(MediaStore.MediaColumns.DATA)
                            if (columnIndex != -1) {
                                val path = it.getString(columnIndex)
                                Log.d(TAG, "Found path in MediaStore: $path")
                                path
                            } else {
                                Log.d(TAG, "No DATA column found, copying to cache")
                                // For content URIs without DATA column, try to copy to cache
                                copyContentUriToCache(uri)
                            }
                        } else {
                            Log.d(TAG, "Cursor is empty")
                            null
                        }
                    } ?: run {
                        Log.d(TAG, "Cursor is null, copying to cache")
                        copyContentUriToCache(uri)
                    }
                }
                else -> {
                    Log.d(TAG, "Unknown URI scheme: ${uri.scheme}")
                    null
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting file path from URI: ${e.message}", e)
            null
        }
    }

    private fun copyContentUriToCache(uri: Uri): String? {
        return try {
            Log.d(TAG, "Copying content URI to cache: $uri")
            val inputStream = contentResolver.openInputStream(uri)
            val fileName = "pdf_${System.currentTimeMillis()}.pdf"
            val cacheFile = java.io.File(cacheDir, fileName)
            
            inputStream?.use { input ->
                cacheFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            
            Log.d(TAG, "Successfully copied to cache: ${cacheFile.absolutePath}")
            cacheFile.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "Error copying content URI to cache: ${e.message}", e)
            null
        }
    }

    private fun saveImageToGallery(context: Context, imageBytes: ByteArray, fileName: String): Boolean {
        return try {
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            val displayName = fileName
            val fos: OutputStream?
            val imageUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, displayName)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                    put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/PDFUtilityPro")
                }
                val uri = context.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                fos = uri?.let { context.contentResolver.openOutputStream(it) }
                uri
            } else {
                val imagesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES).toString()
                val image = java.io.File(imagesDir, displayName)
                fos = java.io.FileOutputStream(image)
                android.net.Uri.fromFile(image)
            }
            fos?.use {
                bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it)
                it.flush()
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
    private fun grantUriPermissionIfNeeded(uri: Uri) {
    try {
        contentResolver.takePersistableUriPermission(
            uri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION
        )
        Log.d(TAG, "Granted read URI permission for: $uri")
    } catch (e: SecurityException) {
        Log.w(TAG, "Failed to take URI permission: ${e.message}")
    } catch (e: Exception) {
        Log.e(TAG, "Unexpected error while granting URI permission: ${e.message}", e)
    }
}

}
