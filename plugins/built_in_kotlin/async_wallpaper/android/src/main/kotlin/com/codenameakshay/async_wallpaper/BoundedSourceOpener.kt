package com.codenameakshay.async_wallpaper

import android.content.Context
import androidx.core.net.toUri
import java.io.ByteArrayInputStream
import java.io.Closeable
import java.io.File
import java.io.FileInputStream
import java.io.FilterInputStream
import java.io.IOException
import java.io.InputStream
import java.net.URI
import javax.net.ssl.HttpsURLConnection

/** Stable failures for non-image sources used by video and OpenGL preparation. */
class BoundedSourceException(
  val code: String,
  message: String,
  cause: Throwable? = null,
) : IOException(message, cause)

/**
 * Opens a Pigeon source with a fixed byte limit without routing video or textures through the
 * bitmap image decoder. URL sources are HTTPS-only, redirect only to HTTPS, and are disconnected
 * when their returned stream is closed.
 */
class BoundedSourceOpener(
  context: Context,
  private val maxBytes: Long,
  private val connectTimeoutMillis: Int = DEFAULT_CONNECT_TIMEOUT_MILLIS,
  private val readTimeoutMillis: Int = DEFAULT_READ_TIMEOUT_MILLIS,
  private val maxRedirects: Int = DEFAULT_MAX_REDIRECTS,
) {
  private val appContext = context.applicationContext

  init {
    require(maxBytes > 0L) { "maxBytes must be positive." }
  }

  /** The caller owns and must close the returned stream. */
  fun open(source: WallpaperSourceData): InputStream {
    return openWithMetadata(source).input
  }

  /** Opens a source and exposes the response MIME type when the source provides one. */
  internal fun openWithMetadata(source: WallpaperSourceData): OpenedSource {
    return when (source.kind ?: throw invalidSource("A source kind is required.")) {
      WallpaperSourceKindData.URL -> openHttps(requiredText(source.url, "URL"))
      WallpaperSourceKindData.FILE_PATH -> OpenedSource(openFile(requiredText(source.filePath, "file path")))
      WallpaperSourceKindData.CONTENT_URI -> OpenedSource(openContentUri(requiredText(source.contentUri, "content URI")))
      WallpaperSourceKindData.BYTES -> OpenedSource(openBytes(source.bytes ?: throw invalidSource("Source bytes are required.")))
    }
  }

  /** Reads a bounded source into private memory for OpenGL's URL-only materialization step. */
  fun readBytes(source: WallpaperSourceData): ByteArray {
    open(source).use { input ->
      return input.readFullyBounded(maxBytes)
    }
  }

  private fun openFile(path: String): InputStream {
    val file = File(path)
    if (!file.isFile || !file.canRead()) {
      throw BoundedSourceException(ERROR_SOURCE_UNAVAILABLE, "The source file is not readable.")
    }
    if (file.length() > maxBytes) {
      throw tooLarge()
    }
    return SizeLimitedInputStream(FileInputStream(file), maxBytes)
  }

  private fun openContentUri(value: String): InputStream {
    val uri = value.toUri()
    if (!uri.scheme.equals(CONTENT_SCHEME, ignoreCase = true) || uri.authority.isNullOrBlank()) {
      throw invalidSource("Sources of this kind must use a content URI.")
    }
    val stream = try {
      appContext.contentResolver.openInputStream(uri)
    } catch (error: SecurityException) {
      throw BoundedSourceException(
        ERROR_SOURCE_UNAVAILABLE,
        "Permission to read the content URI was denied.",
        error,
      )
    } ?: throw BoundedSourceException(
      ERROR_SOURCE_UNAVAILABLE,
      "The content URI could not be opened.",
    )
    return SizeLimitedInputStream(stream, maxBytes)
  }

  private fun openBytes(bytes: ByteArray): InputStream {
    if (bytes.isEmpty()) {
      throw invalidSource("Source bytes must not be empty.")
    }
    if (bytes.size.toLong() > maxBytes) {
      throw tooLarge()
    }
    return SizeLimitedInputStream(ByteArrayInputStream(bytes), maxBytes)
  }

  private fun openHttps(value: String): OpenedSource {
    var currentUri = parseHttpsUri(value)
    var redirects = 0
    while (true) {
      val connection = try {
        currentUri.toURL().openConnection() as? HttpsURLConnection
      } catch (error: IOException) {
        throw BoundedSourceException(ERROR_INVALID_URL, "The source URL is invalid.", error)
      } ?: throw BoundedSourceException(ERROR_INVALID_URL, "The source URL must use HTTPS.")
      connection.instanceFollowRedirects = false
      connection.connectTimeout = connectTimeoutMillis
      connection.readTimeout = readTimeoutMillis
      connection.requestMethod = HTTP_GET
      connection.doInput = true
      try {
        val status = connection.responseCode
        if (status in HTTP_REDIRECT_START..HTTP_REDIRECT_END) {
          if (redirects >= maxRedirects) {
            throw BoundedSourceException(ERROR_HTTP_STATUS, "The source URL redirected too many times.")
          }
          val location = connection.getHeaderField(HTTP_LOCATION_HEADER)
            ?: throw BoundedSourceException(ERROR_HTTP_STATUS, "The source URL redirected without a location.")
          val redirectedUri = try {
            parseHttpsUri(currentUri.resolve(location).toString())
          } catch (error: IllegalArgumentException) {
            throw BoundedSourceException(ERROR_INVALID_URL, "The source URL redirected to an invalid URL.", error)
          }
          connection.disconnect()
          currentUri = redirectedUri
          redirects += 1
          continue
        }
        if (status !in HTTP_SUCCESS_START..HTTP_SUCCESS_END) {
          throw BoundedSourceException(ERROR_HTTP_STATUS, "The source server returned HTTP $status.")
        }
        if (connection.contentLengthLong > maxBytes) {
          throw tooLarge()
        }
        return OpenedSource(
          DisconnectingInputStream(
            SizeLimitedInputStream(connection.inputStream, maxBytes),
            connection,
          ),
          connection.contentType,
        )
      } catch (error: IOException) {
        connection.disconnect()
        throw error
      } catch (error: RuntimeException) {
        connection.disconnect()
        throw BoundedSourceException(ERROR_SOURCE_UNAVAILABLE, "Unable to open the HTTPS source.", error)
      }
    }
  }

  private fun parseHttpsUri(value: String): URI {
    val uri = try {
      URI(value.trim())
    } catch (error: Exception) {
      throw BoundedSourceException(ERROR_INVALID_URL, "The source URL is invalid.", error)
    }
    if (!uri.scheme.equals(HTTPS_SCHEME, ignoreCase = true) || uri.host.isNullOrBlank()) {
      throw BoundedSourceException(ERROR_INVALID_URL, "The source URL must be an absolute HTTPS URL.")
    }
    return uri
  }

  private fun requiredText(value: String?, name: String): String {
    return value?.trim()?.takeIf { it.isNotEmpty() }
      ?: throw invalidSource("A $name is required.")
  }

  private fun invalidSource(message: String): BoundedSourceException {
    return BoundedSourceException(ERROR_INVALID_SOURCE, message)
  }

  private fun tooLarge(): BoundedSourceException {
    return BoundedSourceException(ERROR_SOURCE_TOO_LARGE, "The source exceeds the configured byte limit.")
  }

  private class SizeLimitedInputStream(
    input: InputStream,
    private val limit: Long,
  ) : FilterInputStream(input) {
    private var bytesRead = 0L

    override fun read(): Int {
      val result = super.read()
      if (result >= 0) track(1)
      return result
    }

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
      val count = super.read(buffer, offset, length)
      if (count > 0) track(count.toLong())
      return count
    }

    private fun track(count: Long) {
      bytesRead += count
      if (bytesRead > limit) {
        throw BoundedSourceException(ERROR_SOURCE_TOO_LARGE, "The source exceeds the configured byte limit.")
      }
    }
  }

  private fun InputStream.readFullyBounded(limit: Long): ByteArray {
    val output = java.io.ByteArrayOutputStream()
    val buffer = ByteArray(BUFFER_SIZE)
    var total = 0L
    while (true) {
      val count = read(buffer)
      if (count < 0) {
        return output.toByteArray()
      }
      total += count.toLong()
      if (total > limit) {
        throw tooLarge()
      }
      output.write(buffer, 0, count)
    }
  }

  companion object {
    const val ERROR_INVALID_SOURCE = "invalid-source"
    const val ERROR_INVALID_URL = "invalid-url"
    const val ERROR_SOURCE_UNAVAILABLE = "source-unavailable"
    const val ERROR_SOURCE_TOO_LARGE = "source-too-large"
    const val ERROR_HTTP_STATUS = "http-status"

    const val DEFAULT_CONNECT_TIMEOUT_MILLIS = 15_000
    const val DEFAULT_READ_TIMEOUT_MILLIS = 20_000
    const val DEFAULT_MAX_REDIRECTS = 3

    private const val HTTPS_SCHEME = "https"
    private const val CONTENT_SCHEME = "content"
    private const val HTTP_GET = "GET"
    private const val HTTP_LOCATION_HEADER = "Location"
    private const val HTTP_SUCCESS_START = 200
    private const val HTTP_SUCCESS_END = 299
    private const val HTTP_REDIRECT_START = 300
    private const val HTTP_REDIRECT_END = 399
    private const val BUFFER_SIZE = 8 * 1024
  }

  internal class OpenedSource(
    val input: InputStream,
    val contentType: String? = null,
  ) : Closeable {
    override fun close() = input.close()
  }
}
