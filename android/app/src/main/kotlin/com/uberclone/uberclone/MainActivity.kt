package com.uberclone.uberclone

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ContentResolver
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
    private var pendingImage: MethodChannel.Result? = null
    private val pickerHandler = Handler(Looper.getMainLooper())
    private var activeReads = 0
    private var pendingLimit = MAX_IMAGE_BYTES

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "higo/driver_documents")
            .setMethodCallHandler { call, result ->
                if (call.method != "pickImage") {
                    result.notImplemented()
                } else if (pendingImage != null) {
                    result.error("picker_busy", "An image picker is already open.", null)
                } else if (activeReads >= 2) {
                    result.error("picker_busy", "Document providers are still busy. Try again shortly.", null)
                } else {
                    val maxBytes = call.argument<Int>("maxBytes") ?: MAX_IMAGE_BYTES
                    if (maxBytes != MAX_IMAGE_BYTES && maxBytes != 2 * MAX_IMAGE_BYTES) {
                        result.error("invalid_limit", "Invalid document limit.", null)
                        return@setMethodCallHandler
                    }
                    pendingLimit = maxBytes
                    pendingImage = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "image/*"
                        putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/jpeg", "image/png"))
                    }
                    try {
                        startActivityForResult(intent, IMAGE_REQUEST)
                    } catch (_: ActivityNotFoundException) {
                        pendingImage = null
                        result.error("picker_unavailable", "Image selection is unavailable.", null)
                    }
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != IMAGE_REQUEST) return
        val result = pendingImage ?: return
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pendingImage = null
            result.success(null)
            return
        }
        if (uri.scheme != ContentResolver.SCHEME_CONTENT) {
            pendingImage = null
            result.error("invalid_image", "Choose an image from the document picker.", null)
            return
        }
        val maxBytes = pendingLimit
        activeReads++
        val timeout = Runnable {
            if (pendingImage === result) {
                pendingImage = null
                result.error("picker_timeout", "The document provider did not respond. Try another file.", null)
            }
        }
        pickerHandler.postDelayed(timeout, 10_000)
        Thread {
            try {
                val image = contentResolver.openInputStream(uri)?.use { input ->
                    val output = ByteArrayOutputStream()
                    val buffer = ByteArray(8192)
                    while (output.size() <= maxBytes) {
                        val remaining = maxBytes + 1 - output.size()
                        val count = input.read(buffer, 0, minOf(buffer.size, remaining))
                        if (count == -1) break
                        output.write(buffer, 0, count)
                    }
                    if (output.size() > maxBytes) null else output.toByteArray()
                } ?: throw IOException("Image unavailable or oversized")
                runOnUiThread {
                    activeReads--
                    pickerHandler.removeCallbacks(timeout)
                    if (pendingImage !== result) return@runOnUiThread
                    pendingImage = null
                    result.success(image)
                }
            } catch (_: Exception) {
                runOnUiThread {
                    activeReads--
                    pickerHandler.removeCallbacks(timeout)
                    if (pendingImage !== result) return@runOnUiThread
                    pendingImage = null
                    result.error("invalid_image", "Choose a readable image up to ${maxBytes / MAX_IMAGE_BYTES} MB.", null)
                }
            }
        }.start()
    }

    private companion object {
        const val IMAGE_REQUEST = 3071
        const val MAX_IMAGE_BYTES = 1024 * 1024
    }
}
