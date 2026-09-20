package com.codenameakshay.async_wallpaper

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

internal class WallpaperBootReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent?) {
    val action = intent?.action ?: return
    if (action != Intent.ACTION_BOOT_COMPLETED) {
      return
    }
    val store = WallpaperRotationStore(context)
    val config = store.getConfig() ?: return
    if (config.enableIntervalTrigger) {
      WallpaperRotationScheduler.schedulePeriodic(context, config.intervalMinutes)
      val nextRunEpochMs =
        System.currentTimeMillis() + config.intervalMinutes.toLong() * 60_000L
      store.setNextRunEpochMs(nextRunEpochMs)
    } else {
      // Work can survive a crash between saving the configuration and reconciling triggers, so
      // cancel anything the saved configuration no longer enables.
      WallpaperRotationScheduler.cancelPeriodic(context)
      store.setNextRunEpochMs(0L)
    }
    if (config.enableChargingTrigger) {
      WallpaperRotationScheduler.scheduleCharging(context, config.intervalMinutes)
    } else {
      WallpaperRotationScheduler.cancelCharging(context)
    }
    if (config.enableTimeOfDayTrigger) {
      WallpaperRotationScheduler.scheduleTimeOfDay(context, config.activeHoursStart)
    } else {
      WallpaperRotationScheduler.cancelTimeOfDay(context)
    }
  }
}
