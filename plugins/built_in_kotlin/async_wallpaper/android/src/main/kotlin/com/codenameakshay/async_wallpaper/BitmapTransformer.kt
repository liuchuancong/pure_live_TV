package com.codenameakshay.async_wallpaper

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Point
import android.graphics.Rect
import android.hardware.display.DisplayManager
import android.view.Display
import android.view.Surface
import androidx.core.graphics.createBitmap
import kotlin.math.floor
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sqrt

/** An integer rectangle expressed as left, top, right, and bottom edges. */
data class RectSpec(
  val left: Int,
  val top: Int,
  val right: Int,
  val bottom: Int,
) {
  val width: Int
    get() = right - left

  val height: Int
    get() = bottom - top
}

/** Pure geometry describing one bitmap draw into an output canvas. */
data class BitmapTransformSpec(
  val sourceRect: RectSpec,
  val destinationRect: RectSpec,
  val outputWidth: Int,
  val outputHeight: Int,
)

/**
 * Pure Kotlin scaling and crop math.
 *
 * `centerCrop` crops source pixels before drawing, while `fill` keeps the full source rectangle
 * and lets its scaled destination extend beyond the output canvas. Both cover the target without
 * distortion, but keeping them distinct preserves the caller's requested rendering semantics.
 */
object BitmapTransformMath {
  /**
   * Computes geometry for [mode]. [focalX] and [focalY] are normalized source coordinates and
   * are clamped to [0, 1]; non-finite values fall back to the image center.
   */
  fun calculate(
    mode: WallpaperScaleModeData,
    sourceWidth: Int,
    sourceHeight: Int,
    targetWidth: Int,
    targetHeight: Int,
    focalX: Float = DEFAULT_FOCAL_POINT,
    focalY: Float = DEFAULT_FOCAL_POINT,
  ): BitmapTransformSpec {
    requireValidDimensions(sourceWidth, sourceHeight, targetWidth, targetHeight)
    val clampedFocalX = clampFocalPoint(focalX)
    val clampedFocalY = clampFocalPoint(focalY)

    return when (mode) {
      WallpaperScaleModeData.CENTER_CROP -> {
        BitmapTransformSpec(
          sourceRect = calculateCenterCrop(
            sourceWidth,
            sourceHeight,
            targetWidth,
            targetHeight,
            clampedFocalX,
            clampedFocalY,
          ),
          destinationRect = RectSpec(0, 0, targetWidth, targetHeight),
          outputWidth = targetWidth,
          outputHeight = targetHeight,
        )
      }
      WallpaperScaleModeData.FIT_CENTER -> {
        BitmapTransformSpec(
          sourceRect = RectSpec(0, 0, sourceWidth, sourceHeight),
          destinationRect = fitCenterDestination(
            sourceWidth,
            sourceHeight,
            targetWidth,
            targetHeight,
          ),
          outputWidth = targetWidth,
          outputHeight = targetHeight,
        )
      }
      WallpaperScaleModeData.CENTER -> {
        val cropWidth = min(sourceWidth, targetWidth)
        val cropHeight = min(sourceHeight, targetHeight)
        val sourceLeft = cropStart(sourceWidth, cropWidth, clampedFocalX)
        val sourceTop = cropStart(sourceHeight, cropHeight, clampedFocalY)
        val destinationLeft = (targetWidth - cropWidth) / 2
        val destinationTop = (targetHeight - cropHeight) / 2
        BitmapTransformSpec(
          sourceRect = RectSpec(
            left = sourceLeft,
            top = sourceTop,
            right = sourceLeft + cropWidth,
            bottom = sourceTop + cropHeight,
          ),
          destinationRect = RectSpec(
            left = destinationLeft,
            top = destinationTop,
            right = destinationLeft + cropWidth,
            bottom = destinationTop + cropHeight,
          ),
          outputWidth = targetWidth,
          outputHeight = targetHeight,
        )
      }
      WallpaperScaleModeData.FILL -> {
        val destination = fillDestination(
          sourceWidth,
          sourceHeight,
          targetWidth,
          targetHeight,
          clampedFocalX,
          clampedFocalY,
        )
        BitmapTransformSpec(
          sourceRect = RectSpec(0, 0, sourceWidth, sourceHeight),
          destinationRect = destination,
          outputWidth = targetWidth,
          outputHeight = targetHeight,
        )
      }
      WallpaperScaleModeData.STRETCH -> {
        BitmapTransformSpec(
          sourceRect = RectSpec(0, 0, sourceWidth, sourceHeight),
          destinationRect = RectSpec(0, 0, targetWidth, targetHeight),
          outputWidth = targetWidth,
          outputHeight = targetHeight,
        )
      }
    }
  }

