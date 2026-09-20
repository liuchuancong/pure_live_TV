package com.codenameakshay.async_wallpaper

import java.io.File
import java.nio.file.Files
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RotationStartTest {
  @Test
  fun `a rejected playlist keeps the cache a running rotation reads`() {
    val root = Files.createTempDirectory("rotation").toFile()
    val cache = File(root, "wallpaper_rotation").apply { mkdirs() }
    File(cache, "wallpaper_0.jpg").writeText("running")

    val paths = replaceDirectoryContents(cache) { emptyList() }

    assertTrue(paths.isEmpty())
    assertEquals("running", File(cache, "wallpaper_0.jpg").readText())
    assertEquals(listOf("wallpaper_rotation"), root.list()!!.toList())
  }

  @Test
  fun `an accepted playlist replaces the cache and returns paths inside it`() {
    val root = Files.createTempDirectory("rotation").toFile()
    val cache = File(root, "wallpaper_rotation").apply { mkdirs() }
    File(cache, "wallpaper_0.jpg").writeText("old")

    val paths = replaceDirectoryContents(cache) { staging ->
      File(staging, "wallpaper_1.jpg").writeText("new")
      listOf("wallpaper_1.jpg")
    }

    assertEquals(listOf(File(cache, "wallpaper_1.jpg").absolutePath), paths)
    assertFalse(File(cache, "wallpaper_0.jpg").exists())
    assertEquals("new", File(cache, "wallpaper_1.jpg").readText())
    assertEquals(listOf("wallpaper_rotation"), root.list()!!.toList())
  }

  @Test
  fun `scheduled rotation waits one interval because start already applied a wallpaper`() {
    val request = WallpaperRotationScheduler.rotationRequest(intervalMinutes = 30, requiresCharging = true)

    assertEquals(TimeUnit.MINUTES.toMillis(30), request.workSpec.initialDelay)
    assertEquals(TimeUnit.MINUTES.toMillis(30), request.workSpec.intervalDuration)
    assertTrue(request.workSpec.constraints.requiresCharging())
  }
}
