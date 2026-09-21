package com.example.native_textfield_tv

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.BinaryMessenger

/** NativeTextfieldTvPlugin */
class NativeTextfieldTvPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var messenger: BinaryMessenger

  // 存储所有活跃的 NativeTextfieldTvView 实例
  private val viewInstances = mutableMapOf<Int, NativeTextfieldTvView>()

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    messenger = flutterPluginBinding.binaryMessenger
    channel = MethodChannel(messenger, "native_textfield_tv")
    channel.setMethodCallHandler(this)

    // 注册PlatformViewFactory
    flutterPluginBinding
      .platformViewRegistry
      .registerViewFactory(
        "native_textfield_tv",
        NativeTextfieldTvFactory(messenger, viewInstances)
      )
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    val instanceId = call.argument<Int>("instanceId")
    val view = viewInstances[instanceId]

    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
      return
    }

    if (view == null) {
      result.error("INVALID_INSTANCE", "View instance not found", null)
      return
    }

    when (call.method) {
      "setText" -> {
        val text = call.argument<String>("text")
        view.setText(text ?: "")
        result.success(null)
      }
      "getText" -> {
        result.success(view.getText())
      }
      "requestFocus" -> {
        view.requestFocus()
        result.success(null)
      }
      "clearFocus" -> {
        view.clearFocus()
        result.success(null)
      }
      "setEnabled" -> {
        val enabled = call.argument<Boolean>("enabled") ?: true
        view.setEnabled(enabled)
        result.success(null)
      }
      "setHint" -> {
        val hint = call.argument<String>("hint")
        view.setHint(hint)
        result.success(null)
      }
      "moveCursor" -> {
        val direction = call.argument<String>("direction")
        if (direction == "left" || direction == "right") {
          view.moveCursor(direction)
          result.success(null)
        } else {
          result.error("INVALID_MOVE_CURSOR", "Invalid direction", null)
        }
      }
        "setObscureText" -> {
        val obscure = call.argument<Boolean>("obscureText") ?: false
        view.setObscureText(obscure)
        result.success(null)
      }
      "onSubmitted" -> {
        val text = call.argument<String>("text") ?: ""
        // Forward to Flutter via MethodChannel
        channel.invokeMethod("onSubmitted", mapOf(
          "instanceId" to instanceId,
          "text" to text
        ))
        result.success(null)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    viewInstances.clear()
  }
}

class NativeTextfieldTvFactory(
  private val messenger: BinaryMessenger,
  private val viewInstances: MutableMap<Int, NativeTextfieldTvView>
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: android.content.Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<String?, Any?>?
        val instanceId = creationParams?.get("instanceId") as? Int ?: viewId
        val view = NativeTextfieldTvView(context, viewId, creationParams, messenger)
        viewInstances[instanceId] = view
        return view
    }
}
