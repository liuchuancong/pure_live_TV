package com.mystyle.purelive.tv

import android.app.WallpaperManager
import android.graphics.BitmapFactory
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "pure_live/system_wallpaper"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setWallpaper" -> {
                    val bytes = call.arguments as? ByteArray
                    if (bytes == null) {
                        result.error("bad_args", "image bytes required", null)
                        return@setMethodCallHandler
                    }
                    // Decode + write off the main thread; the reply hops back
                    // to the platform thread.
                    Thread {
                        var error: String? = null
                        try {
                            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                            if (bitmap == null) {
                                error = "decode_failed"
                            } else {
                                val manager = WallpaperManager.getInstance(applicationContext)
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                    manager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                                } else {
                                    manager.setBitmap(bitmap)
                                }
                            }
                        } catch (e: Exception) {
                            error = e.message ?: "set_failed"
                        }
                        val failure = error
                        runOnUiThread {
                            if (failure == null) result.success(true) else result.error("set_failed", failure, null)
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }
}
