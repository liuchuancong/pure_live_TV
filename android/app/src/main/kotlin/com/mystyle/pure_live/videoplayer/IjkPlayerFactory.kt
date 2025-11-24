package com.mystyle.purelive
import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class IjkPlayerFactory(private val context: Context) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val creationParams = args as Map<String, Any>

        val url = creationParams["url"] as String
        val softDecoder = creationParams["softDecoder"] as Boolean
        @Suppress("UNCHECKED_CAST")
        val headers = creationParams["headers"] as Map<String, String>?
        return object : PlatformView {
            private val ijkView = FlutterIjkPlayerView(context!!)
            init {
                url?.let { ijkView.setDataSource(it,softDecoder=softDecoder,headers=headers) }
            }
            override fun getView() = ijkView

            override fun dispose() {
                ijkView.dispose()
            }
        }
    }
}