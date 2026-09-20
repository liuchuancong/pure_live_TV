package com.codenameakshay.async_wallpaper

import android.app.ActivityManager
import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.HandlerThread
import android.os.SystemClock
import android.service.wallpaper.WallpaperService
import android.util.Log
import android.view.MotionEvent
import android.view.Surface
import android.view.SurfaceHolder
import androidx.core.net.toUri
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock
import kotlin.math.max

/**
 * Texture sources accepted by the OpenGL wallpaper core.
 *
 * URL sources are deliberately absent: network work is not allowed on the EGL render thread.
 * Callers that accept URLs must download and validate them through their normal source-loading
 * path, then pass the resulting bounded bytes or private file path here.
 */
sealed interface GlTextureSource {
  data class FilePath(val path: String) : GlTextureSource

  data class ContentUri(val uri: String) : GlTextureSource

  class Bytes(bytes: ByteArray) : GlTextureSource {
    private val value = bytes.copyOf()

    val byteCount: Int
      get() = value.size

    fun copyBytes(): ByteArray = value.copyOf()
  }
}

internal fun GlTextureSource.validationInput(): ShaderProgramValidator.TextureInput {
  return when (this) {
    is GlTextureSource.Bytes -> ShaderProgramValidator.TextureInput(sourceSizeBytes = byteCount.toLong())
    is GlTextureSource.FilePath -> ShaderProgramValidator.TextureInput(
      sourceSizeBytes = File(path).takeIf { it.isFile }?.length(),
    )
    is GlTextureSource.ContentUri -> ShaderProgramValidator.TextureInput()
  }
}

/** Signals that a [GlTextureSource] exceeded [ShaderProgramValidator.MAX_TEXTURE_SOURCE_BYTES]. */
internal class TextureSourceTooLargeException(message: String) : IOException(message)

/**
 * Reads [this] into memory, enforcing [ShaderProgramValidator.MAX_TEXTURE_SOURCE_BYTES]. Throws
 * [TextureSourceTooLargeException] when the source is too large, or a plain [IOException] for any
 * other read failure; callers map both to their own exception type and keep the message.
 */
@Throws(IOException::class, TextureSourceTooLargeException::class)
internal fun GlTextureSource.readBoundedBytes(context: Context): ByteArray {
  return when (this) {
    is GlTextureSource.Bytes -> copyBytes().also { bytes ->
      if (bytes.size.toLong() > ShaderProgramValidator.MAX_TEXTURE_SOURCE_BYTES) {
        throw TextureSourceTooLargeException("Texture source exceeds the configured byte limit.")
      }
    }
    is GlTextureSource.FilePath -> {
      val file = File(path)
      if (!file.isFile || !file.canRead()) {
        throw IOException("Texture file is unavailable.")
      }
      if (file.length() > ShaderProgramValidator.MAX_TEXTURE_SOURCE_BYTES) {
        throw TextureSourceTooLargeException("Texture file exceeds the configured byte limit.")
      }
      FileInputStream(file).use(::readBoundedTextureBytes)
    }
    is GlTextureSource.ContentUri -> {
      val parsedUri = uri.toUri()
      if (!parsedUri.scheme.equals("content", ignoreCase = true) || parsedUri.authority.isNullOrBlank()) {
        throw IOException("Texture URI must be a readable content URI.")
      }
      val input = context.contentResolver.openInputStream(parsedUri)
        ?: throw IOException("Texture content URI could not be opened.")
      input.use(::readBoundedTextureBytes)
    }
  }
}

@Throws(IOException::class, TextureSourceTooLargeException::class)
private fun readBoundedTextureBytes(input: InputStream): ByteArray {
  val output = ByteArrayOutputStream()
  val buffer = ByteArray(TEXTURE_READ_BUFFER_SIZE)
  var total = 0L
  while (true) {
    val read = input.read(buffer)
    if (read < 0) {
      break
    }
    total += read.toLong()
    if (total > ShaderProgramValidator.MAX_TEXTURE_SOURCE_BYTES) {
      throw TextureSourceTooLargeException("Texture source exceeds the configured byte limit.")
    }
    output.write(buffer, 0, read)
  }
  return output.toByteArray()
}

