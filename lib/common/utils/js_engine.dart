import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';

class JsEngine {
  static JavascriptRuntime? _jsRuntime;
  static JavascriptRuntime get jsRuntime => _jsRuntime!;

  static void init() {
    _jsRuntime ??= getJavascriptRuntime();
    jsRuntime.enableHandlePromises();
  }

  static Future<void> loadDouyinSdk() async {
    final webmssdkjs = await rootBundle.loadString('assets/js/webmssdk.js');
    jsRuntime.evaluate(webmssdkjs);
  }

  static JsEvalResult evaluate(String code) {
    return jsRuntime.evaluate(code);
  }

  static Future<JsEvalResult> evaluateAsync(String code) {
    return jsRuntime.evaluateAsync(code);
  }

  static dynamic onMessage(String channelName, dynamic Function(dynamic) fn) {
    return jsRuntime.onMessage(channelName, (args) => null);
  }

  static dynamic sendMessage({
    required String channelName,
    required List<String> args,
    String? uuid,
  }) {
    return jsRuntime.sendMessage(channelName: channelName, args: args);
  }
}
