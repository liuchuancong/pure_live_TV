package com.mystyle.purelive

import android.content.Context
import android.view.TextureView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

class FlutterIjkPlayerView(context: Context) :
    TextureView(context) {
    private val coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private lateinit var videoPlayer: IJKVideoPlayer

    init {
        videoPlayer = IJKVideoPlayer(context, coroutineScope).apply {
            initialize()
            setVideoTextureView(this@FlutterIjkPlayerView)
        }
    }

    fun setDataSource(
        url: String,
        softDecoder: Boolean,
        headers: Map<String, String>?
    ) {
        videoPlayer.prepare(url, softDecoder, headers)
    }

    fun play() {
        videoPlayer.play()
    }

    fun pause() {
        videoPlayer.pause()
    }

    fun seekTo(position: Long) {
        videoPlayer.seekTo(position)
    }

    fun dispose() {
        videoPlayer.release()
        coroutineScope.cancel()
    }

    companion object {
        const val VIEW_TYPE = "plugins.mystyle.purelive/ijk_player"
    }
}