package com.codenameakshay.async_wallpaper

import android.app.Activity
import android.app.WallpaperManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Rect
import android.net.Uri
import kotlin.concurrent.withLock

/**
 * Applies a structured static-wallpaper request without requiring a foreground Activity for the
 * direct path. System UI strategies are intentionally kept separate from bitmap application so
 * their caller can dispatch them on the main thread with a current Activity.
 */
class StaticWallpaperEngine(
  context: Context,
  private val sourceLoader: WallpaperSourceLoader = WallpaperSourceLoader(context.applicationContext),
  private val wallpaperManagerProvider: () -> WallpaperManager = {
    WallpaperManager.getInstance(context.applicationContext)
  },
) {
  private val appContext = context.applicationContext

  /** Applies [request] directly, returning structured failures instead of throwing. */
  fun applyDirect(request: StaticWallpaperRequestData): OperationResultData {
    val validated = validate(request) ?: return invalidRequest(request.target)
    return when (validated.strategy) {
      WallpaperApplyStrategyData.SYSTEM_CROPPER,
      WallpaperApplyStrategyData.SYSTEM_PICKER,
      -> OperationResultPolicy.failed(
        validated.target,
        code = ERROR_UI_STRATEGY_REQUIRES_FOREGROUND,
        message = "The requested system UI strategy must run with a foreground Activity.",
      )
      WallpaperApplyStrategyData.DIRECT,
      WallpaperApplyStrategyData.AUTOMATIC,
      -> applyBitmap(validated)
    }
  }

  /**
   * Opens Android's crop-and-set flow. It never reports an applied wallpaper because control is
   * handed to the system UI after this method returns.
   */
  fun openSystemCropper(
    request: StaticWallpaperRequestData,
    activity: Activity?,
  ): OperationResultData {
    val validated = validate(request) ?: return invalidRequest(request.target)
    if (validated.strategy != WallpaperApplyStrategyData.SYSTEM_CROPPER) {
      return OperationResultPolicy.failed(
        validated.target,
        code = ERROR_INVALID_REQUEST,
        message = "The system cropper can only be used with the systemCropper strategy.",
      )
    }
    val liveActivity = activity.takeIf { it.isUsable() }
      ?: return OperationResultPolicy.foregroundRequired(validated.target)
    val uri = validated.source.contentUri
      ?.takeIf { validated.source.kind == WallpaperSourceKindData.CONTENT_URI }
      ?.let(Uri::parse)
      ?.takeIf { it.scheme.equals(CONTENT_SCHEME, ignoreCase = true) && !it.authority.isNullOrBlank() }
      ?: return OperationResultPolicy.failed(
        validated.target,
        code = ERROR_SYSTEM_CROPPER_REQUIRES_CONTENT_URI,
        message = "The system cropper requires a readable content URI source.",
      )
    val mimeType = try {
      appContext.contentResolver.getType(uri)
    } catch (_: SecurityException) {
      null
    }
    cropperSourceError(mimeType)?.let { (code, message) ->
      return OperationResultPolicy.failed(validated.target, code = code, message = message)
    }

    return try {
      val intent = wallpaperManagerProvider().getCropAndSetWallpaperIntent(uri)
      val resolvedIntent = AndroidCapabilities.resolveExplicit(liveActivity.packageManager, intent)
      if (resolvedIntent == null) {
        OperationResultPolicy.failed(
          validated.target,
          code = ERROR_SYSTEM_UI_UNAVAILABLE,
          message = "This device has no app that can crop and set wallpapers.",
        )
      } else {
        liveActivity.startActivity(resolvedIntent)
        OperationResultPolicy.previewOpened(validated.target)
      }
    } catch (_: ActivityNotFoundException) {
      OperationResultPolicy.failed(
        validated.target,
        code = ERROR_SYSTEM_UI_UNAVAILABLE,
        message = "This device has no app that can crop and set wallpapers.",
      )
    } catch (error: SecurityException) {
      OperationResultPolicy.failed(
        validated.target,
        code = ERROR_PERMISSION_DENIED,
        message = "Permission to open the wallpaper cropper was denied.",
        details = error.message,
      )
    } catch (error: Exception) {
      OperationResultPolicy.failed(
        validated.target,
        code = ERROR_SYSTEM_UI_FAILED,
        message = "Unable to open the wallpaper cropper.",
        details = error.message,
      )
    }
  }

  /** Opens the system wallpaper picker and reports only that user confirmation is outstanding. */
  fun openSystemPicker(
    request: StaticWallpaperRequestData,
    activity: Activity?,
  ): OperationResultData {
    val validated = validate(request) ?: return invalidRequest(request.target)
    if (validated.strategy != WallpaperApplyStrategyData.SYSTEM_PICKER) {
      return OperationResultPolicy.failed(
        validated.target,
        code = ERROR_INVALID_REQUEST,
        message = "The system picker can only be used with the systemPicker strategy.",
      )
    }
    val liveActivity = activity.takeIf { it.isUsable() }
      ?: return OperationResultPolicy.foregroundRequired(validated.target)
    val intent = Intent(Intent.ACTION_SET_WALLPAPER)
    return try {
      val resolvedIntent = AndroidCapabilities.resolveExplicit(liveActivity.packageManager, intent)
      if (resolvedIntent == null) {
        OperationResultPolicy.failed(
          validated.target,
          code = ERROR_SYSTEM_UI_UNAVAILABLE,
          message = "This device has no system wallpaper picker.",
        )
      } else {
        liveActivity.startActivity(resolvedIntent)
        OperationResultPolicy.awaitingUserConfirmation(validated.target)
      }
    } catch (_: ActivityNotFoundException) {
      OperationResultPolicy.failed(
        validated.target,
        code = ERROR_SYSTEM_UI_UNAVAILABLE,
        message = "This device has no system wallpaper picker.",
      )
    } catch (error: SecurityException) {
      OperationResultPolicy.failed(
        validated.target,
        code = ERROR_PERMISSION_DENIED,
        message = "Permission to open the system wallpaper picker was denied.",
        details = error.message,
      )
    } catch (error: Exception) {
      OperationResultPolicy.failed(
        validated.target,
        code = ERROR_SYSTEM_UI_FAILED,
        message = "Unable to open the system wallpaper picker.",
        details = error.message,
      )
    }
  }

  /** Rejects malformed nested Pigeon data before any Android or bitmap work starts. */
  fun validate(request: StaticWallpaperRequestData): ValidatedStaticWallpaperRequest? {
    val source = request.source ?: return null
    val target = request.target ?: return null
    val scaleMode = request.scaleMode ?: return null
    val strategy = request.strategy ?: return null
    if (!source.hasValueForKind()) {
      return null
    }
    return ValidatedStaticWallpaperRequest(source, target, scaleMode, strategy)
  }

  private fun applyBitmap(request: ValidatedStaticWallpaperRequest): OperationResultData {
    val capability = AndroidCapabilities.staticWallpaperSupport(appContext)
    if (!capability.wallpaperSupported) {
      return OperationResultPolicy.unsupported(
        request.target,
        code = ERROR_WALLPAPER_UNSUPPORTED,
        message = "This device does not support static wallpapers.",
      )
    }
    if (!capability.settingAllowed) {
      return OperationResultPolicy.unsupported(
        request.target,
        code = ERROR_WALLPAPER_NOT_ALLOWED,
        message = "Wallpaper changes are restricted on this device.",
      )
    }

    var sourceBitmap: Bitmap? = null
    var transformedBitmap: Bitmap? = null
    return try {
      sourceBitmap = sourceLoader.load(request.source)
      val (width, height) = BitmapTransformer.wallpaperCanvasSize(appContext)
      transformedBitmap = BitmapTransformer.transform(
        bitmap = sourceBitmap,
        mode = request.scaleMode,
        targetWidth = width,
        targetHeight = height,
      )
      applyTransformedBitmap(request.target, transformedBitmap)
    } catch (error: WallpaperSourceException) {
      OperationResultPolicy.failed(
        request.target,
        code = error.code,
        message = error.message ?: "Unable to load the wallpaper source.",
      )
    } catch (error: SecurityException) {
      OperationResultPolicy.failed(
        request.target,
        code = ERROR_PERMISSION_DENIED,
        message = "Permission to set the wallpaper was denied.",
        details = error.message,
      )
    } catch (error: OutOfMemoryError) {
      OperationResultPolicy.failed(
        request.target,
        code = ERROR_OUT_OF_MEMORY,
        message = "The wallpaper image could not be transformed within available memory.",
      )
    } catch (error: Exception) {
      OperationResultPolicy.failed(
        request.target,
        code = ERROR_WALLPAPER_APPLY_FAILED,
        message = "Unable to apply the static wallpaper.",
        details = error.message,
      )
    } finally {
      transformedBitmap.recycleOwned(except = sourceBitmap)
      sourceBitmap.recycleOwned()
    }
  }

  private fun applyTransformedBitmap(
    target: WallpaperTargetData,
    bitmap: Bitmap,
  ): OperationResultData {
    return when (target) {
      WallpaperTargetData.HOME -> applyOne(target, bitmap, WallpaperManager.FLAG_SYSTEM)
      WallpaperTargetData.LOCK -> applyOne(target, bitmap, WallpaperManager.FLAG_LOCK)
      WallpaperTargetData.BOTH -> applyBoth(bitmap)
    }
  }

  private fun applyOne(
    target: WallpaperTargetData,
    bitmap: Bitmap,
    flag: Int,
  ): OperationResultData {
    return try {
      setBitmap(bitmap, flag)
      OperationResultPolicy.applied(target)
    } catch (error: Exception) {
      OperationResultPolicy.failed(
        target,
        code = errorCodeForApply(error),
        message = "Unable to apply the requested wallpaper target.",
        details = error.message,
      )
    }
  }

  /**
   * Android accepts a combined flag on supported devices. If that request fails, retry the two
   * targets in this same serialized operation. The result retains any partial mutation instead of
   * reporting a false all-or-nothing success.
   */
  private fun applyBoth(bitmap: Bitmap): OperationResultData {
    // Hold the mutation lock across the combined attempt and the two-target fallback so another
    // engine or a rotation pass cannot land a write between the home and lock set.
    return wallpaperMutationLock.withLock {
      try {
        setBitmap(bitmap, WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK)
        OperationResultPolicy.applied(WallpaperTargetData.BOTH)
      } catch (combinedError: Exception) {
        val home = applyTargetResult(bitmap, WallpaperManager.FLAG_SYSTEM)
        val lock = applyTargetResult(bitmap, WallpaperManager.FLAG_LOCK)
        OperationResultPolicy.fromTargetResults(
          requestedTarget = WallpaperTargetData.BOTH,
          home = home,
          lock = lock,
          fallbackUsed = true,
          fallbackStrategy = WallpaperApplyStrategyData.DIRECT,
          combinedError = combinedError,
        )
      }
    }
  }

  private fun applyTargetResult(bitmap: Bitmap, flag: Int): TargetResultData {
    return try {
      setBitmap(bitmap, flag)
      OperationResultPolicy.appliedTarget()
    } catch (error: Exception) {
      OperationResultPolicy.failedTarget(
        code = errorCodeForApply(error),
        message = "Unable to apply the requested wallpaper target.",
        details = error.message,
      )
    }
  }

  private fun setBitmap(bitmap: Bitmap, flag: Int) {
    wallpaperMutationLock.withLock {
      wallpaperManagerProvider().setBitmap(
        bitmap,
        Rect(0, 0, bitmap.width, bitmap.height),
        true,
        flag,
      )
    }
  }

  private fun invalidRequest(target: WallpaperTargetData?): OperationResultData {
    return OperationResultPolicy.failed(
      target ?: WallpaperTargetData.HOME,
      code = ERROR_INVALID_REQUEST,
      message = "A complete static wallpaper source, target, scale mode, and strategy are required.",
    )
  }

  private fun errorCodeForApply(error: Exception): String {
    return when (error) {
      is SecurityException -> ERROR_PERMISSION_DENIED
      is IllegalArgumentException -> ERROR_INVALID_REQUEST
      else -> ERROR_WALLPAPER_APPLY_FAILED
    }
  }

  private fun Bitmap?.recycleOwned(except: Bitmap? = null) {
    if (this != null && this !== except && !isRecycled) {
      recycle()
    }
  }

  data class ValidatedStaticWallpaperRequest(
    val source: WallpaperSourceData,
    val target: WallpaperTargetData,
    val scaleMode: WallpaperScaleModeData,
    val strategy: WallpaperApplyStrategyData,
  )

  companion object {
    const val ERROR_INVALID_REQUEST = "invalid-request"
    const val ERROR_WALLPAPER_UNSUPPORTED = "wallpaper-unsupported"
    const val ERROR_WALLPAPER_NOT_ALLOWED = "wallpaper-not-allowed"
    const val ERROR_WALLPAPER_APPLY_FAILED = "wallpaper-apply-failed"
    const val ERROR_PERMISSION_DENIED = "permission-denied"
    const val ERROR_OUT_OF_MEMORY = "out-of-memory"
    const val ERROR_UI_STRATEGY_REQUIRES_FOREGROUND = "ui-strategy-requires-foreground"
    const val ERROR_SYSTEM_CROPPER_REQUIRES_CONTENT_URI = "system-cropper-requires-content-uri"
    const val ERROR_SYSTEM_UI_UNAVAILABLE = "system-ui-unavailable"
    const val ERROR_SYSTEM_UI_FAILED = "system-ui-failed"

    /**
     * Android resolves the crop intent by the URI's MIME type, so an unreadable URI or a non-image
     * type would otherwise fail as a generic "unable to open the cropper".
     */
    internal fun cropperSourceError(mimeType: String?): Pair<String, String>? = when {
      mimeType == null ->
        WallpaperSourceLoader.ERROR_SOURCE_UNAVAILABLE to "The content URI could not be read."
      !mimeType.startsWith("image/", ignoreCase = true) ->
        WallpaperSourceLoader.ERROR_INVALID_CONTENT_TYPE to "The content URI does not identify an image."
      else -> null
    }

    private const val CONTENT_SCHEME = "content"
  }
}

