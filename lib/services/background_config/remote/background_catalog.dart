/// Data models for the wallpaper browser.
///
/// Everything the browser shows comes from one of three places, and these models
/// do not care which:
///
/// * the iTab wallpaper API (`base.itab.link`) for the picture library,
/// * the iTab CDN (`files.itab.link`) for the live wallpapers and for the
///   deepin set,
/// * tables compiled into the app for the solid colours and gradients.
///
/// The previous revision only knew how to read a prebuilt catalog from a GitHub
/// repository, which is why the whole library needed a mirror probe, a catalog
/// download and a per-category shard download before it could show a single
/// thumbnail — and why a slow or blocked mirror left the page empty.
library;

/// What kind of background an entry describes.
enum BackgroundKind { image, video, gradient }

/// One colour stop of a gradient.
class BackgroundGradientStop {
  final String color;

  /// Position in percent, following the CSS description.
  final double pos;

  const BackgroundGradientStop({required this.color, required this.pos});
}

/// One background entry.
class BackgroundItem {
  /// Absolute URL of the picture/video, or a synthetic key for a gradient
  /// (which has no file at all).
  final String file;
  final String? id;
  final String? name;

  /// Poster image of a live wallpaper.
  final String? poster;

  /// Grid-sized copy of [file]; the API usually supplies one.
  final String? thumb;

  /// Size in bytes when the source reports it.
  final int? bytes;

  /// Gradient only: the CSS description, kept for reference/export.
  final String? css;

  /// Gradient only: CSS angle in degrees (0 points up, clockwise positive).
  final int deg;
  final List<BackgroundGradientStop>? gradient;

  const BackgroundItem({
    required this.file,
    this.id,
    this.name,
    this.poster,
    this.thumb,
    this.bytes,
    this.css,
    this.deg = 0,
    this.gradient,
  });

  /// Stable identity used to compare "in use" and to key lists.
  ///
  /// Gradients carry a synthetic [file], so this is simply the file/URL.
  String get key => file.isNotEmpty ? file : 'item:${id ?? name ?? css ?? ''}';
}

/// One group of entries inside a source.
class BackgroundCategory {
  /// Stable identity, also shown as the localised name's fallback.
  final String id;

  /// Primary display name.
  final String name;

  /// English display name; may be empty.
  final String nameEn;

  /// Value of the source's own filter parameter. Empty means "no filter", which
  /// is how the Wallhaven *popular* group is requested.
  final String apiQuery;

  /// Hint shown next to the row. The real total comes from the loaded page.
  final int count;

  /// True for sources that expose a single group, so the UI can skip the
  /// category list and open the grid straight away.
  final bool hidden;

  const BackgroundCategory({
    required this.id,
    required this.name,
    required this.count,
    this.nameEn = '',
    this.apiQuery = '',
    this.hidden = false,
  });

  /// Display name for [languageCode], falling back to whichever is present.
  String localizedName(String languageCode) {
    if (languageCode == 'zh') return name.isNotEmpty ? name : nameEn;
    return nameEn.isNotEmpty ? nameEn : name;
  }

  /// Equality is by id. [backgroundShardProvider] uses this class inside a
  /// provider family key; without == and hashCode every rebuild would create a
  /// new provider and refetch.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BackgroundCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
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
    required this.categories,
    this.nameEn = '',
    this.count = 0,
  });

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
    return categories.where((c) => c.count > 0).toList(growable: false);
  }
}

/// Identifiers of the sources the app compiles in.
class BackgroundSourceIds {
  const BackgroundSourceIds._();

  static const String official = 'official';
  static const String wallhaven = 'wallhaven';
  static const String bing = 'bing';
  static const String deepin = 'deepin';
  static const String video = 'video';
  static const String solidColor = 'solid-color';
}

/// The whole source tree.
///
/// It is a constant table now: the picture library is addressed by the iTab API
/// and the other three sources are fixed sets, so there is nothing to download
/// before the settings page can be drawn.
class BackgroundCatalog {
  final List<BackgroundSource> sources;

  const BackgroundCatalog({required this.sources});

  bool get isEmpty => sources.isEmpty;

  /// The source with [id], or null when the catalog has none.
  BackgroundSource? sourceById(String id) {
    for (final source in sources) {
      if (source.id == id) return source;
    }
    return null;
  }

  /// Picture sources, in the order the library page lists them.
  List<BackgroundSource> get imageSources =>
      sources.where((s) => s.kind == BackgroundKind.image).toList(growable: false);

  static BackgroundSource _single(
    String id,
    String name,
    String nameEn,
    BackgroundKind kind,
    int count,
  ) => BackgroundSource(
    id: id,
    name: name,
    nameEn: nameEn,
    kind: kind,
    categorized: false,
    count: count,
    categories: <BackgroundCategory>[
      BackgroundCategory(id: 'all', name: name, nameEn: nameEn, count: count, hidden: true),
    ],
  );

