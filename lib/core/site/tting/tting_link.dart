/// Exact public channel routes. Numeric owner IDs and broadcast IDs are not
/// interchangeable with the channel ID used by /api/channels.
class TtingLink {
  static int? parse(String raw) {
    final value = raw.trim();
    if (RegExp(r'^[1-9][0-9]{0,15}$').hasMatch(value)) return _id(value);
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !{'https', 'http'}.contains(uri.scheme) ||
        uri.userInfo.isNotEmpty ||
        (uri.hasPort && uri.port != (uri.scheme == 'https' ? 443 : 80)) ||
        !{'www.flextv.co.kr', 'flextv.co.kr', 'www.ttinglive.com', 'ttinglive.com'}.contains(uri.host)) {
      return null;
    }
    final path = value.split('://').last.split(RegExp(r'[?#]')).first;
    if (path.contains('%') || path.contains('\\') || path.contains('/./') || path.contains('/../')) return null;
    final match = RegExp(r'^/channels/([1-9][0-9]{0,15})/live/?$').firstMatch(uri.path);
    return match == null ? null : _id(match[1]!);
  }

  static int? _id(String value) {
    final id = int.tryParse(value);
    return id != null && id <= 9007199254740991 ? id : null;
  }

  static String url(int id) => 'https://www.flextv.co.kr/channels/$id/live';
}
