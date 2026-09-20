package com.codenameakshay.async_wallpaper

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/**
 * Owns one Pigeon implementation per Flutter engine and forwards only a currently attached
 * Activity to it. The implementation stores that Activity weakly, so configuration changes and
 * engine teardown cannot retain an old window.
 */
class AsyncWallpaperPlugin : FlutterPlugin, ActivityAware {
  private var implementation: PigeonApiImpl? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    implementation?.shutdown()
    PigeonApiImpl(binding.applicationContext).also { api ->
      implementation = api
      WallpaperApi.setUp(binding.binaryMessenger, api)
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    WallpaperApi.setUp(binding.binaryMessenger, null)
    implementation?.shutdown()
    implementation = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    implementation?.attachActivity(binding.activity)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    implementation?.detachActivity()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    implementation?.attachActivity(binding.activity)
  }

  override fun onDetachedFromActivity() {
    implementation?.detachActivity()
  }
}
