/// Data models for the remote background catalog.
///
/// Mirrors the JSON layout of the index file and the per-category shards.
/// Fields are kept deliberately small: only what the UI needs to render a
/// tile and what the downloader needs to fetch it.
library;

/// What kind of background a catalog entry describes.
enum BackgroundKind {
  image,
  video,
  gradient;

  static BackgroundKind parse(String? raw) {
    switch (raw) {
      case 'video':
        return BackgroundKind.video;
      case 'gradient':
        return BackgroundKind.gradient;
      default:
        return BackgroundKind.image;
    }
  }

  /// Whether the entry maps to a downloadable file.
  /// Gradients are painted locally, so they have nothing to fetch.
  bool get isDownloadable => this != BackgroundKind.gradient;
}

/// One background entry.
class BackgroundItem {
  /// Path relative to the repository root, e.g.
  /// `wallpapers/official/nature/images/xxx.jpeg`.
  final String file;
  final String? id;
  final String? name;

  /// Poster image path for videos.
  final String? poster;

  /// Size in bytes, shown as a badge on the tile.
  final int? bytes;

  /// Gradient only: CSS-style description of the ramp.
  final String? css;
  final List<BackgroundGradientStop>? gradient;

  const BackgroundItem({
    required this.file,
    this.id,
    this.name,
    this.poster,
    this.bytes,
    this.css,
    this.gradient,
  });

  factory BackgroundItem.fromJson(Map<String, dynamic> json) {
    final rawGradient = json['gradient'];
    return BackgroundItem(
      file: json['file'] as String? ?? '',
      id: json['id'] as String?,
      name: json['name'] as String?,
      poster: json['poster'] as String?,
      bytes: (json['bytes'] as num?)?.toInt(),
      css: json['css'] as String?,
      gradient: rawGradient is List
          ? rawGradient
                .whereType<Map>()
                .map(
                  (e) => BackgroundGradientStop.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(growable: false)
          : null,
    );
  }

  /// Short caption shown under a tile. Falls back to the file stem.
  String label(int index) {
    final raw = name?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    final fromFile = file.split('/').last;
    final dot = fromFile.lastIndexOf('.');
    return dot > 0
        ? fromFile.substring(0, dot)
        : (fromFile.isEmpty ? '#$index' : fromFile);
  }

  /// Stable identity used to compare "currently applying" and "in use".
  ///
  /// Gradients have no real file and can carry an empty [file]; comparing
  /// that directly would make every gradient tile look identical, so it
  /// degrades to a synthetic key.
  String get key {
    if (file.isNotEmpty) return file;
    final identity = id ?? name ?? css ?? '';
    return 'item:$identity';
  }
}

/// One colour stop of a gradient.
class BackgroundGradientStop {
  final String color;
  final double pos;

  const BackgroundGradientStop({required this.color, required this.pos});

  factory BackgroundGradientStop.fromJson(Map<String, dynamic> json) =>
      BackgroundGradientStop(
        color: json['color'] as String? ?? '#000000',
        pos: (json['pos'] as num?)?.toDouble() ?? 0,
      );
}

/// One group of entries inside a source.
class BackgroundCategory {
  final String id;

  /// Primary display name, as published by the catalog.
  final String name;

  /// English display name; may be empty for older catalogs.
  final String nameEn;

  /// Path of the shard holding this group's entries.
  final String catalog;
  final int count;

  /// True for sources that expose a single group, so the UI can hide the
  /// category row entirely.
  final bool hidden;

  /// Prefix prepended to each entry's `file` when the shard is a raw mapping
  /// file rather than a prebuilt catalog shard. Empty means the paths are
  /// already repo-root relative.
  final String pathPrefix;

  const BackgroundCategory({
    required this.id,
    required this.name,
    required this.catalog,
    required this.count,
    this.nameEn = '',
    this.hidden = false,
    this.pathPrefix = '',
  });