  /**
   * Returns the source rectangle whose aspect ratio matches the target. This is intentionally
   * exposed as a small pure operation for callers that need crop hints without drawing a bitmap.
   */
  fun calculateCenterCrop(
    sourceWidth: Int,
    sourceHeight: Int,
    targetWidth: Int,
    targetHeight: Int,
    focalX: Float = DEFAULT_FOCAL_POINT,
    focalY: Float = DEFAULT_FOCAL_POINT,
  ): RectSpec {
    requireValidDimensions(sourceWidth, sourceHeight, targetWidth, targetHeight)
    val cropWidth: Int
    val cropHeight: Int
    if (isSourceWiderThanTarget(sourceWidth, sourceHeight, targetWidth, targetHeight)) {
      cropWidth = scaledDimension(sourceHeight, targetWidth, targetHeight, sourceWidth)
      cropHeight = sourceHeight
    } else {
      cropWidth = sourceWidth
      cropHeight = scaledDimension(sourceWidth, targetHeight, targetWidth, sourceHeight)
    }

    val left = cropStart(sourceWidth, cropWidth, clampFocalPoint(focalX))
    val top = cropStart(sourceHeight, cropHeight, clampFocalPoint(focalY))
    return RectSpec(left, top, left + cropWidth, top + cropHeight)
  }

  /** Clamps normalized focal coordinates and treats NaN/infinity as the visual center. */
  fun clampFocalPoint(value: Float): Float {
    return if (value.isNaN() || value.isInfinite()) {
      DEFAULT_FOCAL_POINT
    } else {
      value.coerceIn(0f, 1f)
    }
  }

  /**
   * Returns the largest scale in (0, 1] that keeps [width] x [height] within both [maxDimension]
   * per side and [maxPixels] total, or `1.0` when the input is already within both bounds.
   */
  fun scaleToFit(width: Int, height: Int, maxDimension: Int, maxPixels: Long): Double {
    val pixelCount = width.toLong() * height.toLong()
    val pixelScale = sqrt(maxPixels.toDouble() / pixelCount.toDouble())
    val dimensionScale = min(
      maxDimension.toDouble() / width.toDouble(),
      maxDimension.toDouble() / height.toDouble(),
    )
    return min(1.0, min(pixelScale, dimensionScale))
  }

  /**
   * Returns the wallpaper canvas for a display measured as [displayWidth] x [displayHeight], in the
   * display's natural orientation and within the transform bounds. [rotated] means the size was
   * measured while the display was turned 90 or 270 degrees.
   *
   * The launcher's desired wallpaper size is deliberately not used: it is a wide virtual canvas,
   * and Android shows a screen-sized window from its left edge, so scale modes computed against it
   * do not match what the user sees.
   */
  fun wallpaperCanvasSize(
    displayWidth: Int,
    displayHeight: Int,
    rotated: Boolean,
    maxDimension: Int = MAX_CANVAS_DIMENSION,
    maxPixels: Long = MAX_CANVAS_PIXELS,
  ): Pair<Int, Int> {
    val width = (if (rotated) displayHeight else displayWidth).coerceAtLeast(1)
    val height = (if (rotated) displayWidth else displayHeight).coerceAtLeast(1)
    val scale = scaleToFit(width, height, maxDimension, maxPixels)
    return floor(width * scale).toInt().coerceAtLeast(1) to
      floor(height * scale).toInt().coerceAtLeast(1)
  }

  private fun fitCenterDestination(
    sourceWidth: Int,
    sourceHeight: Int,
    targetWidth: Int,
    targetHeight: Int,
  ): RectSpec {
    val destinationWidth: Int
    val destinationHeight: Int
    if (isSourceWiderThanTarget(sourceWidth, sourceHeight, targetWidth, targetHeight)) {
      destinationWidth = targetWidth
      destinationHeight = scaledDimension(sourceHeight, targetWidth, sourceWidth, targetHeight)
    } else {
      destinationWidth = scaledDimension(sourceWidth, targetHeight, sourceHeight, targetWidth)
      destinationHeight = targetHeight
    }
    val left = (targetWidth - destinationWidth) / 2
    val top = (targetHeight - destinationHeight) / 2
    return RectSpec(left, top, left + destinationWidth, top + destinationHeight)
  }

  private fun fillDestination(
    sourceWidth: Int,
    sourceHeight: Int,
    targetWidth: Int,
    targetHeight: Int,
    focalX: Float,
    focalY: Float,
  ): RectSpec {
    val destinationWidth: Int
    val destinationHeight: Int
    if (isSourceWiderThanTarget(sourceWidth, sourceHeight, targetWidth, targetHeight)) {
      destinationWidth = scaledDimension(sourceWidth, targetHeight, sourceHeight, Int.MAX_VALUE)
      destinationHeight = targetHeight
    } else {
      destinationWidth = targetWidth
      destinationHeight = scaledDimension(sourceHeight, targetWidth, sourceWidth, Int.MAX_VALUE)
    }
    val left = focusedDestinationStart(targetWidth, destinationWidth, focalX)
    val top = focusedDestinationStart(targetHeight, destinationHeight, focalY)
    return RectSpec(left, top, left + destinationWidth, top + destinationHeight)
  }

