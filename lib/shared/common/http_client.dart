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
      ..interceptors.add(CustomLogInterceptor());
  }

  void rebuildDio() {
    final oldDio = dio;
    dio = _createDio();
    oldDio.close(force: false);
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
      return HttpError(e.message ?? defaultMsg, statusCode: e.response?.statusCode ?? 0);
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
