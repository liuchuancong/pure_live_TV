import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/core/common/request_scope.dart';

enum BigoFailure { transport, access, missing, rateLimited, service, api, schema, identity, cancelled }

enum BigoAccess { public, loginRequired, restricted }

class BigoException implements Exception {
  const BigoException(this.kind);
  final BigoFailure kind;
  @override
  String toString() => 'Bigo ${kind.name}';
}

class BigoDirectoryCard {
  const BigoDirectoryCard({
    required this.siteId,
    required this.ownerId,
    required this.broadcastId,
    required this.sid,
    required this.title,
    required this.nickname,
    required this.cover,
    required this.reportedViewers,
    required this.locked,
    required this.roomFlag,
  });
  final String siteId;
  final int ownerId;
  // JSON numbers here exceed JS's exact integer range. Preserve native int64
  // spelling; do not convert through a double or use it as the public site ID.
  final String broadcastId;
  final int sid;
  final String title;
  final String nickname;
  final String? cover;
  final int? reportedViewers;
  final bool locked;
  final int roomFlag;
}

/// Metadata only. Access-gated alive=0 is not a verified offline observation.
/// Media parsing/registration awaits an actual permitted media response.
class BigoStudioStatus {
  const BigoStudioStatus({
    required this.requestedSiteId,
    required this.ownerId,
    required this.canonicalSiteId,
    required this.access,
    required this.reportedAlive,
    required this.roomStatus,
    required this.roomType,
  });
  final String requestedSiteId;
  final String canonicalSiteId;
  final int ownerId;
  final BigoAccess access;
  final bool? reportedAlive;
  final int roomStatus;
  final String roomType;
}

typedef BigoRequest = Future<({int status, String body})> Function(
  String method,
  Uri uri,
  Map<String, String>? form,
  CancelToken cancel,
);

class BigoApi {
  BigoApi({BigoRequest? request, this.deadline = const Duration(seconds: 20)}) : _request = request ?? _defaultRequest;
  static const origin = 'https://ta.bigo.tv/official_website';
  static const webOrigin = 'https://www.bigo.tv';
  static const headers = {'Origin': webOrigin, 'Referer': '$webOrigin/', 'User-Agent': 'Mozilla/5.0'};
  static const responseLimit = 1024 * 1024;
  final BigoRequest _request;
  final Duration deadline;

  static Future<({int status, String body})> _defaultRequest(
    String method,
    Uri uri,
    Map<String, String>? form,
    CancelToken cancel,
  ) async {
    final response = await HttpClient.instance.dio.request<ResponseBody>(
      uri.toString(),
      data: form,
      cancelToken: cancel,
      options: Options(
        method: method,
        responseType: ResponseType.stream,
        followRedirects: false,
        headers: headers,
        contentType: form == null ? null : Headers.formUrlEncodedContentType,
        validateStatus: (_) => true,
      ),
    );
    final body = response.data;
    if (body == null) throw const BigoException(BigoFailure.schema);
    if (response.statusCode != 200) {
      await body.stream.listen((_) {}).cancel();
      return (status: response.statusCode ?? 0, body: '');
    }
    return (status: 200, body: await readBody(body.stream));
  }

  static Future<String> readBody(Stream<List<int>> source, {Duration timeout = const Duration(seconds: 20)}) async {
    final iterator = StreamIterator(source);
    final bytes = BytesBuilder(copy: false);
    final clock = Stopwatch()..start();
    try {
      while (true) {
        final remaining = timeout - clock.elapsed;
        if (remaining <= Duration.zero) throw TimeoutException('Bigo response deadline');
        if (!await iterator.moveNext().timeout(remaining)) break;
        if (bytes.length + iterator.current.length > responseLimit) throw const BigoException(BigoFailure.schema);
        bytes.add(iterator.current);
      }
      return utf8.decode(bytes.takeBytes());
    } on FormatException {
      throw const BigoException(BigoFailure.schema);
    } finally {
      clock.stop();
      await iterator.cancel();
    }
  }

  Future<T> _scope<T>(CancelToken? caller, Future<T> Function(CancelToken) work) =>
      withRequestCancellation(caller, (transport) async {
        if (transport.isCancelled) throw const BigoException(BigoFailure.cancelled);
        try {
          return await Future.any<T>([
            work(transport),
            transport.whenCancel.then<T>((_) => throw const BigoException(BigoFailure.cancelled)),
          ]).timeout(deadline);
        } on TimeoutException {
          throw const BigoException(BigoFailure.transport);
        } catch (error) {
          if (caller?.isCancelled == true) throw const BigoException(BigoFailure.cancelled);
          if (error is BigoException) rethrow;
          throw const BigoException(BigoFailure.transport);
        }
      });

  Future<Map<String, dynamic>> _read(String path, CancelToken cancel, {Map<String, String>? form}) async {
    if (cancel.isCancelled) throw const BigoException(BigoFailure.cancelled);
    final response = await _request(form == null ? 'GET' : 'POST', Uri.parse('$origin$path'), form, cancel);
    if (cancel.isCancelled) throw const BigoException(BigoFailure.cancelled);
    final failure = switch (response.status) {
      200 => null,
      401 || 403 => BigoFailure.access,
      404 => BigoFailure.missing,
      429 => BigoFailure.rateLimited,
      >= 500 => BigoFailure.service,
      _ => BigoFailure.transport,
    };
    if (failure != null) throw BigoException(failure);
    if (response.body.length > responseLimit || utf8.encode(response.body).length > responseLimit) {
      throw const BigoException(BigoFailure.schema);
    }
    try {
      return _object(jsonDecode(response.body));
    } on FormatException {
      throw const BigoException(BigoFailure.schema);
    }
  }

