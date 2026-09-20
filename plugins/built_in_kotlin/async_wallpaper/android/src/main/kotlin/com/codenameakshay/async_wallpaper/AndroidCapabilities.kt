package com.codenameakshay.async_wallpaper

import android.app.ActivityManager
import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

/** Android-only capability probes shared by the structured wallpaper endpoints. */
object AndroidCapabilities {
  data class StaticWallpaperSupport(
    val wallpaperSupported: Boolean,
    val settingAllowed: Boolean,
  ) {
    val canApplyDirectly: Boolean
      get() = wallpaperSupported && settingAllowed
  }

  fun snapshot(context: Context): WallpaperCapabilitiesData {
    val appContext = context.applicationContext
    val staticSupport = staticWallpaperSupport(appContext)
    val packageManager = appContext.packageManager
    val hasLiveWallpaperFeature = packageManager.hasSystemFeature(PackageManager.FEATURE_LIVE_WALLPAPER)
    val canOpenLiveWallpaperFlow = resolves(
      packageManager,
      Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER),
    )
    val hasVideoService = hasWallpaperService(appContext, VideoLiveWallpaper::class.java)
    val hasOpenGlService = hasWallpaperService(appContext, OpenGlLiveWallpaper::class.java)
    val supportsLive = hasLiveWallpaperFeature && canOpenLiveWallpaperFlow && hasVideoService
    val supportsOpenGl = hasLiveWallpaperFeature && canOpenLiveWallpaperFlow && hasOpenGlService &&
      OpenGlLiveWallpaper.isOpenGlEs2Supported(appContext)
    val hasPicker = resolves(packageManager, Intent(Intent.ACTION_SET_WALLPAPER)) ||
      resolves(packageManager, Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER))
    val glVersion = openGlVersion(appContext)

    return WallpaperCapabilitiesData(
      supportsStaticWallpaper = staticSupport.canApplyDirectly,
      supportsLiveWallpaper = supportsLive,
      supportsOpenGlLiveWallpaper = supportsOpenGl,
      supportsHomeWallpaper = staticSupport.canApplyDirectly,
      supportsLockWallpaper = staticSupport.canApplyDirectly,
      supportsBothWallpapers = staticSupport.canApplyDirectly,
      canSetWallpaper = staticSupport.canApplyDirectly,
      hasSystemWallpaperPicker = hasPicker,
      // Direct bitmap and preparation work do not require an Activity. Any system UI path does.
      requiresForeground = hasPicker || canOpenLiveWallpaperFlow,
      manufacturer = Build.MANUFACTURER ?: "Unknown",
      sdkInt = Build.VERSION.SDK_INT.toLong(),
      openGlVersion = glVersion,
      // Android exposes the requested GLES version without creating an EGL context. Do not
      // manufacture a renderer string that would be misleading on devices with multiple GPUs.
      openGlRenderer = null,
    )
  }

  fun staticWallpaperSupport(context: Context): StaticWallpaperSupport {
    val manager = WallpaperManager.getInstance(context.applicationContext)
    val supported = runCatching { manager.isWallpaperSupported }.getOrDefault(false)
    val allowed = runCatching { manager.isSetWallpaperAllowed }.getOrDefault(false)
    return StaticWallpaperSupport(supported, allowed)
  }

  fun hasVideoLiveWallpaper(context: Context): Boolean {
    val appContext = context.applicationContext
    return appContext.packageManager.hasSystemFeature(PackageManager.FEATURE_LIVE_WALLPAPER) &&
      resolves(appContext.packageManager, Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER)) &&
      hasWallpaperService(appContext, VideoLiveWallpaper::class.java)
  }

  fun hasOpenGlLiveWallpaper(context: Context): Boolean {
    val appContext = context.applicationContext
    return appContext.packageManager.hasSystemFeature(PackageManager.FEATURE_LIVE_WALLPAPER) &&
      resolves(appContext.packageManager, Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER)) &&
      hasWallpaperService(appContext, OpenGlLiveWallpaper::class.java) &&
      OpenGlLiveWallpaper.isOpenGlEs2Supported(appContext)
  }

  fun resolves(packageManager: PackageManager, intent: Intent): Boolean {
    return runCatching {
      packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY) != null
    }.getOrDefault(false)
  }

  /**
   * Resolves [intent] once and returns it pinned to the component that answered.
   *
   * Launching the original implicit intent re-resolves at start time, so a different handler could
   * receive the flow (and, for the cropper, the content URI) than the one that was checked. Returns
   * null when nothing handles the intent.
   */
  fun resolveExplicit(packageManager: PackageManager, intent: Intent): Intent? {
    return runCatching {
      packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
        ?.activityInfo
        ?.let { info -> Intent(intent).setComponent(ComponentName(info.packageName, info.name)) }
    }.getOrNull()
  }

  private fun hasWallpaperService(context: Context, serviceClass: Class<*>): Boolean {
    return runCatching {
      context.packageManager.getServiceInfo(
        ComponentName(context, serviceClass),
        0,
      )
      true
    }.getOrDefault(false)
  }

  private fun openGlVersion(context: Context): String? {
    val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
    val version = manager?.deviceConfigurationInfo?.reqGlEsVersion ?: return null
    if (version == 0) {
      return null
    }
    val major = version shr 16
    val minor = version and 0xffff
    return "$major.$minor"
  }
}
