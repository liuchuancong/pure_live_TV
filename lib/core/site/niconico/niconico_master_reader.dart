import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pure_live/core/site/niconico/niconico_session.dart';
import 'package:pure_live/core/site/niconico/niconico_watch.dart';

typedef NiconicoSeatFactory =
    Future<NiconicoSession> Function(NiconicoWatch watch, CancelToken cancel, String Function(Uri) findProxy);

typedef NiconicoMasterReader =
    Future<String> Function(
      Uri source,
      String? Function(Uri) cookies,
      CancelToken cancel,
      String Function(Uri) findProxy,
    );

/// TV 端有界的 master 预读：只用于列出可选画质，不保存媒体地址与 Cookie。
///
/// 与 pure_live 的 recorder 版本保持同一契约（取消、代理、Cookie 运行时求值、
/// 不允许重定向换根），但用 TV 自有的 dart:io 连接实现，避免为列画质引入录制模块。
Future<String> readNiconicoMaster(
  Uri source,
  String? Function(Uri) cookies,
  CancelToken cancel,
  String Function(Uri) findProxy,
) async {
  if (cancel.isCancelled) throw const NiconicoException(NiconicoFailure.cancelled);
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..findProxy = findProxy;
  StreamSubscription<void>? cancellation;
  try {
    final cookieHeader = cookies(source);
    final request = await client.getUrl(source);
    request.headers.set(HttpHeaders.acceptHeader, '*/*');
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      request.headers.set(HttpHeaders.cookieHeader, cookieHeader);
    }
    cancellation = cancel.whenCancel.asStream().listen((_) => client.close(force: true));
    final response = await request.close().timeout(const Duration(seconds: 5));
    if (cancel.isCancelled) throw const NiconicoException(NiconicoFailure.cancelled);
    // A redirect is a different media root and must be rejected instead of
    // silently feeding the quality catalog a playlist from another host.
    if (response.statusCode != HttpStatus.ok || response.redirects.isNotEmpty) {
      throw const NiconicoException(NiconicoFailure.schema);
    }
    final body = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 5));
    if (cancel.isCancelled) throw const NiconicoException(NiconicoFailure.cancelled);
    return body;
  } on NiconicoException {
    rethrow;
  } catch (_) {
    if (cancel.isCancelled) throw const NiconicoException(NiconicoFailure.cancelled);
    throw const NiconicoException(NiconicoFailure.transport);
  } finally {
    await cancellation?.cancel();
    client.close(force: true);
  }
}