  factory BackgroundCategory.fromJson(Map<String, dynamic> json) =>
      BackgroundCategory(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? json['nameZh'] as String? ?? '',
        nameEn: json['nameEn'] as String? ?? '',
        catalog: json['catalog'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
        hidden: json['hidden'] as bool? ?? false,
        pathPrefix: json['pathPrefix'] as String? ?? '',
      );

  /// Display name for [languageCode], falling back to whichever is present.
  String localizedName(String languageCode) {
    if (languageCode == 'zh') return name.isNotEmpty ? name : nameEn;
    return nameEn.isNotEmpty ? nameEn : name;
  }

  /// Equality is by shard path and prefix. [backgroundShardProvider] uses
  /// this class inside a provider family key; without == and hashCode every
  /// rebuild would create a new provider and refetch.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackgroundCategory &&
          other.id == id &&
          other.catalog == catalog &&
          other.pathPrefix == pathPrefix;

  @override
  int get hashCode => Object.hash(id, catalog, pathPrefix);
}

/// A top-level group of backgrounds.
class BackgroundSource {
  final String id;
  final String name;
  final String nameEn;
  final BackgroundKind kind;
  final bool categorized;
  final int count;
  final List<BackgroundCategory> categories;

  const BackgroundSource({
    required this.id,
    required this.name,
    required this.kind,
    required this.categorized,
    required this.count,
    required this.categories,
    this.nameEn = '',
  });

  factory BackgroundSource.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    return BackgroundSource(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['nameZh'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      kind: BackgroundKind.parse(json['type'] as String?),
      categorized: json['categorized'] as bool? ?? false,
      count: (json['count'] as num?)?.toInt() ?? 0,
      categories: rawCategories is List
          ? rawCategories
                .whereType<Map>()
                .map(
                  (e) => BackgroundCategory.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(growable: false)
          : const <BackgroundCategory>[],
    );
  }

  /// Display name for [languageCode], falling back to whichever is present.
  String localizedName(String languageCode) {
    if (languageCode == 'zh') return name.isNotEmpty ? name : nameEn;
    return nameEn.isNotEmpty ? nameEn : name;
  }

  /// Groups the UI should show. Single-group sources only surface the one
  /// entry, and empty groups are dropped.
  List<BackgroundCategory> get visibleCategories {
    if (!categorized) {
      final hiddenOnes = categories.where((c) => c.hidden).toList();
      return hiddenOnes.isNotEmpty ? hiddenOnes : categories;
    }
    return categories.where((c) => c.count > 0).toList();
  }
}

/// Repository coordinates used to build remote URLs.
class BackgroundRepoInfo {
  final String owner;
  final String name;
  final String branch;

  const BackgroundRepoInfo({
    required this.owner,
    required this.name,
    required this.branch,
  });

  factory BackgroundRepoInfo.fromJson(Map<String, dynamic> json) =>
      BackgroundRepoInfo(
        owner: json['owner'] as String? ?? '',
        name: json['name'] as String? ?? '',
        branch: json['branch'] as String? ?? 'master',
      );
}

/// Root index of the remote catalog.
class BackgroundCatalog {
  final int version;
  final String generatedAt;
  final BackgroundRepoInfo repo;
  final int totalItems;
  final List<BackgroundSource> sources;

  const BackgroundCatalog({
    required this.version,
    required this.generatedAt,
    required this.repo,
    required this.totalItems,
    required this.sources,
  });

  factory BackgroundCatalog.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'];
    final totals = json['totals'];
    return BackgroundCatalog(
      version: (json['version'] as num?)?.toInt() ?? 1,
      generatedAt: json['generatedAt'] as String? ?? '',
      repo: BackgroundRepoInfo.fromJson(
        json['repo'] is Map
            ? Map<String, dynamic>.from(json['repo'] as Map)
            : const {},
      ),
      totalItems: totals is Map
          ? ((totals['items'] as num?)?.toInt() ?? 0)
          : 0,
      sources: rawSources is List
          ? rawSources
                .whereType<Map>()
                .map(
                  (e) =>
                      BackgroundSource.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList(growable: false)
          : const <BackgroundSource>[],
    );
  }

  bool get isEmpty => sources.isEmpty;

