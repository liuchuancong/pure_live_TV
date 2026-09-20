package com.codenameakshay.async_wallpaper

import java.util.Calendar
import java.util.Locale
import java.util.TimeZone
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WallpaperRotationScheduleTest {
  @Test
  fun `normal active window includes start and excludes end`() {
    assertFalse(WallpaperRotationScheduleMath.isWithinActiveHours(5, 6, 23))
    assertTrue(WallpaperRotationScheduleMath.isWithinActiveHours(6, 6, 23))
    assertTrue(WallpaperRotationScheduleMath.isWithinActiveHours(22, 6, 23))
    assertFalse(WallpaperRotationScheduleMath.isWithinActiveHours(23, 6, 23))
  }

  @Test
  fun `window that wraps past midnight includes both sides`() {
    assertTrue(WallpaperRotationScheduleMath.isWithinActiveHours(22, 22, 6))
    assertTrue(WallpaperRotationScheduleMath.isWithinActiveHours(0, 22, 6))
    assertTrue(WallpaperRotationScheduleMath.isWithinActiveHours(5, 22, 6))
    assertFalse(WallpaperRotationScheduleMath.isWithinActiveHours(6, 22, 6))
    assertFalse(WallpaperRotationScheduleMath.isWithinActiveHours(12, 22, 6))
  }

  @Test
  fun `equal start and end describe a full day`() {
    assertTrue(WallpaperRotationScheduleMath.isWithinActiveHours(0, 9, 9))
    assertTrue(WallpaperRotationScheduleMath.isWithinActiveHours(23, 9, 9))
  }

  @Test
  fun `out of range hours are clamped instead of rejected`() {
    assertTrue(WallpaperRotationScheduleMath.isWithinActiveHours(23, 25, -3))
    assertEquals(23, WallpaperRotationScheduleMath.normalizeHour(99))
    assertEquals(0, WallpaperRotationScheduleMath.normalizeHour(-5))
  }

  @Test
  fun `next window start uses today when the hour is still ahead`() {
    val zone = TimeZone.getTimeZone("UTC")
    val now = utcMillis(zone, 2026, Calendar.SEPTEMBER, 15, 5, 30)

    val next = WallpaperRotationScheduleMath.nextStartOfWindowMillis(6, now, zone, Locale.US)

    assertEquals(utcMillis(zone, 2026, Calendar.SEPTEMBER, 15, 6, 0), next)
  }

  @Test
  fun `next window start rolls to tomorrow when the hour has passed`() {
    val zone = TimeZone.getTimeZone("UTC")
    val now = utcMillis(zone, 2026, Calendar.SEPTEMBER, 15, 6, 30)

    val next = WallpaperRotationScheduleMath.nextStartOfWindowMillis(6, now, zone, Locale.US)

    assertEquals(utcMillis(zone, 2026, Calendar.SEPTEMBER, 16, 6, 0), next)
  }

  @Test
  fun `next window start returns the current instant exactly on the hour`() {
    val zone = TimeZone.getTimeZone("UTC")
    val now = utcMillis(zone, 2026, Calendar.SEPTEMBER, 15, 6, 0)

    val next = WallpaperRotationScheduleMath.nextStartOfWindowMillis(6, now, zone, Locale.US)

    assertEquals(now, next)
  }

  private fun utcMillis(
    zone: TimeZone,
    year: Int,
    month: Int,
    day: Int,
    hour: Int,
    minute: Int,
  ): Long {
    return Calendar.getInstance(zone, Locale.US).apply {
      clear()
      set(year, month, day, hour, minute, 0)
    }.timeInMillis
  }
}
