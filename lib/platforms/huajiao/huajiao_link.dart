enum HuajiaoLinkKind { owner, broadcast }

class HuajiaoLink {
  const HuajiaoLink(this.kind, this.id);
  final HuajiaoLinkKind kind;
  final String id;
  static bool validId(String id) => RegExp(r'^[1-9][0-9]{0,15}$').hasMatch(id);
  static String ownerUrl(String uid) {
    if (!validId(uid)) throw const FormatException('Invalid Huajiao owner ID');
    return 'https://h.huajiao.com/site/profile_$uid.html';
  }

  static HuajiaoLink? parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.userInfo.isNotEmpty ||
        (uri.hasPort && uri.port != (uri.scheme == 'https' ? 443 : 80))) {
      return null;
    }
    final host = uri.host.toLowerCase();
    if (!{'huajiao.com', 'www.huajiao.com', 'h.huajiao.com'}.contains(host)) return null;
    try {
      if (host == 'h.huajiao.com') {
        final owner = RegExp(r'^/site/profile_([1-9][0-9]{0,15})\.html$').firstMatch(uri.path);
        if (owner != null) return HuajiaoLink(HuajiaoLinkKind.owner, owner[1]!);
        if (uri.path == '/l/index') {
          final ids = uri.queryParametersAll['liveid'];
          if (ids?.length == 1 && validId(ids!.single)) {
            return HuajiaoLink(HuajiaoLinkKind.broadcast, ids.single);
          }
        }
      } else {
        final match = RegExp(r'^/(user|l)/([1-9][0-9]{0,15})/?$').firstMatch(uri.path);
        if (match != null) {
          return HuajiaoLink(match[1] == 'user' ? HuajiaoLinkKind.owner : HuajiaoLinkKind.broadcast, match[2]!);
        }
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}
