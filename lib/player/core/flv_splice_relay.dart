import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:media_core_logging/media_core_logging.dart';
import 'package:pure_live/player/core/flv_tag_framer.dart';

/// Where the splicer reports: the same hub the playback diagnostics use, so a
/// "did it renew?" question is answered by the log the viewer already watches.
final LogModule _log = MediaCoreLog.of(LogCategory.source);

/// `host/path` of [url] — never its query: the query carries the lease, the
/// signature and the device id, and a log line outlives all three.
String _describe(Uri url) => '${url.host}${url.path}';

/// A live FLV source whose URL stops working at a known time.
///
/// Douyu's anonymous URL carries `expire=300`: the CDN closes the open
/// connection 300 s after the URL was issued, and only a *new* URL of the same
/// room keeps streaming. [refreshAt] is when the next URL should be fetched —
/// early enough that the handover finishes before the cut.
@immutable
class FlvLeasedSource {
  const FlvLeasedSource(this.url, {this.refreshAt});

  final Uri url;

  /// When to fetch the next URL. The old connection keeps streaming until the
  /// new one reaches a keyframe, so this must leave time before the cut.
  final DateTime? refreshAt;
}

/// Resolves a fresh URL for the same room, quality and line.
typedef FlvSourceRenewer = Future<FlvLeasedSource> Function(FlvLeasedSource current);

/// One upstream connection, as the FLV file header followed by complete tags
/// (tag header, data and trailing PreviousTagSize, as [FlvTagFramer] yields).
abstract interface class FlvTagReader {
  /// The next packet, or null at the end of the stream.
  Future<Uint8List?> next();

  Future<void> cancel();
}

typedef FlvTagReaderOpener = Future<FlvTagReader> Function(Uri url);

/// FLV tag fields used for splicing; [tag] is a complete tag.
abstract final class FlvTag {
  static const int audio = 8;
  static const int video = 9;
  static const int script = 18;

  static int type(Uint8List tag) => tag[0] & 0x1f;

  static int timestamp(Uint8List tag) => (tag[7] << 24) | (tag[4] << 16) | (tag[5] << 8) | tag[6];

  static Uint8List withTimestamp(Uint8List tag, int timestamp) {
    final copy = Uint8List.fromList(tag);
    final value = timestamp & 0xffffffff;
    copy[4] = (value >> 16) & 0xff;
    copy[5] = (value >> 8) & 0xff;
    copy[6] = value & 0xff;
    copy[7] = (value >> 24) & 0xff;
    return copy;
  }

  static bool _enhanced(Uint8List tag) => (tag[11] & 0x80) != 0;

  /// AVC/HEVC decoder configuration (legacy FLV or Enhanced FLV SequenceStart).
  static bool isVideoConfig(Uint8List tag) {
    if (type(tag) != video || tag.length < 17) return false;
    if (_enhanced(tag)) return (tag[11] & 0x0f) == 0;
    final codec = tag[11] & 0x0f;
    return (codec == 7 || codec == 12) && tag[12] == 0;
  }

  static bool isKeyframe(Uint8List tag) =>
      type(tag) == video && tag.length > 12 && ((tag[11] >> 4) & 7) == 1 && !isVideoConfig(tag);

  /// AAC AudioSpecificConfig.
  static bool isAudioConfig(Uint8List tag) =>
      type(tag) == audio && tag.length > 16 && (tag[11] >> 4) == 10 && tag[12] == 0;

