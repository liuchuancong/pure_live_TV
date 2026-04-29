import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class CoreError extends Error {
  final int statusCode;
  final String message;

  static String? _lastMessage;
  static DateTime? _lastShowTime;

  CoreError(this.message, {this.statusCode = 0}) {
    final currentMsg = toString();
    final now = DateTime.now();

    // 检查逻辑：如果消息不同，或者距离上次弹窗超过 10 秒，才允许显示
    if (_lastMessage != currentMsg ||
        _lastShowTime == null ||
        now.difference(_lastShowTime!) > const Duration(seconds: 10)) {
      SmartDialog.showToast(currentMsg);

      _lastMessage = currentMsg;
      _lastShowTime = now;
    }
  }

  @override
  String toString() {
    if (statusCode != 0) {
      return statusCodeToString(statusCode);
    }
    return message;
  }

  String statusCodeToString(int statusCode) {
    switch (statusCode) {
      case 400:
        return "错误的请求(400)";
      case 401:
        return "无权限访问资源(401)";
      case 403:
        return "无权限访问资源(403)";
      case 404:
        return "服务器找不到请求的资源(404)";
      case 500:
        return "服务器出现错误(500)";
      case 502:
        return "服务器出现错误(502)";
      case 503:
        return "服务器出现错误(503)";
      default:
        return "连接服务器失败，请稍后再试($statusCode)";
    }
  }
}
