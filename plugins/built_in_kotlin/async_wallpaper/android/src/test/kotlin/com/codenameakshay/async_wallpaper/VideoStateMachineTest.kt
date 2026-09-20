package com.codenameakshay.async_wallpaper

import android.media.MediaMetadataRetriever
import java.io.File
import java.nio.file.Files
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

class VideoStateMachineTest {
  @Test
  fun `prepared visible player starts once then follows visibility`() {
    val stateMachine = VideoPlaybackStateMachine()

    assertEquals(VideoPlaybackAction.PREPARE, stateMachine.onSurfaceCreated())
    assertEquals(VideoPlaybackAction.NONE, stateMachine.onVisibilityChanged(true))
    assertEquals(VideoPlaybackAction.START, stateMachine.onPrepared())
    assertEquals(VideoPlaybackState.PLAYING, stateMachine.state)

    assertEquals(VideoPlaybackAction.NONE, stateMachine.onPrepared())
    assertEquals(VideoPlaybackAction.NONE, stateMachine.onVisibilityChanged(true))
    assertEquals(VideoPlaybackAction.PAUSE, stateMachine.onVisibilityChanged(false))
    assertEquals(VideoPlaybackState.PAUSED, stateMachine.state)
    assertEquals(VideoPlaybackAction.START, stateMachine.onVisibilityChanged(true))
  }

  @Test
  fun `reapply replaces the player only while a surface can show it`() {
    val stateMachine = VideoPlaybackStateMachine()
    assertEquals(VideoPlaybackAction.NONE, stateMachine.onAssetReapplied())

    stateMachine.onSurfaceCreated()
    stateMachine.onVisibilityChanged(true)
    stateMachine.onPrepared()
    assertEquals(VideoPlaybackState.PLAYING, stateMachine.state)
    assertEquals(VideoPlaybackAction.PREPARE, stateMachine.onAssetReapplied())
    assertEquals(VideoPlaybackState.PREPARING, stateMachine.state)
    assertEquals(VideoPlaybackAction.START, stateMachine.onPrepared())

    stateMachine.onPlayerError()
    assertEquals(VideoPlaybackAction.PREPARE, stateMachine.onAssetReapplied())

    stateMachine.onSurfaceDestroyed()
    assertEquals(VideoPlaybackAction.NONE, stateMachine.onAssetReapplied())
    stateMachine.onEngineDestroyed()
    assertEquals(VideoPlaybackAction.NONE, stateMachine.onAssetReapplied())
  }

  @Test
  fun `reapply command matches the platform constant`() {
    assertEquals("android.wallpaper.reapply", WALLPAPER_COMMAND_REAPPLY)
  }

  @Test
  fun `hidden preparation waits until wallpaper is visible`() {
    val stateMachine = VideoPlaybackStateMachine()

    assertEquals(VideoPlaybackAction.PREPARE, stateMachine.onSurfaceCreated())
    assertEquals(VideoPlaybackAction.NONE, stateMachine.onPrepared())
    assertEquals(VideoPlaybackState.PAUSED, stateMachine.state)
    assertEquals(VideoPlaybackAction.START, stateMachine.onVisibilityChanged(true))
  }

  @Test
  fun `surface recreation releases stale player and permits one new preparation`() {
    val stateMachine = VideoPlaybackStateMachine()

    assertEquals(VideoPlaybackAction.PREPARE, stateMachine.onSurfaceCreated())
    assertEquals(VideoPlaybackAction.RELEASE, stateMachine.onSurfaceDestroyed())
    assertEquals(VideoPlaybackState.IDLE, stateMachine.state)
    assertEquals(VideoPlaybackAction.NONE, stateMachine.onSurfaceDestroyed())
    assertEquals(VideoPlaybackAction.RELEASE, stateMachine.onPrepared())

    assertEquals(VideoPlaybackAction.PREPARE, stateMachine.onSurfaceCreated())
    assertEquals(VideoPlaybackAction.NONE, stateMachine.onSurfaceCreated())
  }

  @Test
  fun `error and destroy callbacks are idempotent`() {
    val stateMachine = VideoPlaybackStateMachine()

    assertEquals(VideoPlaybackAction.PREPARE, stateMachine.onSurfaceCreated())
    assertEquals(VideoPlaybackAction.RELEASE, stateMachine.onPlayerError())
    assertEquals(VideoPlaybackAction.NONE, stateMachine.onPlayerError())
    assertEquals(VideoPlaybackAction.NONE, stateMachine.onEngineDestroyed())
    assertEquals(VideoPlaybackState.RELEASED, stateMachine.state)
    assertEquals(VideoPlaybackAction.NONE, stateMachine.onSurfaceCreated())
    assertEquals(VideoPlaybackAction.NONE, stateMachine.onPrepared())
    assertEquals(VideoPlaybackAction.NONE, stateMachine.onEngineDestroyed())
  }

