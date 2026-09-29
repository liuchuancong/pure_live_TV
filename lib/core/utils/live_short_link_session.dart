import 'package:dio/dio.dart';

/// Short-link resolution session. Redirects are followed manually so live room
/// short links can be restored.
/// The session can be closed; afterwards every request returns null.
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

  /// Returns the raw response instead of throwing; null on failure or once the
  /// session is closed.
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
