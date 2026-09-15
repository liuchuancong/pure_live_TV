/// Builds candidate URLs for a file hosted in a GitHub repository.
///
/// The direct origin URL is almost always blocked or throttled on mainland
/// networks, so a list of proxies and CDNs is offered instead. Callers are
/// expected to race them, for example through `RaceHttp.findFastestUrl`.
class GitHubMirror {
  final String owner;
  final String repo;
  final String branch;

  GitHubMirror({required this.owner, required this.repo, this.branch = 'master'});

  /// Direct origin URL for a single file.
  String rawUrl(String filePath) {
    return 'https://raw.githubusercontent.com/$owner/$repo/$branch/$filePath';
  }

  /// jsDelivr CDN.
  String jsdelivr(String filePath) {
    return 'https://cdn.jsdelivr.net/gh/$owner/$repo@$branch/$filePath';
  }

  /// jsDelivr's Fastly-backed CDN, useful when the default edge is slow.
  String jsdelivrFastly(String filePath) {
    return 'https://fastly.jsdelivr.net/gh/$owner/$repo@$branch/$filePath';
  }

  /// Every candidate URL for [filePath], origin first and CDNs last.
  List<String> mirrors(String filePath) {
    final raw = rawUrl(filePath);
    return [
      raw,
      'https://hub.glowp.xyz/$raw',
      'https://hk.gh-proxy.org/$raw',
      'https://raw.kkgithub.com/$owner/$repo/$branch/$filePath',
      'https://wget.la/$raw',
      'https://ghproxy.net/$raw',
      'https://ghfast.top/$raw',
      'https://gh.catmak.name/$raw',
      'https://g.blfrp.cn/$raw',
      // CDN
      jsdelivr(filePath),
      jsdelivrFastly(filePath),
    ];
  }
}
