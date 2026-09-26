import 'dart:io' as io;

import 'package:dio/io.dart';
import 'package:dio/dio.dart';
import 'package:pure_live/shared/utils/core_error.dart';
import 'package:pure_live/shared/utils/custom_interceptor.dart';
import 'package:pure_live/shared/common/proxy_routing.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

class HttpClient {
  static const Duration _connectTimeout = Duration(seconds: 20);
  static const Duration _receiveTimeout = Duration(seconds: 20);
  static const Duration _sendTimeout = Duration(seconds: 20);

  static const int _downloadSuccessCode1 = 200;
  static const int _downloadSuccessCode2 = 206;

  HttpClient._();
  static final HttpClient instance = HttpClient._();
  late Dio dio = _createDio();
  Dio _createDio() {
    return Dio(BaseOptions(connectTimeout: _connectTimeout, receiveTimeout: _receiveTimeout, sendTimeout: _sendTimeout))
      ..transformer = CustomTransformer()
      ..httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = io.HttpClient();
          client.idleTimeout = const Duration(seconds: 30);
          client.findProxy = (uri) {
            final proxyCtrl = SettingsService.to.proxy;
            return buildProxyDirective(
              enabled: proxyCtrl.enableAppProxy.value,
              host: proxyCtrl.appProxyHost.value,
              port: proxyCtrl.appProxyPort.value,
            );
          };
          return client;
        },
      )
      ..interceptors.add(CustomLogInterceptor())
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) => handler.next(applyCustomUserAgent(options))));
  }

  /// The transport-level default when a caller sets an explicit agent anyway.
  static const String defaultDesktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36';

  /// User agent for IPTV playlist/EPG fetches: the user's override when set,
  /// otherwise the desktop browser agent these feeds expect.
  static String get iptvUserAgent {
    final custom = SettingsService.to.iptvState.customIptvUserAgent.trim();
    return custom.isEmpty ? defaultDesktopUserAgent : custom;
  }

  /// The global IPTV request headers (UA + the optional Referer/Cookie the
  /// user configured) merged with per-source [headers], which always win.
  ///
  /// Playlist download, sync and playback all go through this so a source that
  /// needs a Referer/Cookie works everywhere without editing the playlist.
  static Map<String, String> iptvHeaders([Map<String, String>? headers]) {
    final settings = SettingsService.to.iptvState;
    final referer = settings.customIptvReferer.trim();
    final cookie = settings.customIptvCookie.trim();
    return <String, String>{
      'user-agent': iptvUserAgent,
      if (referer.isNotEmpty) 'referer': referer,
      if (cookie.isNotEmpty) 'cookie': cookie,
      ...?headers,
    };
  }

  /// Injects the IPTV "custom user agent" setting into a request unless the
  /// caller asked for a specific one.
  ///
  /// The setting exists to get past playlist/EPG servers that answer 403/444 to
  /// the default Dio agent, so it has to be applied at the transport layer: the
  /// IPTV import and sync paths build their own headers and would otherwise
  /// never see it. Explicit per-call headers (site logins, browser impersonation,
  /// per-channel M3U headers) always win.
  static RequestOptions applyCustomUserAgent(RequestOptions options) {
    if (options.headers.keys.any((name) => name.toLowerCase() == 'user-agent')) return options;
    final agent = SettingsService.to.iptvState.customIptvUserAgent.trim();
    if (agent.isEmpty) return options;
    options.headers['user-agent'] = agent;
    return options;
  }

  void rebuildDio() {
    final oldDio = dio;
    dio = _createDio();
    // In-flight requests still run on the old client: closing it immediately
    // kills them (and trips debug asserts inside dart:io's HttpClient.close).
    // Give them one idle-timeout to drain before teardown.
    Future.delayed(const Duration(seconds: 30), () {
      try {
        oldDio.close(force: false);
      } catch (_) {}
    });
  }

  Future<String> getText(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
    CancelToken? cancel,
  }) async {
    try {
      final result = await dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.plain, headers: header),
        cancelToken: cancel,
      );
      return result.data;
    } catch (e) {
      throw _handleError(e, i18n('http_error_get'));
    }
  }

  Future<dynamic> getJson(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
    CancelToken? cancel,
  }) async {
    try {
      final result = await dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.json, headers: header),
        cancelToken: cancel,
      );
      return result.data;
    } catch (e) {
      throw _handleError(e, i18n('http_error_get'));
    }
  }

  Future<Response<dynamic>> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
    CancelToken? cancel,
  }) async {
    try {
      final result = await dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.json, headers: header),
        cancelToken: cancel,
      );
      return result;
    } catch (e) {
      throw _handleError(e, i18n('http_error_get'));
    }
  }

  Future<dynamic> postJson(
    String url, {
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Map<String, dynamic>? header,
    bool formUrlEncoded = false,
    CancelToken? cancel,
  }) async {
    try {
      final result = await dio.post(
        url,
        queryParameters: queryParameters,
        data: data,
        options: Options(
          responseType: ResponseType.json,
          headers: header,
          contentType: formUrlEncoded ? Headers.formUrlEncodedContentType : null,
        ),
        cancelToken: cancel,
      );
      return result.data;
    } catch (e) {
      throw _handleError(e, i18n('http_error_post'));
    }
  }

  Future<Response> head(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
    CancelToken? cancel,
  }) async {
    try {
      final result = await dio.head(
        url,
        queryParameters: queryParameters,
        options: Options(headers: header, receiveDataWhenStatusError: true),
        cancelToken: cancel,
      );
      return result;
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.badResponse) {
        return e.response!;
      }
      throw HttpError(i18n('http_error_head'));
    }
  }

  Future<io.File> download(
    String url,
    String savePath, {
    Map<String, dynamic>? header,
    CancelToken? cancel,
    Function(int value, int progress)? onReceiveProgress,
  }) async {
    final tempPath = "$savePath.part";
    final tempFile = io.File(tempPath);

    try {
      if (!await tempFile.exists()) {
        await tempFile.create(recursive: true);
      }
      final response = await dio.download(
        url,
        tempPath,
        cancelToken: cancel,
        onReceiveProgress: onReceiveProgress,
        options: Options(headers: header),
      );

      if (response.statusCode == _downloadSuccessCode1 || response.statusCode == _downloadSuccessCode2) {
        return await tempFile.rename(savePath);
      } else {
        throw HttpError(i18n('http_error_download_failed'), statusCode: response.statusCode ?? 0);
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw HttpError(i18n('http_error_download_cancelled'));
      } else if (e.type == DioExceptionType.badResponse) {
        throw HttpError(e.message ?? "", statusCode: e.response?.statusCode ?? 0);
      } else {
        throw HttpError(i18n('http_error_download'));
      }
    }
  }

  HttpError _handleError(dynamic e, String defaultMsg) {
    if (e is DioException && e.type == DioExceptionType.badResponse) {
      final response = e.response;
      final body = response?.data?.toString();
      return HttpError(
        e.message ?? defaultMsg,
        statusCode: response?.statusCode ?? 0,
        responseBody: body == null || body.length <= 256 ? body : body.substring(0, 256),
        responseHeaders: <String, String>{
          for (final entry in response?.headers.map.entries ?? const <MapEntry<String, List<String>>>[])
            if (entry.value.isNotEmpty) entry.key: entry.value.join(', '),
        },
      );
    } else {
      return HttpError(defaultMsg);
    }
  }
}

class CustomTransformer extends BackgroundTransformer {
  @override
  Future<dynamic> transformResponse(RequestOptions options, ResponseBody responseBody) async {
    final contentType = responseBody.headers['content-type']?.first;

    if (contentType != null && contentType.toLowerCase().startsWith('json;')) {
      responseBody.headers['content-type'] = ['application/json${contentType.substring(4)}'];
    }

    return super.transformResponse(options, responseBody);
  }
}
