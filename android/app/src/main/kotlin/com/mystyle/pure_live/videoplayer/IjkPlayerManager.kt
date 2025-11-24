package com.mystyle.purelive

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object IjkPlayerManager {
    private val players = mutableMapOf<Int, FlutterIjkPlayerView>()

    fun register(viewId: Int, player: FlutterIjkPlayerView) {
        players[viewId] = player
    }

    fun unregister(viewId: Int) {
        players.remove(viewId)?.dispose()
    }

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val viewId = call.argument<Int>("viewId")
        if (viewId == null) {
            result.error("missing_view_id", "viewId is required", null)
            return
        }

        val player = players[viewId]
        if (player == null) {
            result.error("player_not_found", "Player for viewId $viewId not found", null)
            return
        }

        when (call.method) {
            "play" -> {
                player.play()
                result.success(null)
            }
            "pause" -> {
                player.pause()
                result.success(null)
            }
            "seekTo" -> {
                val position = call.argument<Long>("position") ?: 0L
                player.seekTo(position)
                result.success(null)
            }
            "dispose" -> {
                unregister(viewId)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}