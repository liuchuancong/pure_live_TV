package com.codenameakshay.async_wallpaper

import java.util.Locale

internal object DownloadImageFormat {
  data class Selection(val mimeType: String, val extension: String)

  fun choose(decodedMimeType: String?, httpContentType: String?): Selection? {
    val httpMimeType = normalize(httpContentType)
    if (httpMimeType != null && !httpMimeType.startsWith("image/")) {
      return null
    }
    return selectionFor(decodedMimeType) ?: selectionFor(httpContentType)
  }

  private fun selectionFor(value: String?): Selection? {
    return when (normalize(value)) {
      "image/jpeg", "image/jpg" -> Selection("image/jpeg", "jpg")
      "image/png", "image/x-png" -> Selection("image/png", "png")
      "image/webp", "image/x-webp" -> Selection("image/webp", "webp")
      "image/gif" -> Selection("image/gif", "gif")
      "image/bmp", "image/x-ms-bmp" -> Selection("image/bmp", "bmp")
      "image/heic" -> Selection("image/heic", "heic")
      "image/heif" -> Selection("image/heif", "heif")
      "image/avif" -> Selection("image/avif", "avif")
      else -> null
    }
  }

  private fun normalize(value: String?): String? {
    return value?.substringBefore(';')?.trim()?.lowercase(Locale.ROOT)?.takeIf { it.isNotEmpty() }
  }
}