private const val TEXTURE_READ_BUFFER_SIZE = 8 * 1024

/**
 * Immutable runtime input for the GLES2 wallpaper renderer.
 *
 * Fragment shaders may declare these optional uniforms with their exact listed types:
 * `u_time` (`float`), `u_resolution` (`vec2`), `u_touch` (`vec2`, normalized), `u_offset`
 * (`vec2`), and `u_texture0` through `u_texture3` (`sampler2D`). The safe vertex shader supplies
 * a `varying vec2 v_uv` in conventional bottom-left-origin texture coordinates.
 */
class OpenGlWallpaperConfiguration(
  val fragmentShader: String,
  textures: List<GlTextureSource> = emptyList(),
  val frameRate: Int = DEFAULT_FRAME_RATE,
) {
  val textures: List<GlTextureSource> = textures.toList()

  companion object {
    const val DEFAULT_FRAME_RATE = 30
  }
}

/** Result of validating and persisting a configuration before the service is launched. */
sealed class OpenGlConfigurationResult {
  data object Saved : OpenGlConfigurationResult()

  data class Rejected(val error: ShaderProgramValidator.ValidationError) : OpenGlConfigurationResult()
}

/**
 * A GLES2 WallpaperService whose EGL context, shader program, textures, and frame loop live on
 * one HandlerThread. It intentionally does not contact the network or invoke Flutter callbacks.
 */
class OpenGlLiveWallpaper : WallpaperService() {
  override fun onCreateEngine(): Engine {
    return OpenGlEngine(
      OpenGlWallpaperConfigurationStore.load(applicationContext),
    )
  }

  private inner class OpenGlEngine(
    configuration: OpenGlWallpaperConfiguration,
  ) : Engine() {
    private val renderThread = WallpaperRenderThread(applicationContext, configuration)

    init {
      setTouchEventsEnabled(true)
    }

    override fun onSurfaceCreated(holder: SurfaceHolder) {
      super.onSurfaceCreated(holder)
      renderThread.surfaceCreated(holder.surface)
    }

    override fun onSurfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
      super.onSurfaceChanged(holder, format, width, height)
      renderThread.surfaceChanged(width, height)
    }

    override fun onSurfaceDestroyed(holder: SurfaceHolder) {
      renderThread.surfaceDestroyed(holder.surface)
      super.onSurfaceDestroyed(holder)
    }

    override fun onVisibilityChanged(visible: Boolean) {
      renderThread.visibilityChanged(visible)
    }

    override fun onOffsetsChanged(
      xOffset: Float,
      yOffset: Float,
      xOffsetStep: Float,
      yOffsetStep: Float,
      xPixelOffset: Int,
      yPixelOffset: Int,
    ) {
      renderThread.offsetsChanged(xOffset, yOffset)
    }

    override fun onTouchEvent(event: MotionEvent) {
      renderThread.touchChanged(event.x, event.y)
      super.onTouchEvent(event)
    }

    /** Loads the newly saved configuration when the user confirms this same component again. */
    override fun onCommand(
      action: String?,
      x: Int,
      y: Int,
      z: Int,
      extras: Bundle?,
      resultRequested: Boolean,
    ): Bundle? {
      if (action == WALLPAPER_COMMAND_REAPPLY) {
        renderThread.configurationChanged(OpenGlWallpaperConfigurationStore.load(applicationContext))
      }
      return super.onCommand(action, x, y, z, extras, resultRequested)
    }

