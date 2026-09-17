import 'dart:convert';

/// Canonicalizes externally supplied HTTP fields before they cross a native
/// player or FFmpeg boundary. Header names are case-insensitive, while the
/// persisted representation is deterministic so playlist refreshes do not
/// create changes from map iteration order alone.
class HttpHeaderPolicy {
  const HttpHeaderPolicy._();

  static final RegExp _validName = RegExp(r'^[a-z0-9-]+$');

  static Map<String, String> normalize(Map<dynamic, dynamic>? source) {
    if (source == null || source.isEmpty) return const <String, String>{};
    final result = <String, String>{};
    for (final entry in source.entries) {
      if (entry.key is! String || entry.value is! String) continue;
      final name = canonicalName(entry.key as String);
      final value = (entry.value as String).replaceAll(RegExp(r'[\u0000-\u001F\u007F]+'), ' ').trim();
      if (name != null && value.isNotEmpty) result[name] = value;
    }
    if (result.isEmpty) return const <String, String>{};
    final sorted = result.entries.toList()..sort((left, right) => left.key.compareTo(right.key));
    return Map<String, String>.unmodifiable({for (final entry in sorted) entry.key: entry.value});
  }

  static String? canonicalName(String raw) {
    var name = raw.trim().toLowerCase();
    if (name.startsWith('!')) name = name.substring(1);
    name = switch (name) {
      'http-user-agent' => 'user-agent',
      'http-referrer' || 'http-referer' || 'referrer' => 'referer',
      'cookies' => 'cookie',
      _ => name,
    };
    return name.isNotEmpty && _validName.hasMatch(name) ? name : null;
  }

  static String? encode(Map<dynamic, dynamic>? source) {
    final normalized = normalize(source);
    return normalized.isEmpty ? null : jsonEncode(normalized);
  }

  static Map<String, String> decode(String? encoded) {
    final value = encoded?.trim();
    if (value == null || value.isEmpty) return const <String, String>{};
    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? normalize(decoded) : const <String, String>{};
    } on FormatException {
      return const <String, String>{};
    }
  }

  /// Adds [headers] to every entry of an m3u/m3u8 playlist as `#EXTHTTP:` directives.
  ///
  /// This is how a source that needs its own UA/Referer/Cookie carries them without a
  /// database write: the parser reads per-entry headers from those directives, and
  /// `#EXTHTTP:` — unlike `#EXTVLCOPT:`, which only accepts `user-agent` and `referer` —
  /// takes any header. The directive goes **before** each `#EXTINF`, which is where the
  /// parser expects the headers of the entry that follows.
  static String mergeIntoM3u(String playlist, Map<dynamic, dynamic>? headers) {
    final normalized = normalize(headers);
    if (normalized.isEmpty) return playlist;

    final directive = '#EXTHTTP:${jsonEncode(normalized)}';
    final buffer = StringBuffer();
    for (final line in playlist.split('\n')) {
      if (line.trimLeft().startsWith('#EXTINF')) buffer.writeln(directive);
      buffer.writeln(line);
    }
    return buffer.toString();
  }
}