  /// Whether both tags carry the same bytes from the tag header's flags on
  /// (the trailing PreviousTagSize differs between CDNs).
  static bool samePayload(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 11; i < a.length - 4; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Streams one continuous FLV to a player while replacing expiring upstream
/// URLs underneath it.
///
/// Before [FlvLeasedSource.refreshAt] the next URL is resolved and connected
/// while the current one keeps streaming. The switch happens at the first
/// keyframe of the new connection that the old one has not delivered yet: the
/// old stream is forwarded up to that timestamp, then the new one from its
/// keyframe on. Both connections of one Douyu room carry the same stream
/// timestamps, so the player sees no gap, repeat or reset; a new connection on
/// another timeline is shifted to continue the old one. If the old stream ends
/// before a new URL is ready, the switch skips at most one GOP.
class FlvSpliceSession {
  /// Built by [FlvSpliceRelay] for one downstream connection.
  FlvSpliceSession._(
    this._source,
    this._open,
    this._renew,
    this._emit,
    this._onRenewed, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Longest wait for the old stream to reach the new keyframe. Tuned here:
  /// a longer wait rides out a slow CDN, a shorter one hands the cut to the
  /// player's own recovery instead of stalling on it.
  static const Duration handoverTimeout = Duration(seconds: 10);

  /// A new connection whose first video timestamp is further away than this
  /// from the delivered position is on another timeline and gets shifted.
  static const Duration alignmentWindow = Duration(seconds: 60);

  final FlvTagReaderOpener _open;
  final FlvSourceRenewer _renew;
  final void Function(Uint8List packet) _emit;
  final void Function(FlvLeasedSource source)? _onRenewed;
  final DateTime Function() _now;

  FlvLeasedSource _source;
  FlvTagReader? _reader;
  Future<Uint8List?>? _pending;
  int _offset = 0;
  int? _lastVideo;
  int? _lastAudio;
  Uint8List? _videoConfig;
  Uint8List? _audioConfig;
  bool _cancelled = false;
  int _switches = 0;

  int get switches => _switches;

  static final Object _deadline = Object();

  Future<void> run() async {
    final first = await _open(_source.url);
    _reader = first;
    final header = await first.next();
    if (header == null) throw const FormatException('Empty FLV upstream');
    _emit(header);
    try {
      while (!_cancelled) {
        final ended = await _pumpUntil(_source.refreshAt);
        if (_cancelled) return;
        if (!await _handover(oldEnded: ended)) {
          if (ended) return;
          // Keep the working connection; the next cut ends the session and the
          // player's own recovery takes over.
          _source = FlvLeasedSource(_source.url);
        }
      }
    } finally {
      await _dropReader();
    }
  }

  Future<void> cancel() async {
    _cancelled = true;
    await _dropReader();
  }

  /// Forwards the current reader until [deadline]. Returns true if it ended.
  Future<bool> _pumpUntil(DateTime? deadline) async {
    while (!_cancelled) {
      final next = await _nextBefore(deadline);
      if (identical(next, _deadline)) return false;
      if (next == null) return true;
      _forward(next as Uint8List, _offset);
    }
    return false;
  }

  Future<Object?> _nextBefore(DateTime? deadline) async {
    final reader = _reader!;
    final pending = _pending ??= reader.next();
    Object? result;
    if (deadline == null) {
      result = await pending;
    } else {
      final remaining = deadline.difference(_now());
      if (remaining <= Duration.zero) return _deadline;
      final timer = Completer<Object?>();
      final t = Timer(remaining, () {
        if (!timer.isCompleted) timer.complete(_deadline);
      });
      unawaited(
        pending.then(
          (value) {
            if (!timer.isCompleted) timer.complete(value);
          },
          onError: (Object error, StackTrace stack) {
            if (!timer.isCompleted) timer.completeError(error, stack);
          },
        ),
      );
      try {
        result = await timer.future;
      } finally {
        t.cancel();
      }
      if (identical(result, _deadline)) return _deadline;
    }
    _pending = null;
    return result;
  }

  Future<bool> _handover({required bool oldEnded}) async {
    final FlvLeasedSource next;
    final FlvTagReader reader;
    try {
      next = await _renew(_source);
      reader = await _open(next.url);
    } on Object catch (error) {
      _log.warning('splice: renewal failed, keeping the current upstream', error: error);
      return false;
    }
    if (_cancelled) {
      await reader.cancel();
      return false;
    }
    Uint8List? keyframe;
    Uint8List? videoConfig;
    Uint8List? audioConfig;
    int? offset;
    try {
      if (await reader.next().timeout(const Duration(seconds: 15)) == null) {
        throw const FormatException('Empty FLV upstream');
      }
      final searchEnd = _now().add(const Duration(seconds: 15));
      while (keyframe == null) {
        if (_now().isAfter(searchEnd)) throw TimeoutException('No keyframe on the new FLV upstream');
        final tag = await reader.next().timeout(const Duration(seconds: 15));
        if (tag == null) throw const FormatException('New FLV upstream ended before a keyframe');
        if (FlvTag.isVideoConfig(tag)) {
          videoConfig = tag;
          continue;
        }
        if (FlvTag.isAudioConfig(tag)) {
          audioConfig = tag;
          continue;
        }
        if (FlvTag.type(tag) != FlvTag.video) continue;
        final raw = FlvTag.timestamp(tag);
        if (offset == null) {
          final last = _lastVideo;
          offset = last == null || (raw - last).abs() <= alignmentWindow.inMilliseconds ? 0 : last + 1 - raw;
        }
        if (FlvTag.isKeyframe(tag) && (_lastVideo == null || raw + offset > _lastVideo!)) keyframe = tag;
      }
    } on Object catch (error) {
      _log.warning('splice: new upstream unusable, keeping the current one', error: error);
      await reader.cancel();
      return false;
    }
    final switchAt = FlvTag.timestamp(keyframe) + offset!;

    // Position the old stream had reached, for the "gap" the switch costs.
    final int? previousVideo = _lastVideo;

    if (!oldEnded) {
      // Deliver the old stream up to the new keyframe.
      final until = _now().add(handoverTimeout);
      while (!_cancelled) {
        final next = await _nextBefore(until);
        if (identical(next, _deadline) || next == null) break;
        final tag = next as Uint8List;
        final type = FlvTag.type(tag);
        final ts = FlvTag.timestamp(tag) + _offset;
        if (type == FlvTag.video && ts >= switchAt) break;
        if (type == FlvTag.audio && ts >= switchAt) continue;
        _forward(tag, _offset);
      }
    }
    await _dropReader();
    if (_cancelled) {
      await reader.cancel();
      return false;
    }

    _reader = reader;
    _offset = offset;
    _source = next;
    _switches++;
    if (videoConfig != null && (_videoConfig == null || !FlvTag.samePayload(videoConfig, _videoConfig!))) {
      _forward(FlvTag.withTimestamp(videoConfig, switchAt - offset), offset);
    }
    if (audioConfig != null && (_audioConfig == null || !FlvTag.samePayload(audioConfig, _audioConfig!))) {
      _forward(FlvTag.withTimestamp(audioConfig, switchAt - offset), offset);
    }
    _forward(keyframe, offset);
    _onRenewed?.call(next);

    _log.info(
      'splice: switched to a renewed upstream',
      fields: <String, Object?>{
        'switch': _switches,
        'gapMs': previousVideo == null ? null : switchAt - previousVideo,
        'offsetMs': offset,
        'upstream': _describe(next.url),
      },
    );

    return true;
  }

  void _forward(Uint8List tag, int offset) {
    final type = FlvTag.type(tag);
    if (type == FlvTag.script && _switches > 0) return;
    final ts = FlvTag.timestamp(tag) + offset;
    if (FlvTag.isVideoConfig(tag)) {
      _videoConfig = tag;
    } else if (FlvTag.isAudioConfig(tag)) {
      _audioConfig = tag;
    } else if (type == FlvTag.video) {
      if (_lastVideo != null && ts < _lastVideo!) return;
      _lastVideo = ts;
    } else if (type == FlvTag.audio) {
      if (_lastAudio != null && ts <= _lastAudio!) return;
      _lastAudio = ts;
    }
    _emit(offset == 0 ? tag : FlvTag.withTimestamp(tag, ts));
  }

  Future<void> _dropReader() async {
    final reader = _reader;
    _reader = null;
    final pending = _pending;
    _pending = null;
    pending?.ignore();
    if (reader != null) await reader.cancel();
  }
}

/// Loopback HTTP relay serving [FlvSpliceSession] to a native player.
///
/// ### Why this lives in the app
///
/// Nothing here is engine-specific: the problem is a *stream* whose URL lease
/// ends mid-playback (Douyu hands anonymous original quality a link that dies
/// after 300 s), and every engine that opened such a URL sees the CDN close the
/// connection, fail to reopen it cleanly — on this hardware the reopen is also
/// where the hardware decoder refuses to configure — and burn a line. Which
/// sources carry a lease and how a fresh URL is obtained is deployment
/// knowledge, so the decision and the mechanism both live here, and the player
/// (media_core) only ever sees a normal loopback URL.
///
/// The relay is a normal HTTP server on loopback; the native player must reach
/// it directly, so the URI handed to the player has to be exempt from any
/// configured proxy. media_core does that by itself: a source on loopback is
/// treated as a private input and never proxied.
class FlvSpliceRelay {
  FlvSpliceRelay._(this._server, this._source, this._renew, this._headers, this._findProxy, this._secret);

  final HttpServer _server;
  FlvLeasedSource _source;
  final FlvSourceRenewer _renew;
  final Map<String, String> _headers;
  final String Function(Uri) _findProxy;
  final String _secret;
  final Set<FlvSpliceSession> _sessions = <FlvSpliceSession>{};
  final Set<Future<void>> _serving = <Future<void>>{};
  StreamSubscription<HttpRequest>? _requests;
  Future<FlvLeasedSource>? _renewing;
  Future<void>? _closing;
  bool _closed = false;

  /// Whether the relay has been closed and must not be handed out again.
  bool get isClosed => _closed;

  /// The loopback URI the native player should open.
  Uri get inputUri => Uri(scheme: 'http', host: '127.0.0.1', port: _server.port, path: '/$_secret/live.flv');

  /// Plain FLV over HTTP(S) with a lease this app knows about. The lease is the
  /// opt-in: the caller only attaches one for platforms whose CDN closes the
  /// open connection when it ends (Douyu — `expire=300` anonymously, and the
  /// same schedule behind a signed-in `expire=0` link). Leases that only stop
  /// *new* connections never reach this relay, and every other input keeps its
  /// direct native connection.
  static bool appliesTo(String url, {required DateTime? refreshAt}) {
    if (refreshAt == null) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || !const <String>{'http', 'https'}.contains(uri.scheme.toLowerCase())) return false;
    return uri.path.toLowerCase().endsWith('.flv');
  }

  /// Binds the loopback server for [initial].
  ///
  /// [findProxy] resolves the upstream connections exactly like the player
  /// would have, so a configured proxy keeps applying to the CDN requests.
  static Future<FlvSpliceRelay> start(
    FlvLeasedSource initial, {
    required FlvSourceRenewer renew,
    required Map<String, String> headers,
    required String Function(Uri) findProxy,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0, shared: false);
    final random = Random.secure();
    final secret = base64UrlEncode(List<int>.generate(18, (_) => random.nextInt(256))).replaceAll('=', '');
    final relay = FlvSpliceRelay._(
      server,
      initial,
      renew,
      Map<String, String>.unmodifiable(headers),
      findProxy,
      secret,
    );
    relay._requests = server.listen((request) {
      if (request.method != 'GET' || request.uri.path != relay.inputUri.path || relay._closed) {
        unawaited(_reject(request, HttpStatus.notFound));
        return;
      }
      late final Future<void> serving;
      serving = relay._serve(request).whenComplete(() => relay._serving.remove(serving));
      relay._serving.add(serving);
    });

    final refreshAt = initial.refreshAt;
    _log.info(
      'splice: relay armed',
      fields: <String, Object?>{
        'upstream': _describe(initial.url),
        'local': relay.inputUri.port,
        'renewInMs': refreshAt?.difference(DateTime.now()).inMilliseconds,
      },
    );

    return relay;
  }

  /// Concurrent sessions (a native reconnect overlapping the old request)
  /// share one resolver call per lease.
  Future<FlvLeasedSource> _renewShared(FlvLeasedSource current) {
    if (!identical(current, _source)) return Future.value(_source);
    return _renewing ??= _renew(current)
        .then((next) {
          _source = next;
          return next;
        })
        .whenComplete(() => _renewing = null);
  }

  Future<FlvTagReader> _openUpstream(Uri url) async {
    final client = HttpClient()
      ..findProxy = _findProxy
      ..connectionTimeout = const Duration(seconds: 15)
      ..autoUncompress = true;
    try {
      final request = await client.getUrl(url);
      _headers.forEach((name, value) => request.headers.set(name, value));
      final response = await request.close().timeout(const Duration(seconds: 20));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('FLV upstream answered ${response.statusCode}', uri: url);
      }
      return _HttpFlvTagReader(client, response);
    } on Object {
      client.close(force: true);
      rethrow;
    }
  }

  Future<void> _serve(HttpRequest downstream) async {
    final response = downstream.response;
    var started = false;
    final session = FlvSpliceSession._(
      _source,
      _openUpstream,
      _renewShared,
      (packet) {
        if (!started) {
          started = true;
          response.headers.contentType = ContentType('video', 'x-flv');
          response.headers.set('cache-control', 'no-store');
          response.bufferOutput = false;
        }
        response.add(packet);
      },
      null,
    );
    _sessions.add(session);
    try {
      await session.run();
    } on Object catch (error) {
      _log.warning('splice: session ended', error: error);
      if (!started) {
        try {
          response.statusCode = HttpStatus.badGateway;
        } on StateError {
          /* Headers already sent. */
        }
      }
    } finally {
      _sessions.remove(session);
      try {
        await response.close();
      } on Object {
        /* The native reader may already have gone. */
      }
    }
  }

  /// Closes the server and every session. Idempotent.
  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    _closed = true;
    await Future.wait(_sessions.toList().map((session) => session.cancel()));
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

class _HttpFlvTagReader implements FlvTagReader {
  _HttpFlvTagReader(this._client, Stream<List<int>> body) {
    _subscription = body.listen(
      (chunk) {
        try {
          _queue.addAll(_framer.add(chunk));
        } on FormatException catch (error, stack) {
          _fail(error, stack);
          return;
        }
        _wake();
        // Bound memory while the session is not reading (it waits on the
        // other connection during a handover).
        if (_queue.length > 2048) _subscription.pause();
      },
      onError: (Object error, StackTrace stack) => _fail(error, stack),
      onDone: () {
        _done = true;
        _wake();
      },
      cancelOnError: true,
    );
  }

  final HttpClient _client;
  final FlvTagFramer _framer = FlvTagFramer();
  final ListQueue<Uint8List> _queue = ListQueue<Uint8List>();
  late final StreamSubscription<List<int>> _subscription;
  Completer<void>? _waiter;
  Object? _error;
  bool _done = false;

  void _wake() {
    final waiter = _waiter;
    _waiter = null;
    waiter?.complete();
  }

  void _fail(Object error, StackTrace stack) {
    _error = error;
    _done = true;
    _wake();
  }

  @override
  Future<Uint8List?> next() async {
    while (_queue.isEmpty) {
      if (_error != null) {
        // A reset or truncated body ends this connection like a clean close;
        // the session decides whether a new URL follows.
        _log.debug('splice: upstream connection ended', fields: <String, Object?>{'error': '$_error'});
        return null;
      }
      if (_done) return null;
      if (_subscription.isPaused) _subscription.resume();
      await (_waiter ??= Completer<void>()).future;
    }
    final packet = _queue.removeFirst();
    if (_queue.length < 512 && _subscription.isPaused) _subscription.resume();
    return packet;
  }

  @override
  Future<void> cancel() async {
    _done = true;
    _wake();
    _client.close(force: true);
    try {
      await _subscription.cancel();
    } on Object {
      /* Already failed. */
    }
  }
}