    override fun onDestroy() {
      renderThread.shutdown()
      super.onDestroy()
    }
  }

  private class WallpaperRenderThread(
    context: Context,
    initialConfiguration: OpenGlWallpaperConfiguration,
  ) {
    private val appContext = context.applicationContext
    private val thread = HandlerThread("AsyncWallpaper-OpenGL").apply { start() }
    private val handler = Handler(thread.looper)
    private val createdAtNanos = SystemClock.elapsedRealtimeNanos()

    // Everything below is accessed only from [handler].
    private var configuration = initialConfiguration
    private var frameIntervalMillis = frameIntervalFor(initialConfiguration)
    private var destroyed = false
    private var visible = false
    private var surface: Surface? = null
    private var surfaceGeneration = 0L
    private var attachedGeneration = -1L
    private var frameGeneration = 0L
    private var scheduledFrameGeneration: Long? = null
    private var fatalSurfaceGeneration: Long? = null
    private var renderer: GlRenderer? = null
    private var width = 1
    private var height = 1
    private var touchX = 0.5f
    private var touchY = 0.5f
    private var offsetX = 0f
    private var offsetY = 0f
    private val frameState = GlRenderer.FrameState(0f, 1, 1, 0.5f, 0.5f, 0f, 0f)
    private val frameRunnable = Runnable {
      val generation = scheduledFrameGeneration
      if (scheduledFrameGeneration == generation) {
        scheduledFrameGeneration = null
      }
      if (destroyed || generation == null || generation != frameGeneration || !canRender()) {
        return@Runnable
      }
      drawFrame()
      scheduleFrame()
    }

    fun surfaceCreated(newSurface: Surface) {
      handler.post {
        if (destroyed) {
          return@post
        }
        surface = newSurface
        surfaceGeneration += 1L
        attachedGeneration = -1L
        fatalSurfaceGeneration = null
        invalidateScheduledFrame()
        scheduleFrame(immediate = true)
      }
    }

    fun surfaceChanged(newWidth: Int, newHeight: Int) {
      handler.post {
        if (destroyed) {
          return@post
        }
        width = max(1, newWidth)
        height = max(1, newHeight)
        renderer?.updateViewport(width, height)
        scheduleFrame(immediate = true)
      }
    }

    fun surfaceDestroyed(destroyedSurface: Surface) {
      handler.post {
        if (destroyed) {
          return@post
        }
        if (surface === destroyedSurface || surface?.isValid != true) {
          surface = null
          attachedGeneration = -1L
          renderer?.detachSurface()
        }
        invalidateScheduledFrame()
      }
    }

    fun visibilityChanged(isVisible: Boolean) {
      handler.post {
        if (destroyed) {
          return@post
        }
        visible = isVisible
        invalidateScheduledFrame()
        if (visible) {
          scheduleFrame(immediate = true)
        }
      }
    }

    fun offsetsChanged(newOffsetX: Float, newOffsetY: Float) {
      handler.post {
        if (destroyed) {
          return@post
        }
        offsetX = newOffsetX.coerceIn(0f, 1f)
        offsetY = newOffsetY.coerceIn(0f, 1f)
        scheduleFrame(immediate = true)
      }
    }

    fun touchChanged(x: Float, y: Float) {
      handler.post {
        if (destroyed) {
          return@post
        }
        touchX = (x / width.toFloat()).coerceIn(0f, 1f)
        touchY = (y / height.toFloat()).coerceIn(0f, 1f)
        scheduleFrame(immediate = true)
      }
    }

    /** Swaps in a newly confirmed configuration; the next frame builds a renderer for it. */
    fun configurationChanged(newConfiguration: OpenGlWallpaperConfiguration) {
      handler.post {
        if (destroyed) {
          return@post
        }
        configuration = newConfiguration
        frameIntervalMillis = frameIntervalFor(newConfiguration)
        renderer?.release()
        renderer = null
        attachedGeneration = -1L
        fatalSurfaceGeneration = null
        invalidateScheduledFrame()
        scheduleFrame(immediate = true)
      }
    }

    fun shutdown() {
      if (Thread.currentThread() === thread) {
        releaseOnRenderThread()
        thread.quitSafely()
        return
      }
      val released = CountDownLatch(1)
      val accepted = handler.post {
        releaseOnRenderThread()
        released.countDown()
        thread.quitSafely()
      }
      if (accepted) {
        // Do not perform EGL cleanup from the service/UI thread. A bounded wait gives the queued
        // render task a chance to release resources without risking an indefinite lifecycle stall.
        runCatching { released.await(SHUTDOWN_WAIT_MILLIS, TimeUnit.MILLISECONDS) }
      }
    }

    private fun scheduleFrame(immediate: Boolean = false) {
      if (!canRender()) {
        return
      }
      val generation = frameGeneration
      if (scheduledFrameGeneration == generation) {
        return
      }
      scheduledFrameGeneration = generation
      handler.postDelayed(frameRunnable, if (immediate) 0L else frameIntervalMillis)
    }

    private fun drawFrame() {
      val currentSurface = surface ?: return
      if (!currentSurface.isValid) {
        handleSurfaceLost()
        return
      }

      var currentRenderer = renderer
      if (currentRenderer == null) {
        currentRenderer = GlRenderer(appContext, configuration)
        renderer = currentRenderer
      }
      if (attachedGeneration != surfaceGeneration) {
        when (val result = currentRenderer.attachSurface(currentSurface, width, height)) {
          is GlRenderer.Result.Success -> attachedGeneration = surfaceGeneration
          else -> {
            handleRendererResult(result)
            return
          }
        }
      }

      frameState.elapsedSeconds = ((SystemClock.elapsedRealtimeNanos() - createdAtNanos)
        .coerceAtLeast(0L) / NANOS_PER_SECOND).toFloat()
      frameState.width = width
      frameState.height = height
      frameState.touchX = touchX
      frameState.touchY = touchY
      frameState.offsetX = offsetX
      frameState.offsetY = offsetY
      handleRendererResult(currentRenderer.render(frameState))
    }

    private fun handleRendererResult(result: GlRenderer.Result) {
      when (result) {
        is GlRenderer.Result.Success -> Unit
        is GlRenderer.Result.ContextLost -> {
          renderer?.release()
          renderer = null
          attachedGeneration = -1L
          // A context loss is recoverable. The next scheduled frame creates fresh EGL resources.
        }
        is GlRenderer.Result.SurfaceLost -> handleSurfaceLost()
        is GlRenderer.Result.Failure -> {
          Log.e(TAG, "OpenGL wallpaper render failure [${result.code}]: ${result.message}")
          renderer?.release()
          renderer = null
          attachedGeneration = -1L
          // Compilation/linking and texture-source failures need a new configuration or surface;
          // do not spin at the requested FPS while a persistent failure remains.
          fatalSurfaceGeneration = surfaceGeneration
          invalidateScheduledFrame()
        }
      }
    }

    private fun handleSurfaceLost() {
      renderer?.detachSurface()
      surface = null
      attachedGeneration = -1L
      invalidateScheduledFrame()
    }

    private fun canRender(): Boolean {
      return !destroyed && visible && surface != null && fatalSurfaceGeneration != surfaceGeneration
    }

    private fun invalidateScheduledFrame() {
      frameGeneration += 1L
      scheduledFrameGeneration = null
      handler.removeCallbacks(frameRunnable)
    }

    private fun releaseOnRenderThread() {
      if (destroyed) {
        return
      }
      destroyed = true
      invalidateScheduledFrame()
      renderer?.release()
      renderer = null
      surface = null
      attachedGeneration = -1L
    }

    private companion object {
      private const val NANOS_PER_SECOND = 1_000_000_000.0
      private const val SHUTDOWN_WAIT_MILLIS = 1_000L

      private fun frameIntervalFor(configuration: OpenGlWallpaperConfiguration): Long = max(
        1L,
        1_000L / configuration.frameRate.coerceIn(
          ShaderProgramValidator.MIN_FRAME_RATE.toInt(),
          ShaderProgramValidator.MAX_FRAME_RATE.toInt(),
        ),
      )
    }
  }

  companion object {
    private const val TAG = "OpenGlLiveWallpaper"

    /** Returns whether the platform advertises the ES2 context required by [GlRenderer]. */
    fun isOpenGlEs2Supported(context: Context): Boolean {
      val manager = context.applicationContext.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
      return manager?.deviceConfigurationInfo?.reqGlEsVersion?.let { version ->
        version >= OPENGL_ES2_VERSION
      } ?: false
    }

    /**
     * Validates and atomically switches the persisted configuration used by the next engine.
     * Source data is copied into app-private files now, so the render thread never performs I/O
     * beyond reading a bounded local texture file.
     */
    fun saveConfiguration(
      context: Context,
      configuration: OpenGlWallpaperConfiguration,
    ): OpenGlConfigurationResult {
      val validation = ShaderProgramValidator.validate(
        fragmentShader = configuration.fragmentShader,
        textures = configuration.textures.map { source -> source.validationInput() },
        frameRate = configuration.frameRate.toLong(),
        openGlEs2Available = isOpenGlEs2Supported(context),
      )
      if (validation is ShaderProgramValidator.Result.Invalid) {
        return OpenGlConfigurationResult.Rejected(validation.error)
      }
      return try {
        OpenGlWallpaperConfigurationStore.save(context.applicationContext, configuration)
        OpenGlConfigurationResult.Saved
      } catch (error: TextureStorageException) {
        OpenGlConfigurationResult.Rejected(
          ShaderProgramValidator.ValidationError(
            ShaderProgramValidator.ErrorCode.TEXTURE_SOURCE_UNAVAILABLE,
            error.message ?: "Unable to read a texture source.",
          ),
        )
      } catch (error: IOException) {
        OpenGlConfigurationResult.Rejected(
          ShaderProgramValidator.ValidationError(
            ShaderProgramValidator.ErrorCode.CONFIGURATION_STORE_FAILED,
            error.message ?: "Unable to persist the OpenGL wallpaper configuration.",
          ),
        )
      } catch (error: SecurityException) {
        OpenGlConfigurationResult.Rejected(
          ShaderProgramValidator.ValidationError(
            ShaderProgramValidator.ErrorCode.TEXTURE_SOURCE_UNAVAILABLE,
            "Permission to read a texture source was denied.",
          ),
        )
      }
    }

    /** Opens the system live-wallpaper flow for this service. */
    fun setToWallpaper(context: Context) {
      val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        putExtra(
          WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
          ComponentName(context, OpenGlLiveWallpaper::class.java),
        )
      }
      context.startActivity(intent)
    }

    fun openWallpaperChooser(context: Context) {
      val intent = Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      }
      context.startActivity(intent)
    }

    private const val OPENGL_ES2_VERSION = 0x0002_0000
  }
}