  private fun isSourceWiderThanTarget(
    sourceWidth: Int,
    sourceHeight: Int,
    targetWidth: Int,
    targetHeight: Int,
  ): Boolean {
    return sourceWidth.toLong() * targetHeight > sourceHeight.toLong() * targetWidth
  }

  private fun scaledDimension(
    sourceDimension: Int,
    multiplier: Int,
    divisor: Int,
    upperBound: Int,
  ): Int {
    val scaled = (sourceDimension.toDouble() * multiplier / divisor).roundToInt()
    return scaled.coerceIn(1, upperBound)
  }

  private fun cropStart(total: Int, crop: Int, focalPoint: Float): Int {
    val desired = (total * focalPoint - crop / 2f).roundToInt()
    return desired.coerceIn(0, total - crop)
  }

  private fun focusedDestinationStart(canvas: Int, destination: Int, focalPoint: Float): Int {
    if (destination <= canvas) {
      return (canvas - destination) / 2
    }
    val desired = (canvas / 2f - destination * focalPoint).roundToInt()
    return desired.coerceIn(canvas - destination, 0)
  }

  private fun requireValidDimensions(
    sourceWidth: Int,
    sourceHeight: Int,
    targetWidth: Int,
    targetHeight: Int,
  ) {
    require(hasValidDimensions(sourceWidth, sourceHeight, targetWidth, targetHeight)) {
      "Source and target dimensions must be positive."
    }
  }

  private fun hasValidDimensions(
    sourceWidth: Int,
    sourceHeight: Int,
    targetWidth: Int,
    targetHeight: Int,
  ): Boolean {
    return sourceWidth > 0 && sourceHeight > 0 && targetWidth > 0 && targetHeight > 0
  }

  private const val DEFAULT_FOCAL_POINT = 0.5f
  private const val MAX_CANVAS_DIMENSION = 4_096
  private const val MAX_CANVAS_PIXELS = 8L * 1024L * 1024L
}

/** Applies [BitmapTransformMath] geometry using Android's bitmap and canvas APIs. */
object BitmapTransformer {
  /** The wallpaper canvas for the default display; needs no Activity, so workers can use it. */
  fun wallpaperCanvasSize(context: Context): Pair<Int, Int> {
    val display = context.getSystemService(DisplayManager::class.java)?.getDisplay(Display.DEFAULT_DISPLAY)
    val size = Point()
    if (display != null) {
      @Suppress("DEPRECATION")
      display.getRealSize(size)
    } else {
      context.resources.displayMetrics.let { size.set(it.widthPixels, it.heightPixels) }
    }
    val rotated = display?.rotation == Surface.ROTATION_90 || display?.rotation == Surface.ROTATION_270
    return BitmapTransformMath.wallpaperCanvasSize(size.x, size.y, rotated)
  }

  /** Calculates and applies a scale mode in one call. */
  fun transform(
    bitmap: Bitmap,
    mode: WallpaperScaleModeData,
    targetWidth: Int,
    targetHeight: Int,
    focalX: Float = 0.5f,
    focalY: Float = 0.5f,
    backgroundColor: Int = Color.BLACK,
  ): Bitmap {
    val geometry = BitmapTransformMath.calculate(
      mode,
      bitmap.width,
      bitmap.height,
      targetWidth,
      targetHeight,
      focalX,
      focalY,
    )
    return apply(bitmap, geometry, backgroundColor)
  }

  /** Draws [bitmap] according to pure [geometry] without taking ownership of the source bitmap. */
  fun apply(
    bitmap: Bitmap,
    geometry: BitmapTransformSpec,
    backgroundColor: Int = Color.BLACK,
  ): Bitmap {
    require(!bitmap.isRecycled) { "Cannot transform a recycled bitmap." }
    require(geometry.outputWidth > 0 && geometry.outputHeight > 0) {
      "Output dimensions must be positive."
    }
    require(geometry.sourceRect.isWithin(bitmap.width, bitmap.height)) {
      "Source rectangle must be within bitmap bounds."
    }
    require(geometry.destinationRect.width > 0 && geometry.destinationRect.height > 0) {
      "Destination rectangle must have positive dimensions."
    }

    val output = createBitmap(
      geometry.outputWidth,
      geometry.outputHeight,
      Bitmap.Config.ARGB_8888,
    )
    val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG or Paint.DITHER_FLAG)
    Canvas(output).apply {
      drawColor(backgroundColor)
      drawBitmap(
        bitmap,
        geometry.sourceRect.toAndroidRect(),
        geometry.destinationRect.toAndroidRect(),
        paint,
      )
    }
    return output
  }

  private fun RectSpec.isWithin(width: Int, height: Int): Boolean {
    return left >= 0 && top >= 0 && right <= width && bottom <= height && this.width > 0 && this.height > 0
  }

  private fun RectSpec.toAndroidRect(): Rect = Rect(left, top, right, bottom)
}
