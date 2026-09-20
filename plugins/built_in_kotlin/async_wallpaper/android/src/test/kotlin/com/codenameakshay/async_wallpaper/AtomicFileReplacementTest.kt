package com.codenameakshay.async_wallpaper

import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import java.nio.file.Files
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test

class AtomicFileReplacementTest {
  private lateinit var directory: File

  @Before
  fun setUp() {
    directory = Files.createTempDirectory("video-wallpaper-repository").toFile()
  }

  @After
  fun tearDown() {
    directory.deleteRecursively()
  }

  @Test
  fun `validated candidate atomically replaces active file and leaves no temp files`() {
    val source = writeFile("candidate.mp4", "new-video")
    val active = writeFile(VideoWallpaperRepository.ACTIVE_VIDEO_FILE_NAME, "previous-video")
    val repository = VideoWallpaperRepository(directory, acceptingValidator(), HostFileSystem)

    val prepared = repository.prepare(source)

    assertEquals(active.absolutePath, prepared.file.absolutePath)
    assertEquals("new-video", active.readText())
    assertEquals("video/mp4", prepared.metadata.mimeType)
    assertNoTemporaryFiles()
  }

  @Test
  fun `validation failure preserves prior active file and cleans candidate`() {
    val source = writeFile("corrupt.mp4", "corrupt-video")
    val active = writeFile(VideoWallpaperRepository.ACTIVE_VIDEO_FILE_NAME, "previous-video")
    val repository = VideoWallpaperRepository(
      directory,
      VideoFileValidator {
        throw VideoMetadataValidationException(
          VideoValidationFailure.INVALID_MIME_TYPE,
          "corrupt test input",
        )
      },
      HostFileSystem,
    )

    assertThrowsVideoValidation { repository.prepare(source) }

    assertEquals("previous-video", active.readText())
    assertNoTemporaryFiles()
  }

  @Test
  fun `failed atomic move preserves prior active file and cleans candidate`() {
    val source = writeFile("candidate.mp4", "new-video")
    val active = writeFile(VideoWallpaperRepository.ACTIVE_VIDEO_FILE_NAME, "previous-video")
    val repository = VideoWallpaperRepository(
      directory,
      acceptingValidator(),
      FailingMoveFileSystem,
    )

    try {
      repository.prepare(source)
      fail("Expected replacement to fail")
    } catch (_: IOException) {
    }

    assertEquals("previous-video", active.readText())
    assertNoTemporaryFiles()
  }

  @Test
  fun `source equal to active file validates without copying or replacing itself`() {
    val active = writeFile(VideoWallpaperRepository.ACTIVE_VIDEO_FILE_NAME, "existing-video")
    val fileSystem = RecordingFileSystem()
    val repository = VideoWallpaperRepository(directory, acceptingValidator(), fileSystem)

    val prepared = repository.prepare(active)

    assertEquals(active.absolutePath, prepared.file.absolutePath)
    assertEquals("existing-video", active.readText())
    assertEquals(0, fileSystem.createTempFileCalls)
    assertEquals(0, fileSystem.copyCalls)
    assertEquals(0, fileSystem.replaceCalls)
  }

  @Test
  fun `preparation removes abandoned candidate files before creating a new one`() {
    val source = writeFile("candidate.mp4", "new-video")
    val stale = writeFile("${VideoWallpaperRepository.ACTIVE_VIDEO_FILE_NAME}.interrupted.tmp", "partial")
    val repository = VideoWallpaperRepository(directory, acceptingValidator(), HostFileSystem)

    repository.prepare(source)

    assertFalse(stale.exists())
    assertNoTemporaryFiles()
  }

  @Test
  fun `concurrent preparation serializes complete replacement transactions`() {
    val first = writeFile("first.mp4", "first-video")
    val second = writeFile("second.mp4", "second-video")
    val fileSystem = BlockingFileSystem()
    val repository = VideoWallpaperRepository(directory, acceptingValidator(), fileSystem)
    val executor = Executors.newFixedThreadPool(2)

    try {
      val firstResult = executor.submit<PreparedVideo> { repository.prepare(first) }
      assertTrue(fileSystem.firstCopyStarted.await(5, TimeUnit.SECONDS))

      val secondStarted = CountDownLatch(1)
      val secondResult = executor.submit<PreparedVideo> {
        secondStarted.countDown()
        repository.prepare(second)
      }
      assertTrue(secondStarted.await(5, TimeUnit.SECONDS))
      assertFalse(secondResult.isDone)
      assertEquals(1, fileSystem.maxConcurrentCopies.get())

      fileSystem.allowFirstCopy.countDown()
      firstResult.get(5, TimeUnit.SECONDS)
      secondResult.get(5, TimeUnit.SECONDS)

      assertEquals(1, fileSystem.maxConcurrentCopies.get())
      assertTrue(
        File(directory, VideoWallpaperRepository.ACTIVE_VIDEO_FILE_NAME).readText() in
          setOf("first-video", "second-video"),
      )
      assertNoTemporaryFiles()
    } finally {
      fileSystem.allowFirstCopy.countDown()
      executor.shutdownNow()
    }
  }

