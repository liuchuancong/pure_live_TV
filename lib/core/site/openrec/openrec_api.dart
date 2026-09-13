import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/core/common/request_scope.dart';

enum OpenrecFailure {
  transport,
  access,
  rateLimited,
  service,
  missing,
  schema,
  cancelled,
  restricted,
  notLive,
  mediaUnavailable,
  identity,
  ambiguous,
}

class OpenrecException implements Exception {
  const OpenrecException(this.kind);
  final OpenrecFailure kind;
  @override
  String toString() => 'Openrec ${kind.name}';
}

typedef OpenrecRequest = Future<({int status, String body})> Function(Uri uri, CancelToken? cancel);

class OpenrecChannel {
  OpenrecChannel({
    required this.id,
    required this.numericId,
    required this.name,
    required this.avatar,
    required this.isLive,
    required Iterable<String> movieIds,
  }) : movieIds = List.unmodifiable(movieIds);
  // /channels accepts the case-preserved public ID, not openrec_user_id or recxuser_id.
  final String id;
  final int numericId;
  final String name;
  final String avatar;
  final bool isLive;
  final List<String> movieIds;
}

class OpenrecMovie {
  const OpenrecMovie({
    required this.id,
    required this.channelId,
    required this.numericChannelId,
    required this.name,
    required this.avatar,
    required this.title,
    required this.cover,
    required this.viewers,
    required this.isLive,
    required this.publicMediaAllowed,
  });
  final String id;
  final String channelId;
  final int numericChannelId;
  final String name;
  final String avatar;
  final String title;
  final String cover;
  final int? viewers;
  final bool isLive;
  final bool publicMediaAllowed;
}

class OpenrecDirectory {
  OpenrecDirectory({
    required Iterable<OpenrecMovie> movies,
    required this.rawCount,
    required this.nextPage,
    required this.hasMore,
  }) : movies = List.unmodifiable(movies);
  final List<OpenrecMovie> movies;
  final int rawCount;
  final int nextPage;
  final bool hasMore;
}

class OpenrecMedia {
  const OpenrecMedia(this.id, this.url);
  // Source family, NOT a resolution, codec, or a guarantee of access/decoding.
  final String id;
  final String url;
}

class OpenrecBroadcast {
  OpenrecBroadcast(this.movie, Iterable<OpenrecMedia> media) : media = List.unmodifiable(media);
  final OpenrecMovie movie;
  final List<OpenrecMedia> media;
}

class OpenrecRoom {
  const OpenrecRoom(this.channel, this.broadcast);
  final OpenrecChannel channel;
  final OpenrecBroadcast? broadcast;
}

/// Anonymous v5 contracts for OPENREC, renamed mellow-fan in July 2026.
/// Data layer only; registration, HLS quality parsing and native acceptance are separate.
/// The shared Dio owns routing: a proxy failure never triggers hidden direct fallback.
class OpenrecApi {
  OpenrecApi({OpenrecRequest? request}) : _request = request ?? _defaultRequest;
  static const origin = 'https://public.mellow-fan.com';
  static const webOrigin = 'https://www.mellow-fan.com';
  static const responseLimit = 2 * 1024 * 1024;
  // Retain these on master, child playlist AND segment requests. Captured child
  // playlists returned 401 without them and 200 with them, without credentials.
  static const headers = {'User-Agent': 'Mozilla/5.0', 'Referer': '$webOrigin/', 'Origin': webOrigin};
  final OpenrecRequest _request;

  static Future<({int status, String body})> _defaultRequest(Uri uri, CancelToken? cancel) =>
      withRequestCancellation(cancel, (transport) async {
        final response = await HttpClient.instance.dio.get<ResponseBody>(
          uri.toString(),
          cancelToken: transport,
          options: Options(
            responseType: ResponseType.stream,
            followRedirects: false,
            headers: headers,
            receiveTimeout: const Duration(seconds: 20),
            validateStatus: (_) => true,
          ),
        );
        final body = response.data;
        if (body == null) throw const OpenrecException(OpenrecFailure.schema);
        if (response.statusCode != 200) {
          await body.stream.listen((_) {}).cancel();
          return (status: response.statusCode ?? 0, body: '');
        }
        return (status: 200, body: await readBody(body.stream));
      });

