package com.codenameakshay.async_wallpaper

import android.app.Activity

internal fun WallpaperSourceData.hasValueForKind(): Boolean {
  return when (kind) {
    WallpaperSourceKindData.URL -> !url.isNullOrBlank()
    WallpaperSourceKindData.FILE_PATH -> !filePath.isNullOrBlank()
    WallpaperSourceKindData.CONTENT_URI -> !contentUri.isNullOrBlank()
    WallpaperSourceKindData.BYTES -> bytes?.isNotEmpty() == true
    null -> false
  }
}

internal fun Activity?.isUsable(): Boolean = this != null && !isFinishing && !isDestroyed
