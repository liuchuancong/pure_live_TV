import 'package:dio/dio.dart';

/// 短链跳转解析会话：手动跟随 3xx 重定向，供直播间短链还原使用。
/// 会话可关闭；关闭后所有请求直接返回 null。
class LiveShortLinkSession {
  LiveShortLinkSession({required Duration timeout, Dio Function()? clientFactory})
    : _dio = _createClient(timeout, clientFactory),
      _closed = false;

  static const Set<int> redirectStatuses = {301, 302, 303, 307, 308};

  final Dio _dio;
  bool _closed;

  bool get isClosed => _closed;

  static Dio _createClient(Duration timeout, Dio Function()? clientFactory) {
    final dio = clientFactory != null ? clientFactory() : Dio();
    dio.options
      ..connectTimeout = timeout
      ..receiveTimeout = timeout
      ..followRedirects = false
      ..validateStatus = (status) => status != null && status < 400;
    return dio;
  }

  /// 返回原始响应（不抛异常）；失败或会话已关闭时返回 null。
  Future<Response?> get(Uri uri, {Map<String, String> headers = const {}}) async {
    if (_closed) return null;
    try {
      return await _dio.getUri(
        uri,
        options: Options(headers: headers),
      );
    } catch (_) {
      return null;
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _dio.close(force: true);
  }
}
