package com.codenameakshay.async_wallpaper

import java.util.concurrent.locks.ReentrantLock

/**
 * One process-wide lock around the actual `WallpaperManager` writes.
 *
 * [OperationQueue] serializes work inside a single Flutter engine, but rotation also runs from
 * WorkManager workers and alarm receivers in the same process. Serializing the write itself keeps
 * a rotation apply from interleaving with a direct static apply.
 */
internal val wallpaperMutationLock = ReentrantLock()