  /// The compiled-in source tree.
  ///
  /// Category counts are hints for the row subtitles; the grid reports the real
  /// number once the page loads.
  factory BackgroundCatalog.builtIn() {
    // Official categories, as the extension's own sidebar lists them. The
    // "all" bucket is deliberately absent: it overlaps the seven groups and
    // would just duplicate content.
    BackgroundSource images(
      String id,
      String name,
      String nameEn,
      bool categorized,
      List<(String, String, String, int)> groups,
    ) => BackgroundSource(
      id: id,
      name: name,
      nameEn: nameEn,
      kind: BackgroundKind.image,
      categorized: categorized,
      count: groups.fold(0, (sum, g) => sum + g.$4),
      categories: <BackgroundCategory>[
        for (final (catId, catZh, catEn, count) in groups)
          BackgroundCategory(
            id: catId,
            name: catZh,
            nameEn: catEn,
            apiQuery: catId,
            count: count,
            hidden: !categorized,
          ),
      ],
    );

    return BackgroundCatalog(
      sources: <BackgroundSource>[
        images(
          BackgroundSourceIds.official,
          '官方壁纸',
          'Official',
          true,
          const <(String, String, String, int)>[
            ('nature', '自然', 'Nature', 240),
            ('acg', '动漫', 'Anime', 240),
            ('art', '艺术', 'Art', 155),
            ('architecture', '建筑', 'Architecture', 28),
            ('life', '生命', 'Life', 31),
            ('geometry', '纹理', 'Texture', 72),
            ('other', '其他', 'Other', 240),
          ],
        ),
        BackgroundSource(
          id: BackgroundSourceIds.wallhaven,
          name: 'Wallhaven',
          nameEn: 'Wallhaven',
          kind: BackgroundKind.image,
          categorized: true,
          count: 4532,
          categories: const <BackgroundCategory>[
            BackgroundCategory(id: 'popular', name: '热门', nameEn: 'Popular', count: 233),
            BackgroundCategory(id: 'minimalism', name: '极简主义', nameEn: 'Minimalism', apiQuery: 'id:2278', count: 240),
            BackgroundCategory(id: 'patterns', name: '图案', nameEn: 'Patterns', apiQuery: 'id:869', count: 240),
            BackgroundCategory(id: 'landscape', name: '风景', nameEn: 'Landscape', apiQuery: 'id:711', count: 240),
            BackgroundCategory(id: 'nature', name: '自然', nameEn: 'Nature', apiQuery: 'id:37', count: 240),
            BackgroundCategory(id: 'cosplay', name: 'Cosplay', nameEn: 'Cosplay', apiQuery: 'id:12757', count: 240),
            BackgroundCategory(id: 'spiderman', name: '蜘蛛侠', nameEn: 'Spider-Man', apiQuery: 'id:2319', count: 240),
            BackgroundCategory(id: 'ghibli', name: '吉卜力', nameEn: 'Ghibli', apiQuery: 'id:1748', count: 240),
            BackgroundCategory(id: 'naruto', name: '火影忍者', nameEn: 'Naruto', apiQuery: 'id:78174', count: 219),
            BackgroundCategory(id: 'sci-fi', name: '科幻', nameEn: 'Sci-Fi', apiQuery: 'id:14', count: 240),
            BackgroundCategory(id: 'anime', name: '日漫', nameEn: 'Anime', apiQuery: 'id:1', count: 240),
            BackgroundCategory(id: 'anime-girls', name: '动漫女孩', nameEn: 'Anime Girls', apiQuery: 'id:5', count: 240),
            BackgroundCategory(id: 'cyberpunk', name: '赛博朋克', nameEn: 'Cyberpunk', apiQuery: 'id:376', count: 240),
            BackgroundCategory(id: 'pixel-art', name: '像素艺术', nameEn: 'Pixel Art', apiQuery: 'id:2321', count: 240),
            BackgroundCategory(id: 'artwork', name: 'Artwork', nameEn: 'Artwork', apiQuery: 'id:323', count: 240),
            BackgroundCategory(id: 'cityscape', name: 'Cityscape', nameEn: 'Cityscape', apiQuery: 'id:479', count: 240),
            BackgroundCategory(id: 'digital-art', name: 'Digital Art', nameEn: 'Digital Art', apiQuery: 'id:13', count: 240),
            BackgroundCategory(id: 'fantasy-art', name: 'Fantasy Art', nameEn: 'Fantasy Art', apiQuery: 'id:853', count: 240),
            BackgroundCategory(id: 'final-fantasy', name: 'Final Fantasy', nameEn: 'Final Fantasy', apiQuery: 'id:997', count: 240),
          ],
        ),
        _single(BackgroundSourceIds.bing, '必应壁纸', 'Bing', BackgroundKind.image, 2030),
        _single(BackgroundSourceIds.deepin, 'deepin', 'deepin', BackgroundKind.image, 26),
        _single(BackgroundSourceIds.video, '动态壁纸', 'Live Wallpapers', BackgroundKind.video, 125),
        _single(BackgroundSourceIds.solidColor, '纯色渐变', 'Colors', BackgroundKind.gradient, 151),
      ],
    );
  }
}
