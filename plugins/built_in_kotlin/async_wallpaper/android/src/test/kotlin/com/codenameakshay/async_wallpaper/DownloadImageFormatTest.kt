package com.codenameakshay.async_wallpaper

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class DownloadImageFormatTest {
  @Test
  fun `decoded format wins and normalizes the published name`() {
    assertEquals(
      DownloadImageFormat.Selection("image/png", "png"),
      DownloadImageFormat.choose("image/png", "image/jpeg; charset=binary"),
    )
  }

  @Test
  fun `known HTTP image type fills in a missing decoded MIME type`() {
    assertEquals(
      DownloadImageFormat.Selection("image/webp", "webp"),
      DownloadImageFormat.choose(null, " image/webp "),
    )
  }

  @Test
  fun `unknown or non-image types are rejected`() {
    assertNull(DownloadImageFormat.choose("image/tiff", "image/tiff"))
    assertNull(DownloadImageFormat.choose("image/png", "text/html"))
  }
}
