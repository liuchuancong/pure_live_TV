import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pure_live/platforms/niconico/niconico_session.dart';
import 'package:pure_live/platforms/niconico/niconico_watch.dart';

typedef NiconicoSeatFactory =
    Future<NiconicoSession> Function(NiconicoWatch watch, CancelToken cancel, String Function(Uri) findProxy);

typedef NiconicoMasterReader =
    Future<String> Function(
      Uri source,
      String? Function(Uri) cookies,
      CancelToken cancel,
      String Function(Uri) findProxy,
    );

/// Bounded HLS master pre-read used only to enumerate qualities.
///
/// Cancellation, proxy routing, runtime cookie evaluation and the no-redirect
/// rule are all enforced; nothing media-related is retained afterwards.
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
