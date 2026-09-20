package com.codenameakshay.async_wallpaper

import android.media.MediaMetadataRetriever
import java.io.File
import java.io.IOException
import java.util.Locale

/**
 * The metadata we need to safely hand a video to [android.media.MediaPlayer].
 *
 * Width and height describe the encoded stream. [displayWidth] and
 * [displayHeight] account for the video rotation metadata.
 */
data class VideoMetadata(
  val mimeType: String,
  val width: Int,
  val height: Int,
  val rotationDegrees: Int,
  val durationMillis: Long,
) {
  val displayWidth: Int
    get() = if (rotationDegrees == 90 || rotationDegrees == 270) height else width

  val displayHeight: Int
    get() = if (rotationDegrees == 90 || rotationDegrees == 270) width else height
}

/** Reasons a candidate cannot become the active live-wallpaper video. */
enum class VideoValidationFailure {
  MISSING_FILE,
  NO_VIDEO_TRACK,
  INVALID_MIME_TYPE,
  INVALID_DIMENSIONS,
  INVALID_ROTATION,
  INVALID_DURATION,
  RETRIEVER_FAILURE,
}

/** A stable, caller-friendly validation failure. */
class VideoMetadataValidationException(
  val failure: VideoValidationFailure,
  message: String,
  cause: Throwable? = null,
) : IOException(message, cause)

/** Small seam around Android's retriever so metadata policy remains JVM-testable. */
interface VideoMetadataRetriever {
  fun setDataSource(path: String)

  fun extractMetadata(keyCode: Int): String?

  fun release()
}

/** Any file validator that can be used by [VideoWallpaperRepository]. */
fun interface VideoFileValidator {
  @Throws(VideoMetadataValidationException::class)
  fun validate(file: File): VideoMetadata
}

/**
 * Validates the material properties of a video before it replaces the active
 * live-wallpaper asset. MediaMetadataRetriever parsing is deliberately kept
 * separate from the policy so failures can be exercised without Android APIs.
 */
class VideoMetadataValidator(
  private val retrieverFactory: () -> VideoMetadataRetriever = { AndroidVideoMetadataRetriever() },
) : VideoFileValidator {
  override fun validate(file: File): VideoMetadata {
    if (!file.isFile || !file.canRead() || file.length() <= 0L) {
      throw VideoMetadataValidationException(
        VideoValidationFailure.MISSING_FILE,
        "Video source is missing, unreadable, or empty: ${file.absolutePath}",
      )
    }

    var retriever: VideoMetadataRetriever? = null
    try {
      retriever = retrieverFactory()
      retriever.setDataSource(file.absolutePath)
      return VideoMetadataPolicy.validate(
        hasVideoTrack = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_HAS_VIDEO),
        mimeType = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_MIMETYPE),
        width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH),
        height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT),
        rotationDegrees = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION),
        durationMillis = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION),
      )
    } catch (error: VideoMetadataValidationException) {
      throw error
    } catch (error: Exception) {
      throw VideoMetadataValidationException(
        VideoValidationFailure.RETRIEVER_FAILURE,
        "Unable to read video metadata from ${file.absolutePath}",
        error,
      )
    } finally {
      runCatching { retriever?.release() }
    }
  }
}

/** Pure validation policy shared by Android metadata extraction and JVM tests. */
object VideoMetadataPolicy {
  fun validate(
    hasVideoTrack: String?,
    mimeType: String?,
    width: String?,
    height: String?,
    rotationDegrees: String?,
    durationMillis: String?,
  ): VideoMetadata {
    if (!hasVideoTrack.isAffirmativeVideoTrack()) {
      throw VideoMetadataValidationException(
        VideoValidationFailure.NO_VIDEO_TRACK,
        "The media does not contain a playable video track.",
      )
    }

    val normalizedMimeType = mimeType?.trim()?.lowercase(Locale.ROOT)
    if (normalizedMimeType.isNullOrEmpty() || !normalizedMimeType.startsWith("video/")) {
      throw VideoMetadataValidationException(
        VideoValidationFailure.INVALID_MIME_TYPE,
        "Expected a video MIME type but found '${mimeType.orEmpty()}'.",
      )
    }

    val parsedWidth = width?.trim()?.toIntOrNull()
    val parsedHeight = height?.trim()?.toIntOrNull()
    if (parsedWidth == null || parsedHeight == null || parsedWidth <= 0 || parsedHeight <= 0) {
      throw VideoMetadataValidationException(
        VideoValidationFailure.INVALID_DIMENSIONS,
        "Video dimensions must be positive, but were ${width.orEmpty()}x${height.orEmpty()}.",
      )
    }

    val parsedRotation = when {
      rotationDegrees.isNullOrBlank() -> 0
      else -> rotationDegrees.trim().toIntOrNull()
        ?: throw VideoMetadataValidationException(
          VideoValidationFailure.INVALID_ROTATION,
          "Video rotation is not numeric: '$rotationDegrees'.",
        )
    }
    if (parsedRotation !in VALID_ROTATIONS) {
      throw VideoMetadataValidationException(
        VideoValidationFailure.INVALID_ROTATION,
        "Video rotation must be one of $VALID_ROTATIONS, but was $parsedRotation.",
      )
    }

    val parsedDuration = durationMillis?.trim()?.toLongOrNull()
    if (parsedDuration == null || parsedDuration <= 0L) {
      throw VideoMetadataValidationException(
        VideoValidationFailure.INVALID_DURATION,
        "Video duration must be positive, but was '${durationMillis.orEmpty()}'.",
      )
    }

    return VideoMetadata(
      mimeType = normalizedMimeType,
      width = parsedWidth,
      height = parsedHeight,
      rotationDegrees = parsedRotation,
      durationMillis = parsedDuration,
    )
  }

  private fun String?.isAffirmativeVideoTrack(): Boolean {
    return when (this?.trim()?.lowercase(Locale.ROOT)) {
      "yes", "true", "1" -> true
      else -> false
    }
  }

  private val VALID_ROTATIONS = setOf(0, 90, 180, 270)
}

private class AndroidVideoMetadataRetriever : VideoMetadataRetriever {
  private val delegate = MediaMetadataRetriever()

  override fun setDataSource(path: String) {
    delegate.setDataSource(path)
  }

  override fun extractMetadata(keyCode: Int): String? = delegate.extractMetadata(keyCode)

  override fun release() {
    delegate.release()
  }
}
