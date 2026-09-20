package com.codenameakshay.async_wallpaper

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import androidx.core.net.toUri
import java.io.ByteArrayInputStream
import java.io.File
import java.io.FileInputStream
import java.io.FilterInputStream
import java.io.IOException
import java.io.InputStream
import java.net.URI
import java.util.Locale
import javax.net.ssl.HttpsURLConnection

/**
 * A recoverable error while opening or decoding a [WallpaperSourceData].
 *
 * Callers can map [code] to their transport error without having to infer a
 * failure category from an exception message.
 */
class WallpaperSourceException(
  val code: String,
  message: String,
  cause: Throwable? = null,
) : IOException(message, cause)

/**
 * Opens and decodes static wallpaper sources without buffering an entire remote response.
 *
 * The decoder opens a source independently for bounds, EXIF, and sampled bitmap reads. This
 * deliberately trades a small number of sequential reads for bounded memory use: network,
 * file, and content-URI sources are never copied into a byte array before decoding.
 */
class WallpaperSourceLoader(
  context: Context,
  private val limits: Limits = Limits(),
) {
  /** Limits that protect the host process from oversized encoded and decoded images. */
  data class Limits(
    val connectTimeoutMillis: Int = DEFAULT_CONNECT_TIMEOUT_MILLIS,
    val readTimeoutMillis: Int = DEFAULT_READ_TIMEOUT_MILLIS,
    val maxEncodedBytes: Long = DEFAULT_MAX_ENCODED_BYTES,
    val maxDecodedPixels: Long = DEFAULT_MAX_DECODED_PIXELS,
    val maxRedirects: Int = DEFAULT_MAX_REDIRECTS,
  ) {
    init {
      require(connectTimeoutMillis > 0) { "connectTimeoutMillis must be positive." }
      require(readTimeoutMillis > 0) { "readTimeoutMillis must be positive." }
      require(maxEncodedBytes > 0) { "maxEncodedBytes must be positive." }
      require(maxDecodedPixels > 0) { "maxDecodedPixels must be positive." }
      require(maxRedirects >= 0) { "maxRedirects must not be negative." }
    }
  }

  private val appContext = context.applicationContext

  /**
   * Decodes [source] with a bounded sample size and applies supported EXIF orientation values.
   * The caller owns the returned bitmap and must recycle it when it is no longer needed.
   */
  @Throws(WallpaperSourceException::class)
  fun load(source: WallpaperSourceData): Bitmap {
    val inputSource = inputSourceFor(source)
    val bounds = decodeBounds(inputSource)
    val sampleSize = calculateInSampleSize(
      width = bounds.width,
      height = bounds.height,
      maxPixels = limits.maxDecodedPixels,
    )
    val decoded = decodeBitmap(inputSource, sampleSize)
    val exifOrientation = readExifOrientation(inputSource)
    val normalized = applyExifOrientation(decoded, exifOrientation)

    if (pixelCount(normalized.width, normalized.height) > limits.maxDecodedPixels) {
      if (!normalized.isRecycled) {
        normalized.recycle()
      }
      throw WallpaperSourceException(
        code = ERROR_IMAGE_TOO_LARGE,
        message = "The decoded image exceeds the configured pixel limit.",
      )
    }

    return normalized
  }

  private fun inputSourceFor(source: WallpaperSourceData): InputSource {
    return when (source.kind ?: throw invalidSource("A wallpaper source kind is required.")) {
      WallpaperSourceKindData.URL -> networkInputSource(requiredValue(source.url, "URL"))
      WallpaperSourceKindData.FILE_PATH -> fileInputSource(requiredValue(source.filePath, "file path"))
      WallpaperSourceKindData.CONTENT_URI -> contentUriInputSource(
        requiredValue(source.contentUri, "content URI"),
      )
      WallpaperSourceKindData.BYTES -> byteInputSource(
        source.bytes ?: throw invalidSource("Wallpaper bytes are required."),
      )
    }
  }

  private fun networkInputSource(value: String): InputSource {
    val url = parseHttpsUri(value)
    return InputSource { openNetworkStream(url) }
  }

  private fun fileInputSource(value: String): InputSource {
    val file = File(value)
    if (!file.isFile || !file.canRead()) {
      throw WallpaperSourceException(
        code = ERROR_SOURCE_UNAVAILABLE,
        message = "The wallpaper file is not readable.",
      )
    }
    if (file.length() > limits.maxEncodedBytes) {
      throw encodedImageTooLarge()
    }
    return InputSource {
      SizeLimitedInputStream(FileInputStream(file), limits.maxEncodedBytes)
    }
  }

  private fun contentUriInputSource(value: String): InputSource {
    val uri = value.toUri()
    if (!uri.scheme.equals(CONTENT_SCHEME, ignoreCase = true) || uri.authority.isNullOrBlank()) {
      throw invalidSource("Wallpaper content sources must use a content URI.")
    }

    val contentType = try {
      appContext.contentResolver.getType(uri)
    } catch (error: SecurityException) {
      throw sourceUnavailable(error)
    }
    if (contentType != null && !isImageContentType(contentType)) {
      throw WallpaperSourceException(
        code = ERROR_INVALID_CONTENT_TYPE,
        message = "The content URI does not identify an image.",
      )
    }

    return InputSource {
      val stream = try {
        appContext.contentResolver.openInputStream(uri)
      } catch (error: SecurityException) {
        throw sourceUnavailable(error)
      } ?: throw WallpaperSourceException(
        code = ERROR_SOURCE_UNAVAILABLE,
        message = "The content URI could not be opened.",
      )
      SizeLimitedInputStream(stream, limits.maxEncodedBytes)
    }
  }

  private fun byteInputSource(value: ByteArray): InputSource {
    if (value.isEmpty()) {
      throw invalidSource("Wallpaper bytes must not be empty.")
    }
    if (value.size.toLong() > limits.maxEncodedBytes) {
      throw encodedImageTooLarge()
    }
    return InputSource {
      SizeLimitedInputStream(ByteArrayInputStream(value), limits.maxEncodedBytes)
    }
  }

  private fun decodeBounds(inputSource: InputSource): ImageBounds {
    val options = BitmapFactory.Options().apply {
      inJustDecodeBounds = true
    }
    openForDecode(inputSource) { input ->
      BitmapFactory.decodeStream(input, null, options)
    }

    if (options.outWidth <= 0 || options.outHeight <= 0) {
      throw WallpaperSourceException(
        code = ERROR_INVALID_IMAGE,
        message = "The source does not contain a decodable image.",
      )
    }
    if (options.outMimeType != null && !isImageContentType(options.outMimeType)) {
      throw WallpaperSourceException(
        code = ERROR_INVALID_CONTENT_TYPE,
        message = "The source does not contain an image MIME type.",
      )
    }
    return ImageBounds(options.outWidth, options.outHeight)
  }

  private fun decodeBitmap(inputSource: InputSource, sampleSize: Int): Bitmap {
    val options = BitmapFactory.Options().apply {
      inSampleSize = sampleSize
      inScaled = false
      inPreferredConfig = Bitmap.Config.ARGB_8888
    }
    val decoded = openForDecode(inputSource) { input ->
      BitmapFactory.decodeStream(input, null, options)
    } ?: throw WallpaperSourceException(
      code = ERROR_INVALID_IMAGE,
      message = "The source could not be decoded as an image.",
    )

    if (decoded.width <= 0 || decoded.height <= 0) {
      decoded.recycle()
      throw WallpaperSourceException(
        code = ERROR_INVALID_IMAGE,
        message = "The decoded image has invalid dimensions.",
      )
    }
    if (pixelCount(decoded.width, decoded.height) > limits.maxDecodedPixels) {
      decoded.recycle()
      throw WallpaperSourceException(
        code = ERROR_IMAGE_TOO_LARGE,
        message = "The decoded image exceeds the configured pixel limit.",
      )
    }
    return decoded
  }

  private fun readExifOrientation(inputSource: InputSource): Int {
    // EXIF is optional metadata. A failure to inspect it should not turn a valid image into a
    // failed wallpaper operation, because the following decode pass remains authoritative.
    return try {
      inputSource.open().buffered().use { input ->
        ExifInterface(input).getAttributeInt(
          ExifInterface.TAG_ORIENTATION,
          ExifInterface.ORIENTATION_NORMAL,
        )
      }
    } catch (_: IOException) {
      ExifInterface.ORIENTATION_NORMAL
    } catch (_: SecurityException) {
      ExifInterface.ORIENTATION_NORMAL
    }
  }

  private fun applyExifOrientation(bitmap: Bitmap, orientation: Int): Bitmap {
    val matrix = Matrix()
    val needsTransform = when (orientation) {
      ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> {
        matrix.setScale(-1f, 1f)
        true
      }
      ExifInterface.ORIENTATION_ROTATE_180 -> {
        matrix.setRotate(180f)
        true
      }
      ExifInterface.ORIENTATION_FLIP_VERTICAL -> {
        matrix.setScale(1f, -1f)
        true
      }
      ExifInterface.ORIENTATION_TRANSPOSE -> {
        matrix.setRotate(90f)
        matrix.postScale(-1f, 1f)
        true
      }
      ExifInterface.ORIENTATION_ROTATE_90 -> {
        matrix.setRotate(90f)
        true
      }
      ExifInterface.ORIENTATION_TRANSVERSE -> {
        matrix.setRotate(-90f)
        matrix.postScale(-1f, 1f)
        true
      }
      ExifInterface.ORIENTATION_ROTATE_270 -> {
        matrix.setRotate(-90f)
        true
      }
      else -> false
    }
    if (!needsTransform) {
      return bitmap
    }

    val normalized = Bitmap.createBitmap(
      bitmap,
      0,
      0,
      bitmap.width,
      bitmap.height,
      matrix,
      true,
    )
    if (normalized !== bitmap) {
      bitmap.recycle()
    }
    return normalized
  }

  private fun openNetworkStream(initialUri: URI): InputStream {
    var currentUri = initialUri
    var redirectCount = 0
    while (true) {
      val connection = createHttpsConnection(currentUri)
      try {
        val status = connection.responseCode
        if (status in HTTP_REDIRECT_START..HTTP_REDIRECT_END) {
          if (redirectCount >= limits.maxRedirects) {
            connection.disconnect()
            throw WallpaperSourceException(
              code = ERROR_HTTP_STATUS,
              message = "The image URL redirected too many times.",
            )
          }
          val location = connection.getHeaderField(HTTP_LOCATION_HEADER)
            ?: run {
              connection.disconnect()
              throw WallpaperSourceException(
                code = ERROR_HTTP_STATUS,
                message = "The image URL redirected without a location.",
              )
          }
          connection.disconnect()
          val redirectUri = try {
            currentUri.resolve(location)
          } catch (error: IllegalArgumentException) {
            throw WallpaperSourceException(
              code = ERROR_INVALID_URL,
              message = "The image server returned an invalid redirect URL.",
              cause = error,
            )
          }
          currentUri = parseHttpsUri(redirectUri.toString())
          redirectCount += 1
          continue
        }

        if (status !in HTTP_SUCCESS_START..HTTP_SUCCESS_END) {
          connection.disconnect()
          throw WallpaperSourceException(
            code = ERROR_HTTP_STATUS,
            message = "The image server returned HTTP $status.",
          )
        }
        if (!isImageContentType(connection.contentType)) {
          connection.disconnect()
          throw WallpaperSourceException(
            code = ERROR_INVALID_CONTENT_TYPE,
            message = "The image server did not return an image content type.",
          )
        }
        if (connection.contentLengthLong > limits.maxEncodedBytes) {
          connection.disconnect()
          throw encodedImageTooLarge()
        }

        val input = connection.inputStream
        return SizeLimitedInputStream(
          DisconnectingInputStream(input, connection),
          limits.maxEncodedBytes,
        )
      } catch (error: WallpaperSourceException) {
        throw error
      } catch (error: IOException) {
        connection.disconnect()
        throw sourceUnavailable(error)
      } catch (error: SecurityException) {
        connection.disconnect()
        throw sourceUnavailable(error)
      }
    }
  }

  private fun createHttpsConnection(uri: URI): HttpsURLConnection {
    val connection = try {
      uri.toURL().openConnection()
    } catch (error: IOException) {
      throw sourceUnavailable(error)
    }
    if (connection !is HttpsURLConnection) {
      throw WallpaperSourceException(
        code = ERROR_INVALID_URL,
        message = "Wallpaper network sources must use HTTPS.",
      )
    }
    return connection.apply {
      requestMethod = HTTP_GET
      connectTimeout = limits.connectTimeoutMillis
      readTimeout = limits.readTimeoutMillis
      instanceFollowRedirects = false
      useCaches = false
      doInput = true
      setRequestProperty(HTTP_ACCEPT_HEADER, IMAGE_ACCEPT_HEADER)
    }
  }

  private fun <T> openForDecode(inputSource: InputSource, decode: (InputStream) -> T): T {
    return try {
      inputSource.open().use(decode)
    } catch (error: WallpaperSourceException) {
      throw error
    } catch (error: IOException) {
      throw sourceUnavailable(error)
    } catch (error: SecurityException) {
      throw sourceUnavailable(error)
    }
  }

  private fun parseHttpsUri(value: String): URI {
    val uri = try {
      URI(value)
    } catch (error: Exception) {
      throw WallpaperSourceException(
        code = ERROR_INVALID_URL,
        message = "The wallpaper URL is invalid.",
        cause = error,
      )
    }
    if (
      !uri.isAbsolute ||
      !uri.scheme.equals(HTTPS_SCHEME, ignoreCase = true) ||
      uri.host.isNullOrBlank() ||
      uri.userInfo != null
    ) {
      throw WallpaperSourceException(
        code = ERROR_INVALID_URL,
        message = "Wallpaper network sources must be absolute HTTPS URLs.",
      )
    }
    return uri
  }

  private fun requiredValue(value: String?, name: String): String {
    return value?.takeIf { it.isNotBlank() }
      ?: throw invalidSource("A wallpaper $name is required.")
  }

  private fun invalidSource(message: String): WallpaperSourceException {
    return WallpaperSourceException(ERROR_INVALID_SOURCE, message)
  }

  private fun encodedImageTooLarge(): WallpaperSourceException {
    return WallpaperSourceException(
      code = ERROR_IMAGE_TOO_LARGE,
      message = "The encoded image exceeds the configured size limit.",
    )
  }

  private fun sourceUnavailable(cause: Throwable): WallpaperSourceException {
    return WallpaperSourceException(
      code = ERROR_SOURCE_UNAVAILABLE,
      message = "The wallpaper source could not be read.",
      cause = cause,
    )
  }

  private data class InputSource(val open: () -> InputStream)

  private data class ImageBounds(
    val width: Int,
    val height: Int,
  )

  /** Enforces an encoded-byte limit even when a source has no reliable content length. */
  private class SizeLimitedInputStream(
    input: InputStream,
    private val maxBytes: Long,
  ) : FilterInputStream(input) {
    private var bytesRead = 0L

    override fun read(): Int {
      val value = super.read()
      if (value != -1) {
        track(1)
      }
      return value
    }

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
      val read = super.read(buffer, offset, length)
      if (read > 0) {
        track(read.toLong())
      }
      return read
    }

    override fun skip(byteCount: Long): Long {
      val skipped = super.skip(byteCount)
      if (skipped > 0) {
        track(skipped)
      }
      return skipped
    }

    private fun track(count: Long) {
      bytesRead += count
      if (bytesRead > maxBytes) {
        throw WallpaperSourceException(
          code = ERROR_IMAGE_TOO_LARGE,
          message = "The encoded image exceeds the configured size limit.",
        )
      }
    }
  }

  companion object {
    const val ERROR_INVALID_SOURCE = "invalid-source"
    const val ERROR_INVALID_URL = "invalid-url"
    const val ERROR_INVALID_CONTENT_TYPE = "invalid-content-type"
    const val ERROR_HTTP_STATUS = "http-status"
    const val ERROR_IMAGE_TOO_LARGE = "image-too-large"
    const val ERROR_INVALID_IMAGE = "invalid-image"
    const val ERROR_SOURCE_UNAVAILABLE = "source-unavailable"

    const val DEFAULT_CONNECT_TIMEOUT_MILLIS = 15_000
    const val DEFAULT_READ_TIMEOUT_MILLIS = 20_000
    const val DEFAULT_MAX_ENCODED_BYTES = 32L * 1024L * 1024L
    const val DEFAULT_MAX_DECODED_PIXELS = 16L * 1024L * 1024L
    const val DEFAULT_MAX_REDIRECTS = 3

    /** Returns a power-of-two sample size that keeps the expected decoded pixel count bounded. */
    fun calculateInSampleSize(width: Int, height: Int, maxPixels: Long): Int {
      require(width > 0 && height > 0) { "Image dimensions must be positive." }
      require(maxPixels > 0) { "maxPixels must be positive." }

      var sampleSize = 1
      while (sampledPixelCount(width, height, sampleSize) > maxPixels) {
        if (sampleSize > Int.MAX_VALUE / 2) {
          return Int.MAX_VALUE
        }
        sampleSize *= 2
      }
      return sampleSize
    }

    private fun sampledPixelCount(width: Int, height: Int, sampleSize: Int): Long {
      val sampledWidth = (width.toLong() + sampleSize - 1L) / sampleSize
      val sampledHeight = (height.toLong() + sampleSize - 1L) / sampleSize
      return sampledWidth * sampledHeight
    }

    private fun pixelCount(width: Int, height: Int): Long {
      return width.toLong() * height.toLong()
    }

    private fun isImageContentType(value: String?): Boolean {
      val mimeType = value
        ?.substringBefore(';')
        ?.trim()
        ?.lowercase(Locale.ROOT)
      return mimeType?.startsWith("image/") == true
    }

    private const val HTTPS_SCHEME = "https"
    private const val CONTENT_SCHEME = "content"
    private const val HTTP_GET = "GET"
    private const val HTTP_ACCEPT_HEADER = "Accept"
    private const val IMAGE_ACCEPT_HEADER = "image/*"
    private const val HTTP_LOCATION_HEADER = "Location"
    private const val HTTP_SUCCESS_START = 200
    private const val HTTP_SUCCESS_END = 299
    private const val HTTP_REDIRECT_START = 300
    private const val HTTP_REDIRECT_END = 399
  }
}