  static Future<String> readBody(Stream<List<int>> stream, {Duration timeout = const Duration(seconds: 20)}) async {
    final iterator = StreamIterator(stream);
    final bytes = BytesBuilder(copy: false);
    final watch = Stopwatch()..start();
    try {
      while (true) {
        final remaining = timeout - watch.elapsed;
        if (remaining <= Duration.zero) throw TimeoutException('Openrec response deadline');
        if (!await iterator.moveNext().timeout(remaining)) break;
        final chunk = iterator.current;
        if (bytes.length + chunk.length > responseLimit) throw const OpenrecException(OpenrecFailure.schema);
        bytes.add(chunk);
      }
      return utf8.decode(bytes.takeBytes());
    } on FormatException {
      throw const OpenrecException(OpenrecFailure.schema);
    } finally {
      watch.stop();
      await iterator.cancel();
    }
  }

  Future<String> _read(Uri uri, CancelToken? cancel) async {
    void checkCancelled() {
      if (cancel?.isCancelled == true) throw const OpenrecException(OpenrecFailure.cancelled);
    }

    checkCancelled();
    late final ({int status, String body}) response;
    try {
      response = await _request(uri, cancel);
    } catch (error) {
      checkCancelled();
      if (error is OpenrecException) rethrow;
      if (error is DioException && CancelToken.isCancel(error)) throw const OpenrecException(OpenrecFailure.cancelled);
      throw const OpenrecException(OpenrecFailure.transport);
    }
    checkCancelled();
    final failure = switch (response.status) {
      200 => null,
      401 || 403 => OpenrecFailure.access,
      404 => OpenrecFailure.missing,
      429 => OpenrecFailure.rateLimited,
      >= 500 => OpenrecFailure.service,
      _ => OpenrecFailure.transport,
    };
    if (failure != null) throw OpenrecException(failure);
    if (response.body.length > responseLimit || utf8.encode(response.body).length > responseLimit) {
      throw const OpenrecException(OpenrecFailure.schema);
    }
    return response.body;
  }

