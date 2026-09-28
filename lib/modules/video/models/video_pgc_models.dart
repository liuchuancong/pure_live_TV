/// PGC (番剧/影视) models for the video module's newBV 影视 section.
library;

/// One PGC card as the grids show it (feed / index / search result).
class PgcItem {
  const PgcItem({
    required this.seasonId,
    required this.title,
    required this.cover,
    this.subtitle = '',
    this.badge = '',
    this.rating = 0,
    this.episodeCount = 0,
  });

  factory PgcItem.fromJson(Map<dynamic, dynamic> json) => PgcItem(
    seasonId: int.tryParse(json['season_id']?.toString() ?? '') ?? 0,
    title: _strip(json['title']?.toString() ?? ''),
    cover: _https(json['cover']?.toString() ?? ''),
    subtitle: _strip(json['subtitle']?.toString() ?? json['sub_title']?.toString() ?? ''),
    badge: json['badge']?.toString() ?? '',
    rating: double.tryParse(json['rating']?.toString() ?? '') ?? 0,
    episodeCount: int.tryParse(json['total']?['value']?.toString() ?? json['total_count']?.toString() ?? '') ?? 0,
  );

  final int seasonId;
  final String title;
  final String cover;
  final String subtitle;
  final String badge;
  final double rating;
  final int episodeCount;
}

/// One episode of a season — the unit the player queue plays.
class PgcEpisode {
  const PgcEpisode({
    required this.epId,
    required this.cid,
    required this.title,
    required this.longTitle,
    this.cover = '',
    this.durationMs = 0,
    this.badge = '',
  });

  factory PgcEpisode.fromJson(Map<dynamic, dynamic> json) => PgcEpisode(
    epId: int.tryParse(json['id']?.toString() ?? '') ?? 0,
    cid: int.tryParse(json['cid']?.toString() ?? '') ?? 0,
    title: json['title']?.toString() ?? '',
    longTitle: json['long_title']?.toString() ?? '',
    cover: _https(json['cover']?.toString() ?? ''),
    durationMs: int.tryParse(json['duration']?.toString() ?? '') ?? 0,
    badge: json['badge']?.toString() ?? '',
  );

  final int epId;
  final int cid;

  /// "第 1 话" style short index.
  final String title;
  final String longTitle;
  final String cover;
  final int durationMs;
  final String badge;
}

/// The full season detail (`pgc/view/web/season`).
class PgcSeason {
  const PgcSeason({
    required this.seasonId,
    required this.title,
    required this.cover,
    this.evaluate = '',
    this.episodes = const [],
    this.badge = '',
    this.rating = 0,
    this.styles = const [],
    this.pubTime = '',
  });

  factory PgcSeason.fromJson(Map<dynamic, dynamic> json) => PgcSeason(
    seasonId: int.tryParse(json['season_id']?.toString() ?? '') ?? 0,
    title: json['title']?.toString() ?? '',
    cover: _https(json['cover']?.toString() ?? ''),
    evaluate: json['evaluate']?.toString() ?? '',
    badge: json['badge']?.toString() ?? '',
    rating: double.tryParse(json['rating']?['score']?.toString() ?? '') ?? 0,
    styles: [
      for (final s in (json['styles'] as List?) ?? const <dynamic>[]) s['name']?.toString() ?? '',
    ].where((s) => s.isNotEmpty).toList(),
    pubTime: json['publish']?['pub_time']?.toString() ?? '',
    episodes: [
      for (final ep in (json['episodes'] as List?) ?? const <dynamic>[]) PgcEpisode.fromJson(ep),
    ],
  );

  final int seasonId;
  final String title;
  final String cover;
  final String evaluate;
  final List<PgcEpisode> episodes;
  final String badge;
  final double rating;
  final List<String> styles;
  final String pubTime;
}

String _https(String url) => url.startsWith('//') ? 'https:$url' : url;

String _strip(String text) => text.replaceAll(RegExp(r'</?em[^>]*>'), '');
