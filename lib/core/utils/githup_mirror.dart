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

  /// Raw-file proxies that accept the origin URL as a path suffix.
  ///
  /// Order matters: earlier entries are the more reliable ones as of the
  /// latest probe, and they also support HTTP Range (206) for resumable
  /// downloads.
  static const List<String> _rawPrefixes = [
    // Best: api=200 + asset=206, resumable.
    'https://cdn.gh-proxy.org/',
    'https://edgeone.gh-proxy.org/',
    'https://hk.gh-proxy.org/',
    'https://gh.noki.eu.org/',
    'https://gh-proxy.com/',
    'https://slink.ltd/',

    // Usable: api=200 + asset=200.
    'https://ghproxy.link/',
    'https://gh-proxy.net/',
    'https://gitproxy.click/',
    'https://v6.gh-proxy.org/',

    // Asset-only: API is rate-limited but raw files download fine.
    'https://ghproxy.net/',
    'https://wget.la/',
    'https://gh.catmak.name/',
    'https://g.blfrp.cn/',
  ];

  /// Every candidate URL for [filePath], origin first and CDNs last.
  List<String> mirrors(String filePath) {
    final raw = rawUrl(filePath);
    return [
      raw,
      for (final prefix in _rawPrefixes) '$prefix$raw',
      'https://raw.kkgithub.com/$owner/$repo/$branch/$filePath',
      // CDN
      jsdelivr(filePath),
      jsdelivrFastly(filePath),
    ];
  }

  /// The origin prefix of a raw file address.
  static const String _originPrefix = 'https://raw.githubusercontent.com/';

  /// Candidate URLs for an arbitrary address, without knowing the repository
  /// up front: a `raw.githubusercontent.com` address expands into the mirror
  /// pool, while any other host is returned unchanged so self-hosted playlists
  /// keep their own address.
  static List<String> candidatesFor(String url) {
    final trimmed = url.trim();
    if (!trimmed.startsWith(_originPrefix)) return [trimmed];
    // owner/repo/branch/rest — the rest stays verbatim so its encoding and
    // query string survive the round trip.
    final parts = trimmed.substring(_originPrefix.length).split('/');
    if (parts.length < 4 || parts.take(3).any((part) => part.isEmpty)) return [trimmed];
    final mirror = GitHubMirror(owner: parts[0], repo: parts[1], branch: parts[2]);
    return [trimmed, ...mirror.mirrors(parts.skip(3).join('/')).skip(1)];
  }
}
