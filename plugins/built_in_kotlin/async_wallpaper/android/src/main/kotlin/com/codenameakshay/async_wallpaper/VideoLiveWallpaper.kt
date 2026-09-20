package com.codenameakshay.async_wallpaper

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.MediaPlayer
import android.os.Bundle
import android.service.wallpaper.WallpaperService
import android.util.Log
import android.view.SurfaceHolder
import java.io.File

/**
 * `WallpaperManager.COMMAND_REAPPLY` (hidden API). On API 30+ Android does not rebind a live
 * wallpaper when the user sets the same component again; it sends this command to the running
 * engine instead, so the engine must reload its content itself.
 */
internal const val WALLPAPER_COMMAND_REAPPLY = "android.wallpaper.reapply"

/** The two scaling modes supported directly by Android's MediaPlayer. */
enum class VideoWallpaperScaleMode {
  CENTER_CROP,
  FIT_CENTER,
}

/**
 * Live wallpaper backed by the active file managed by [VideoWallpaperRepository].
 * Player work is deliberately contained in the engine: surface and visibility
 * callbacks only transition the pure [VideoPlaybackStateMachine], then the
 * resulting action is applied while holding a single lifecycle lock.
 */
class VideoLiveWallpaper : WallpaperService() {
  override fun onCreateEngine(): Engine = VideoEngine()

  inner class VideoEngine : Engine() {
    private val lifecycleLock = Any()
    private val stateMachine = VideoPlaybackStateMachine()

    private var mediaPlayer: MediaPlayer? = null
    private var playerGeneration = 0L

    override fun onSurfaceCreated(holder: SurfaceHolder) {
      super.onSurfaceCreated(holder)
      synchronized(lifecycleLock) {
        if (stateMachine.onSurfaceCreated() == VideoPlaybackAction.PREPARE) {
          preparePlayerLocked(holder)
        }
      }
    }

    override fun onVisibilityChanged(visible: Boolean) {
      synchronized(lifecycleLock) {
        applyActionLocked(stateMachine.onVisibilityChanged(visible))
      }
    }

    override fun onSurfaceDestroyed(holder: SurfaceHolder) {
      synchronized(lifecycleLock) {
        applyActionLocked(stateMachine.onSurfaceDestroyed())
      }
      super.onSurfaceDestroyed(holder)
    }

    override fun onDestroy() {
      synchronized(lifecycleLock) {
        applyActionLocked(stateMachine.onEngineDestroyed())
      }
      super.onDestroy()
    }

    /** Reloads the active video when the user confirms this same component again. */
    override fun onCommand(
      action: String?,
      x: Int,
      y: Int,
      z: Int,
      extras: Bundle?,
      resultRequested: Boolean,
    ): Bundle? {
      if (action == WALLPAPER_COMMAND_REAPPLY) {
        synchronized(lifecycleLock) {
          if (stateMachine.onAssetReapplied() == VideoPlaybackAction.PREPARE) {
            releasePlayerLocked()
            preparePlayerLocked(surfaceHolder)
          }
        }
      }
      return super.onCommand(action, x, y, z, extras, resultRequested)
    }

    private fun preparePlayerLocked(holder: SurfaceHolder) {
      val file = File(filesDir, VideoWallpaperRepository.ACTIVE_VIDEO_FILE_NAME)
      if (!file.isFile || !file.canRead() || file.length() <= 0L) {
        Log.w(TAG, "No readable live wallpaper video at ${file.absolutePath}")
        stateMachine.onPlayerError()
        return
      }

      val player = try {
        MediaPlayer()
      } catch (error: Exception) {
        Log.e(TAG, "Unable to create live wallpaper player", error)
        stateMachine.onPlayerError()
        return
      }

      val generation = ++playerGeneration
      mediaPlayer = player
      try {
        val scaleMode = VideoWallpaperRepository(filesDir).activeScaleMode()
        player.setOnPreparedListener { preparedPlayer ->
          synchronized(lifecycleLock) {
            if (!isCurrentPlayer(preparedPlayer, generation)) {
              return@synchronized
            }
            applyActionLocked(stateMachine.onPrepared())
          }
        }
        player.setOnErrorListener { failedPlayer, what, extra ->
          synchronized(lifecycleLock) {
            if (isCurrentPlayer(failedPlayer, generation)) {
              Log.e(TAG, "Live wallpaper player error: what=$what extra=$extra")
              handlePlayerFailureLocked()
            }
          }
          true
        }
        player.setSurface(holder.surface)
        player.setDataSource(file.absolutePath)
        player.isLooping = true
        // Live wallpaper should never take over the user's audio by default.
        player.setVolume(0f, 0f)
        player.setVideoScalingMode(scaleMode.mediaPlayerMode())
        player.prepareAsync()
      } catch (error: Exception) {
        Log.e(TAG, "Failed to prepare live wallpaper player", error)
        handlePlayerFailureLocked()
      }
    }

    private fun applyActionLocked(action: VideoPlaybackAction) {
      when (action) {
        VideoPlaybackAction.NONE -> Unit
        VideoPlaybackAction.PREPARE -> Unit // Only onSurfaceCreated owns the SurfaceHolder.
        VideoPlaybackAction.START -> startPlayerLocked()
        VideoPlaybackAction.PAUSE -> pausePlayerLocked()
        VideoPlaybackAction.RELEASE -> releasePlayerLocked()
      }
    }

    private fun startPlayerLocked() {
      val player = mediaPlayer ?: return
      try {
        player.start()
      } catch (error: Exception) {
        Log.e(TAG, "Failed to start live wallpaper player", error)
        handlePlayerFailureLocked()
      }
    }

    private fun pausePlayerLocked() {
      val player = mediaPlayer ?: return
      try {
        player.pause()
      } catch (error: Exception) {
        Log.e(TAG, "Failed to pause live wallpaper player", error)
        handlePlayerFailureLocked()
      }
    }

    private fun handlePlayerFailureLocked() {
      stateMachine.onPlayerError()
      releasePlayerLocked()
    }

    /** The only release path. Clearing the reference first makes it idempotent. */
    private fun releasePlayerLocked() {
      val player = mediaPlayer ?: return
      mediaPlayer = null
      playerGeneration += 1L
      runCatching { player.release() }
        .onFailure { error -> Log.w(TAG, "Failed to release live wallpaper player", error) }
    }

    private fun isCurrentPlayer(candidate: MediaPlayer, generation: Long): Boolean {
      return mediaPlayer === candidate && playerGeneration == generation
    }
  }