/**
 * Centralized result construction so partial and unsupported outcomes are reported per target
 * instead of collapsed into one boolean. It is platform-independent so the contract is covered by
 * regular JVM unit tests.
 */
object OperationResultPolicy {
  const val ERROR_FOREGROUND_REQUIRED = "foreground-required"
  const val ERROR_PARTIAL_APPLY = "partial-apply"

  fun applied(target: WallpaperTargetData): OperationResultData {
    return OperationResultData(
      status = OperationStatusData.APPLIED,
      requestedTarget = target,
      home = if (target.requestsHome()) appliedTarget() else null,
      lock = if (target.requestsLock()) appliedTarget() else null,
      fallbackUsed = false,
    )
  }

  fun previewOpened(target: WallpaperTargetData): OperationResultData = pendingResult(
    status = OperationStatusData.PREVIEW_OPENED,
    target = target,
  )

  fun awaitingUserConfirmation(target: WallpaperTargetData): OperationResultData = pendingResult(
    status = OperationStatusData.AWAITING_USER_CONFIRMATION,
    target = target,
  )

  fun foregroundRequired(target: WallpaperTargetData): OperationResultData = OperationResultData(
    status = OperationStatusData.FOREGROUND_REQUIRED,
    requestedTarget = target,
    home = if (target.requestsHome()) notAttemptedTarget() else null,
    lock = if (target.requestsLock()) notAttemptedTarget() else null,
    errorCode = ERROR_FOREGROUND_REQUIRED,
    errorMessage = "A live foreground Activity is required to open system wallpaper UI.",
    fallbackUsed = false,
  )

