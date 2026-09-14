// Normalizes a browser cookie header into a single safe value.
final RegExp _cookieControlCharacters = RegExp(r'[\u0000-\u001F\u007F]');

String normalizeAccountCookie(String value) {
  return value.replaceAll(_cookieControlCharacters, '').trim();
}
