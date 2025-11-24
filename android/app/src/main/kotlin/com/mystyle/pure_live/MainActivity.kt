package com.mystyle.purelive
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                FlutterIjkPlayerView.VIEW_TYPE,
                IjkPlayerFactory(this)
            )
        val channel = MethodChannel(
            flutterEngine.dartExecutor,
            "plugins.mystyle.purelive/ijk_player_control"
        )
        channel.setMethodCallHandler { call, result ->
            IjkPlayerManager.handleMethodCall(call, result)
        }
    }
}
