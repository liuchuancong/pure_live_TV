package com.codenameakshay.async_wallpaper

import android.content.Context

internal object WallpaperRotationRunner {
  fun runNext(context: Context): Boolean {
    val store = WallpaperRotationStore(context)
    if (!store.isRunning()) {
      return true
    }
    val engine = WallpaperRotationEngine(context, store)
    val success = engine.applyNextWallpaper()
    val config = store.getConfig()
    if (config != null && config.enableIntervalTrigger) {
      val nextRunEpochMs =
        System.currentTimeMillis() + config.intervalMinutes.toLong() * 60_000L
      store.setNextRunEpochMs(nextRunEpochMs)
    }
    return success
  }
}
