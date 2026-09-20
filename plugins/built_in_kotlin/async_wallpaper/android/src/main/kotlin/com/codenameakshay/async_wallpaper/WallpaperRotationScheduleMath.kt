package com.codenameakshay.async_wallpaper

import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

/**
 * Pure trigger math for wallpaper rotation.
 *
 * Deliberately free of Android types so the active-hour window and the next alarm instant stay
 * covered by plain JVM unit tests.
 */
internal object WallpaperRotationScheduleMath {
  const val HOURS_PER_DAY = 24

  /** Clamps any caller-supplied hour into `0..23`. */
  fun normalizeHour(hour: Int): Int = hour.coerceIn(0, HOURS_PER_DAY - 1)

  /**
   * Whether [hour] falls inside a window that starts at [startHour] and ends at [endHour].
   *
   * A window may wrap past midnight (for example 22 to 6). Equal start and end hours describe a
   * full-day window rather than an empty one.
   */
  fun isWithinActiveHours(hour: Int, startHour: Int, endHour: Int): Boolean {
    val hourOfDay = normalizeHour(hour)
    val start = normalizeHour(startHour)
    val end = normalizeHour(endHour)
    return when {
      start == end -> true
      start < end -> hourOfDay in start until end
      else -> hourOfDay >= start || hourOfDay < end
    }
  }

  /** Returns the next occurrence of [startHour]:00 local time at or after [nowMillis]. */
  fun nextStartOfWindowMillis(
    startHour: Int,
    nowMillis: Long,
    timeZone: TimeZone = TimeZone.getDefault(),
    locale: Locale = Locale.getDefault(),
  ): Long {
    return Calendar.getInstance(timeZone, locale).apply {
      timeInMillis = nowMillis
      set(Calendar.HOUR_OF_DAY, normalizeHour(startHour))
      set(Calendar.MINUTE, 0)
      set(Calendar.SECOND, 0)
      set(Calendar.MILLISECOND, 0)
      if (timeInMillis < nowMillis) {
        add(Calendar.DAY_OF_YEAR, 1)
      }
    }.timeInMillis
  }
}