  /// Verified US/English homepage request; finite snapshot, not all rooms or
  /// a pagination contract. The server returned 20 rows despite fetchNum=10.
  Future<List<BigoDirectoryCard>> directory({CancelToken? cancel}) => _scope(
    cancel,
    (token) async =>
        parseDirectory(await _read('/OInterfaceWeb/vedioList/72?tabType=00&fetchNum=10&lang=en&countryCode=US', token)),
  );

  Future<BigoStudioStatus> studioStatus({required String siteId, required int expectedOwnerId, CancelToken? cancel}) =>
      _scope(cancel, (token) async {
        validateSiteId(siteId);
        _ownerId(expectedOwnerId);
        return parseStudioStatus(
          await _read('/studio/getInternalStudioInfo', token, form: {'siteId': siteId, 'supportHevc': '0'}),
          siteId: siteId,
          expectedOwnerId: expectedOwnerId,
        );
      });

  static Map<String, dynamic> _object(Object? value) {
    if (value is! Map<String, dynamic>) throw const BigoException(BigoFailure.schema);
    return value;
  }

  static String _text(Object? value) {
    if (value is! String) throw const BigoException(BigoFailure.schema);
    return value;
  }

  static int _number(Object? value) {
    if (value is! int || value < 0) throw const BigoException(BigoFailure.schema);
    return value;
  }

  static int _ownerId(Object? value) {
    if (value is! int || value < 1 || value > 9007199254740991) throw const BigoException(BigoFailure.identity);
    return value;
  }

  static String validateSiteId(String value) {
    if (!RegExp(r'^[A-Za-z0-9_][A-Za-z0-9_.-]{0,63}$').hasMatch(value)) {
      throw const BigoException(BigoFailure.identity);
    }
    return value;
  }

  static bool _binary(Object? value) {
    if (value is! int || (value != 0 && value != 1)) throw const BigoException(BigoFailure.schema);
    return value == 1;
  }

  static bool _boolean(Object? value) {
    if (value is! bool) throw const BigoException(BigoFailure.schema);
    return value;
  }

  static Map<String, dynamic> _success(Map<String, dynamic> json) {
    final code = json['code'];
    if (code is! int) throw const BigoException(BigoFailure.schema);
    if (code != 0) throw const BigoException(BigoFailure.api);
    return _object(json['data']);
  }

  static List<BigoDirectoryCard> parseDirectory(Map<String, dynamic> json) {
    final envelope = _success(json);
    if (envelope['resCode'] is! String) throw const BigoException(BigoFailure.schema);
    if (envelope['resCode'] != '0') throw const BigoException(BigoFailure.api);
    final rows = envelope['data'];
    if (rows is! List || rows.length > 500) throw const BigoException(BigoFailure.schema);
    final seen = <String>{};
    final owners = <int>{};
    final result = <BigoDirectoryCard>[];
    for (final row in rows) {
      final item = _object(row);
      final siteId = validateSiteId(_text(item['bigo_id']));
      final owner = _ownerId(item['owner']);
      if (!seen.add(siteId) || !owners.add(owner)) throw const BigoException(BigoFailure.identity);
      final broadcast = item['room_id'];
      if (broadcast is! int || broadcast < 1 || (kIsWeb && broadcast > 9007199254740991)) {
        throw const BigoException(BigoFailure.identity);
      }
      result.add(
        BigoDirectoryCard(
          siteId: siteId,
          ownerId: owner,
          broadcastId: broadcast.toString(),
          sid: _ownerId(item['sid']),
          title: _text(item['room_topic']),
          nickname: _text(item['nick_name']),
          cover: item['cover_m'] == null ? null : _text(item['cover_m']),
          reportedViewers: item['user_count'] == null ? null : _number(item['user_count']),
          locked: _binary(item['is_locked']),
          roomFlag: _number(item['room_flag']),
        ),
      );
    }
    return List.unmodifiable(result);
  }

  static BigoStudioStatus parseStudioStatus(
    Map<String, dynamic> json, {
    required String siteId,
    required int expectedOwnerId,
  }) {
    validateSiteId(siteId);
    _ownerId(expectedOwnerId);
    final data = _success(json);
    final owner = _ownerId(data['uid']);
    if (owner != expectedOwnerId) throw const BigoException(BigoFailure.identity);
    final login = _boolean(data['needLogin']);
    final password = _boolean(data['passRoom']);
    final paid = _text(data['isPaidShow']);
    if (!{'', '0', '1'}.contains(paid)) throw const BigoException(BigoFailure.schema);
    final alive = _binary(data['alive']);
    final access = login
        ? BigoAccess.loginRequired
        : (password || paid == '1')
        ? BigoAccess.restricted
        : BigoAccess.public;
    return BigoStudioStatus(
      requestedSiteId: siteId,
      ownerId: owner,
      canonicalSiteId: validateSiteId(_text(data['clientBigoId'])),
      access: access,
      reportedAlive: access == BigoAccess.public ? alive : null,
      roomStatus: _number(data['roomStatus']),
      roomType: _text(data['roomType']),
    );
  }
}