/** Persists a renderable configuration in the application-private files directory. */
private object OpenGlWallpaperConfigurationStore {
  private const val PREFERENCES_NAME = "async_wallpaper.opengl"
  private const val KEY_SHADER = "fragment_shader"
  private const val KEY_FRAME_RATE = "frame_rate"
  private const val KEY_TEXTURE_COUNT = "texture_count"
  private const val KEY_TEXTURE_PATH_PREFIX = "texture_path_"
  private const val TEXTURE_DIRECTORY = "async_wallpaper_opengl"
  private const val TEXTURE_FILE_SUFFIX = ".texture"
  // Separate Flutter engines have separate operation queues, so serialize configuration I/O process-wide.
  private val configurationLock = ReentrantLock()

  fun load(context: Context): OpenGlWallpaperConfiguration = configurationLock.withLock {
    val preferences = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
    val shader = preferences.getString(KEY_SHADER, null) ?: return@withLock defaultConfiguration()
    val frameRate = preferences.getInt(KEY_FRAME_RATE, OpenGlWallpaperConfiguration.DEFAULT_FRAME_RATE)
    val count = preferences.getInt(KEY_TEXTURE_COUNT, 0)
    if (count !in 0..ShaderProgramValidator.MAX_TEXTURE_COUNT) {
      return@withLock defaultConfiguration()
    }
    val textures = ArrayList<GlTextureSource>(count)
    repeat(count) { index ->
      val path = preferences.getString("$KEY_TEXTURE_PATH_PREFIX$index", null)
        ?: return@withLock defaultConfiguration()
      textures += GlTextureSource.FilePath(path)
    }
    val configuration = OpenGlWallpaperConfiguration(shader, textures, frameRate)
    val validation = ShaderProgramValidator.validate(
      fragmentShader = configuration.fragmentShader,
      textures = configuration.textures.map { source -> source.validationInput() },
      frameRate = configuration.frameRate.toLong(),
      openGlEs2Available = true,
    )
    if (validation.isValid) configuration else defaultConfiguration()
  }

