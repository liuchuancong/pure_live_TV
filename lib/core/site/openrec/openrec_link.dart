import 'openrec_api.dart';

enum OpenrecLinkKind { channel, movie }

class OpenrecLink {
  const OpenrecLink(this.kind, this.id);
  final OpenrecLinkKind kind;
  final String id;
  static bool validId(String value) =>
      RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(value) && !value.contains(RegExp(r'\s'));

  static OpenrecLink? parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.userInfo.isNotEmpty ||
        (uri.hasPort && uri.port != (uri.scheme == 'https' ? 443 : 80)) ||
        !{'openrec.tv', 'www.openrec.tv', 'mellow-fan.com', 'www.mellow-fan.com'}.contains(uri.host)) {
      return null;
    }
    // Reject encoded path separators/IDs and traversal before Uri normalization.
    final rawPath = raw.trim().split('://').last.split(RegExp(r'[?#]')).first;
    if (rawPath.contains('%') || rawPath.contains('\\') || rawPath.contains('/./') || rawPath.contains('/../')) {
      return null;
    }
    final match = RegExp(r'^/(user|live|movie)/([A-Za-z0-9_-]{1,64})/?$').firstMatch(uri.path);
    if (match == null) return null;
    return OpenrecLink(match[1] == 'user' ? OpenrecLinkKind.channel : OpenrecLinkKind.movie, match[2]!);
  }
}

/// Pin the numeric owner alongside the public lookup ID. A renamed/reassigned
/// slug must produce an error rather than reconnect a saved room to someone else.
class OpenrecRoomKey {
  const OpenrecRoomKey._(this.channelId, this.numericId);
  final String channelId;
  final int numericId;
  static OpenrecRoomKey create(String channelId, int numericId) {
    if (!OpenrecLink.validId(channelId) || numericId < 1 || numericId > 9007199254740991) {
      throw const OpenrecException(OpenrecFailure.identity);
    }
    return OpenrecRoomKey._(channelId, numericId);
  }

  static OpenrecRoomKey parse(String raw) {
    final parts = raw.split('@');
    if (parts.length != 2 || !RegExp(r'^[1-9][0-9]{0,15}$').hasMatch(parts[1])) {
      throw const OpenrecException(OpenrecFailure.identity);
    }
    return create(parts[0], int.parse(parts[1]));
  }

  String get value => '$channelId@$numericId';
  String get url => '${OpenrecApi.webOrigin}/user/$channelId';
}
