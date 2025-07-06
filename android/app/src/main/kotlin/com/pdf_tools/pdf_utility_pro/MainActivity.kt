package com.pdf_tools.pdf_utility_pro

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PDF_CHANNEL = "com.pdfutilitypro/pdf_handler"
    private val MEDIA_STORE_CHANNEL = "com.pdfutilitypro/media_store"
    private var pdfFilePath: String? = null

    companion object {
        private const val TAG = "MainActivity"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PDF_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPdfFilePath" -> {
                    Log.d(TAG, "Flutter requested PDF file path: $pdfFilePath")
                    result.success(pdfFilePath)
                }
                else -> result.notImplemented()
            }
        }

        // Add MethodChannel for saving images to gallery
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_STORE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveImageToGallery" -> {
                    val imageBytes = call.argument<ByteArray>("imageBytes")
                    val fileName = call.argument<String>("fileName") ?: "image_${System.currentTimeMillis()}.png"
                    if (imageBytes != null) {
                        val saved = saveImageToGallery(imageBytes, fileName)
                        if (saved) {
                            result.success(true)
                        } else {
                            result.error("SAVE_FAILED", "Failed to save image", null)
                        }
                    } else {
                        result.error("NO_IMAGE", "No image bytes provided", null)
                    }
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
                    pdfFilePath = getFilePathFromUri(uri)
                    Log.d(TAG, "Extracted file path: $pdfFilePath")
                }
            }

            Intent.ACTION_SEND -> {
                val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                Log.d(TAG, "ACTION_SEND received with URI: $uri")
                if (uri != null) {
                    pdfFilePath = getFilePathFromUri(uri)
                    Log.d(TAG, "Extracted file path: $pdfFilePath")
                }
            }

            Intent.ACTION_SEND_MULTIPLE -> {
                val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                Log.d(TAG, "ACTION_SEND_MULTIPLE received with ${uris?.size} URIs")
                if (!uris.isNullOrEmpty()) {
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
                    Log.d(TAG, "Content URI detected, copying to cache")
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

    private fun saveImageToGallery(imageBytes: ByteArray, fileName: String): Boolean {
        return try {
            val bitmap = android.graphics.BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            val resolver = applicationContext.contentResolver
            val contentValues = android.content.ContentValues().apply {
                put(android.provider.MediaStore.Images.Media.DISPLAY_NAME, fileName)
                put(android.provider.MediaStore.Images.Media.MIME_TYPE, "image/png")
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                    put(android.provider.MediaStore.Images.Media.RELATIVE_PATH, android.os.Environment.DIRECTORY_PICTURES)
                    put(android.provider.MediaStore.Images.Media.IS_PENDING, 1)
                }
            }
            val uri = resolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
            uri?.let {
                resolver.openOutputStream(it)?.use { outStream ->
                    bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, outStream)
                } ?: return false
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                    contentValues.clear()
                    contentValues.put(android.provider.MediaStore.Images.Media.IS_PENDING, 0)
                    resolver.update(uri, contentValues, null, null)
                }
                true
            } ?: false
        } catch (e: Exception) {
            false
        }
    }
} 