  fun unsupported(
    target: WallpaperTargetData,
    code: String,
    message: String,
    details: String? = null,
  ): OperationResultData = OperationResultData(
    status = OperationStatusData.UNSUPPORTED,
    requestedTarget = target,
    home = if (target.requestsHome()) unsupportedTarget(code, message, details) else null,
    lock = if (target.requestsLock()) unsupportedTarget(code, message, details) else null,
    errorCode = code,
    errorMessage = message,
    errorDetails = details,
    fallbackUsed = false,
  )

  fun failed(
    target: WallpaperTargetData,
    code: String,
    message: String,
    details: String? = null,
  ): OperationResultData = OperationResultData(
    status = OperationStatusData.FAILED,
    requestedTarget = target,
    home = if (target.requestsHome()) failedTarget(code, message, details) else null,
    lock = if (target.requestsLock()) failedTarget(code, message, details) else null,
    errorCode = code,
    errorMessage = message,
    errorDetails = details,
    fallbackUsed = false,
  )

  /** Produces an all-applied result only when every requested target actually succeeded. */
  fun fromTargetResults(
    requestedTarget: WallpaperTargetData,
    home: TargetResultData?,
    lock: TargetResultData?,
    fallbackUsed: Boolean,
    fallbackStrategy: WallpaperApplyStrategyData?,
    combinedError: Exception? = null,
  ): OperationResultData {
    val allApplied = (!requestedTarget.requestsHome() || home?.status == TargetStatusData.APPLIED) &&
      (!requestedTarget.requestsLock() || lock?.status == TargetStatusData.APPLIED)
    if (allApplied) {
      return OperationResultData(
        status = OperationStatusData.APPLIED,
        requestedTarget = requestedTarget,
        home = home,
        lock = lock,
        fallbackUsed = fallbackUsed,
        fallbackStrategy = fallbackStrategy,
      )
    }

    val firstFailure = listOfNotNull(
      home?.takeIf { it.status != TargetStatusData.APPLIED },
      lock?.takeIf { it.status != TargetStatusData.APPLIED },
    ).firstOrNull()
    return OperationResultData(
      status = OperationStatusData.FAILED,
      requestedTarget = requestedTarget,
      home = home,
      lock = lock,
      errorCode = if (home?.status == TargetStatusData.APPLIED || lock?.status == TargetStatusData.APPLIED) {
        ERROR_PARTIAL_APPLY
      } else {
        firstFailure?.errorCode ?: ERROR_PARTIAL_APPLY
      },
      errorMessage = if (home?.status == TargetStatusData.APPLIED || lock?.status == TargetStatusData.APPLIED) {
        "Only some requested wallpaper targets were applied."
      } else {
        firstFailure?.errorMessage ?: "Unable to apply the requested wallpaper targets."
      },
      errorDetails = combinedError?.message ?: firstFailure?.errorDetails,
      fallbackUsed = fallbackUsed,
      fallbackStrategy = fallbackStrategy,
    )
  }

