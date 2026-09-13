// 同步自 pure_live cookie_value.dart：把浏览器 Cookie 头文本归一化为安全单值。
final RegExp _cookieControlCharacters = RegExp(r'[\u0000-\u001F\u007F]');

String normalizeAccountCookie(String value) {
  return value.replaceAll(_cookieControlCharacters, '').trim();
}
