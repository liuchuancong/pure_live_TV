package com.codenameakshay.async_wallpaper

import kotlin.math.sqrt
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class BitmapTransformMathTest {
  @Test
  fun `center crop crops a landscape source around its center`() {
    assertEquals(
      RectSpec(500, 0, 1500, 1000),
      BitmapTransformMath.calculateCenterCrop(2000, 1000, 1000, 1000, 0.5f, 0.5f),
    )
  }

  @Test
  fun `center crop clamps focal points at both source edges`() {
    assertEquals(
      RectSpec(0, 0, 1000, 1000),
      BitmapTransformMath.calculateCenterCrop(2000, 1000, 1000, 1000, -5f, -2f),
    )
    assertEquals(
      RectSpec(1000, 0, 2000, 1000),
      BitmapTransformMath.calculateCenterCrop(2000, 1000, 1000, 1000, 7f, 3f),
    )
  }

  @Test
  fun `center crop handles portrait sources with vertical focal positions`() {
    assertEquals(
      RectSpec(0, 1000, 1000, 2000),
      BitmapTransformMath.calculateCenterCrop(1000, 2000, 1000, 1000, 0.5f, 0.75f),
    )
  }

  @Test
  fun `fit center preserves the full image and letterboxes landscape inputs`() {
    val geometry = BitmapTransformMath.calculate(
      WallpaperScaleModeData.FIT_CENTER,
      sourceWidth = 2000,
      sourceHeight = 1000,
      targetWidth = 1000,
      targetHeight = 1000,
    )

    assertEquals(RectSpec(0, 0, 2000, 1000), geometry.sourceRect)
    assertEquals(RectSpec(0, 250, 1000, 750), geometry.destinationRect)
    assertEquals(1000, geometry.outputWidth)
    assertEquals(1000, geometry.outputHeight)
  }

  @Test
  fun `fit center handles portrait inputs in a landscape target`() {
    val geometry = BitmapTransformMath.calculate(
      WallpaperScaleModeData.FIT_CENTER,
      sourceWidth = 1000,
      sourceHeight = 2000,
      targetWidth = 2000,
      targetHeight = 1000,
    )

    assertEquals(RectSpec(750, 0, 1250, 1000), geometry.destinationRect)
  }

  @Test
  fun `center keeps a smaller image unscaled and centered`() {
    val geometry = BitmapTransformMath.calculate(
      WallpaperScaleModeData.CENTER,
      sourceWidth = 500,
      sourceHeight = 200,
      targetWidth = 1000,
      targetHeight = 1000,
    )

    assertEquals(RectSpec(0, 0, 500, 200), geometry.sourceRect)
    assertEquals(RectSpec(250, 400, 750, 600), geometry.destinationRect)
  }

  @Test
  fun `center crops an oversized source without scaling it`() {
    val geometry = BitmapTransformMath.calculate(
      WallpaperScaleModeData.CENTER,
      sourceWidth = 2000,
      sourceHeight = 1000,
      targetWidth = 1000,
      targetHeight = 1000,
    )

    assertEquals(RectSpec(500, 0, 1500, 1000), geometry.sourceRect)
    assertEquals(RectSpec(0, 0, 1000, 1000), geometry.destinationRect)
  }

  @Test
  fun `fill keeps the source intact and positions its scaled canvas around the focal point`() {
    val geometry = BitmapTransformMath.calculate(
      WallpaperScaleModeData.FILL,
      sourceWidth = 2000,
      sourceHeight = 1000,
      targetWidth = 1000,
      targetHeight = 1000,
    )

    assertEquals(RectSpec(0, 0, 2000, 1000), geometry.sourceRect)
    assertEquals(RectSpec(-500, 0, 1500, 1000), geometry.destinationRect)
  }

  @Test
  fun `stretch maps every source pixel to the full target without aspect preservation`() {
    val geometry = BitmapTransformMath.calculate(
      WallpaperScaleModeData.STRETCH,
      sourceWidth = 2000,
      sourceHeight = 1000,
      targetWidth = 1000,
      targetHeight = 1000,
    )

    assertEquals(RectSpec(0, 0, 2000, 1000), geometry.sourceRect)
    assertEquals(RectSpec(0, 0, 1000, 1000), geometry.destinationRect)
  }

  @Test
  fun `non-finite focal points fall back to center`() {
    assertEquals(0.5f, BitmapTransformMath.clampFocalPoint(Float.NaN), 0f)
    assertEquals(0.5f, BitmapTransformMath.clampFocalPoint(Float.POSITIVE_INFINITY), 0f)
  }

  @Test
  fun `invalid dimensions fail explicitly`() {
    assertThrows(IllegalArgumentException::class.java) {
      BitmapTransformMath.calculate(
        WallpaperScaleModeData.CENTER_CROP,
        sourceWidth = 100,
        sourceHeight = -1,
        targetWidth = 100,
        targetHeight = 100,
      )
    }
  }

  @Test
  fun `scale to fit keeps images already within both bounds unscaled`() {
    assertEquals(
      1.0,
      BitmapTransformMath.scaleToFit(width = 100, height = 100, maxDimension = 200, maxPixels = 1_000_000),
      0.0,
    )
  }

  @Test
  fun `scale to fit is limited by the longer side when only a dimension is exceeded`() {
    assertEquals(
      0.512,
      BitmapTransformMath.scaleToFit(width = 8000, height = 8000, maxDimension = 4096, maxPixels = Long.MAX_VALUE),
      1e-9,
    )
  }

  @Test
  fun `scale to fit is limited by pixel count when only the total is exceeded`() {
    assertEquals(
      sqrt(0.5),
      BitmapTransformMath.scaleToFit(width = 100, height = 100, maxDimension = 1_000_000, maxPixels = 5_000),
      1e-9,
    )
  }

  @Test
  fun `wallpaper canvas is the display size, not the launcher's wide virtual size`() {
    assertEquals(1080 to 2400, BitmapTransformMath.wallpaperCanvasSize(1080, 2400, rotated = false))
  }

  @Test
  fun `wallpaper canvas uses the natural orientation when measured while rotated`() {
    assertEquals(1080 to 2400, BitmapTransformMath.wallpaperCanvasSize(2400, 1080, rotated = true))
  }

  @Test
  fun `wallpaper canvas stays within the transform bounds and keeps its aspect ratio`() {
    val (width, height) = BitmapTransformMath.wallpaperCanvasSize(7680, 4320, rotated = false)

    assert(width <= 4_096 && height <= 4_096)
    assert(width.toLong() * height <= 8L * 1024L * 1024L)
    assertEquals(7680.0 / 4320.0, width.toDouble() / height, 0.001)
  }

  @Test
  fun `decoder sampling chooses a power of two within the pixel budget`() {
    assertEquals(
      4,
      WallpaperSourceLoader.calculateInSampleSize(
        width = 8000,
        height = 4000,
        maxPixels = 2_000_000,
      ),
    )
  }
}
