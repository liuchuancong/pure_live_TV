package com.codenameakshay.async_wallpaper

import java.io.FilterInputStream
import java.io.InputStream
import java.net.HttpURLConnection

/**
 * Closes both the response stream and its HTTP connection.
 *
 * Shared by [BoundedSourceOpener] and [WallpaperSourceLoader], whose HTTPS-fetch paths otherwise
 * diverge in header handling, content-type validation, and error codes.
 */
internal class DisconnectingInputStream(
  input: InputStream,
  private val connection: HttpURLConnection,
) : FilterInputStream(input) {
  override fun close() {
    try {
      super.close()
    } finally {
      connection.disconnect()
    }
  }
}
