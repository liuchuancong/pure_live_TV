/// 在线动态壁纸（视频壁纸）图源。
///
/// iTab 的「视频」页签走的是它自家的 `/wallpaper/video/list`：分「最新 / 最热」排序 +
/// 无限滚动，返回 `{url, thumb}` 由前端塞进 `<video>` 循环播放。那套接口挂在
/// `api.codelife.cc` 上且要带客户端签名，第三方没法直接调用。
///
/// 所以这里保留同样的**交互形态**（选图源 → 选分类 → 取一条 → 立即播放 + 记下封面），
/// 数据来源分两条路：
/// 1. 内置公开接口（素颜 API）。这类接口的 CDN 说挂就挂 —— 实测它返回的
///    `cdn.video.aibizhi.dandanjiang.tv` 已经全部 502，所以内置源只当兜底；
/// 2. **自定义接口地址**（[BackgroundVideoSources.buildCustomRequestUrl]）：
///    用户填自己的接口，`{page}` / `{tag}` 会被替换，响应按同一套规则解析
///    （`url` / `video` / `src` 取视频，`cover` / `thumb` / `poster` 取封面）。
class BackgroundVideoSources {
  BackgroundVideoSources._();

  /// 不使用在线动态壁纸（只用本机视频或手填地址）。
  static const String noneId = 'none';

  /// 用户自定义接口。
  static const String customId = 'custom';

  /// 素颜 API 的随机壁纸接口。
  ///
  /// `screen=2` 取视频，`format` 是分类；用 JSON 形式（返回
  /// `{code, data:[{url, cover, width, height}]}`）而不是 `type=url`，
  /// 因为封面要一起拿到。
  static const String suyanVideoUrl = 'https://api.suyanw.cn/api/loveanimer.php';

  /// 素颜接口的视频分类（`format` 取值）。
  static const List<({int id, String name})> suyanVideoTags = <({int id, String name})>[
    (id: 1, name: '动漫'),
    (id: 2, name: '网红'),
    (id: 3, name: '游戏'),
    (id: 4, name: '热门'),
    (id: 5, name: '风景'),
    (id: 6, name: '其他'),
    (id: 7, name: '热舞'),
    (id: 8, name: '娱乐'),
    (id: 9, name: '影视'),
    (id: 10, name: '动物'),
  ];

  /// 可用图源。
  static const List<({String id, String name, String url})> sources = <({String id, String name, String url})>[
    (id: noneId, name: '不使用', url: ''),
    (id: customId, name: '自定义接口', url: ''),
    (id: 'sample', name: '示例视频（自检）', url: sampleVideoUrl),
    (id: 'suyan', name: '素颜动态壁纸', url: suyanVideoUrl),
  ];

  /// 一条稳定的公开测试视频。
  ///
  /// 「示例视频」源用它：内置的第三方接口说挂就挂，留一条确定可播的地址，
  /// 用户能先确认播放链路（下载 → 解码 → 循环）没问题，再去排查接口。
  static const String sampleVideoUrl =
      'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4';

  static List<String> get names => sources.map((e) => e.name).toList(growable: false);

  static int clampIndex(int index) => index.clamp(0, sources.length - 1);

  static int indexOfId(String id) {
    final index = sources.indexWhere((e) => e.id == id);
    return index < 0 ? 0 : index;
  }

  static ({String id, String name, String url}) at(int index) => sources[clampIndex(index)];

  static bool supportsTags(int index) {
    final id = at(index).id;
    return id == 'suyan' || id == customId;
  }  /// 分类列表；「不使用」返回空表，「自定义接口」用素颜的分类名当通用标签。
  static List<String> tagNames(int sourceIndex) {
    if (!supportsTags(sourceIndex)) return const <String>[];
    return suyanVideoTags.map((e) => e.name).toList(growable: false);
  }

  static int clampTagIndex(int sourceIndex, int tagIndex) {
    final tags = tagNames(sourceIndex);
    if (tags.isEmpty) return 0;
    return tagIndex.clamp(0, tags.length - 1);
  }

  /// 素颜接口的分类 id（自定义接口的 `{tag}` 也会填这个值）。
  static int tagId(int sourceIndex, int tagIndex) {
    if (suyanVideoTags.isEmpty) return 1;
    return suyanVideoTags[clampTagIndex(sourceIndex, tagIndex)].id;
  }

  /// 组装内置图源的请求地址；「不使用」和「自定义接口」返回空串。
  static String buildRequestUrl(int sourceIndex, int tagIndex, {int page = 1}) {
    final source = at(sourceIndex);
    if (source.id == 'suyan') {
      return '${source.url}?screen=2&format=${tagId(sourceIndex, tagIndex)}&page=$page';
    }
    return '';
  }

  /// 组装用户自定义接口的请求地址。
  ///
  /// 占位符：`{page}` 页码、`{tag}` 分类 id、`{random}` 随机数（防缓存）。
  /// 一个占位符都没有时，原样请求 —— 有些接口本来就只返回随机一条。
  static String buildCustomRequestUrl(
    String template, {
    int page = 1,
    int tag = 1,
    int random = 0,
  }) {
    var url = template.trim();
    if (url.isEmpty) return '';
    url = url.replaceAll('{page}', '$page');
    url = url.replaceAll('{tag}', '$tag');
    url = url.replaceAll('{random}', '$random');
    return url;
  }

  /// 从接口响应里挑出视频直链。
  static String? pickVideoUrl(dynamic data) {
    final found = _pickByKeys(data, const <String>['url', 'video', 'videoUrl', 'src', 'playUrl', 'link']);
    if (found == null) return null;
    return found.startsWith('http') ? found : null;
  }

  /// 从接口响应里挑出封面图。
  static String? pickCoverUrl(dynamic data) {
    final found = _pickByKeys(data, const <String>['cover', 'thumb', 'poster', 'pic', 'image']);
    if (found == null) return null;
    return found.startsWith('http') ? found : null;
  }

  static String? _pickByKeys(dynamic data, List<String> keys) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is List) {
      for (final item in data) {
        final found = _pickByKeys(item, keys);
        if (found != null) return found;
      }
      return null;
    }
    if (data is Map) {
      for (final key in keys) {
        final found = _pickByKeys(data[key], keys);
        if (found != null) return found;
      }
      // 常见包装层：`{code, data:[...]}` / `{data:{...}}`。
      if (data.containsKey('data')) {
        final found = _pickByKeys(data['data'], keys);
        if (found != null) return found;
      }
    }
    return null;
  }
}