  @Throws(IOException::class, TextureStorageException::class)
  fun save(context: Context, configuration: OpenGlWallpaperConfiguration) = configurationLock.withLock {
    val rootDirectory = File(context.filesDir, TEXTURE_DIRECTORY)
    if (!rootDirectory.exists() && !rootDirectory.mkdirs()) {
      throw IOException("Unable to create the OpenGL texture directory.")
    }
    if (!rootDirectory.isDirectory) {
      throw IOException("OpenGL texture storage is not a directory.")
    }
    val generationDirectory = File(
      rootDirectory,
      "$OPEN_GL_CONFIGURATION_DIRECTORY_PREFIX${UUID.randomUUID()}",
    )
    val preferences = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
    val previousPreferences = preferences.all
    var committed = false
    try {
      if (!generationDirectory.mkdir()) {
        throw IOException("Unable to allocate OpenGL texture storage.")
      }

      val persistedTextures = configuration.textures.mapIndexed { index, source ->
        val bytes = readSource(context, source)
        val destination = File(generationDirectory, "$index$TEXTURE_FILE_SUFFIX")
        FileOutputStream(destination).use { output ->
          output.write(bytes)
          output.flush()
          output.fd.sync()
        }
        destination.absolutePath
      }

      val editor = preferences.edit()
        .putString(KEY_SHADER, configuration.fragmentShader)
        .putInt(KEY_FRAME_RATE, configuration.frameRate)
        .putInt(KEY_TEXTURE_COUNT, persistedTextures.size)
      repeat(ShaderProgramValidator.MAX_TEXTURE_COUNT) { index ->
        val path = persistedTextures.getOrNull(index)
        if (path == null) {
          editor.remove("$KEY_TEXTURE_PATH_PREFIX$index")
        } else {
          editor.putString("$KEY_TEXTURE_PATH_PREFIX$index", path)
        }
      }
      if (!editor.commit()) {
        restoreConfigurationPreferences(preferences, previousPreferences)
        throw IOException("Unable to persist the OpenGL wallpaper configuration.")
      }
      committed = true
    } finally {
      if (!committed) {
        deleteOpenGlGenerationDirectory(rootDirectory, generationDirectory)
      }
    }

    // The just-committed preferences point at [generationDirectory]. Until commit succeeds, old
    // generations remain untouched so a failed configuration cannot strand the active wallpaper.
    rootDirectory.listFiles()
      ?.asSequence()
      ?.filter { directory ->
        directory.isDirectory &&
          directory.name.startsWith(OPEN_GL_CONFIGURATION_DIRECTORY_PREFIX) &&
          directory != generationDirectory
      }
      ?.forEach { directory ->
        deleteOpenGlGenerationDirectory(rootDirectory, directory)
      }
  }

