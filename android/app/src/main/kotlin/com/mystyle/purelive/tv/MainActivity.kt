package com.mystyle.purelive.tv
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var nativeHttpChannel: NativeHttpChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (nativeHttpChannel == null) {
            nativeHttpChannel = NativeHttpChannel(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun onDestroy() {
        nativeHttpChannel?.dispose()
        nativeHttpChannel = null
        super.onDestroy()
    }
}
