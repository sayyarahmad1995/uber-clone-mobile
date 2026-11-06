package com.uberclone.uberclone

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ContentResolver
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import android.provider.MediaStore
import androidx.core.content.FileProvider
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.File

class DriverSelfieFileProvider : FileProvider()

class MainActivity : FlutterActivity() {
    private var pendingImage: MethodChannel.Result? = null
    private val pickerHandler = Handler(Looper.getMainLooper())
    private var activeReads = 0
    private var pendingLimit = MAX_IMAGE_BYTES
    private var pendingSelfie: File? = null
    private var pendingSelfieUri: Uri? = null
    private val selfieDirectory get() = File(cacheDir, "driver-selfies")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // A camera activity can outlive this process. Abandoned captures are
        // never restored as draft data and are removed when HiGO restarts.
        selfieDirectory.listFiles()?.forEach { it.delete() }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "higo/driver_documents")
            .setMethodCallHandler { call, result ->
                if (call.method != "pickImage" && call.method != "captureSelfie") {
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
                    if (call.method == "captureSelfie") {
                        launchSelfie(result)
                        return@setMethodCallHandler
                    }
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
        if (requestCode == SELFIE_REQUEST) {
            completeSelfie(resultCode)
            return
        }
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

    private fun launchSelfie(result: MethodChannel.Result) {
        try {
            selfieDirectory.mkdirs()
            val file = File.createTempFile("selfie-", ".jpg", selfieDirectory)
            pendingSelfie = file
            val uri = FileProvider.getUriForFile(this, "$packageName.driver-selfies", file)
            pendingSelfieUri = uri
            val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                putExtra(MediaStore.EXTRA_OUTPUT, uri)
                putExtra("android.intent.extras.CAMERA_FACING", 1)
                putExtra("android.intent.extra.USE_FRONT_CAMERA", true)
                addFlags(SELFIE_GRANTS)
                clipData = android.content.ClipData.newRawUri("HiGO selfie", uri)
            }
            startActivityForResult(intent, SELFIE_REQUEST)
        } catch (_: Exception) {
            releaseSelfie()?.delete()
            pendingImage = null
            result.error("camera_unavailable", "Unable to open the camera. Check camera permissions and try again.", null)
        }
    }

    private fun releaseSelfie(): File? {
        pendingSelfieUri?.let { revokeUriPermission(it, SELFIE_GRANTS) }
        pendingSelfieUri = null
        return pendingSelfie.also { pendingSelfie = null }
    }

    private fun completeSelfie(resultCode: Int) {
        val file = releaseSelfie() ?: return
        val result = pendingImage
        if (resultCode != Activity.RESULT_OK || result == null) {
            file.delete()
            pendingImage = null
            result?.success(null)
            return
        }
        val maxBytes = pendingLimit
        activeReads++
        Thread {
            val bytes = try {
                readSelfie(file, maxBytes)
            } catch (_: Exception) {
                null
            } finally {
                file.delete()
            }
            runOnUiThread {
                activeReads--
                if (pendingImage !== result) return@runOnUiThread
                pendingImage = null
                if (bytes == null) {
                    result.error("invalid_selfie", "Retake the selfie. The camera image could not be prepared within 2 MB.", null)
                } else {
                    result.success(bytes)
                }
            }
        }.start()
    }

    private fun readSelfie(file: File, maxBytes: Int): ByteArray? {
        if (file.length() !in 1..MAX_RAW_SELFIE_BYTES) return null
        val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.path, options)
        if (options.outWidth <= 0 || options.outHeight <= 0 ||
            options.outWidth.toLong() * options.outHeight > MAX_RAW_SELFIE_PIXELS) return null
        options.inSampleSize = 1
        while (maxOf(options.outWidth, options.outHeight) / options.inSampleSize > MAX_SELFIE_EDGE) {
            options.inSampleSize *= 2
        }
        options.inJustDecodeBounds = false
        val bitmap = BitmapFactory.decodeFile(file.path, options) ?: return null
        try {
            val orientation = ExifInterface(file.path).getAttributeInt(
                ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL
            )
            val transform = Matrix().apply {
                when (orientation) {
                    ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> setScale(-1f, 1f)
                    ExifInterface.ORIENTATION_ROTATE_180 -> setRotate(180f)
                    ExifInterface.ORIENTATION_FLIP_VERTICAL -> setScale(1f, -1f)
                    ExifInterface.ORIENTATION_TRANSPOSE -> { setRotate(90f); postScale(-1f, 1f) }
                    ExifInterface.ORIENTATION_ROTATE_90 -> setRotate(90f)
                    ExifInterface.ORIENTATION_TRANSVERSE -> { setRotate(270f); postScale(-1f, 1f) }
                    ExifInterface.ORIENTATION_ROTATE_270 -> setRotate(270f)
                }
            }
            val upright = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, transform, true)
            try {
                val output = ByteArrayOutputStream()
                if (!upright.compress(Bitmap.CompressFormat.JPEG, 85, output) || output.size() > maxBytes) return null
                return output.toByteArray()
            } finally {
                if (upright !== bitmap) upright.recycle()
            }
        } finally {
            bitmap.recycle()
        }
    }

    private companion object {
        const val IMAGE_REQUEST = 3071
        const val SELFIE_REQUEST = 3072
        const val SELFIE_GRANTS = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        const val MAX_RAW_SELFIE_BYTES = 24L * 1024 * 1024
        const val MAX_RAW_SELFIE_PIXELS = 80_000_000L
        const val MAX_SELFIE_EDGE = 1440
        const val MAX_IMAGE_BYTES = 1024 * 1024
    }
}
