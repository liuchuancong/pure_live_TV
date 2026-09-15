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

  const BackgroundCategory({
    required this.id,
    required this.name,
    required this.catalog,
    required this.count,
    this.hidden = false,
  });

  factory BackgroundCategory.fromJson(Map<String, dynamic> json) =>
      BackgroundCategory(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        catalog: json['catalog'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
        hidden: json['hidden'] as bool? ?? false,
      );
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
}
