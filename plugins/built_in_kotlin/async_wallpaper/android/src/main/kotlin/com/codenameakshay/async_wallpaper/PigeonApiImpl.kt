package com.codenameakshay.async_wallpaper

import android.Manifest
import android.app.Activity
import android.app.WallpaperManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import androidx.core.net.toUri
import java.io.File
import java.io.IOException
import java.lang.ref.WeakReference
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Android implementation of the Pigeon transport.
 *
 * All mutating work is submitted to [operationQueue] so an image write, video replacement, and
 * renderer configuration cannot race each other. A foreground Activity is retained weakly and is
 * consulted only immediately before launching system UI; direct work remains safe from a worker
 * or headless Flutter engine.
 */
class PigeonApiImpl(
  context: Context,
  private val operationQueue: OperationQueue = OperationQueue(),
  private val mainHandler: Handler = Handler(Looper.getMainLooper()),
  private val staticWallpaperEngine: StaticWallpaperEngine = StaticWallpaperEngine(context),
  private val videoRepository: VideoWallpaperRepository = VideoWallpaperRepository(context.filesDir),
  private val videoSourceOpener: BoundedSourceOpener = BoundedSourceOpener(
    context,
    MAX_VIDEO_SOURCE_BYTES,
  ),
  private val textureSourceOpener: BoundedSourceOpener = BoundedSourceOpener(
    context,
    ShaderProgramValidator.MAX_TEXTURE_SOURCE_BYTES,
  ),
  private val downloadSourceOpener: BoundedSourceOpener = BoundedSourceOpener(
    context,
    MAX_DOWNLOAD_SOURCE_BYTES,
  ),
) : WallpaperApi {
  private val appContext = context.applicationContext
  private val ioExecutor: ExecutorService = Executors.newCachedThreadPool()
  private val rotationStore = WallpaperRotationStore(appContext)
  private val rotationEngine = WallpaperRotationEngine(appContext, rotationStore)

  @Volatile
  private var activityReference: WeakReference<Activity>? = null

  /** Called by [AsyncWallpaperPlugin] only while Flutter has an attached Activity. */
  fun attachActivity(activity: Activity) {
    activityReference = WeakReference(activity)
  }

  /** Clears the weak reference on normal and configuration-change detach paths. */
  fun detachActivity(activity: Activity? = null) {
    val current = activityReference?.get()
    if (activity == null || current == null || current === activity) {
      activityReference = null
    }
  }

  /** Ends the plugin-owned queue and releases every Activity reference on engine detach. */
  fun shutdown() {
    activityReference = null
    operationQueue.shutdown()
  }

  override fun getPlatformVersion(callback: (Result<String>) -> Unit) {
    callback(Result.success("Android ${Build.VERSION.RELEASE}"))
  }

  override fun checkMaterialYouSupport(callback: (Result<MaterialYouSupportData>) -> Unit) {
    callback(
      Result.success(
        MaterialYouSupportData(
          isSupported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S,
          androidVersion = Build.VERSION.RELEASE,
          sdkInt = Build.VERSION.SDK_INT.toLong(),
        ),
      ),
    )
  }

  override fun getCapabilities(callback: (Result<WallpaperCapabilitiesData>) -> Unit) {
    callback(Result.success(AndroidCapabilities.snapshot(appContext)))
  }

  override fun startWallpaperRotation(
    config: WallpaperRotationConfigData,
    callback: (Result<Boolean>) -> Unit,
  ) {
    ioExecutor.execute {
      val success = runCatching {
        val intervalMinutes = config.intervalMinutes?.toInt() ?: 0
        when (rotationEngine.startRotation(config)) {
          RotationStartResult.STARTED -> {
            try {
              reconcileRotationTriggers(config, intervalMinutes)
              true
            } catch (error: Exception) {
              // The wallpaper is already applied but the schedules are unknown; report failure and
              // tear the rotation down rather than leaving a half-armed trigger set.
              Log.e(TAG, "Rotation started but trigger reconciliation failed", error)
              rollbackFailedRotationStart()
              false
            }
          }
          // Only a start that already persisted a new configuration may roll back, so a rejected
          // request cannot stop a rotation that is still running.
          RotationStartResult.FAILED_AFTER_SAVE -> {
            rollbackFailedRotationStart()
            false
          }
          RotationStartResult.REJECTED -> false
        }
      }.getOrElse {
        Log.e(TAG, "startWallpaperRotation failed", it)
        false
      }
      postCallback(callback, Result.success(success))
    }
  }

  override fun stopWallpaperRotation(callback: (Result<Boolean>) -> Unit) {
    ioExecutor.execute {
      val success = runCatching {
        WallpaperRotationScheduler.cancelPeriodic(appContext)
        WallpaperRotationScheduler.cancelCharging(appContext)
        WallpaperRotationScheduler.cancelTimeOfDay(appContext)
        rotationStore.stopRotation()
        rotationEngine.clearRotationCache()
        true
      }.getOrElse {
        Log.e(TAG, "stopWallpaperRotation failed", it)
        false
      }
      postCallback(callback, Result.success(success))
    }
  }

  /**
   * Reconciles every background trigger with the configuration that was just saved. Each trigger
   * is scheduled or cancelled independently so changing one setting never leaves a stale schedule
   * for another.
   */
  private fun reconcileRotationTriggers(
    config: WallpaperRotationConfigData,
    intervalMinutes: Int,
  ) {
    if (config.enableIntervalTrigger == true) {
      WallpaperRotationScheduler.schedulePeriodic(appContext, intervalMinutes)
      rotationStore.setNextRunEpochMs(
        System.currentTimeMillis() + intervalMinutes.toLong() * 60_000L,
      )
    } else {
      WallpaperRotationScheduler.cancelPeriodic(appContext)
      rotationStore.setNextRunEpochMs(0L)
    }

    if (config.enableChargingTrigger == true) {
      WallpaperRotationScheduler.scheduleCharging(appContext, intervalMinutes)
    } else {
      WallpaperRotationScheduler.cancelCharging(appContext)
    }

    val startHour = config.activeHoursStart?.toInt()
      ?: WallpaperRotationStore.DEFAULT_ACTIVE_HOURS_START
    if (config.enableTimeOfDayTrigger == true) {
      WallpaperRotationScheduler.scheduleTimeOfDay(appContext, startHour)
    } else {
      WallpaperRotationScheduler.cancelTimeOfDay(appContext)
    }
  }

  /**
   * A start that could not apply its first wallpaper must not leave schedules or a running flag
   * behind. The failure reason is preserved for [WallpaperRotationStatusData.lastError].
   */
  private fun rollbackFailedRotationStart() {
    val failureReason = rotationStore.getStatusData().lastError
    WallpaperRotationScheduler.cancelPeriodic(appContext)
    WallpaperRotationScheduler.cancelCharging(appContext)
    WallpaperRotationScheduler.cancelTimeOfDay(appContext)
    rotationStore.stopRotation()
    rotationEngine.clearRotationCache()
    rotationStore.setLastError(failureReason)
  }

  override fun getWallpaperRotationStatus(
    callback: (Result<WallpaperRotationStatusData>) -> Unit,
  ) {
    val status = runCatching {
      rotationStore.getStatusData()
    }.getOrElse {
      Log.e(TAG, "getWallpaperRotationStatus failed", it)
      WallpaperRotationStatusData(
        isRunning = false,
        nextRunEpochMs = 0L,
        currentIndex = 0L,
        cachedCount = 0L,
        totalCount = 0L,
        lastError = it.message,
        effectiveIntervalMinutes = 0L,
      )
    }
    callback(Result.success(status))
  }

  override fun rotateWallpaperNow(callback: (Result<Boolean>) -> Unit) {
    ioExecutor.execute {
      val success = runCatching {
        rotationEngine.applyNextWallpaper()
      }.getOrElse {
        Log.e(TAG, "rotateWallpaperNow failed", it)
        false
      }
      postCallback(callback, Result.success(success))
    }
  }

  override fun applyWallpaper(
    request: StaticWallpaperRequestData,
    callback: (Result<OperationResultData>) -> Unit,
  ) {
    enqueueOperation(request.target, callback) {
      when (request.strategy) {
        WallpaperApplyStrategyData.SYSTEM_CROPPER -> runOnMainBlocking {
          staticWallpaperEngine.openSystemCropper(request, currentActivity())
        }
        WallpaperApplyStrategyData.SYSTEM_PICKER -> runOnMainBlocking {
          staticWallpaperEngine.openSystemPicker(request, currentActivity())
        }
        WallpaperApplyStrategyData.DIRECT,
        WallpaperApplyStrategyData.AUTOMATIC,
        null,
        -> staticWallpaperEngine.applyDirect(request)
      }
    }
  }

  override fun prepareVideoWallpaper(
    request: VideoWallpaperRequestData,
    callback: (Result<OperationResultData>) -> Unit,
  ) {
    enqueueOperation(request.target, callback) {
      prepareVideoAsset(request)
    }
  }

  override fun openLiveWallpaperPreview(
    request: VideoWallpaperRequestData,
    callback: (Result<OperationResultData>) -> Unit,
  ) {
    enqueueOperation(request.target, callback) {
      val target = request.target ?: return@enqueueOperation OperationResultPolicy.failed(
        WallpaperTargetData.HOME,
        ERROR_INVALID_REQUEST,
        "A video wallpaper target is required.",
      )
      // Opening the preview is a UI operation. Do not replace the active asset in a headless
      // engine that has no way to show the user the system confirmation screen.
      if (!runOnMainBlocking { currentActivity() != null }) {
        return@enqueueOperation OperationResultPolicy.foregroundRequired(target)
      }
      val prepared = prepareVideoAsset(request)
      if (prepared.status != OperationStatusData.AWAITING_USER_CONFIRMATION) {
        prepared
      } else {
        runOnMainBlocking {
          val scaleMode = request.scaleMode
          if (scaleMode == null) {
            OperationResultPolicy.failed(
              target,
              ERROR_INVALID_REQUEST,
              "A video wallpaper scale mode is required.",
            )
          } else {
            openLiveWallpaperUi(target, VideoLiveWallpaper::class.java) {
              promoteVideoAsset(target, scaleMode)
            }
          }
        }
      }
    }
  }

  override fun applyOpenGlWallpaper(
    request: OpenGlWallpaperRequestData,
    callback: (Result<OperationResultData>) -> Unit,
  ) {
    enqueueOperation(request.target, callback) {
      val target = request.target ?: return@enqueueOperation OperationResultPolicy.failed(
        WallpaperTargetData.HOME,
        ERROR_INVALID_REQUEST,
        "An OpenGL wallpaper target is required.",
      )
      // Persisting a renderer configuration is a mutation. Avoid changing it when the requested
      // preview cannot be shown by this headless engine.
      if (!runOnMainBlocking { currentActivity() != null }) {
        return@enqueueOperation OperationResultPolicy.foregroundRequired(target)
      }
      prepareAndOpenOpenGlWallpaper(request)
    }
  }

  override fun setMaterialYouWallpaper(url: String, callback: (Result<Boolean>) -> Unit) {
    // Material You effects remain a launcher/system concern; apply the supplied image to both
    // targets directly when Android permits it.
    enqueueBoolean(callback) {
      staticWallpaperEngine.applyDirect(
        StaticWallpaperRequestData(
          source = WallpaperSourceData(kind = WallpaperSourceKindData.URL, url = url),
          target = WallpaperTargetData.BOTH,
          scaleMode = WallpaperScaleModeData.CENTER_CROP,
          strategy = WallpaperApplyStrategyData.DIRECT,
        ),
      ).status == OperationStatusData.APPLIED
    }
  }

  override fun openWallpaperChooser(callback: (Result<Boolean>) -> Unit) {
    enqueueBoolean(callback) {
      runOnMainBlocking {
        val activity = currentActivity() ?: return@runOnMainBlocking false
        val intent = Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER)
        val resolvedIntent = AndroidCapabilities.resolveExplicit(activity.packageManager, intent)
        if (resolvedIntent == null) {
          false
        } else {
          runCatching { activity.startActivity(resolvedIntent) }.isSuccess
        }
      }
    }
  }

  override fun downloadWallpaper(url: String, callback: (Result<Boolean>) -> Unit) {
    enqueueBoolean(callback) {
      downloadToMediaStore(url)
    }
  }

  private fun prepareVideoAsset(request: VideoWallpaperRequestData): OperationResultData {
    val target = request.target
      ?: return OperationResultPolicy.failed(
        WallpaperTargetData.HOME,
        ERROR_INVALID_REQUEST,
        "A video wallpaper target is required.",
      )
    val source = request.source
      ?: return OperationResultPolicy.failed(
        target,
        ERROR_INVALID_REQUEST,
        "A video wallpaper source is required.",
      )
    val scaleMode = request.scaleMode
      ?: return OperationResultPolicy.failed(
        target,
        ERROR_INVALID_REQUEST,
        "A video wallpaper scale mode is required.",
      )
    if (scaleMode != WallpaperScaleModeData.CENTER_CROP &&
      scaleMode != WallpaperScaleModeData.FIT_CENTER
    ) {
      return OperationResultPolicy.unsupported(
        target,
        ERROR_VIDEO_SCALE_UNSUPPORTED,
        "Video live wallpapers support only centerCrop and fitCenter scaling.",
      )
    }
    if (!source.hasValueForKind()) {
      return OperationResultPolicy.failed(
        target,
        ERROR_INVALID_REQUEST,
        "The video wallpaper source is incomplete.",
      )
    }
    if (!AndroidCapabilities.hasVideoLiveWallpaper(appContext)) {
      return OperationResultPolicy.unsupported(
        target,
        ERROR_LIVE_WALLPAPER_UNSUPPORTED,
        "This device cannot open this app's live wallpaper flow.",
      )
    }

    return try {
      videoSourceOpener.open(source).use { input ->
        videoRepository.preparePending(input)
      }
      // Preparing changes only an app-private candidate. The user has not selected it yet.
      OperationResultPolicy.awaitingUserConfirmation(target)
    } catch (error: BoundedSourceException) {
      OperationResultPolicy.failed(target, error.code, error.message ?: "Unable to read the video source.")
    } catch (error: VideoMetadataValidationException) {
      OperationResultPolicy.failed(
        target,
        videoValidationCode(error),
        error.message ?: "The video source is not playable.",
      )
    } catch (error: SecurityException) {
      OperationResultPolicy.failed(
        target,
        ERROR_PERMISSION_DENIED,
        "Permission to read or prepare the video source was denied.",
        error.message,
      )
    } catch (error: IOException) {
      OperationResultPolicy.failed(
        target,
        ERROR_VIDEO_PREPARATION_FAILED,
        "Unable to prepare the video wallpaper.",
        error.message,
      )
    } catch (error: Exception) {
      OperationResultPolicy.failed(
        target,
        ERROR_VIDEO_PREPARATION_FAILED,
        "Unable to prepare the video wallpaper.",
        error.message,
      )
    }
  }

  private fun openLiveWallpaperUi(
    target: WallpaperTargetData,
    serviceClass: Class<*>,
    beforeLaunch: (() -> OperationResultData?)? = null,
  ): OperationResultData {
    val activity = currentActivity() ?: return OperationResultPolicy.foregroundRequired(target)
    val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
      putExtra(
        WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
        ComponentName(appContext, serviceClass),
      )
    }
    return try {
      val resolvedIntent = AndroidCapabilities.resolveExplicit(activity.packageManager, intent)
      if (resolvedIntent == null) {
        OperationResultPolicy.failed(
          target,
          ERROR_SYSTEM_UI_UNAVAILABLE,
          "This device has no system live wallpaper preview UI.",
        )
      } else {
        beforeLaunch?.invoke()?.let { return it }
        activity.startActivity(resolvedIntent)
        // Android owns target selection in this UI. Do not claim home or lock was applied.
        OperationResultPolicy.previewOpened(target)
      }
    } catch (_: ActivityNotFoundException) {
      OperationResultPolicy.failed(
        target,
        ERROR_SYSTEM_UI_UNAVAILABLE,
        "This device has no system live wallpaper preview UI.",
      )
    } catch (error: SecurityException) {
      OperationResultPolicy.failed(
        target,
        ERROR_PERMISSION_DENIED,
        "Permission to open live wallpaper preview was denied.",
        error.message,
      )
    } catch (error: Exception) {
      OperationResultPolicy.failed(
        target,
        ERROR_SYSTEM_UI_FAILED,
        "Unable to open live wallpaper preview.",
        error.message,
      )
    }
  }

  private fun promoteVideoAsset(
    target: WallpaperTargetData,
    scaleMode: WallpaperScaleModeData,
  ): OperationResultData? {
    val videoScaleMode = when (scaleMode) {
      WallpaperScaleModeData.CENTER_CROP -> VideoWallpaperScaleMode.CENTER_CROP
      WallpaperScaleModeData.FIT_CENTER -> VideoWallpaperScaleMode.FIT_CENTER
      else -> return OperationResultPolicy.unsupported(
        target,
        ERROR_VIDEO_SCALE_UNSUPPORTED,
        "Video live wallpapers support only centerCrop and fitCenter scaling.",
      )
    }
    return try {
      videoRepository.promotePending(videoScaleMode)
      null
    } catch (error: VideoMetadataValidationException) {
      OperationResultPolicy.failed(
        target,
        videoValidationCode(error),
        error.message ?: "The video source is not playable.",
      )
    } catch (error: IOException) {
      OperationResultPolicy.failed(
        target,
        ERROR_VIDEO_PREPARATION_FAILED,
        "Unable to prepare the video wallpaper.",
        error.message,
      )
    } catch (error: Exception) {
      OperationResultPolicy.failed(
        target,
        ERROR_VIDEO_PREPARATION_FAILED,
        "Unable to prepare the video wallpaper.",
        error.message,
      )
    }
  }

  private fun prepareAndOpenOpenGlWallpaper(request: OpenGlWallpaperRequestData): OperationResultData {
    val target = request.target
      ?: return OperationResultPolicy.failed(
        WallpaperTargetData.HOME,
        ERROR_INVALID_REQUEST,
        "An OpenGL wallpaper target is required.",
      )
    val fragmentShader = request.fragmentShader
      ?: return OperationResultPolicy.failed(target, ERROR_INVALID_REQUEST, "A fragment shader is required.")
    val frameRate = request.frameRate
      ?: return OperationResultPolicy.failed(target, ERROR_INVALID_REQUEST, "A frame rate is required.")
    val textures = request.textures
      ?: return OperationResultPolicy.failed(target, ERROR_INVALID_REQUEST, "A texture list is required.")
    if (frameRate !in ShaderProgramValidator.MIN_FRAME_RATE..ShaderProgramValidator.MAX_FRAME_RATE) {
      return OperationResultPolicy.failed(
        target,
        ShaderProgramValidator.ErrorCode.FRAME_RATE_OUT_OF_RANGE.wireCode,
        "Frame rate must be between ${ShaderProgramValidator.MIN_FRAME_RATE} and " +
          "${ShaderProgramValidator.MAX_FRAME_RATE} FPS.",
      )
    }
    if (!AndroidCapabilities.hasOpenGlLiveWallpaper(appContext)) {
      return OperationResultPolicy.unsupported(
        target,
        ERROR_OPENGL_WALLPAPER_UNSUPPORTED,
        "This device cannot open this app's OpenGL live wallpaper flow.",
      )
    }

    val textureSources = try {
      textures.mapIndexed { index, source ->
        source ?: throw BoundedSourceException(
          BoundedSourceOpener.ERROR_INVALID_SOURCE,
          "Texture $index is missing.",
        )
        textureSourceFor(source)
      }
    } catch (error: BoundedSourceException) {
      return OperationResultPolicy.failed(
        target,
        error.code,
        error.message ?: "Unable to read an OpenGL texture source.",
      )
    } catch (error: Exception) {
      return OperationResultPolicy.failed(
        target,
        ERROR_OPENGL_CONFIGURATION_FAILED,
        "Unable to prepare OpenGL texture sources.",
        error.message,
      )
    }

    val configuration = OpenGlWallpaperConfiguration(
      fragmentShader = fragmentShader,
      textures = textureSources,
      frameRate = frameRate.toInt(),
    )
    when (val saved = OpenGlLiveWallpaper.saveConfiguration(appContext, configuration)) {
      OpenGlConfigurationResult.Saved -> Unit
      is OpenGlConfigurationResult.Rejected -> {
        return OperationResultPolicy.failed(
          target,
          saved.error.wireCode,
          saved.error.message,
        )
      }
    }

    return runOnMainBlocking {
      openLiveWallpaperUi(target, OpenGlLiveWallpaper::class.java)
    }
  }

  private fun textureSourceFor(source: WallpaperSourceData): GlTextureSource {
    return when (source.kind ?: throw BoundedSourceException(
      BoundedSourceOpener.ERROR_INVALID_SOURCE,
      "A texture source kind is required.",
    )) {
      WallpaperSourceKindData.URL -> GlTextureSource.Bytes(textureSourceOpener.readBytes(source))
      WallpaperSourceKindData.FILE_PATH -> {
        val path = source.filePath?.trim()?.takeIf { it.isNotEmpty() }
          ?: throw BoundedSourceException(BoundedSourceOpener.ERROR_INVALID_SOURCE, "A texture file path is required.")
        GlTextureSource.FilePath(path)
      }
      WallpaperSourceKindData.CONTENT_URI -> {
        val uri = source.contentUri?.trim()?.takeIf { it.isNotEmpty() }
          ?: throw BoundedSourceException(BoundedSourceOpener.ERROR_INVALID_SOURCE, "A texture content URI is required.")
        val parsed = uri.toUri()
        if (!parsed.scheme.equals("content", ignoreCase = true) || parsed.authority.isNullOrBlank()) {
          throw BoundedSourceException(
            BoundedSourceOpener.ERROR_INVALID_SOURCE,
            "Texture content sources must use a content URI.",
          )
        }
        GlTextureSource.ContentUri(uri)
      }
      WallpaperSourceKindData.BYTES -> {
        val bytes = source.bytes
          ?: throw BoundedSourceException(BoundedSourceOpener.ERROR_INVALID_SOURCE, "Texture bytes are required.")
        if (bytes.isEmpty()) {
          throw BoundedSourceException(BoundedSourceOpener.ERROR_INVALID_SOURCE, "Texture bytes must not be empty.")
        }
        if (bytes.size.toLong() > ShaderProgramValidator.MAX_TEXTURE_SOURCE_BYTES) {
          throw BoundedSourceException(
            BoundedSourceOpener.ERROR_SOURCE_TOO_LARGE,
            "Texture bytes exceed the configured byte limit.",
          )
        }
        GlTextureSource.Bytes(bytes)
      }
    }
  }

  private fun downloadToMediaStore(url: String): Boolean {
    var uri: Uri? = null
    var temporaryFile: File? = null
    var completed = false
    return try {
      if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
        appContext.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
        PackageManager.PERMISSION_GRANTED
      ) {
        Log.e(
          TAG,
          "downloadWallpaper needs WRITE_EXTERNAL_STORAGE on Android 9 and older; " +
            "the host app must declare it with maxSdkVersion 28 and request it at runtime.",
        )
        return false
      }
      val source = WallpaperSourceData(kind = WallpaperSourceKindData.URL, url = url)
      val openedSource = downloadSourceOpener.openWithMetadata(source)
      val contentType = openedSource.contentType
      val downloadedFile = File.createTempFile("async-wallpaper-", ".download", appContext.cacheDir)
      temporaryFile = downloadedFile
      openedSource.use { opened ->
        downloadedFile.outputStream().use { output ->
          opened.input.copyTo(output)
        }
      }
      val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
      BitmapFactory.decodeFile(downloadedFile.absolutePath, options)
      val imageFormat = if (options.outWidth > 0 && options.outHeight > 0) {
        DownloadImageFormat.choose(options.outMimeType, contentType)
      } else {
        null
      } ?: return false
      // A header can report valid dimensions for a truncated file, so decode once with a bounded
      // sample size to prove the payload is a complete image before publishing it.
      val decoded = BitmapFactory.decodeFile(
        downloadedFile.absolutePath,
        BitmapFactory.Options().apply {
          inSampleSize = WallpaperSourceLoader.calculateInSampleSize(
            options.outWidth,
            options.outHeight,
            MAX_DOWNLOAD_DECODED_PIXELS,
          )
          inPreferredConfig = Bitmap.Config.ARGB_8888
        },
      ) ?: return false
      decoded.recycle()
      val values = ContentValues().apply {
        put(
          MediaStore.Images.Media.DISPLAY_NAME,
          "wallpaper_${System.currentTimeMillis()}.${imageFormat.extension}",
        )
        put(MediaStore.Images.Media.MIME_TYPE, imageFormat.mimeType)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
          put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/AsyncWallpaper")
          put(MediaStore.Images.Media.IS_PENDING, 1)
        }
      }
      val resolver = appContext.contentResolver
      uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return false
      val written = downloadedFile.inputStream().use { input ->
        resolver.openOutputStream(uri!!)?.use { output ->
          input.copyTo(output)
          true
        } ?: false
      }
      if (!written) {
        return false
      }
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        val updatedRows = resolver.update(
          uri!!,
          ContentValues().apply { put(MediaStore.Images.Media.IS_PENDING, 0) },
          null,
          null,
        )
        if (updatedRows == 0) {
          return false
        }
      }
      completed = true
      true
    } catch (error: Exception) {
      Log.e(TAG, "downloadWallpaper failed", error)
      false
    } finally {
      // Do not leave an abandoned, user-visible pending record if writing failed midway.
      if (!completed && uri != null) {
        runCatching { appContext.contentResolver.delete(uri!!, null, null) }
      }
      temporaryFile?.delete()
    }
  }

  private fun enqueueOperation(
    requestedTarget: WallpaperTargetData?,
    callback: (Result<OperationResultData>) -> Unit,
    operation: () -> OperationResultData,
  ) {
    operationQueue.submit(operation) { result ->
      val data = result.getOrElse { error -> operationFailure(requestedTarget, error) }
      postCallback(callback, Result.success(data))
    }
  }

  private fun enqueueBoolean(
    callback: (Result<Boolean>) -> Unit,
    operation: () -> Boolean,
  ) {
    operationQueue.submit(operation) { result ->
      postCallback(callback, Result.success(result.getOrDefault(false)))
    }
  }


  private fun <T> postCallback(callback: (Result<T>) -> Unit, result: Result<T>) {
    if (Looper.myLooper() == Looper.getMainLooper()) {
      callback(result)
      return
    }
    if (!mainHandler.post { callback(result) }) {
      // Handler rejection means there is no main queue to marshal onto; do not lose the exactly
      // once Pigeon reply. BasicMessageChannel accepts replies from a background thread.
      callback(result)
    }
  }

  private fun operationFailure(
    requestedTarget: WallpaperTargetData?,
    error: Throwable,
  ): OperationResultData {
    val target = requestedTarget ?: WallpaperTargetData.HOME
    return when (error) {
      is OperationQueueShutdownException -> OperationResultPolicy.failed(
        target,
        ERROR_QUEUE_SHUTDOWN,
        "The wallpaper operation queue is no longer available.",
      )
      is MainThreadUnavailableException -> OperationResultPolicy.foregroundRequired(target)
      is BoundedSourceException -> OperationResultPolicy.failed(target, error.code, error.message ?: "Unable to read the source.")
      is WallpaperSourceException -> OperationResultPolicy.failed(target, error.code, error.message ?: "Unable to read the source.")
      is SecurityException -> OperationResultPolicy.failed(target, ERROR_PERMISSION_DENIED, "Permission was denied.", error.message)
      is OutOfMemoryError -> OperationResultPolicy.failed(target, ERROR_OUT_OF_MEMORY, "The operation exceeded available memory.")
      else -> OperationResultPolicy.failed(target, ERROR_OPERATION_FAILED, "The wallpaper operation failed.", error.message)
    }
  }

  private fun <T> runOnMainBlocking(operation: () -> T): T {
    if (Looper.myLooper() == Looper.getMainLooper()) {
      return operation()
    }
    val latch = CountDownLatch(1)
    val gate = MainThreadOperationGate()
    var result: Result<T>? = null
    val runnable = Runnable {
      if (!gate.begin()) {
        return@Runnable
      }
      try {
        result = runCatching(operation)
      } finally {
        gate.complete()
        latch.countDown()
      }
    }
    if (!mainHandler.post(runnable)) {
      gate.cancelBeforeStart()
      throw MainThreadUnavailableException()
    }
    var interruptedWhileWaiting = false
    val completedWithinTimeout = try {
      latch.await(MAIN_THREAD_WAIT_MILLIS, TimeUnit.MILLISECONDS)
    } catch (_: InterruptedException) {
      interruptedWhileWaiting = true
      false
    }
    if (!completedWithinTimeout) {
      mainHandler.removeCallbacks(runnable)
      if (gate.cancelBeforeStart()) {
        if (interruptedWhileWaiting) {
          Thread.currentThread().interrupt()
        }
        throw MainThreadUnavailableException()
      }
      // The main-thread action began before timeout. Wait for that action to finish rather than
      // replying first and allowing a delayed system UI launch or mutation afterward.
      awaitMainOperationCompletion(latch)
    }
    if (interruptedWhileWaiting) {
      Thread.currentThread().interrupt()
    }
    return result?.getOrThrow() ?: throw MainThreadUnavailableException()
  }

  private fun awaitMainOperationCompletion(latch: CountDownLatch) {
    var interrupted = false
    while (true) {
      try {
        latch.await()
        break
      } catch (_: InterruptedException) {
        interrupted = true
      }
    }
    if (interrupted) {
      Thread.currentThread().interrupt()
    }
  }

  private fun currentActivity(): Activity? {
    val reference = activityReference
    val activity = reference?.get()
    if (!activity.isUsable()) {
      // Do not erase a newer Activity attached during a configuration change while a queued
      // operation was checking an older weak reference.
      if (activityReference === reference) {
        activityReference = null
      }
      return null
    }
    return activity
  }

  private fun videoValidationCode(error: VideoMetadataValidationException): String {
    return when (error.failure) {
      VideoValidationFailure.MISSING_FILE -> BoundedSourceOpener.ERROR_SOURCE_UNAVAILABLE
      VideoValidationFailure.INVALID_MIME_TYPE -> WallpaperSourceLoader.ERROR_INVALID_CONTENT_TYPE
      VideoValidationFailure.NO_VIDEO_TRACK,
      VideoValidationFailure.INVALID_DIMENSIONS,
      VideoValidationFailure.INVALID_ROTATION,
      VideoValidationFailure.INVALID_DURATION,
      -> ERROR_INVALID_VIDEO
      VideoValidationFailure.RETRIEVER_FAILURE -> ERROR_VIDEO_PREPARATION_FAILED
    }
  }

  private class MainThreadUnavailableException : IllegalStateException()

  companion object {
    private const val TAG = "AsyncWallpaper"
    private const val MAX_VIDEO_SOURCE_BYTES = 256L * 1024L * 1024L
    /** Generous bound for one downloaded wallpaper; validation still happens from a temp file. */
    private const val MAX_DOWNLOAD_SOURCE_BYTES = 64L * 1024L * 1024L
    private const val MAX_DOWNLOAD_DECODED_PIXELS = 16L * 1024L * 1024L
    private const val MAIN_THREAD_WAIT_MILLIS = 10_000L

    private const val ERROR_INVALID_REQUEST = "invalid-request"
    private const val ERROR_PERMISSION_DENIED = "permission-denied"
    private const val ERROR_OUT_OF_MEMORY = "out-of-memory"
    private const val ERROR_OPERATION_FAILED = "operation-failed"
    private const val ERROR_QUEUE_SHUTDOWN = "queue-shutdown"
    private const val ERROR_LIVE_WALLPAPER_UNSUPPORTED = "live-wallpaper-unsupported"
    private const val ERROR_OPENGL_WALLPAPER_UNSUPPORTED = "opengl-live-wallpaper-unsupported"
    private const val ERROR_VIDEO_PREPARATION_FAILED = "video-preparation-failed"
    private const val ERROR_INVALID_VIDEO = "invalid-video"
    private const val ERROR_VIDEO_SCALE_UNSUPPORTED = "video-scale-unsupported"
    private const val ERROR_OPENGL_CONFIGURATION_FAILED = "opengl-configuration-failed"
    private const val ERROR_SYSTEM_UI_UNAVAILABLE = "system-ui-unavailable"
    private const val ERROR_SYSTEM_UI_FAILED = "system-ui-failed"
  }
}
