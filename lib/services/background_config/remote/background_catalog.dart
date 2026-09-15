/// 远端背景目录的数据模型。
///
/// 对应 background 仓库根目录的 `catalog.json` 与
/// `catalog/<source>/<category>.json`。字段刻意保持精简，
/// 只带界面渲染和下载需要的部分。
library;

/// 背景资源的种类
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

  /// 能否设为整页背景（渐变走本地渲染，不下载）
  bool get isDownloadable => this != BackgroundKind.gradient;
}

/// 一条背景资源
class BackgroundItem {
  /// 仓库相对路径，例如 `wallpapers/official/nature/images/xxx.jpeg`
  final String file;
  final String? id;
  final String? name;

  /// 视频封面（仓库相对路径）
  final String? poster;

  /// 字节数，用于显示体积
  final int? bytes;

  /// 渐变专用：可直接喂给 CSS/Flutter 的 linear-gradient 描述
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

  /// 界面上显示的短标题
  String label(int index) {
    final raw = name?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    final fromFile = file.split('/').last;
    final dot = fromFile.lastIndexOf('.');
    return dot > 0 ? fromFile.substring(0, dot) : (fromFile.isEmpty ? '#$index' : fromFile);
  }
}

/// 渐变的一个色标
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

/// 来源下的一个分类分片
class BackgroundCategory {
  final String id;
  final String name;

  /// 分片的仓库相对路径
  final String catalog;
  final int count;

  /// 只有一个分类的来源（bing/deepin）置 true，界面不再显示分类栏
  final bool hidden;

  /// 分片是仓库原生的 `mapping.json` 时，条目 `file` 相对的前缀。
  /// 走 catalog 分片时为空字符串（那时 file 已经是仓库根相对路径）。
  final String pathPrefix;

  const BackgroundCategory({
    required this.id,
    required this.name,
    required this.catalog,
    required this.count,
    this.hidden = false,
    this.pathPrefix = '',
  });

  factory BackgroundCategory.fromJson(Map<String, dynamic> json) =>
      BackgroundCategory(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        catalog: json['catalog'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
        hidden: json['hidden'] as bool? ?? false,
        pathPrefix: json['pathPrefix'] as String? ?? '',
      );

  /// 相等性按「分片路径 + 前缀」判定。
  /// [backgroundShardProvider] 用本类做 family key，没有 == / hashCode
  /// 的话每次 rebuild 都会生成新 provider，导致重复请求。
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

/// 一个背景来源（官方壁纸 / Wallhaven / 必应 / deepin / 动态壁纸 / 纯色渐变）
class BackgroundSource {
  final String id;
  final String name;
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
  });

  factory BackgroundSource.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    return BackgroundSource(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
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

  /// 界面用：无分类来源只暴露唯一的那个分片
  List<BackgroundCategory> get visibleCategories {
    if (!categorized) {
      final hidden = categories.where((c) => c.hidden).toList();
      return hidden.isNotEmpty ? hidden : categories;
    }
    return categories.where((c) => c.count > 0).toList();
  }
}

/// 仓库信息，用于拼远端地址
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

/// 总索引 `catalog.json`
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
                  (e) => BackgroundSource.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(growable: false)
          : const <BackgroundSource>[],
    );
  }

  bool get isEmpty => sources.isEmpty;

  /// 内置目录。
  ///
  /// 仓库里没有预生成的 `catalog.json` 时用它兜底：结构和分类清单
  /// 来自本地抓取目录，图片清单仍然从仓库的 `mapping.json` 现取，
  /// 所以不需要仓库额外放任何文件。
  ///
  /// 计数只是分类标签上的初始提示，实际以 `mapping.json` 为准。
  factory BackgroundCatalog.builtIn() {
    const prefix = 'wallpapers/';
    BackgroundSource images(
      String id,
      String name,
      bool categorized,
      List<(String, String, int)> cats,
    ) => BackgroundSource(
      id: id,
      name: name,
      kind: BackgroundKind.image,
      categorized: categorized,
      count: cats.fold(0, (sum, c) => sum + c.$3),
      categories: [
        for (final (catId, catName, count) in cats)
          BackgroundCategory(
            id: catId,
            name: catName,
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
        images('official', '官方壁纸', true, const <(String, String, int)>[
          ('nature', '自然', 240),
          ('art', '艺术', 155),
          ('architecture', '建筑', 28),
          ('life', '生命', 31),
          ('geometry', '纹理', 72),
          ('other', '其他', 240),
        ]),
        images('wallhaven', 'Wallhaven', true, const <(String, String, int)>[
          ('popular', '热门', 233),
          ('minimalism', '极简主义', 240),
          ('patterns', '图案', 240),
          ('landscape', '风景', 240),
          ('nature', '自然', 240),
          ('cosplay', 'Cosplay', 240),
          ('spiderman', '蜘蛛侠', 240),
          ('ghibli', '吉卜力', 240),
          ('naruto', '火影忍者', 219),
          ('sci-fi', '科幻', 240),
          ('anime', '日漫', 240),
          ('anime-girls', '动漫女孩', 240),
          ('cyberpunk', '赛博朋克', 240),
          ('pixel-art', '像素艺术', 240),
          ('artwork', 'Artwork', 240),
          ('cityscape', 'Cityscape', 240),
          ('digital-art', 'Digital Art', 240),
          ('fantasy-art', 'Fantasy Art', 240),
          ('final-fantasy', 'Final Fantasy', 240),
        ]),
        images('bing', '必应壁纸', false, const <(String, String, int)>[
          ('all', '必应壁纸', 161),
        ]),
        images('deepin', 'deepin', false, const <(String, String, int)>[
          ('all', 'deepin', 26),
        ]),
        BackgroundSource(
          id: 'video',
          name: '动态壁纸',
          kind: BackgroundKind.video,
          categorized: false,
          count: 114,
          categories: const <BackgroundCategory>[
            BackgroundCategory(
              id: 'all',
              name: '动态壁纸',
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
          kind: BackgroundKind.gradient,
          categorized: false,
          count: 139,
          categories: <BackgroundCategory>[
            BackgroundCategory(
              id: 'all',
              name: '纯色渐变',
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

/// 分类分片内容
class BackgroundShard {
  final String source;
  final String category;
  final String name;
  final BackgroundKind kind;
  final int count;
  final List<BackgroundItem> items;

  /// 纯色渐变来源的自定义色板
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

  /// 统一解析三种分片格式，避免 App 依赖某一种仓库布局：
  ///
  /// 1. `{ items: [...] }` —— 预生成的 catalog 分片，`file` 已是仓库根相对路径
  /// 2. `[ {...}, ... ]` —— 仓库原生的 `mapping.json`，`file` 相对 [pathPrefix]
  /// 3. `{ backgrounds: [...] }` —— 根目录的 `solid-colors.json`
  ///
  /// [pathPrefix] 来自 [BackgroundCategory.pathPrefix]。
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
      // 单对象兜底：当成一条记录
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
        // mapping.json 里会混进下载失败的记录，跳过
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

    throw const FormatException('无法识别的分片格式');
  }

  /// `mapping.json` 的一条 → [BackgroundItem]，`file` 补成仓库根相对路径
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

  /// `solid-colors.json` 的一条 → [BackgroundItem]（渐变的“文件”就是 css 本身）
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
