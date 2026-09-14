import 'package:dio/dio.dart' show Headers;
import 'package:pure_live/shared/common/http_client.dart';

/// State of one Bilibili QR login attempt.
enum BiliBiliQrStatus { loading, unscanned, scanned, success, expired, failed }

/// A freshly generated QR session: [url] is encoded into the QR image and
/// [key] is the polling token.
class BiliBiliQrSession {
  const BiliBiliQrSession({required this.url, required this.key});

  final String url;
  final String key;
}

/// Result of one poll. [cookie] is only filled for [BiliBiliQrStatus.success].
class BiliBiliQrPoll {
  const BiliBiliQrPoll({required this.status, this.cookie = ''});

  final BiliBiliQrStatus status;
  final String cookie;
}

/// Bilibili QR-code login: generate a QR session and poll it until the user
/// confirms on the phone.
class BiliBiliQrLoginService {
  static const String _generateUrl = 'https://passport.bilibili.com/x/passport-login/web/qrcode/generate';
  static const String _pollUrl = 'https://passport.bilibili.com/x/passport-login/web/qrcode/poll';

  Future<BiliBiliQrSession> generate() async {
    final result = await HttpClient.instance.getJson(_generateUrl);
    if (result is! Map || result['code'] != 0) {
      throw StateError('${result is Map ? result['message'] : 'QR code request failed'}');
    }
    final data = (result['data'] as Map).cast<String, dynamic>();
    return BiliBiliQrSession(url: '${data['url']}', key: '${data['qrcode_key']}');
  }

  Future<BiliBiliQrPoll> poll(String key) async {
    final response = await HttpClient.instance.get(_pollUrl, queryParameters: {'qrcode_key': key});
    final body = response.data;
    if (body is! Map || body['code'] != 0) {
      return const BiliBiliQrPoll(status: BiliBiliQrStatus.failed);
    }
    final data = (body['data'] as Map).cast<String, dynamic>();
    return switch (data['code']) {
      0 => BiliBiliQrPoll(status: BiliBiliQrStatus.success, cookie: _cookieFrom(response.headers)),
      86038 => const BiliBiliQrPoll(status: BiliBiliQrStatus.expired),
      86090 => const BiliBiliQrPoll(status: BiliBiliQrStatus.scanned),
      _ => const BiliBiliQrPoll(status: BiliBiliQrStatus.unscanned),
    };
  }

  /// Joins `name=value` pairs of every `set-cookie` header.
  static String _cookieFrom(Headers headers) {
    final Object? raw = headers['set-cookie'] ?? headers['Set-Cookie'];
    final List<Object?> values = raw is List ? List<Object?>.from(raw) : <Object?>[if (raw != null) raw];
    final pairs = <String>[];
    for (final value in values) {
      final pair = '$value'.split(';').first.trim();
      if (pair.isNotEmpty) pairs.add(pair);
    }
    return pairs.join(';');
  }
}
