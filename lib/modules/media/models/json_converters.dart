/// The lenient scalar handling every bilibili JSON answer needs: the web API
/// happily returns numbers as strings, omits fields, and ships `//`-rooted
/// CDN urls. Codegen models wire these through `@JsonKey(fromJson: ...)`
/// per field; hand-written parsers call them directly.
library;

/// `int.tryParse(value.toString())` with a 0 fallback — bilibili answers
/// count fields as `123`, `"123"` or nothing.
int lenientIntOf(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;

/// `double.tryParse(value.toString())` with a 0 fallback (coins, ratings).
double lenientDoubleOf(Object? value) => double.tryParse(value?.toString() ?? '') ?? 0;

/// `value.toString()` with an empty fallback — for fields the API sometimes
/// omits or sends as numbers.
String lenientStringOf(Object? value) => value?.toString() ?? '';

/// Protocol-relative CDN urls (`//i0.hdslb.com/...`) become https urls.
String httpsUrl(String url) => url.startsWith('//') ? 'https:$url' : url;

/// The [httpsUrl] shape @JsonKey(fromJson:) takes.
String httpsUrlOf(Object? value) => httpsUrl(value?.toString() ?? '');

/// Drops the `<em>` highlight wrappers search results wrap titles in.
String stripHtml(String text) => text.replaceAll(RegExp(r'</?em[^>]*>'), '');

/// The [stripHtml] shape @JsonKey(fromJson:) takes.
String stripHtmlOf(Object? value) => stripHtml(value?.toString() ?? '');

/// Search results and dynamics carry "mm:ss" (or "hh:mm:ss") strings instead
/// of seconds; anything else parses as 0.
int durationTextToSeconds(String text) {
  final parts = text.split(':');
  if (parts.length == 2) {
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }
  if (parts.length == 3) {
    return (int.tryParse(parts[0]) ?? 0) * 3600 + (int.tryParse(parts[1]) ?? 0) * 60 + (int.tryParse(parts[2]) ?? 0);
  }
  return 0;
}

/// A unix-seconds timestamp as `yyyy/MM/dd`; empty for non-positive values.
String formatTimestamp(int seconds) {
  if (seconds <= 0) return '';
  final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}
