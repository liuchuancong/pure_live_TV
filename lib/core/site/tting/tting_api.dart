import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pure_live/core/common/hls_source_query_policy.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/core/common/request_scope.dart';

enum TtingFailure {
  transport,
  access,
  missing,
  rateLimited,
  service,
  schema,
  identity,
  restricted,
  notLive,
  expired,
  mediaUnavailable,
  cancelled,
}

class TtingException implements Exception {
  const TtingException(this.kind);
  final TtingFailure kind;
  @override
  String toString() => 'TTing ${kind.name}';
}

typedef TtingRequest = Future<({int status, String body})> Function(Uri uri, CancelToken cancel);

class TtingChannel {
  const TtingChannel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.nickname,
    required this.avatar,
    required this.isLive,
    required this.restricted,
  });
  final int id;
  final int ownerId;
  final String name;
  final String nickname;
  final String avatar;
  final bool isLive;
  final bool restricted;
}

class TtingSource {
  const TtingSource(this.family, this.resolution, this.url, this.policy, this.expiresAt);
  final String family;
  final int resolution;
  final String url;
  final HlsSourceQueryPolicy policy;
  final DateTime expiresAt;
}

class TtingBroadcast {
  TtingBroadcast({
    required this.channel,
    required this.id,
    required this.title,
    required this.cover,
    required Iterable<TtingSource> sources,
  }) : sources = List.unmodifiable(sources);
  final TtingChannel channel;
  final int id;
  final String title;
  final String cover;
  final List<TtingSource> sources;
}

class TtingDirectoryCard {
  const TtingDirectoryCard(this.id, this.title, this.nickname, this.avatar, this.cover, this.viewers);
  final int id;
  final String title;
  final String nickname;
  final String avatar;
  final String cover;
  final int? viewers;
}

/// Anonymous FLEX contracts observed through the official TTing redirect.
/// No account, cross-host fallback, global token cache or guessed pagination.
class TtingApi {
  TtingApi({TtingRequest? request, this.deadline = const Duration(seconds: 20), DateTime Function()? now})
    : _request = request ?? _defaultRequest,
      _now = now ?? DateTime.now;
  static const origin = 'https://api.flextv.co.kr';
  static const webOrigin = 'https://www.flextv.co.kr';
  static const responseLimit = 1024 * 1024;
  static const playHeaders = {'Referer': '$webOrigin/', 'Origin': webOrigin, 'User-Agent': 'Mozilla/5.0'};
  static const apiHeaders = {...playHeaders, 'x-site-code': 'flex'};
  final TtingRequest _request;
  final Duration deadline;
  final DateTime Function() _now;

