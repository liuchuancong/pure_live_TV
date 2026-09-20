package com.codenameakshay.async_wallpaper

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

internal class WallpaperRotationWorker(
  appContext: Context,
  params: WorkerParameters,
) : CoroutineWorker(appContext, params) {
  override suspend fun doWork(): Result {
    return if (WallpaperRotationRunner.runNext(applicationContext)) {
      Result.success()
    } else {
      // The configured interval, charging, and time-of-day triggers already own the retry cadence.
      // Returning retry() here would also spin for permanent failures such as a deleted or
      // unreadable playlist file, so fail the run and let the next scheduled trigger try again.
      Result.failure()
    }
  }
}
