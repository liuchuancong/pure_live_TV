package com.codenameakshay.async_wallpaper

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequest
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * Owns every background trigger for wallpaper rotation.
 *
 * Intervals and charging use WorkManager; time-of-day uses a one-shot alarm that
 * [WallpaperTimeOfDayReceiver] re-arms after each delivery. No trigger needs a long-running
 * foreground service, which keeps rotation working on Android 14+ (no missing
 * `FOREGROUND_SERVICE_DATA_SYNC` permission) and on Android 15+, where `dataSync` services cannot
 * be started from `BOOT_COMPLETED` and are capped at six hours per day.
 */
internal object WallpaperRotationScheduler {
  private const val PERIODIC_WORK_NAME = "async_wallpaper_rotation_periodic"
  private const val CHARGING_WORK_NAME = "async_wallpaper_rotation_charging"
  private const val IMMEDIATE_WORK_NAME = "async_wallpaper_rotation_immediate"
  private const val TIME_OF_DAY_REQUEST_CODE = 42043

  fun schedulePeriodic(context: Context, intervalMinutes: Int) {
    WorkManager.getInstance(context).enqueueUniquePeriodicWork(
      PERIODIC_WORK_NAME,
      ExistingPeriodicWorkPolicy.UPDATE,
      rotationRequest(intervalMinutes, requiresCharging = false),
    )
  }

  fun cancelPeriodic(context: Context) {
    WorkManager.getInstance(context).cancelUniqueWork(PERIODIC_WORK_NAME)
  }

  /**
   * Rotates while the device is charging. Replaces the previous always-registered
   * `ACTION_POWER_CONNECTED` receiver, which required a persistent foreground service.
   */
  fun scheduleCharging(context: Context, intervalMinutes: Int) {
    WorkManager.getInstance(context).enqueueUniquePeriodicWork(
      CHARGING_WORK_NAME,
      ExistingPeriodicWorkPolicy.UPDATE,
      rotationRequest(intervalMinutes, requiresCharging = true),
    )
  }

  /**
   * Starting a rotation already applies the first wallpaper, so the first scheduled run waits one
   * interval. Without the delay WorkManager runs a new periodic request at once and skips ahead.
   */
  internal fun rotationRequest(intervalMinutes: Int, requiresCharging: Boolean): PeriodicWorkRequest {
    return PeriodicWorkRequestBuilder<WallpaperRotationWorker>(intervalMinutes.toLong(), TimeUnit.MINUTES)
      .setInitialDelay(intervalMinutes.toLong(), TimeUnit.MINUTES)
      .setConstraints(Constraints.Builder().setRequiresCharging(requiresCharging).build())
      .build()
  }

  fun cancelCharging(context: Context) {
    WorkManager.getInstance(context).cancelUniqueWork(CHARGING_WORK_NAME)
  }

  fun enqueueImmediate(context: Context) {
    val request = OneTimeWorkRequestBuilder<WallpaperRotationWorker>().build()
    WorkManager.getInstance(context).enqueueUniqueWork(
      IMMEDIATE_WORK_NAME,
      ExistingWorkPolicy.REPLACE,
      request,
    )
  }

  /**
   * Arms one alarm at the next occurrence of [startHour] local time. The alarm is intentionally
   * inexact so the plugin needs no exact-alarm special access; wallpaper rotation does not need
   * minute-level precision. [WallpaperTimeOfDayReceiver] re-arms it after each delivery.
   */
  fun scheduleTimeOfDay(context: Context, startHour: Int) {
    alarmManager(context)?.setAndAllowWhileIdle(
      AlarmManager.RTC_WAKEUP,
      WallpaperRotationScheduleMath.nextStartOfWindowMillis(
        startHour = startHour,
        nowMillis = System.currentTimeMillis(),
      ),
      timeOfDayPendingIntent(context),
    )
  }

  fun cancelTimeOfDay(context: Context) {
    alarmManager(context)?.cancel(timeOfDayPendingIntent(context))
  }

  private fun timeOfDayPendingIntent(context: Context): PendingIntent {
    return PendingIntent.getBroadcast(
      context,
      TIME_OF_DAY_REQUEST_CODE,
      Intent(context, WallpaperTimeOfDayReceiver::class.java),
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
  }

  private fun alarmManager(context: Context): AlarmManager? {
    return context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
  }
}
