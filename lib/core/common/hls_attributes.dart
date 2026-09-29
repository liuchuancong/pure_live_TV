/// Parses the comma-separated attribute list of an HLS tag, such as the
/// payload of `#EXT-X-MEDIA:` or `#EXT-X-KEY:`.
///
/// Values may be quoted. CR, LF and NUL are rejected inside quotes, a repeated
/// attribute name is malformed, and a trailing comma means the list was cut
/// short. [onError] lets each caller raise its own error type.
Map<String, String> parseHlsAttributes(
  String text, {
  required Never Function(String message) onError,
}) {
  final values = <String, String>{};
  final pattern = RegExp(r'([A-Z0-9-]+)=("[^"\r\n\x00]*"|[^,\s"]+)(?:,|$)');
  var offset = 0;
  while (offset < text.length) {
    final match = pattern.matchAsPrefix(text, offset);
    if (match == null || values.containsKey(match[1])) {
      onError('Malformed HLS attributes');
    }
    final value = match[2]!;
    values[match[1]!] = value.startsWith('"')
        ? value.substring(1, value.length - 1)
        : value;
    offset = match.end;
  }
  if (text.endsWith(',')) onError('Incomplete HLS attributes');
  return values;
}