  companion object {
    private const val TAG = "VideoLiveWallpaper"

    fun setToWallpaper(context: Context) {
      val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        putExtra(
          WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
          ComponentName(context, VideoLiveWallpaper::class.java),
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
  }
}

private fun VideoWallpaperScaleMode.mediaPlayerMode(): Int {
  return when (this) {
    VideoWallpaperScaleMode.CENTER_CROP -> {
      MediaPlayer.VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING
    }
    VideoWallpaperScaleMode.FIT_CENTER -> MediaPlayer.VIDEO_SCALING_MODE_SCALE_TO_FIT
  }
}

/** Pure lifecycle policy exercised by [VideoStateMachineTest] on the JVM. */
enum class VideoPlaybackState {
  IDLE,
  PREPARING,
  PAUSED,
  PLAYING,
  RELEASED,
}

enum class VideoPlaybackAction {
  NONE,
  PREPARE,
  START,
  PAUSE,
  RELEASE,
}

class VideoPlaybackStateMachine {
  var state: VideoPlaybackState = VideoPlaybackState.IDLE
    private set

  var hasSurface: Boolean = false
    private set

  var isVisible: Boolean = false
    private set

  fun onSurfaceCreated(): VideoPlaybackAction {
    if (state == VideoPlaybackState.RELEASED) {
      return VideoPlaybackAction.NONE
    }
    hasSurface = true
    if (state != VideoPlaybackState.IDLE) {
      return VideoPlaybackAction.NONE
    }
    state = VideoPlaybackState.PREPARING
    return VideoPlaybackAction.PREPARE
  }

  fun onVisibilityChanged(visible: Boolean): VideoPlaybackAction {
    if (state == VideoPlaybackState.RELEASED) {
      return VideoPlaybackAction.NONE
    }
    isVisible = visible
    return when (state) {
      VideoPlaybackState.PAUSED if visible -> {
        state = VideoPlaybackState.PLAYING
        VideoPlaybackAction.START
      }
      VideoPlaybackState.PLAYING if !visible -> {
        state = VideoPlaybackState.PAUSED
        VideoPlaybackAction.PAUSE
      }
      else -> VideoPlaybackAction.NONE
    }
  }

  fun onPrepared(): VideoPlaybackAction {
    if (state == VideoPlaybackState.RELEASED) {
      return VideoPlaybackAction.NONE
    }
    if (!hasSurface) {
      state = VideoPlaybackState.IDLE
      return VideoPlaybackAction.RELEASE
    }
    if (state != VideoPlaybackState.PREPARING) {
      return VideoPlaybackAction.NONE
    }
    return if (isVisible) {
      state = VideoPlaybackState.PLAYING
      VideoPlaybackAction.START
    } else {
      state = VideoPlaybackState.PAUSED
      VideoPlaybackAction.NONE
    }
  }

  /** A new active asset was confirmed; replace the player if a surface can show it now. */
  fun onAssetReapplied(): VideoPlaybackAction {
    if (state == VideoPlaybackState.RELEASED || !hasSurface) {
      return VideoPlaybackAction.NONE
    }
    state = VideoPlaybackState.PREPARING
    return VideoPlaybackAction.PREPARE
  }

  fun onPlayerError(): VideoPlaybackAction {
    if (state == VideoPlaybackState.RELEASED) {
      return VideoPlaybackAction.NONE
    }
    val hadPlayer = state != VideoPlaybackState.IDLE
    state = VideoPlaybackState.IDLE
    return if (hadPlayer) VideoPlaybackAction.RELEASE else VideoPlaybackAction.NONE
  }

  fun onSurfaceDestroyed(): VideoPlaybackAction {
    hasSurface = false
    if (state == VideoPlaybackState.RELEASED || state == VideoPlaybackState.IDLE) {
      return VideoPlaybackAction.NONE
    }
    state = VideoPlaybackState.IDLE
    return VideoPlaybackAction.RELEASE
  }

  fun onEngineDestroyed(): VideoPlaybackAction {
    if (state == VideoPlaybackState.RELEASED) {
      return VideoPlaybackAction.NONE
    }
    val hadPlayer = state != VideoPlaybackState.IDLE
    hasSurface = false
    state = VideoPlaybackState.RELEASED
    return if (hadPlayer) VideoPlaybackAction.RELEASE else VideoPlaybackAction.NONE
  }
}
