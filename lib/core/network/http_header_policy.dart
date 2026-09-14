/// HTTP 请求头归一化策略：键转小写、去空白值。
class HttpHeaderPolicy {
  const HttpHeaderPolicy._();

  static Map<String, String> normalize(Map<String, String> headers) {
    final result = <String, String>{};
    for (final entry in headers.entries) {
      final key = entry.key.trim().toLowerCase();
      final value = entry.value.trim();
      if (key.isEmpty || value.isEmpty) continue;
      result[key] = value;
    }
    return result;
  }
}