  private fun restoreConfigurationPreferences(
    preferences: android.content.SharedPreferences,
    previousValues: Map<String, *>,
  ) {
    val editor = preferences.edit()
    configurationPreferenceKeys().forEach { key ->
      when (val value = previousValues[key]) {
        is String -> editor.putString(key, value)
        is Int -> editor.putInt(key, value)
        else -> editor.remove(key)
      }
    }
    // A failed write cannot always be recovered (for example, exhausted storage), but this keeps
    // the in-process view consistent whenever the platform allows the old values to be restored.
    editor.commit()
  }

  private fun configurationPreferenceKeys(): List<String> {
    return buildList {
      add(KEY_SHADER)
      add(KEY_FRAME_RATE)
      add(KEY_TEXTURE_COUNT)
      repeat(ShaderProgramValidator.MAX_TEXTURE_COUNT) { index ->
        add("$KEY_TEXTURE_PATH_PREFIX$index")
      }
    }
  }

  private fun defaultConfiguration(): OpenGlWallpaperConfiguration {
    return OpenGlWallpaperConfiguration(
      fragmentShader = DEFAULT_FRAGMENT_SHADER,
      frameRate = OpenGlWallpaperConfiguration.DEFAULT_FRAME_RATE,
    )
  }

  @Throws(IOException::class, TextureStorageException::class)
  private fun readSource(context: Context, source: GlTextureSource): ByteArray {
    return try {
      source.readBoundedBytes(context)
    } catch (error: IOException) {
      throw TextureStorageException(error.message ?: "Unable to read a texture source.")
    }
  }

