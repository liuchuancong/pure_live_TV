package com.codenameakshay.async_wallpaper

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import java.util.Calendar

internal class WallpaperTimeOfDayReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent?) {
    Log.d(TAG, "Received time-of-day alarm")
    val store = WallpaperRotationStore(context)
    if (!store.isRunning() || !store.isTimeOfDayTriggerEnabled()) {
      Log.d(TAG, "Skip time-of-day rotation: not running or disabled")
      return
    }

    val startHour = store.getActiveHoursStart()
    val endHour = store.getActiveHoursEnd()

    // The alarm is one-shot, so re-arm it before doing any work. That keeps the next window queued
    // even when this delivery is skipped or the rotation itself fails.
    WallpaperRotationScheduler.scheduleTimeOfDay(context, startHour)

    val currentHour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
    if (!WallpaperRotationScheduleMath.isWithinActiveHours(currentHour, startHour, endHour)) {
      Log.d(
        TAG,
        "Skip time-of-day rotation: outside active hours ($currentHour not in $startHour-$endHour)",
      )
      return
    }

    // Hand off through WorkManager. A BroadcastReceiver returns immediately, so applying the
    // wallpaper here on a private executor risks the process being killed before it finishes.
    WallpaperRotationScheduler.enqueueImmediate(context)
  }

  companion object {
    private const val TAG = "TimeOfDayReceiver"
  }
}
