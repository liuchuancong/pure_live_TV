package com.mystyle.purelive

import android.content.Context
import android.graphics.SurfaceTexture
import android.net.Uri
import android.view.Surface
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.TextureView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import tv.danmaku.ijk.media.player.IMediaPlayer
import tv.danmaku.ijk.media.player.IjkMediaPlayer

class IJKVideoPlayer(
    private val context: Context,
    private val coroutineScope: CoroutineScope
) : VideoPlayer(coroutineScope) {

    private var currentUrl: String? = null


    private val ijkPlayer by lazy {
        IjkMediaPlayer().apply {
            //            IjkMediaPlayer.native_setLogLevel(IjkMediaPlayer.IJK_LOG_INFO)
            setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "dns_cache_clear", 1)
            setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "dns_cache_timeout", 0)
            setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "http-detect-range-support", 0)
            setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "reconnect", 2)
            setOption(
                IjkMediaPlayer.OPT_CATEGORY_FORMAT,
                "timeout",
                1000L * 15
            )
            setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "analyzemaxduration", 100L)
            setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "analyzeduration", 1)
            setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "probesize", 1024 * 10)
            setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "fflags", "fastseek")
        }
    }

    private fun setOption(softDecoder: Boolean) {
        ijkPlayer.apply {
            setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "allowed_extensions", "ALL")
            if (softDecoder)
                setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec", 0)
            else {
                setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec", 1)
                setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec-all-videos", 1)
                setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec-hevc", 1)
                setOption(
                    IjkMediaPlayer.OPT_CATEGORY_PLAYER,
                    "mediacodec-handle-resolution-change",
                    1
                )
            }
            setOption(
                IjkMediaPlayer.OPT_CATEGORY_FORMAT,
                "protocol_whitelist",
                "crypto,file,http,https,tcp,tls,udp,rtmp,rtsp"
            )
            setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "opensles", 0)
            setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "framedrop", 5)
            setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "fast", 1)
            setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "start-on-prepared", 1)
            setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "enable-accurate-seek", 1)

            // rtsp设置 https://ffmpeg.org/ffmpeg-protocols.html#rtsp
            setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "rtsp_transport", "tcp")
            setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "rtsp_flags", "prefer_tcp")
            setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "buffer_size", 1316)
            setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "infbuf", 1)  // 无限读
            setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "flush_packets", 1L)

            //  关闭播放器缓冲，这个必须关闭，否则会出现播放一段时间后，一直卡住，控制台打印 FFP_MSG_BUFFERING_START
            setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "packet-buffering", 0)

            //https://www.cnblogs.com/Fitz/p/18537127
            // setOption(IjkMediaPlayer.OPT_CATEGORY_CODEC, "skip_loop_filter",0) //丢弃一些“无用”的数据包，例如AVI格式中的零大小数据包
            // setOption(IjkMediaPlayer.OPT_CATEGORY_CODEC, "skip_frame", 0) //不跳帧，解码所有帧
        }
    }

    private var updatePositionJob: Job? = null

    private val playerListener = object : IMediaPlayer.OnPreparedListener,
        IMediaPlayer.OnInfoListener,
        IMediaPlayer.OnErrorListener,
        IMediaPlayer.OnVideoSizeChangedListener,
        IMediaPlayer.OnCompletionListener {

        override fun onPrepared(mp: IMediaPlayer?) {
            triggerPrepared()
            triggerReady()

            updatePositionJob?.cancel()
            updatePositionJob = coroutineScope.launch {
                while (true) {
                    triggerCurrentPosition(ijkPlayer.currentPosition)
                    triggerDuration(ijkPlayer.duration)
                    delay(1000)
                }
            }
        }

        override fun onInfo(mp: IMediaPlayer?, what: Int, extra: Int): Boolean {
            when (what) {
                IMediaPlayer.MEDIA_INFO_BUFFERING_START -> triggerBuffering(true)
                IMediaPlayer.MEDIA_INFO_BUFFERING_END -> triggerBuffering(false)
                IMediaPlayer.MEDIA_INFO_VIDEO_RENDERING_START -> triggerIsPlayingChanged(true)
            }
            return true
        }

        override fun onError(mp: IMediaPlayer?, what: Int, extra: Int): Boolean {
            triggerError(PlaybackException("IJKPlayerError", what))
            return true
        }

        override fun onVideoSizeChanged(
            mp: IMediaPlayer?,
            width: Int,
            height: Int,
            sarNum: Int,
            sarDen: Int
        ) {
            triggerResolution(width, height)
        }

        override fun onCompletion(mp: IMediaPlayer?) {
            triggerIsPlayingChanged(false)
        }
    }

    override fun initialize() {
        super.initialize()
        ijkPlayer.apply {
            setOnPreparedListener(playerListener)
            setOnInfoListener(playerListener)
            setOnErrorListener(playerListener)
            setOnVideoSizeChangedListener(playerListener)
            setOnCompletionListener(playerListener)
        }
    }

    override fun release() {
        updatePositionJob?.cancel()
        ijkPlayer.reset()
        ijkPlayer.release()
        super.release()
    }

    override fun prepare(
        url: String,
        softDecoder: Boolean,
        headers: Map<String, String>?
    ) {
        currentUrl = url
        try {
            ijkPlayer.reset()
            // 在设置数据源前确保Surface有效
            if (currentSurface != null) {
                ijkPlayer.setSurface(currentSurface)
            }
            ijkPlayer.setDataSource(context, Uri.parse(url), headers)
            setOption(softDecoder)
            ijkPlayer.prepareAsync()
        } catch (e: Exception) {
            handleError(e)
        }
    }

    // 添加错误处理方法
    private fun handleError(e: Exception) {
        triggerError(PlaybackException("PlaybackError", -1))
    }

    override fun play() {
        if (!ijkPlayer.isPlaying) {
            ijkPlayer.start()
            triggerIsPlayingChanged(true)
        }
    }

    override fun pause() {
        if (ijkPlayer.isPlaying) {
            ijkPlayer.pause()
            triggerIsPlayingChanged(false)
        }
    }

    override fun seekTo(position: Long) {
        if (ijkPlayer.duration > 0) {
            ijkPlayer.seekTo(position)
        }
    }

    override fun stop() {
        updatePositionJob?.cancel()
        ijkPlayer.stop()
        super.stop()
    }

    // 添加成员变量保存当前Surface
    private var currentSurface: Surface? = null

    override fun setVideoSurfaceView(surfaceView: SurfaceView) {
        surfaceView.holder.addCallback(object : SurfaceHolder.Callback {
            override fun surfaceCreated(holder: SurfaceHolder) {
                currentSurface = holder.surface
                ijkPlayer.setDisplay(holder)
                // Resume playback when the surface is available again
                play()
            }

            override fun surfaceChanged(
                holder: SurfaceHolder,
                format: Int,
                width: Int,
                height: Int
            ) {
            }

            override fun surfaceDestroyed(holder: SurfaceHolder) {
                // Pause playback when the surface is destroyed
                pause()
                ijkPlayer.setSurface(null)
                currentSurface?.release()
                currentSurface = null
            }
        })
        ijkPlayer.setDisplay(surfaceView.holder)
    }

    override fun setVideoTextureView(textureView: TextureView) {
        textureView.surfaceTextureListener = object : TextureView.SurfaceTextureListener {
            override fun onSurfaceTextureAvailable(
                surface: SurfaceTexture,
                width: Int,
                height: Int
            ) {
                currentSurface = Surface(surface)
                ijkPlayer.setSurface(currentSurface)
                play()
            }

            override fun onSurfaceTextureSizeChanged(
                surface: SurfaceTexture,
                width: Int,
                height: Int
            ) {
            }

            override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
                pause()
                ijkPlayer.setSurface(null)
                currentSurface?.release()
                currentSurface = null
                return true
            }

            override fun onSurfaceTextureUpdated(surface: SurfaceTexture) {}
        }

        if (textureView.isAvailable) {
            val newSurface = Surface(textureView.surfaceTexture)
            currentSurface = newSurface
            ijkPlayer.setSurface(newSurface)
        }
    }
}