  private const val DEFAULT_FRAGMENT_SHADER = """
    precision mediump float;
    varying vec2 v_uv;
    uniform float u_time;
    uniform vec2 u_resolution;
    uniform vec2 u_touch;
    uniform vec2 u_offset;

    void main() {
      vec2 uv = v_uv + (u_offset - 0.5) * 0.02;
      float wave = 0.5 + 0.5 * sin(u_time * 0.25 + uv.x * 6.2831853);
      gl_FragColor = vec4(0.03 + wave * 0.05, 0.05 + wave * 0.08, 0.10 + wave * 0.12, 1.0);
    }
  """
}

private class TextureStorageException(message: String) : IOException(message)

private const val OPEN_GL_CONFIGURATION_DIRECTORY_PREFIX = "configuration-"

/**
 * Deletes one generated configuration directory only when it is a direct child of [rootDirectory].
 * Canonical-path checks keep a malformed path or a symlink from reaching arbitrary filesystem data.
 */
internal fun deleteOpenGlGenerationDirectory(rootDirectory: File, generationDirectory: File): Boolean {
  val canonicalRoot = runCatching { rootDirectory.canonicalFile }.getOrElse { return false }
  val canonicalGeneration = runCatching { generationDirectory.canonicalFile }.getOrElse { return false }
  val directChild = File(canonicalRoot, generationDirectory.name)
  if (canonicalGeneration != directChild ||
    canonicalGeneration.parentFile != canonicalRoot ||
    !canonicalGeneration.name.startsWith(OPEN_GL_CONFIGURATION_DIRECTORY_PREFIX) ||
    (generationDirectory.exists() && !generationDirectory.isDirectory)
  ) {
    return false
  }
  return deleteInsideOpenGlRoot(canonicalRoot, canonicalGeneration)
}

private fun deleteInsideOpenGlRoot(rootDirectory: File, target: File): Boolean {
  val absoluteTarget = target.absoluteFile
  val canonicalTarget = runCatching { target.canonicalFile }.getOrElse { return false }
  if (absoluteTarget != canonicalTarget) {
    // Do not traverse a symlink. Deleting the link itself is safe and never deletes its target.
    return target.delete()
  }
  if (!isWithinOpenGlRoot(rootDirectory, canonicalTarget)) {
    return false
  }
  if (canonicalTarget.isDirectory) {
    val children = canonicalTarget.listFiles() ?: return false
    if (children.any { child -> !deleteInsideOpenGlRoot(rootDirectory, child) }) {
      return false
    }
  }
  return canonicalTarget.delete()
}

private fun isWithinOpenGlRoot(rootDirectory: File, candidate: File): Boolean {
  var current: File? = candidate
  while (current != null) {
    if (current == rootDirectory) {
      return true
    }
    current = current.parentFile
  }
  return false
}