  /// Fallback structure used when no prebuilt index is available.
  ///
  /// Counts are only hints shown on the tab labels; the real total comes from
  /// the shard that actually loads, so a stale number never hides content.
  factory BackgroundCatalog.builtIn() {
    const prefix = 'wallpapers/';

    BackgroundSource images(
      String id,
      String nameZh,
      String nameEn,
      bool categorized,
      List<(String, String, String, int)> groups,
    ) => BackgroundSource(
      id: id,
      name: nameZh,
      nameEn: nameEn,
      kind: BackgroundKind.image,
      categorized: categorized,
      count: groups.fold(0, (sum, g) => sum + g.$4),
      categories: [
        for (final (catId, catZh, catEn, count) in groups)
          BackgroundCategory(
            id: catId,
            name: catZh,
            nameEn: catEn,
            catalog: '$prefix$id/${categorized ? '$catId/' : ''}mapping.json',
            count: count,
            hidden: !categorized,
            pathPrefix: prefix,
          ),
      ],
    );

    return BackgroundCatalog(
      version: 1,
      generatedAt: '',
      repo: const BackgroundRepoInfo(
        owner: 'liuchuancong',
        name: 'background',
        branch: 'master',
      ),
      totalItems: 0,
      sources: <BackgroundSource>[
        images(
          'official',
          '官方壁纸',
          'Official',
          true,
          const <(String, String, String, int)>[
            ('nature', '自然', 'Nature', 240),
            ('art', '艺术', 'Art', 155),
            ('architecture', '建筑', 'Architecture', 28),
            ('life', '生命', 'Life', 31),
            ('geometry', '纹理', 'Texture', 72),
            ('other', '其他', 'Other', 240),
          ],
        ),
        images(
          'wallhaven',
          'Wallhaven',
          'Wallhaven',
          true,
          const <(String, String, String, int)>[
            ('popular', '热门', 'Popular', 233),
            ('minimalism', '极简主义', 'Minimalism', 240),
            ('patterns', '图案', 'Patterns', 240),
            ('landscape', '风景', 'Landscape', 240),
            ('nature', '自然', 'Nature', 240),
            ('cosplay', 'Cosplay', 'Cosplay', 240),
            ('spiderman', '蜘蛛侠', 'Spider-Man', 240),
            ('ghibli', '吉卜力', 'Ghibli', 240),
            ('naruto', '火影忍者', 'Naruto', 219),
            ('sci-fi', '科幻', 'Sci-Fi', 240),
            ('anime', '日漫', 'Anime', 240),
            ('anime-girls', '动漫女孩', 'Anime Girls', 240),
            ('cyberpunk', '赛博朋克', 'Cyberpunk', 240),
            ('pixel-art', '像素艺术', 'Pixel Art', 240),
            ('artwork', 'Artwork', 'Artwork', 240),
            ('cityscape', 'Cityscape', 'Cityscape', 240),
            ('digital-art', 'Digital Art', 'Digital Art', 240),
            ('fantasy-art', 'Fantasy Art', 'Fantasy Art', 240),
            ('final-fantasy', 'Final Fantasy', 'Final Fantasy', 240),
          ],
        ),
        images('bing', '必应壁纸', 'Bing', false, const <(String, String, String, int)>[
          ('all', '必应壁纸', 'Bing', 161),
        ]),
        images('deepin', 'deepin', 'deepin', false, const <(String, String, String, int)>[
          ('all', 'deepin', 'deepin', 26),
        ]),
        const BackgroundSource(
          id: 'video',
          name: '动态壁纸',
          nameEn: 'Live Wallpapers',
          kind: BackgroundKind.video,
          categorized: false,
          count: 114,
          categories: <BackgroundCategory>[
            BackgroundCategory(
              id: 'all',
              name: '动态壁纸',
              nameEn: 'Live Wallpapers',
              catalog: 'videos/mapping.json',
              count: 114,
              hidden: true,
              pathPrefix: 'videos/',
            ),
          ],
        ),
        const BackgroundSource(
          id: 'solid-color',
          name: '纯色渐变',
          nameEn: 'Colors',
          kind: BackgroundKind.gradient,
          categorized: false,
          count: 139,
          categories: <BackgroundCategory>[
            BackgroundCategory(
              id: 'all',
              name: '纯色渐变',
              nameEn: 'Colors',
              catalog: 'solid-colors.json',
              count: 139,
              hidden: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// Entries of one category.
class BackgroundShard {
  final String source;
  final String category;
  final String name;
  final BackgroundKind kind;
  final int count;
  final List<BackgroundItem> items;

  /// Palette offered by the gradient source.
  final List<String> customPalette;

  const BackgroundShard({
    required this.source,
    required this.category,
    required this.name,
    required this.kind,
    required this.count,
    required this.items,
    this.customPalette = const <String>[],
  });

  factory BackgroundShard.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final rawPalette = json['customPalette'];
    return BackgroundShard(
      source: json['source'] as String? ?? '',
      category: json['category'] as String? ?? '',
      name: json['name'] as String? ?? '',
      kind: BackgroundKind.parse(json['type'] as String?),
      count: (json['count'] as num?)?.toInt() ?? 0,
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (e) => BackgroundItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList(growable: false)
          : const <BackgroundItem>[],
      customPalette: rawPalette is List
          ? rawPalette.whereType<String>().toList(growable: false)
          : const <String>[],
    );
  }

  /// Accepts any of the three shard layouts so the app does not depend on one
  /// particular repository arrangement:
  ///
  /// 1. `{ items: [...] }` - prebuilt shard, `file` already repo-root relative
  /// 2. `[ {...}, ... ]` - raw mapping file, `file` relative to [pathPrefix]
  /// 3. `{ backgrounds: [...] }` - the standalone gradient list
  factory BackgroundShard.parse(
    dynamic raw, {
    required BackgroundCategory category,
    required BackgroundKind kind,
    String source = '',
  }) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map['items'] is List) {
        return BackgroundShard.fromJson(map);
      }
      final backgrounds = map['backgrounds'];
      if (backgrounds is List) {
        final palette = map['customPalette'];
        return BackgroundShard(
          source: source,
          category: category.id,
          name: category.name,
          kind: BackgroundKind.gradient,
          count: backgrounds.length,
          customPalette: palette is List
              ? palette.whereType<String>().toList(growable: false)
              : const <String>[],
          items: backgrounds
              .whereType<Map>()
              .map((e) => _gradientItem(Map<String, dynamic>.from(e)))
              .toList(growable: false),
        );
      }
      // Single object: treat it as one entry.
      return BackgroundShard(
        source: source,
        category: category.id,
        name: category.name,
        kind: kind,
        count: 1,
        items: <BackgroundItem>[_mappingItem(map, category.pathPrefix)],
      );
    }

    if (raw is List) {
      final items = <BackgroundItem>[];
      for (final entry in raw) {
        if (entry is! Map) continue;
        final map = Map<String, dynamic>.from(entry);
        // Mapping files also record failed downloads; skip those.
        final status = map['status'];
        if (status is String &&
            status != 'ok' &&
            status != 'exists' &&
            status != 'listed') {
          continue;
        }
        final item = _mappingItem(map, category.pathPrefix);
        if (item.file.isEmpty) continue;
        items.add(item);
      }
      return BackgroundShard(
        source: source,
        category: category.id,
        name: category.name,
        kind: kind,
        count: items.length,
        items: items,
      );
    }

    throw const FormatException('unrecognised shard format');
  }

  /// One mapping-file row, with `file` widened to a repo-root relative path.
  static BackgroundItem _mappingItem(Map<String, dynamic> json, String prefix) {
    final rawFile = json['file'] as String? ?? '';
    final poster = json['poster'] as String?;
    return BackgroundItem(
      file: rawFile.isEmpty ? '' : '$prefix$rawFile',
      id: json['id'] as String?,
      name: json['name'] as String?,
      poster: poster == null || poster.isEmpty ? null : '$prefix$poster',
      bytes: (json['bytes'] as num?)?.toInt(),
    );
  }

  /// One gradient row. Its "file" is the CSS description itself, so the
  /// pseudo path below only exists to keep tiles distinguishable.
  static BackgroundItem _gradientItem(Map<String, dynamic> json) {
    return BackgroundItem(
      file: 'solid-colors.json#${json['index'] ?? ''}',
      id: json['index'] as String?,
      name: json['name'] as String?,
      css: json['css'] as String?,
      gradient: json['gradient'] is List
          ? (json['gradient'] as List)
                .whereType<Map>()
                .map(
                  (e) => BackgroundGradientStop.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(growable: false)
          : null,
    );
  }
}
