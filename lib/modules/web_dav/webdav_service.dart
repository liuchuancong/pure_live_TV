import 'package:webdav_client/webdav_client.dart' as webdav;

class WebDAVService {
  final String url;
  final String username;
  final String password;

  late final webdav.Client _client;

  webdav.Client get client => _client;

  WebDAVService({required this.url, required this.username, required this.password}) {
    _client = webdav.newClient(url.trim(), user: username, password: password, debug: true);
  }

  Future<List<webdav.File>> readDirectory(String path) async {
    try {
      final response = await _client.readDir(path);
      if (response.isEmpty) {
        throw Exception('Empty response from server');
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