  fun appliedTarget(): TargetResultData = TargetResultData(status = TargetStatusData.APPLIED)

  fun failedTarget(
    code: String,
    message: String,
    details: String? = null,
  ): TargetResultData = TargetResultData(
    status = TargetStatusData.FAILED,
    errorCode = code,
    errorMessage = message,
    errorDetails = details,
  )

  fun unsupportedTarget(
    code: String,
    message: String,
    details: String? = null,
  ): TargetResultData = TargetResultData(
    status = TargetStatusData.UNSUPPORTED,
    errorCode = code,
    errorMessage = message,
    errorDetails = details,
  )

  fun notAttemptedTarget(): TargetResultData = TargetResultData(status = TargetStatusData.NOT_ATTEMPTED)

  private fun pendingResult(
    status: OperationStatusData,
    target: WallpaperTargetData,
  ): OperationResultData = OperationResultData(
    status = status,
    requestedTarget = target,
    home = if (target.requestsHome()) notAttemptedTarget() else null,
    lock = if (target.requestsLock()) notAttemptedTarget() else null,
    fallbackUsed = false,
  )

  private fun WallpaperTargetData.requestsHome(): Boolean {
    return this == WallpaperTargetData.HOME || this == WallpaperTargetData.BOTH
  }

  private fun WallpaperTargetData.requestsLock(): Boolean {
    return this == WallpaperTargetData.LOCK || this == WallpaperTargetData.BOTH
  }
}
