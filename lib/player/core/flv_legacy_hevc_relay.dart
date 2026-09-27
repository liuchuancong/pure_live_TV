import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:pure_live/player/core/flv_legacy_hevc_rewriter.dart';
import 'package:pure_live/player/core/flv_tag_framer.dart';

/// Playback-only loopback relay that applies [FlvLegacyHevcTagRewriter].
///
/// Only the hosts this app names are routed here (see [appliesTo]) so ordinary
/// FLV keeps its direct connection. Every local request opens its own upstream
/// connection, which keeps the player's own reconnect behaviour intact.
///
/// ### Why this lives in the app
///
/// Nothing here is engine-specific: the rewriter fixes a *stream* that carries
/// a legacy FLV spelling, and any demuxer older than FFmpeg 8.0 drops it. Which
/// CDNs serve that spelling depends on the rooms this app plays and on
/// individual broadcasters' encoders — deployment knowledge, not library
/// behaviour — so the decision and the mechanism both live here, and the player
/// (media_core) only ever sees a normal loopback URL.
///
/// The relay is a normal HTTP server on loopback; the native player must reach
/// it directly, so the URI handed to the player has to be exempt from any
/// configured proxy. media_core does that by itself: a source on loopback is
/// treated as a private input and never proxied.
class FlvLegacyHevcRelay {
  FlvLegacyHevcRelay._(this._server, this._upstream, this._headers, this._findProxy, this._secret);

  final HttpServer _server;
  final Uri _upstream;
  final Map<String, String> _headers;
  final String Function(Uri) _findProxy;
  final String _secret;
  final Set<HttpClient> _clients = <HttpClient>{};
  final Set<Future<void>> _serving = <Future<void>>{};
  StreamSubscription<HttpRequest>? _requests;
  Future<void>? _closing;
  bool _closed = false;

  /// Whether the relay has been closed and must not be handed out again.
  bool get isClosed => _closed;

  /// The loopback URI the native player should open.
  Uri get inputUri => Uri(scheme: 'http', host: '127.0.0.1', port: _server.port, path: '/$_secret/live.flv');

  /// Whether [url] is a plain FLV from one of [hostSuffixes].
  ///
  /// The list is the caller's policy: which CDNs serve codec-id-12 HEVC depends
  /// on the deployment (and on individual broadcasters' encoders), so it is
  /// passed in rather than baked into this file. An empty list means the relay
  /// applies to nothing, which is the honest default for a caller that has not
  /// observed the problem anywhere.
  static bool appliesTo(String url, {required Iterable<String> hostSuffixes}) {
    final uri = Uri.tryParse(url);
    if (uri == null || !const <String>{'http', 'https'}.contains(uri.scheme.toLowerCase())) return false;
    if (!uri.path.toLowerCase().endsWith('.flv')) return false;
    final host = uri.host.toLowerCase();
    return hostSuffixes.any(host.endsWith);
  }

  /// Binds the loopback server for [url].
  ///
  /// [findProxy] resolves the upstream connection exactly like the player
  /// would have, so a configured proxy keeps applying to the CDN request.
  /// [hostSuffixes] is the same policy [appliesTo] was asked with.
  static Future<FlvLegacyHevcRelay> start(
    String url,
    Map<String, String> headers, {
    required String Function(Uri) findProxy,
    required Iterable<String> hostSuffixes,
  }) async {
    if (!appliesTo(url, hostSuffixes: hostSuffixes)) {
      throw const FormatException('Expected a legacy HEVC FLV input');
    }
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0, shared: false);
    final random = Random.secure();
    final secret = base64UrlEncode(List<int>.generate(18, (_) => random.nextInt(256))).replaceAll('=', '');
    final relay = FlvLegacyHevcRelay._(server, Uri.parse(url), Map<String, String>.unmodifiable(headers), findProxy, secret);
    relay._requests = server.listen((request) {
      if (request.method != 'GET' || request.uri.path != relay.inputUri.path || relay._closed) {
        unawaited(_reject(request, HttpStatus.notFound));
        return;
      }
      late final Future<void> serving;
      serving = relay._serve(request).whenComplete(() => relay._serving.remove(serving));
      relay._serving.add(serving);
    });
    return relay;
  }

  Future<void> _serve(HttpRequest downstream) async {
    final client = HttpClient()
      ..findProxy = _findProxy
      ..connectionTimeout = const Duration(seconds: 15)
      ..autoUncompress = true;
    _clients.add(client);
    var sent = false;
    try {
      final request = await client.getUrl(_upstream);
      _headers.forEach((name, value) => request.headers.set(name, value));
      final upstream = await request.close().timeout(const Duration(seconds: 20));
      if (upstream.statusCode != HttpStatus.ok) {
        downstream.response.statusCode = upstream.statusCode;
        return;
      }
      downstream.response.headers.contentType = ContentType('video', 'x-flv');
      downstream.response.headers.set('cache-control', 'no-store');
      downstream.response.bufferOutput = false;
      final framer = FlvTagFramer();
      final rewriter = FlvLegacyHevcTagRewriter();
      await for (final chunk in upstream) {
        if (_closed) break;
        for (final packet in framer.add(chunk)) {
          downstream.response.add(rewriter.rewrite(packet));
          sent = true;
        }
        await downstream.response.flush();
      }
    } catch (_) {
      if (!sent) {
        try {
          downstream.response.statusCode = HttpStatus.badGateway;
        } on StateError {
          /* Headers already sent. */
        }
      }
    } finally {
      try {
        await downstream.response.close();
      } on Object {
        /* The native reader may already have gone. */
      }
      _clients.remove(client);
      client.close(force: true);
    }
  }

  /// Closes the server and every upstream connection. Idempotent.
  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    _closed = true;
    for (final client in _clients.toList()) {
      client.close(force: true);
    }
    await _server.close(force: true);
    await _requests?.cancel();
    await Future.wait(_serving.toList());
  }

  static Future<void> _reject(HttpRequest request, int status) async {
    try {
      request.response.statusCode = status;
      await request.response.close();
    } on Object {
      /* Peer closed its request. */
    }
  }
}