  static Future<({int status, String body})> _defaultRequest(Uri uri, CancelToken cancel) async {
    final response = await HttpClient.instance.dio.get<ResponseBody>(
      uri.toString(),
      cancelToken: cancel,
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: false,
        headers: apiHeaders,
        validateStatus: (_) => true,
      ),
    );
    final body = response.data;
    if (body == null) throw const TtingException(TtingFailure.schema);
    if (response.statusCode != 200) {
      await body.stream.listen((_) {}).cancel();
      return (status: response.statusCode ?? 0, body: '');
    }
    return (status: 200, body: await readBody(body.stream));
  }

  static Future<String> readBody(Stream<List<int>> stream, {Duration timeout = const Duration(seconds: 20)}) async {
    final bytes = BytesBuilder(copy: false);
    final iterator = StreamIterator(stream);
    final watch = Stopwatch()..start();
    try {
      while (true) {
        final remaining = timeout - watch.elapsed;
        if (remaining <= Duration.zero) throw TimeoutException('TTing body deadline');
        if (!await iterator.moveNext().timeout(remaining)) break;
        final chunk = iterator.current;
        if (bytes.length + chunk.length > responseLimit) throw const TtingException(TtingFailure.schema);
        bytes.add(chunk);
      }
      return utf8.decode(bytes.takeBytes());
    } on FormatException {
      throw const TtingException(TtingFailure.schema);
    } finally {
      watch.stop();
      await iterator.cancel();
    }
  }

  Future<T> _scope<T>(CancelToken? caller, Future<T> Function(CancelToken) work) =>
      withRequestCancellation(caller, (transport) async {
        if (transport.isCancelled) throw const TtingException(TtingFailure.cancelled);
        try {
          return await Future.any<T>([
            work(transport),
            transport.whenCancel.then<T>((_) => throw const TtingException(TtingFailure.cancelled)),
          ]).timeout(deadline);
        } on TimeoutException {
          throw const TtingException(TtingFailure.transport);
        } catch (error) {
          if (caller?.isCancelled == true) throw const TtingException(TtingFailure.cancelled);
          if (error is TtingException) rethrow;
          throw const TtingException(TtingFailure.transport);
        }
      });

  Future<Map<String, dynamic>> _read(String path, CancelToken cancel) async {
    if (cancel.isCancelled) throw const TtingException(TtingFailure.cancelled);
    final response = await _request(Uri.parse('$origin$path'), cancel);
    if (cancel.isCancelled) throw const TtingException(TtingFailure.cancelled);
    final failure = switch (response.status) {
      200 => null,
      401 || 403 => TtingFailure.access,
      404 => TtingFailure.missing,
      429 => TtingFailure.rateLimited,
      >= 500 => TtingFailure.service,
      _ => TtingFailure.transport,
    };
    if (failure != null) throw TtingException(failure);
    if (response.body.length > responseLimit || utf8.encode(response.body).length > responseLimit) {
      throw const TtingException(TtingFailure.schema);
    }
    try {
      return object(jsonDecode(response.body));
    } on FormatException {
      throw const TtingException(TtingFailure.schema);
    }
  }

  Future<TtingChannel> channel(int id, {CancelToken? cancel}) => _scope(cancel, (token) async {
    positiveId(id);
    return parseChannel(await _read('/api/channels/$id/profile', token), expectedId: id);
  });

  /// One deadline owns both identity lookup and stream acquisition.
  Future<({TtingChannel channel, TtingBroadcast? broadcast})> room(int id, {CancelToken? cancel}) => _scope(cancel, (
    token,
  ) async {
    positiveId(id);
    final channel = parseChannel(await _read('/api/channels/$id/profile', token), expectedId: id);
    if (!channel.isLive) return (channel: channel, broadcast: null);
    if (channel.restricted) throw const TtingException(TtingFailure.restricted);
    final broadcast = parseBroadcast(await _read('/api/channels/$id/stream?option=all', token), channel, now: _now());
    return (channel: channel, broadcast: broadcast);
  });

  Future<List<TtingDirectoryCard>> directory({CancelToken? cancel}) => _scope(
    cancel,
    (token) async =>
        parseDirectory(await _read('/api/channels/live-list-main?includeAdult=false&liveOption=total', token)),
  );

  static Map<String, dynamic> object(Object? value) {
    if (value is! Map<String, dynamic>) throw const TtingException(TtingFailure.schema);
    return value;
  }

  static int positiveId(Object? value) {
    if (value is! int || value < 1 || value > 9007199254740991) throw const TtingException(TtingFailure.identity);
    return value;
  }

  static bool flag(Object? value) {
    if (value is bool) return value;
    if (value is int && value == 1) return true;
    if (value is int && value == 0) return false;
    throw const TtingException(TtingFailure.schema);
  }

  static String text(Object? value) => value is String ? value.trim() : '';
  static String image(Object? value) {
    final raw = text(value);
    final uri = Uri.tryParse(raw);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty && uri.userInfo.isEmpty ? raw : '';
  }

  static bool _barrier(Object? raw) {
    final map = object(raw);
    final values = [flag(map['blind']), flag(map['suspended']), flag(map['isLocked']), flag(map['isForAdult'])];
    final level = map['minRatingLevel'];
    if (level is! int || level < 0) throw const TtingException(TtingFailure.schema);
    if (map.containsKey('isBanned')) values.add(flag(map['isBanned']));
    if (map.containsKey('visitAllow')) values.add(flag(map['visitAllow']));
    return values.any((v) => v) || level > 0;
  }

  static TtingChannel parseChannel(Map<String, dynamic> map, {required int expectedId}) {
    final id = positiveId(map['id']);
    if (id != expectedId) throw const TtingException(TtingFailure.identity);
    final owner = object(map['owner']);
    return TtingChannel(
      id: id,
      ownerId: positiveId(owner['id']),
      name: text(map['name']),
      nickname: text(owner['nickname']),
      avatar: image(owner['thumbUrl']),
      isLive: flag(map['isInLive']),
      restricted: _barrier(map['barrier']) || owner['channelStop'] != null || map['channelStop'] != null,
    );
  }

  static bool _timestampPresent(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key)) throw const TtingException(TtingFailure.schema);
    final value = map[key];
    if (value == null) return false;
    if (value is! String || DateTime.tryParse(value) == null) throw const TtingException(TtingFailure.schema);
    return true;
  }

  static TtingBroadcast parseBroadcast(Map<String, dynamic> map, TtingChannel channel, {required DateTime now}) {
    final stream = object(map['stream']);
    final owner = object(map['owner']);
    if (positiveId(map['id']) != channel.id ||
        positiveId(stream['channelId']) != channel.id ||
        positiveId(owner['id']) != channel.ownerId) {
      throw const TtingException(TtingFailure.identity);
    }
    final broadcastId = positiveId(stream['id']);
    final ended = _timestampPresent(stream, 'endedAt');
    final disconnected = _timestampPresent(stream, 'disconnectedAt');
    final finalized = flag(stream['finalized']);
    if (!channel.isLive || ended || disconnected || finalized) throw const TtingException(TtingFailure.notLive);
    final status = object(map['status']);
    final streamBarrier = [
      flag(stream['suspended']),
      flag(stream['blind']),
      flag(stream['isForAdult']),
      flag(stream['visitAllow']),
    ];
    final rating = stream['minRatingLevel'];
    if (rating is! int || rating < 0 || stream['password'] is! String) throw const TtingException(TtingFailure.schema);
    if (channel.restricted ||
        _barrier(status['barrier']) ||
        streamBarrier.any((v) => v) ||
        rating > 0 ||
        text(stream['password']).isNotEmpty ||
        owner['channelStop'] != null) {
      throw const TtingException(TtingFailure.restricted);
    }
    final family = map['sourceType'];
    if (family != 'ncp' && family != 'ncp_llh') throw const TtingException(TtingFailure.mediaUnavailable);
    final raw = map['sources'];
    if (raw is! List || raw.length > 32) throw const TtingException(TtingFailure.schema);
    final sources = <TtingSource>[];
    final resolutions = <int>{};
    for (final entry in raw) {
      final source = object(entry);
      if (source['format'] != family) throw const TtingException(TtingFailure.mediaUnavailable);
      final resolution = source['resolution'];
      if (resolution is! int || resolution < 0 || resolution > 8640 || !resolutions.add(resolution)) {
        throw const TtingException(TtingFailure.schema);
      }
      final url = text(source['url']);
      final uri = Uri.tryParse(url);
      if (uri == null ||
          uri.scheme != 'https' ||
          !uri.host.endsWith('.edge.naverncp.com') ||
          uri.userInfo.isNotEmpty ||
          (uri.hasPort && uri.port != 443) ||
          !uri.path.endsWith('.m3u8')) {
        throw const TtingException(TtingFailure.schema);
      }
      late final HlsSourceQueryPolicy policy;
      try {
        policy = HlsSourceQueryPolicy.fromSource(uri);
      } catch (_) {
        throw const TtingException(TtingFailure.schema);
      }
      final expiryFields = (uri.queryParameters['token'] ?? '')
          .split('~')
          .where((part) => part.startsWith('exp='))
          .toList();
      if (expiryFields.length != 1 || !RegExp(r'^exp=[0-9]{1,10}$').hasMatch(expiryFields.single)) {
        throw const TtingException(TtingFailure.schema);
      }
      final expires = DateTime.fromMillisecondsSinceEpoch(
        int.parse(expiryFields.single.substring(4)) * 1000,
        isUtc: true,
      );
      if (!expires.isAfter(now.toUtc())) throw const TtingException(TtingFailure.expired);
      sources.add(TtingSource(family as String, resolution, url, policy, expires));
    }
    if (sources.isEmpty) throw const TtingException(TtingFailure.mediaUnavailable);
    sources.sort((a, b) => b.resolution.compareTo(a.resolution));
    return TtingBroadcast(
      channel: channel,
      id: broadcastId,
      title: text(stream['title']),
      cover: image(map['thumbUrl']),
      sources: sources,
    );
  }

  static List<TtingDirectoryCard> parseDirectory(Map<String, dynamic> map) {
    final data = map['data'];
    final count = map['count'];
    if (data is! List || data.length > 500 || count is! int || count != data.length) {
      throw const TtingException(TtingFailure.schema);
    }
    final result = <TtingDirectoryCard>[];
    final ids = <int>{};
    for (final raw in data) {
      final item = object(raw);
      final id = positiveId(item['channelId']);
      if (!ids.add(id)) throw const TtingException(TtingFailure.identity);
      final live = flag(item['isInLive']);
      final ended = _timestampPresent(item, 'endedAt');
      final restricted = _barrier(item['barrier']);
      if (!live || ended || restricted) continue;
      final owner = object(item['owner']);
      final viewers = item['playerCount'];
      if (viewers != null && (viewers is! int || viewers < 0)) throw const TtingException(TtingFailure.schema);
      result.add(
        TtingDirectoryCard(
          id,
          text(item['title']),
          text(owner['nickname']),
          image(owner['thumbUrl']),
          image(item['thumbUrl']),
          viewers as int?,
        ),
      );
    }
    return List.unmodifiable(result);
  }
}
