package com.example.pdf_utility_pro

import android.content.ContentValues
import android.content.Context
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pdfutilitypro/media_store"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveImageToGallery") {
                val imageBytes = call.arguments as ByteArray
                val success = saveImageToGallery(this, imageBytes)
                result.success(success)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveImageToGallery(context: Context, imageBytes: ByteArray): Boolean {
        return try {
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            val displayName = "qr_${System.currentTimeMillis()}.png"
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
}