  private fun acceptingValidator(): VideoFileValidator = VideoFileValidator {
    VideoMetadata(
      mimeType = "video/mp4",
      width = 1920,
      height = 1080,
      rotationDegrees = 0,
      durationMillis = 1000L,
    )
  }

  private fun writeFile(name: String, contents: String): File {
    return File(directory, name).apply { writeText(contents) }
  }

  private fun assertNoTemporaryFiles() {
    val leftovers = directory.listFiles()
      ?.filter { it.name.startsWith("${VideoWallpaperRepository.ACTIVE_VIDEO_FILE_NAME}.") }
      .orEmpty()
    assertTrue("Unexpected temporary files: $leftovers", leftovers.isEmpty())
  }

  private fun assertThrowsVideoValidation(operation: () -> Unit) {
    try {
      operation()
      fail("Expected video validation failure")
    } catch (_: VideoMetadataValidationException) {
    }
  }

  private class RecordingFileSystem : VideoFileSystem {
    var createTempFileCalls = 0
    var copyCalls = 0
    var replaceCalls = 0

    override fun createTempFile(directory: File, prefix: String, suffix: String): File {
      createTempFileCalls += 1
      return HostFileSystem.createTempFile(directory, prefix, suffix)
    }

    override fun copyAndSync(source: InputStream, destination: File) {
      copyCalls += 1
      HostFileSystem.copyAndSync(source, destination)
    }

    override fun replaceAtomically(source: File, destination: File) {
      replaceCalls += 1
      HostFileSystem.replaceAtomically(source, destination)
    }

    override fun delete(file: File): Boolean = HostFileSystem.delete(file)
  }

  private object FailingMoveFileSystem : VideoFileSystem {
    override fun createTempFile(directory: File, prefix: String, suffix: String): File {
      return HostFileSystem.createTempFile(directory, prefix, suffix)
    }

    override fun copyAndSync(source: InputStream, destination: File) {
      HostFileSystem.copyAndSync(source, destination)
    }

    override fun replaceAtomically(source: File, destination: File) {
      throw IOException("simulated atomic move failure")
    }

    override fun delete(file: File): Boolean = HostFileSystem.delete(file)
  }

  private class BlockingFileSystem : VideoFileSystem {
    val firstCopyStarted = CountDownLatch(1)
    val allowFirstCopy = CountDownLatch(1)
    val maxConcurrentCopies = AtomicInteger()

    private val activeCopies = AtomicInteger()
    private val copyCalls = AtomicInteger()

    override fun createTempFile(directory: File, prefix: String, suffix: String): File {
      return HostFileSystem.createTempFile(directory, prefix, suffix)
    }

    override fun copyAndSync(source: InputStream, destination: File) {
      val active = activeCopies.incrementAndGet()
      maxConcurrentCopies.updateAndGet { previous -> maxOf(previous, active) }
      try {
        if (copyCalls.incrementAndGet() == 1) {
          firstCopyStarted.countDown()
          check(allowFirstCopy.await(5, TimeUnit.SECONDS))
        }
        HostFileSystem.copyAndSync(source, destination)
      } finally {
        activeCopies.decrementAndGet()
      }
    }

    override fun replaceAtomically(source: File, destination: File) {
      HostFileSystem.replaceAtomically(source, destination)
    }

    override fun delete(file: File): Boolean = HostFileSystem.delete(file)
  }

  /** JVM implementation used to verify the same-directory replacement contract. */
  private object HostFileSystem : VideoFileSystem {
    override fun createTempFile(directory: File, prefix: String, suffix: String): File {
      return File.createTempFile(prefix, suffix, directory)
    }

    override fun copyAndSync(source: InputStream, destination: File) {
      FileOutputStream(destination).use { output ->
        source.copyTo(output)
        output.flush()
        output.channel.force(true)
      }
    }

    override fun replaceAtomically(source: File, destination: File) {
      if (!source.renameTo(destination)) {
        throw IOException("Unable to atomically replace ${destination.absolutePath}.")
      }
    }

    override fun delete(file: File): Boolean = !file.exists() || file.delete()
  }
}