  @Test
  fun `destroying a prepared player releases it exactly once`() {
    val stateMachine = VideoPlaybackStateMachine()

    assertEquals(VideoPlaybackAction.PREPARE, stateMachine.onSurfaceCreated())
    assertEquals(VideoPlaybackAction.NONE, stateMachine.onPrepared())
    assertEquals(VideoPlaybackAction.RELEASE, stateMachine.onEngineDestroyed())
    assertFalse(stateMachine.hasSurface)
    assertEquals(VideoPlaybackAction.NONE, stateMachine.onEngineDestroyed())
  }

  @Test
  fun `metadata policy accepts rotated playable video and exposes display dimensions`() {
    val metadata = VideoMetadataPolicy.validate(
      hasVideoTrack = "yes",
      mimeType = " Video/MP4 ",
      width = "1920",
      height = "1080",
      rotationDegrees = "90",
      durationMillis = "1200",
    )

    assertEquals("video/mp4", metadata.mimeType)
    assertEquals(1920, metadata.width)
    assertEquals(1080, metadata.height)
    assertEquals(1080, metadata.displayWidth)
    assertEquals(1920, metadata.displayHeight)
    assertEquals(1200L, metadata.durationMillis)
  }

  @Test
  fun `metadata policy rejects missing track MIME dimensions rotation and duration`() {
    assertValidationFailure(VideoValidationFailure.NO_VIDEO_TRACK) {
      VideoMetadataPolicy.validate("no", "video/mp4", "1", "1", "0", "1")
    }
    assertValidationFailure(VideoValidationFailure.INVALID_MIME_TYPE) {
      VideoMetadataPolicy.validate("yes", "image/jpeg", "1", "1", "0", "1")
    }
    assertValidationFailure(VideoValidationFailure.INVALID_DIMENSIONS) {
      VideoMetadataPolicy.validate("yes", "video/mp4", "0", "1", "0", "1")
    }
    assertValidationFailure(VideoValidationFailure.INVALID_ROTATION) {
      VideoMetadataPolicy.validate("yes", "video/mp4", "1", "1", "45", "1")
    }
    assertValidationFailure(VideoValidationFailure.INVALID_DURATION) {
      VideoMetadataPolicy.validate("yes", "video/mp4", "1", "1", "0", "0")
    }
  }

  @Test
  fun `metadata validator reads every required metadata key and always releases retriever`() {
    val file = Files.createTempFile("video-validator", ".mp4").toFile()
    file.writeText("not decoded because the retriever is fake")
    val retriever = FakeMetadataRetriever(
      mapOf(
        MediaMetadataRetriever.METADATA_KEY_HAS_VIDEO to "1",
        MediaMetadataRetriever.METADATA_KEY_MIMETYPE to "video/webm",
        MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH to "640",
        MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT to "480",
        MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION to "0",
        MediaMetadataRetriever.METADATA_KEY_DURATION to "99",
      ),
    )

    try {
      val metadata = VideoMetadataValidator { retriever }.validate(file)

      assertEquals("video/webm", metadata.mimeType)
      assertEquals(file.absolutePath, retriever.sourcePath)
      assertTrue(retriever.released)
      assertEquals(6, retriever.requestedKeys.size)
    } finally {
      file.delete()
    }
  }

  @Test
  fun `metadata validator releases retriever when validation rejects metadata`() {
    val file = Files.createTempFile("video-validator-invalid", ".mp4").toFile()
    file.writeText("not decoded because the retriever is fake")
    val retriever = FakeMetadataRetriever(
      mapOf(
        MediaMetadataRetriever.METADATA_KEY_HAS_VIDEO to "no",
      ),
    )

    try {
      assertValidationFailure(VideoValidationFailure.NO_VIDEO_TRACK) {
        VideoMetadataValidator { retriever }.validate(file)
      }
      assertTrue(retriever.released)
    } finally {
      file.delete()
    }
  }

  private fun assertValidationFailure(
    expectedFailure: VideoValidationFailure,
    operation: () -> Unit,
  ) {
    try {
      operation()
      fail("Expected $expectedFailure")
    } catch (error: VideoMetadataValidationException) {
      assertEquals(expectedFailure, error.failure)
    }
  }

  private class FakeMetadataRetriever(
    private val values: Map<Int, String?>,
  ) : VideoMetadataRetriever {
    var sourcePath: String? = null
    val requestedKeys = mutableListOf<Int>()
    var released = false

    override fun setDataSource(path: String) {
      sourcePath = path
    }

    override fun extractMetadata(keyCode: Int): String? {
      requestedKeys += keyCode
      return values[keyCode]
    }

    override fun release() {
      released = true
    }
  }
}