  Future<Object?> _get(String path, Map<String, String> query, CancelToken? cancel) async {
    final body = await _read(
      Uri.parse('$origin/external/api/v5/$path').replace(queryParameters: query.isEmpty ? null : query),
      cancel,
    );
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const OpenrecException(OpenrecFailure.schema);
    }
  }

  Future<String> manifest(String url, {CancelToken? cancel}) async => _read(Uri.parse(mediaUrl(url)), cancel);

  Future<OpenrecDirectory> directory({int page = 1, int limit = 30, CancelToken? cancel}) async {
    if (page < 1 || page > 1000000 || limit < 1 || limit > 30) throw const OpenrecException(OpenrecFailure.schema);
    final rows = _list(
      await _get('movies', {
        'is_live': 'true',
        'onair_status': '1',
        'page': '$page',
        'limit': '$limit',
        'sort': 'live_views',
      }, cancel),
    );
    final movies = <String, OpenrecMovie>{};
    for (final row in rows) {
      final movie = _movie(_object(row));
      if (!movie.isLive) continue;
      final previous = movies[movie.id];
      if (previous != null &&
          (previous.channelId != movie.channelId || previous.numericChannelId != movie.numericChannelId)) {
        throw const OpenrecException(OpenrecFailure.identity);
      }
      movies.putIfAbsent(movie.id, () => movie);
    }
    // v5 has no hasMore envelope and returned two rows for limit=1 in a live
    // probe. The requested limit is only a hint, not a proven server page size.
    // Only an explicitly empty raw page ends pagination, regardless of filtering.
    if (rows.isNotEmpty && page == 1000000) throw const OpenrecException(OpenrecFailure.schema);
    return OpenrecDirectory(movies: movies.values, rawCount: rows.length, nextPage: page + 1, hasMore: rows.isNotEmpty);
  }

  Future<OpenrecChannel> channel(String channelId, {int? expectedNumericId, CancelToken? cancel}) async {
    final id = _id(channelId);
    if (expectedNumericId != null) _positive(expectedNumericId);
    final data = _object(await _get('channels/$id', {}, cancel));
    final actualId = _id(data['id']);
    final numericId = _positive(data['openrec_user_id']);
    if (actualId != id || (expectedNumericId != null && expectedNumericId != numericId)) {
      throw const OpenrecException(OpenrecFailure.identity);
    }
    final live = _bool(data['is_live']);
    final ids = <String>{};
    for (final raw in _list(data['onair_broadcast_movies'])) {
      final movie = _movie(_object(raw));
      if (movie.channelId != id || movie.numericChannelId != numericId) {
        throw const OpenrecException(OpenrecFailure.identity);
      }
      if (!movie.isLive) throw const OpenrecException(OpenrecFailure.schema);
      ids.add(movie.id);
    }
    if (!live && ids.isNotEmpty) throw const OpenrecException(OpenrecFailure.schema);
    if (live && ids.isEmpty) throw const OpenrecException(OpenrecFailure.mediaUnavailable);
    return OpenrecChannel(
      id: id,
      numericId: numericId,
      name: _text(data['nickname']),
      avatar: _image(data['icon_image_url']),
      isLive: live,
      movieIds: ids,
    );
  }

  Future<Map<String, dynamic>> _movieData(String movieId, CancelToken? cancel) async =>
      _object(await _get('movies/${_id(movieId)}', {}, cancel));

  /// Share identity and metadata do not depend on permission to consume media.
  Future<OpenrecMovie> movie(String movieId, {CancelToken? cancel}) async {
    final id = _id(movieId);
    final result = _movie(await _movieData(id, cancel));
    if (result.id != id) throw const OpenrecException(OpenrecFailure.identity);
    return result;
  }

  Future<OpenrecBroadcast> broadcast(
    String movieId, {
    String? expectedChannelId,
    int? expectedNumericId,
    CancelToken? cancel,
  }) async {
    final id = _id(movieId);
    if (expectedChannelId != null) _id(expectedChannelId);
    if (expectedNumericId != null) _positive(expectedNumericId);
    final data = await _movieData(id, cancel);
    final result = _movie(data);
    if (result.id != id ||
        (expectedChannelId != null && result.channelId != expectedChannelId) ||
        (expectedNumericId != null && result.numericChannelId != expectedNumericId)) {
      throw const OpenrecException(OpenrecFailure.identity);
    }
    if (!result.isLive) throw const OpenrecException(OpenrecFailure.notLive);
    if (!result.publicMediaAllowed) throw const OpenrecException(OpenrecFailure.restricted);
    final media = _object(data['media']);
    final sources = <OpenrecMedia>[];
    final seen = <String>{};
    for (final entry in const {'url': 'hls', 'url_ull': 'low-latency-hls', 'url_public': 'public-hls'}.entries) {
      final value = media[entry.key];
      if (value == null || value == '') continue;
      final url = mediaUrl(value);
      if (seen.add(url)) sources.add(OpenrecMedia(entry.value, url));
    }
    // No trial, archive, audio-only or URL rewriting fallback.
    if (sources.isEmpty) throw const OpenrecException(OpenrecFailure.mediaUnavailable);
    return OpenrecBroadcast(result, sources);
  }

  Future<OpenrecRoom> room(String channelId, {int? expectedNumericId, CancelToken? cancel}) async {
    final owner = await channel(channelId, expectedNumericId: expectedNumericId, cancel: cancel);
    if (!owner.isLive) return OpenrecRoom(owner, null);
    if (owner.movieIds.length != 1) throw const OpenrecException(OpenrecFailure.ambiguous);
    final live = await broadcast(
      owner.movieIds.single,
      expectedChannelId: owner.id,
      expectedNumericId: owner.numericId,
      cancel: cancel,
    );
    return OpenrecRoom(owner, live);
  }

  static OpenrecMovie _movie(Map<String, dynamic> data) {
    final channel = _object(data['channel']);
    final status = data['onair_status'];
    if (status is! int || status < 0 || status > 2) throw const OpenrecException(OpenrecFailure.schema);
    final live = _bool(data['is_live']) && status == 1;
    final name = _text(channel['nickname']);
    final title = data['title'];
    if (title is! String) throw const OpenrecException(OpenrecFailure.schema);
    final publicType = _text(data['public_type']);
    if (!data.containsKey('ppv_event')) throw const OpenrecException(OpenrecFailure.schema);
    final hidden = _bool(data['is_hidden']);
    final banned = _bool(data['is_banned']);
    final expired = _bool(data['force_expired']);
    final premiere = _bool(data['is_premiere']);
    final encryption = data['encryption_type'];
    if (encryption is! int || encryption < 0) throw const OpenrecException(OpenrecFailure.schema);
    final viewersHidden = _bool(data['is_viewers_hidden']);
    final viewers = data['live_views'];
    if (!viewersHidden && viewers != null && (viewers is! int || viewers < 0)) {
      throw const OpenrecException(OpenrecFailure.schema);
    }
    return OpenrecMovie(
      id: _id(data['id']),
      channelId: _id(channel['id']),
      numericChannelId: _positive(channel['openrec_user_id']),
      name: name,
      avatar: _image(channel['icon_image_url']),
      title: title.trim().isEmpty ? name : title.trim(),
      cover: _image(data['thumbnail_url']),
      viewers: viewersHidden ? null : viewers as int?,
      isLive: live,
      publicMediaAllowed:
          publicType == 'all' &&
          !hidden &&
          !banned &&
          !expired &&
          !premiere &&
          encryption == 0 &&
          data['ppv_event'] == null,
    );
    // ended_at may be a future expiry while onair_status=1; total_views is
    // cumulative. Neither is used to infer offline state or concurrent viewers.
  }

  static Map<String, dynamic> _object(Object? value) {
    if (value is! Map<String, dynamic>) throw const OpenrecException(OpenrecFailure.schema);
    return value;
  }

  static List<dynamic> _list(Object? value) {
    if (value is! List || value.length > 1000) throw const OpenrecException(OpenrecFailure.schema);
    return value;
  }

  static bool _bool(Object? value) {
    if (value is! bool) throw const OpenrecException(OpenrecFailure.schema);
    return value;
  }

  static String _id(Object? value) {
    if (value is! String || !RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(value)) {
      throw const OpenrecException(OpenrecFailure.identity);
    }
    return value;
  }

  static int _positive(Object? value) {
    if (value is! int || value <= 0) throw const OpenrecException(OpenrecFailure.schema);
    return value;
  }

  static String _text(Object? value) {
    if (value is! String || value.trim().isEmpty) throw const OpenrecException(OpenrecFailure.schema);
    return value.trim();
  }

  static bool _trusted(Uri uri) =>
      uri.scheme == 'https' &&
      uri.userInfo.isEmpty &&
      uri.port == 443 &&
      !uri.hasFragment &&
      (RegExp(r'^[a-z0-9-]+\.cloudfront\.net$').hasMatch(uri.host) ||
          uri.host.endsWith('.openrec.tv') ||
          uri.host.endsWith('.mellow-fan.com'));
  static String _image(Object? value) {
    if (value is! String || value.length > 8192) return '';
    final uri = Uri.tryParse(value);
    return uri != null && _trusted(uri) ? value : '';
  }

  static String mediaUrl(Object? value) {
    if (value is! String || value.length > 8192 || value.contains(RegExp(r'\s'))) {
      throw const OpenrecException(OpenrecFailure.schema);
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !_trusted(uri) || !uri.path.endsWith('.m3u8')) {
      throw const OpenrecException(OpenrecFailure.schema);
    }
    return value;
  }
}
