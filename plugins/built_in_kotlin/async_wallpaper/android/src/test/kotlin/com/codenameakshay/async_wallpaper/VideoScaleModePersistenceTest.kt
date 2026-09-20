package com.codenameakshay.async_wallpaper

import org.junit.Assert.assertEquals
import org.junit.Test

class VideoScaleModePersistenceTest {
  @Test
  fun `only supported persisted modes are restored`() {
    assertEquals(
      VideoWallpaperScaleMode.FIT_CENTER,
      VideoScaleModePersistence.decode(VideoWallpaperScaleMode.FIT_CENTER.name),
    )
    assertEquals(
      VideoWallpaperScaleMode.CENTER_CROP,
      VideoScaleModePersistence.decode("unknown"),
    )
    assertEquals(
      VideoWallpaperScaleMode.CENTER_CROP,
      VideoScaleModePersistence.decode(null),
    )
  }
}
