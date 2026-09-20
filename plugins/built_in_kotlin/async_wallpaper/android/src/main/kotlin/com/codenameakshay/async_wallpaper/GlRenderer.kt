package com.codenameakshay.async_wallpaper

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLContext
import android.opengl.EGLDisplay
import android.opengl.EGLSurface
import android.opengl.GLES20
import android.opengl.GLUtils
import android.view.Surface
import androidx.core.graphics.scale
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import kotlin.math.max
import kotlin.math.min

/**
 * Owns one EGL display/context and the resources for an [OpenGlWallpaperConfiguration].
 *
 * Every public method must be called from one render thread. The wallpaper engine serializes
 * calls through its HandlerThread so EGL, shader, and texture ownership never crosses threads.
 */
class GlRenderer(
  context: Context,
  private val configuration: OpenGlWallpaperConfiguration,
) {
  data class FrameState(
    var elapsedSeconds: Float,
    var width: Int,
    var height: Int,
    /** Normalized, top-left-origin touch coordinates. */
    var touchX: Float,
    /** Normalized, top-left-origin touch coordinates. */
    var touchY: Float,
    /** Wallpaper-engine horizontal offset, normally in the inclusive 0..1 range. */
    var offsetX: Float,
    /** Wallpaper-engine vertical offset, normally in the inclusive 0..1 range. */
    var offsetY: Float,
  )

  sealed class Result {
    data object Success : Result()

    /** EGL signalled that all resources must be recreated from a fresh context. */
    data object ContextLost : Result()

    /** The wallpaper surface went away; wait for a later surface-created callback. */
    data object SurfaceLost : Result()

    data class Failure(
      val code: String,
      val message: String,
    ) : Result()
  }

  private val appContext = context.applicationContext
  private val quad: FloatBuffer = ByteBuffer
    .allocateDirect(FULL_SCREEN_QUAD.size * Float.SIZE_BYTES)
    .order(ByteOrder.nativeOrder())
    .asFloatBuffer()
    .apply {
      put(FULL_SCREEN_QUAD)
      position(0)
    }

  private var ownerThread: Thread? = null
  private var eglDisplay: EGLDisplay = EGL14.EGL_NO_DISPLAY
  private var eglContext: EGLContext = EGL14.EGL_NO_CONTEXT
  private var eglConfig: EGLConfig? = null
  private var windowSurface: EGLSurface = EGL14.EGL_NO_SURFACE
  private var cleanupSurface: EGLSurface = EGL14.EGL_NO_SURFACE
  private var attachedSurface: Surface? = null
  private var program = 0
  private var positionAttribute = -1
  private var textureIds = IntArray(0)
  private val uniformLocations = HashMap<String, Int>()
  private var maxTextureSize = 0
  private var viewportWidth = 1
  private var viewportHeight = 1
  private var lastShaderLog: String? = null

  /** Attaches the renderer to the current WallpaperService surface without drawing a frame. */
  fun attachSurface(surface: Surface, width: Int, height: Int): Result {
    assertRenderThread()
    if (!surface.isValid) {
      return Result.SurfaceLost
    }

    initializeEglIfNeeded()?.let { return it }
    if (windowSurface != EGL14.EGL_NO_SURFACE && attachedSurface !== surface) {
      destroyWindowSurface()
    }
    if (windowSurface == EGL14.EGL_NO_SURFACE) {
      val config = eglConfig
        ?: return Result.Failure(ERROR_EGL_INITIALIZATION_FAILED, "No EGL configuration is available.")
      windowSurface = EGL14.eglCreateWindowSurface(
        eglDisplay,
        config,
        surface,
        intArrayOf(EGL14.EGL_NONE),
        0,
      )
      if (windowSurface == EGL14.EGL_NO_SURFACE) {
        return eglFailure("create window surface")
      }
      attachedSurface = surface
    }
    if (!makeCurrent(windowSurface)) {
      return eglFailure("make window surface current")
    }

    updateViewport(width, height)
    return ensureGlResources()
  }

  /** Updates the draw viewport after [android.service.wallpaper.WallpaperService.Engine.onSurfaceChanged]. */
  fun updateViewport(width: Int, height: Int) {
    assertRenderThread()
    viewportWidth = max(1, width)
    viewportHeight = max(1, height)
    if (windowSurface != EGL14.EGL_NO_SURFACE && makeCurrent(windowSurface)) {
      GLES20.glViewport(0, 0, viewportWidth, viewportHeight)
    }
  }

  /** Draws exactly one frame. Callers are responsible for FPS scheduling. */
  fun render(frame: FrameState): Result {
    assertRenderThread()
    if (windowSurface == EGL14.EGL_NO_SURFACE || attachedSurface?.isValid != true) {
      return Result.SurfaceLost
    }
    if (!makeCurrent(windowSurface)) {
      return eglFailure("make window surface current for draw")
    }

    ensureGlResources().let { resources ->
      if (resources !is Result.Success) {
        return resources
      }
    }

    val width = max(1, frame.width)
    val height = max(1, frame.height)
    viewportWidth = width
    viewportHeight = height
    clearGlErrors()
    GLES20.glViewport(0, 0, width, height)
    GLES20.glClearColor(0f, 0f, 0f, 1f)
    GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
    GLES20.glUseProgram(program)
    GLES20.glEnableVertexAttribArray(positionAttribute)
    quad.position(0)
    GLES20.glVertexAttribPointer(
      positionAttribute,
      POSITION_COMPONENTS,
      GLES20.GL_FLOAT,
      false,
      0,
      quad,
    )

    setFloat("u_time", frame.elapsedSeconds)
    setVec2("u_resolution", width.toFloat(), height.toFloat())
    setVec2("u_touch", frame.touchX, frame.touchY)
    setVec2("u_offset", frame.offsetX, frame.offsetY)
    textureIds.forEachIndexed { index, texture ->
      GLES20.glActiveTexture(GLES20.GL_TEXTURE0 + index)
      GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture)
      setInt("u_texture$index", index)
    }
    GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
    GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, VERTEX_COUNT)
    GLES20.glDisableVertexAttribArray(positionAttribute)

    takeGlError()?.let { error ->
      return Result.Failure(ERROR_GL_DRAW_FAILED, "OpenGL draw failed with error 0x${error.toString(16)}.")
    }
    if (!EGL14.eglSwapBuffers(eglDisplay, windowSurface)) {
      return eglFailure("swap buffers")
    }
    return Result.Success
  }

  /** Releases only the EGL window surface; programs and textures remain associated with the context. */
  fun detachSurface() {
    assertRenderThread()
    destroyWindowSurface()
  }

  /**
   * Releases GL objects, EGL surfaces, the EGL context, and the display. This must run on the
   * render thread; context destruction is the fallback cleanup path if no surface can be current.
   */
  fun release() {
    assertRenderThread()
    if (eglDisplay == EGL14.EGL_NO_DISPLAY) {
      resetState()
      return
    }

    if (makeCleanupSurfaceCurrent()) {
      releaseGlResources()
    }
    destroyWindowSurface()
    if (cleanupSurface != EGL14.EGL_NO_SURFACE) {
      EGL14.eglDestroySurface(eglDisplay, cleanupSurface)
      cleanupSurface = EGL14.EGL_NO_SURFACE
    }
    if (eglContext != EGL14.EGL_NO_CONTEXT) {
      EGL14.eglDestroyContext(eglDisplay, eglContext)
    }
    EGL14.eglTerminate(eglDisplay)
    EGL14.eglReleaseThread()
    resetState()
  }

  private fun initializeEglIfNeeded(): Result? {
    if (eglDisplay != EGL14.EGL_NO_DISPLAY) {
      return null
    }

    eglDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
    if (eglDisplay == EGL14.EGL_NO_DISPLAY) {
      resetState()
      return Result.Failure(ERROR_EGL_UNAVAILABLE, "Unable to obtain an EGL display.")
    }
    val versions = IntArray(2)
    if (!EGL14.eglInitialize(eglDisplay, versions, 0, versions, 1)) {
      val failure = eglFailure("initialize EGL")
      release()
      return failure
    }

    val configurations = arrayOfNulls<EGLConfig>(1)
    val count = IntArray(1)
    val attributes = intArrayOf(
      EGL14.EGL_RENDERABLE_TYPE,
      EGL14.EGL_OPENGL_ES2_BIT,
      EGL14.EGL_SURFACE_TYPE,
      EGL14.EGL_WINDOW_BIT or EGL14.EGL_PBUFFER_BIT,
      EGL14.EGL_RED_SIZE,
      8,
      EGL14.EGL_GREEN_SIZE,
      8,
      EGL14.EGL_BLUE_SIZE,
      8,
      EGL14.EGL_ALPHA_SIZE,
      8,
      EGL14.EGL_NONE,
    )
    if (!EGL14.eglChooseConfig(eglDisplay, attributes, 0, configurations, 0, configurations.size, count, 0) ||
      count[0] <= 0 || configurations[0] == null
    ) {
      val failure = eglFailure("choose EGL config")
      release()
      return failure
    }
    eglConfig = configurations[0]
    eglContext = EGL14.eglCreateContext(
      eglDisplay,
      eglConfig,
      EGL14.EGL_NO_CONTEXT,
      intArrayOf(EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL14.EGL_NONE),
      0,
    )
    if (eglContext == EGL14.EGL_NO_CONTEXT) {
      val failure = eglFailure("create GLES2 context")
      release()
      return failure
    }

    // A tiny pbuffer lets us explicitly delete GL objects after the wallpaper surface disappears.
    // Some valid window-only EGL implementations do not expose one; context destruction remains
    // the safe fallback on those devices.
    cleanupSurface = EGL14.eglCreatePbufferSurface(
      eglDisplay,
      eglConfig,
      intArrayOf(EGL14.EGL_WIDTH, 1, EGL14.EGL_HEIGHT, 1, EGL14.EGL_NONE),
      0,
    )
    return null
  }

  private fun ensureGlResources(): Result {
    if (program != 0) {
      return Result.Success
    }
    val validation = ShaderProgramValidator.validate(
      fragmentShader = configuration.fragmentShader,
      textures = configuration.textures.map { it.validationInput() },
      frameRate = configuration.frameRate.toLong(),
    )
    if (validation is ShaderProgramValidator.Result.Invalid) {
      return Result.Failure(validation.error.wireCode, validation.error.message)
    }

    val vertexShader = compileShader(GLES20.GL_VERTEX_SHADER, SAFE_VERTEX_SHADER, "vertex")
      ?: return Result.Failure(ERROR_VERTEX_SHADER_COMPILATION_FAILED, "The built-in vertex shader could not compile.")
    val fragmentShader = compileShader(GLES20.GL_FRAGMENT_SHADER, configuration.fragmentShader, "fragment")
      ?: run {
        GLES20.glDeleteShader(vertexShader)
        return Result.Failure(
          ERROR_FRAGMENT_SHADER_COMPILATION_FAILED,
          "Fragment shader compilation failed: ${limitedGlLog()}",
        )
      }
    val linkedProgram = GLES20.glCreateProgram()
    if (linkedProgram == 0) {
      GLES20.glDeleteShader(vertexShader)
      GLES20.glDeleteShader(fragmentShader)
      return Result.Failure(ERROR_PROGRAM_LINK_FAILED, "Unable to allocate an OpenGL program.")
    }
    GLES20.glAttachShader(linkedProgram, vertexShader)
    GLES20.glAttachShader(linkedProgram, fragmentShader)
    GLES20.glBindAttribLocation(linkedProgram, 0, POSITION_ATTRIBUTE)
    GLES20.glLinkProgram(linkedProgram)
    val linkStatus = IntArray(1)
    GLES20.glGetProgramiv(linkedProgram, GLES20.GL_LINK_STATUS, linkStatus, 0)
    GLES20.glDeleteShader(vertexShader)
    GLES20.glDeleteShader(fragmentShader)
    if (linkStatus[0] != GLES20.GL_TRUE) {
      val log = GLES20.glGetProgramInfoLog(linkedProgram).take(MAX_GL_LOG_CHARS)
      GLES20.glDeleteProgram(linkedProgram)
      return Result.Failure(
        ERROR_PROGRAM_LINK_FAILED,
        "Fragment shader could not link with the built-in vertex shader: $log",
      )
    }

    program = linkedProgram
    positionAttribute = GLES20.glGetAttribLocation(program, POSITION_ATTRIBUTE)
    if (positionAttribute < 0) {
      releaseGlResources()
      return Result.Failure(ERROR_PROGRAM_LINK_FAILED, "Built-in position attribute was optimized away.")
    }
    RENDERER_UNIFORM_NAMES.forEach { name ->
      uniformLocations[name] = GLES20.glGetUniformLocation(program, name)
    }
    maxTextureSize = queryMaxTextureSize()
    if (maxTextureSize <= 0) {
      releaseGlResources()
      return Result.Failure(ERROR_TEXTURE_LIMIT_UNAVAILABLE, "The GLES2 context reported no texture capacity.")
    }

    val textureResult = uploadTextures()
    if (textureResult !is Result.Success) {
      releaseGlResources()
      return textureResult
    }
    return Result.Success
  }

  private fun compileShader(type: Int, source: String, label: String): Int? {
    val shader = GLES20.glCreateShader(type)
    if (shader == 0) {
      return null
    }
    GLES20.glShaderSource(shader, source)
    GLES20.glCompileShader(shader)
    val status = IntArray(1)
    GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, status, 0)
    if (status[0] == GLES20.GL_TRUE) {
      return shader
    }
    // Query the log before deleting the shader because several drivers discard it on delete.
    val log = GLES20.glGetShaderInfoLog(shader).take(MAX_GL_LOG_CHARS)
    GLES20.glDeleteShader(shader)
    lastShaderLog = "$label shader: $log"
    return null
  }

  private fun limitedGlLog(): String {
    return lastShaderLog?.take(MAX_GL_LOG_CHARS).orEmpty()
  }

  private fun uploadTextures(): Result {
    if (configuration.textures.isEmpty()) {
      return Result.Success
    }
    val ids = IntArray(configuration.textures.size)
    clearGlErrors()
    GLES20.glGenTextures(ids.size, ids, 0)
    if (ids.any { it == 0 }) {
      GLES20.glDeleteTextures(ids.size, ids, 0)
      return Result.Failure(ERROR_TEXTURE_ALLOCATION_FAILED, "Unable to allocate OpenGL texture handles.")
    }

    try {
      configuration.textures.forEachIndexed { index, source ->
        val bitmap = decodeTexture(source)
        try {
          GLES20.glActiveTexture(GLES20.GL_TEXTURE0 + index)
          GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, ids[index])
          GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_MIN_FILTER,
            GLES20.GL_LINEAR,
          )
          GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_MAG_FILTER,
            GLES20.GL_LINEAR,
          )
          GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_WRAP_S,
            GLES20.GL_CLAMP_TO_EDGE,
          )
          GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_WRAP_T,
            GLES20.GL_CLAMP_TO_EDGE,
          )
          GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
          takeGlError()?.let { error ->
            throw TextureLoadException(
              ERROR_TEXTURE_UPLOAD_FAILED,
              "Texture $index upload failed with OpenGL error 0x${error.toString(16)}.",
            )
          }
        } finally {
          if (!bitmap.isRecycled) {
            bitmap.recycle()
          }
        }
      }
    } catch (error: TextureLoadException) {
      GLES20.glDeleteTextures(ids.size, ids, 0)
      return Result.Failure(error.code, error.message ?: "Unable to load a wallpaper texture.")
    } catch (error: IOException) {
      GLES20.glDeleteTextures(ids.size, ids, 0)
      return Result.Failure(ERROR_TEXTURE_SOURCE_UNAVAILABLE, error.message ?: "Unable to open a wallpaper texture.")
    } catch (error: SecurityException) {
      GLES20.glDeleteTextures(ids.size, ids, 0)
      return Result.Failure(ERROR_TEXTURE_SOURCE_UNAVAILABLE, "Permission to read a wallpaper texture was denied.")
    }
    textureIds = ids
    GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
    return Result.Success
  }

  @Throws(IOException::class, TextureLoadException::class)
  private fun decodeTexture(source: GlTextureSource): Bitmap {
    val bytes = readTextureBytes(source)
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
    if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
      throw TextureLoadException(ERROR_TEXTURE_DECODE_FAILED, "Texture source is not a decodable image.")
    }
    val sampleSize = calculateSampleSize(bounds.outWidth, bounds.outHeight)
    val decoded = BitmapFactory.decodeByteArray(
      bytes,
      0,
      bytes.size,
      BitmapFactory.Options().apply {
        inSampleSize = sampleSize
        inPreferredConfig = Bitmap.Config.ARGB_8888
      },
    ) ?: throw TextureLoadException(ERROR_TEXTURE_DECODE_FAILED, "Texture image could not be decoded.")
    if (decoded.width <= 0 || decoded.height <= 0) {
      decoded.recycle()
      throw TextureLoadException(ERROR_TEXTURE_DECODE_FAILED, "Texture image has invalid dimensions.")
    }
    return scaleToTextureLimit(decoded)
  }

  @Throws(IOException::class, TextureLoadException::class)
  private fun readTextureBytes(source: GlTextureSource): ByteArray {
    return try {
      source.readBoundedBytes(appContext)
    } catch (error: TextureSourceTooLargeException) {
      throw TextureLoadException(
        ShaderProgramValidator.ErrorCode.TEXTURE_SOURCE_TOO_LARGE.wireCode,
        error.message ?: "Texture source exceeds the configured byte limit.",
      )
    } catch (error: IOException) {
      throw TextureLoadException(ERROR_TEXTURE_SOURCE_UNAVAILABLE, error.message ?: "Unable to open a wallpaper texture.")
    }
  }

  private fun calculateSampleSize(width: Int, height: Int): Int {
    val maximumDimension = min(ShaderProgramValidator.MAX_TEXTURE_DIMENSION, maxTextureSize)
    var sampleSize = 1
    while (true) {
      val sampledWidth = ceilDiv(width.toLong(), sampleSize.toLong())
      val sampledHeight = ceilDiv(height.toLong(), sampleSize.toLong())
      val sampledPixels = sampledWidth * sampledHeight
      if (sampledWidth <= maximumDimension &&
        sampledHeight <= maximumDimension &&
        sampledPixels <= ShaderProgramValidator.MAX_TEXTURE_PIXELS
      ) {
        return sampleSize
      }
      if (sampleSize >= MAX_SAMPLE_SIZE) {
        return sampleSize
      }
      sampleSize *= 2
    }
  }

  private fun scaleToTextureLimit(bitmap: Bitmap): Bitmap {
    val maximumDimension = min(ShaderProgramValidator.MAX_TEXTURE_DIMENSION, maxTextureSize)
    val scale = BitmapTransformMath.scaleToFit(
      bitmap.width,
      bitmap.height,
      maximumDimension,
      ShaderProgramValidator.MAX_TEXTURE_PIXELS,
    )
    if (scale >= 1.0) {
      return bitmap
    }
    val scaledWidth = max(1, (bitmap.width * scale).toInt())
    val scaledHeight = max(1, (bitmap.height * scale).toInt())
    val scaled = bitmap.scale(scaledWidth, scaledHeight)
    if (scaled !== bitmap) {
      bitmap.recycle()
    }
    return scaled
  }

  private fun queryMaxTextureSize(): Int {
    val value = IntArray(1)
    GLES20.glGetIntegerv(GLES20.GL_MAX_TEXTURE_SIZE, value, 0)
    return value[0]
  }

  private fun setFloat(name: String, value: Float) {
    uniformLocations[name]?.takeIf { it >= 0 }?.let { location ->
      GLES20.glUniform1f(location, value)
    }
  }

  private fun setVec2(name: String, x: Float, y: Float) {
    uniformLocations[name]?.takeIf { it >= 0 }?.let { location ->
      GLES20.glUniform2f(location, x, y)
    }
  }

  private fun setInt(name: String, value: Int) {
    uniformLocations[name]?.takeIf { it >= 0 }?.let { location ->
      GLES20.glUniform1i(location, value)
    }
  }

  private fun makeCurrent(surface: EGLSurface): Boolean {
    return EGL14.eglMakeCurrent(eglDisplay, surface, surface, eglContext)
  }

  private fun makeCleanupSurfaceCurrent(): Boolean {
    val surface = when {
      cleanupSurface != EGL14.EGL_NO_SURFACE -> cleanupSurface
      windowSurface != EGL14.EGL_NO_SURFACE -> windowSurface
      else -> return false
    }
    return makeCurrent(surface)
  }

  private fun destroyWindowSurface() {
    if (eglDisplay == EGL14.EGL_NO_DISPLAY || windowSurface == EGL14.EGL_NO_SURFACE) {
      attachedSurface = null
      return
    }
    if (cleanupSurface != EGL14.EGL_NO_SURFACE) {
      makeCurrent(cleanupSurface)
    } else {
      EGL14.eglMakeCurrent(
        eglDisplay,
        EGL14.EGL_NO_SURFACE,
        EGL14.EGL_NO_SURFACE,
        EGL14.EGL_NO_CONTEXT,
      )
    }
    EGL14.eglDestroySurface(eglDisplay, windowSurface)
    windowSurface = EGL14.EGL_NO_SURFACE
    attachedSurface = null
  }

  private fun releaseGlResources() {
    if (textureIds.isNotEmpty()) {
      GLES20.glDeleteTextures(textureIds.size, textureIds, 0)
      textureIds = IntArray(0)
    }
    if (program != 0) {
      GLES20.glDeleteProgram(program)
      program = 0
    }
    positionAttribute = -1
    uniformLocations.clear()
    maxTextureSize = 0
  }

  private fun eglFailure(operation: String): Result {
    return when (val error = EGL14.eglGetError()) {
      EGL14.EGL_CONTEXT_LOST -> Result.ContextLost
      EGL14.EGL_BAD_SURFACE,
      EGL14.EGL_BAD_NATIVE_WINDOW,
      -> Result.SurfaceLost
      else -> Result.Failure(
        ERROR_EGL_OPERATION_FAILED,
        "$operation failed with EGL error 0x${error.toString(16)}.",
      )
    }
  }

  private fun clearGlErrors() {
    while (GLES20.glGetError() != GLES20.GL_NO_ERROR) {
      // Drain a stale driver error before attributing a later operation to this frame.
    }
  }

  private fun takeGlError(): Int? {
    val error = GLES20.glGetError()
    return error.takeUnless { it == GLES20.GL_NO_ERROR }
  }

  private fun assertRenderThread() {
    val currentThread = Thread.currentThread()
    val recordedOwner = ownerThread
    if (recordedOwner == null) {
      ownerThread = currentThread
    } else {
      check(recordedOwner === currentThread) { "GlRenderer must only be used from its render thread." }
    }
  }

  private fun resetState() {
    eglDisplay = EGL14.EGL_NO_DISPLAY
    eglContext = EGL14.EGL_NO_CONTEXT
    eglConfig = null
    windowSurface = EGL14.EGL_NO_SURFACE
    cleanupSurface = EGL14.EGL_NO_SURFACE
    attachedSurface = null
    program = 0
    positionAttribute = -1
    textureIds = IntArray(0)
    uniformLocations.clear()
    maxTextureSize = 0
    lastShaderLog = null
  }

  private class TextureLoadException(
    val code: String,
    override val message: String,
  ) : IOException(message)

  private companion object {
    private const val POSITION_ATTRIBUTE = "a_position"
    private const val POSITION_COMPONENTS = 2
    private const val VERTEX_COUNT = 4
    private const val MAX_SAMPLE_SIZE = 1 shl 30
    private const val MAX_GL_LOG_CHARS = 1024

    private const val ERROR_EGL_UNAVAILABLE = "egl-unavailable"
    private const val ERROR_EGL_INITIALIZATION_FAILED = "egl-initialization-failed"
    private const val ERROR_EGL_OPERATION_FAILED = "egl-operation-failed"
    private const val ERROR_VERTEX_SHADER_COMPILATION_FAILED = "vertex-shader-compilation-failed"
    private const val ERROR_FRAGMENT_SHADER_COMPILATION_FAILED = "shader-compilation-failed"
    private const val ERROR_PROGRAM_LINK_FAILED = "shader-link-failed"
    private const val ERROR_TEXTURE_LIMIT_UNAVAILABLE = "texture-limit-unavailable"
    private const val ERROR_TEXTURE_ALLOCATION_FAILED = "texture-allocation-failed"
    private const val ERROR_TEXTURE_SOURCE_UNAVAILABLE = "texture-source-unavailable"
    private const val ERROR_TEXTURE_DECODE_FAILED = "texture-decode-failed"
    private const val ERROR_TEXTURE_UPLOAD_FAILED = "texture-upload-failed"
    private const val ERROR_GL_DRAW_FAILED = "gl-draw-failed"

    private val FULL_SCREEN_QUAD = floatArrayOf(
      -1f,
      -1f,
      1f,
      -1f,
      -1f,
      1f,
      1f,
      1f,
    )

    private val RENDERER_UNIFORM_NAMES = listOf(
      "u_time",
      "u_resolution",
      "u_touch",
      "u_offset",
      "u_texture0",
      "u_texture1",
      "u_texture2",
      "u_texture3",
    )

    private const val SAFE_VERTEX_SHADER = """
      attribute vec2 a_position;
      varying vec2 v_uv;

      void main() {
        v_uv = a_position * 0.5 + 0.5;
        gl_Position = vec4(a_position, 0.0, 1.0);
      }
    """

    private fun ceilDiv(numerator: Long, denominator: Long): Long {
      return ((numerator - 1L) / denominator) + 1L
    }
  }
}
