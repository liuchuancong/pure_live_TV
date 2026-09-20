package com.codenameakshay.async_wallpaper

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Test

class ResultContractTest {
  @Test
  fun `cropper reports an unreadable or non-image content URI as a source error`() {
    assertEquals(
      WallpaperSourceLoader.ERROR_SOURCE_UNAVAILABLE,
      StaticWallpaperEngine.cropperSourceError(null)?.first,
    )
    assertEquals(
      WallpaperSourceLoader.ERROR_INVALID_CONTENT_TYPE,
      StaticWallpaperEngine.cropperSourceError("video/mp4")?.first,
    )
    assertEquals(null, StaticWallpaperEngine.cropperSourceError("image/jpeg"))
  }

  @Test
  fun `partial both fallback retains the successful target but never reports applied`() {
    val result = OperationResultPolicy.fromTargetResults(
      requestedTarget = WallpaperTargetData.BOTH,
      home = OperationResultPolicy.appliedTarget(),
      lock = OperationResultPolicy.failedTarget("wallpaper-apply-failed", "lock failed"),
      fallbackUsed = true,
      fallbackStrategy = WallpaperApplyStrategyData.DIRECT,
    )

    assertEquals(OperationStatusData.FAILED, result.status)
    assertNotEquals(OperationStatusData.APPLIED, result.status)
    assertEquals(TargetStatusData.APPLIED, result.home?.status)
    assertEquals(TargetStatusData.FAILED, result.lock?.status)
    assertEquals(OperationResultPolicy.ERROR_PARTIAL_APPLY, result.errorCode)
    assertEquals(true, result.fallbackUsed)
    assertEquals(WallpaperApplyStrategyData.DIRECT, result.fallbackStrategy)
  }

  @Test
  fun `combined fallback can report applied only after every requested target succeeds`() {
    val result = OperationResultPolicy.fromTargetResults(
      requestedTarget = WallpaperTargetData.BOTH,
      home = OperationResultPolicy.appliedTarget(),
      lock = OperationResultPolicy.appliedTarget(),
      fallbackUsed = true,
      fallbackStrategy = WallpaperApplyStrategyData.DIRECT,
    )

    assertEquals(OperationStatusData.APPLIED, result.status)
    assertEquals(TargetStatusData.APPLIED, result.home?.status)
    assertEquals(TargetStatusData.APPLIED, result.lock?.status)
    assertEquals(true, result.fallbackUsed)
  }

  @Test
  fun `unsupported or restricted target never claims an applied wallpaper`() {
    val result = OperationResultPolicy.unsupported(
      WallpaperTargetData.BOTH,
      code = StaticWallpaperEngine.ERROR_WALLPAPER_NOT_ALLOWED,
      message = "Wallpaper changes are restricted.",
    )

    assertEquals(OperationStatusData.UNSUPPORTED, result.status)
    assertEquals(TargetStatusData.UNSUPPORTED, result.home?.status)
    assertEquals(TargetStatusData.UNSUPPORTED, result.lock?.status)
    assertFalse(result.home?.status == TargetStatusData.APPLIED)
    assertFalse(result.lock?.status == TargetStatusData.APPLIED)
  }

  @Test
  fun `system UI outcomes leave every requested target not attempted`() {
    val preview = OperationResultPolicy.previewOpened(WallpaperTargetData.BOTH)
    val awaiting = OperationResultPolicy.awaitingUserConfirmation(WallpaperTargetData.HOME)

    assertEquals(OperationStatusData.PREVIEW_OPENED, preview.status)
    assertEquals(TargetStatusData.NOT_ATTEMPTED, preview.home?.status)
    assertEquals(TargetStatusData.NOT_ATTEMPTED, preview.lock?.status)
    assertEquals(OperationStatusData.AWAITING_USER_CONFIRMATION, awaiting.status)
    assertEquals(TargetStatusData.NOT_ATTEMPTED, awaiting.home?.status)
  }

  @Test
  fun `validation failures use stable failed target detail`() {
    val result = OperationResultPolicy.failed(
      WallpaperTargetData.LOCK,
      StaticWallpaperEngine.ERROR_INVALID_REQUEST,
      "A complete request is required.",
    )

    assertEquals(OperationStatusData.FAILED, result.status)
    assertEquals(TargetStatusData.FAILED, result.lock?.status)
    assertEquals(StaticWallpaperEngine.ERROR_INVALID_REQUEST, result.lock?.errorCode)
    assertEquals(StaticWallpaperEngine.ERROR_INVALID_REQUEST, result.errorCode)
  }
}
