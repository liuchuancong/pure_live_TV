import 'package:flutter/widgets.dart';

/// 在线壁纸图源与填充模式候选值。
///
/// 基础图源表移植自老项目 `pure_live` 的 `AppConsts.currentBoxImageSources` /
/// `wumingApiKeys`；`url == noneUrl` 表示不换壁纸。
///
/// ⚠️ 「官方壁纸」「Wallhaven」「Deepin」目前写的是**占位示例地址**，拿到真实接口后
/// 只改这张表即可 —— 解析逻辑是通用的（见 [pickImageUrlFromJson]）：
/// - 直链图源：URL 本身就是图片，直接下载；
/// - JSON 图源：先请求拿到 JSON，再从里面挑直链；
/// - 无铭系：还要额外带 `type=json&apiKey=`，见 `BackgroundController.getRandomImage`。
class BackgroundImageSources {
  BackgroundImageSources._();

  /// 不使用随机壁纸时 url 的取值。
  static const String noneUrl = 'default';

  static const List<({String name, String url})> sources = <({String name, String url})>[
    (name: '不使用', url: noneUrl),

    // —— 以下三条是占位示例地址，等真实接口就位后替换 ——
    (name: '官方壁纸', url: 'https://example.com/purelive/wallpaper/random'),
    (name: 'Wallhaven', url: 'https://wallhaven.cc/api/v1/search?sorting=random&atleast=1920x1080'),
    (name: 'Deepin', url: 'https://example.com/deepin/wallpapers/list.json'),

    // —— 现成可用的公开图源 ——
    (name: '必应每日', url: 'https://bing.img.run/rand.php'),
    (name: '小晓API', url: 'https://v2.xxapi.cn/api/wallpaper'),
    (name: '无铭必应每日壁纸', url: 'https://jkapi.com/api/bing_img'),
    (name: '无铭随机美囡图片', url: 'https://jkapi.com/api/meinv_img'),
    (name: '无铭随机黑絲图片', url: 'https://jkapi.com/api/heisi_img'),
    (name: '无铭随机白絲图片', url: 'https://jkapi.com/api/baisi_img'),
    (name: '无铭随机抖音美女图片', url: 'https://jkapi.com/api/dymm_img'),
    (name: '无铭半次元cosplay', url: 'https://jkapi.com/api/bcy_cos'),
    (name: '无铭动漫壁纸', url: 'https://jkapi.com/api/dm_wallpaper'),
    (name: '无铭随机唯美女生图片', url: 'https://jkapi.com/api/wm_girl'),
    (name: 'mtyqx', url: 'https://api.mtyqx.cn/tapi/random.php'),
    (name: '栗次元', url: 'https://t.alcy.cc/'),
    (name: 'picsum', url: 'https://picsum.photos/1280/720/?blur=10'),
    (name: 'dmoe', url: 'https://www.dmoe.cc/random.php'),
    (name: 'loliApi', url: 'https://www.loliapi.com/bg/'),
    (name: '搏天动漫', url: 'https://api.btstu.cn/sjbz/?lx=dongman'),
    (name: '搏天妹子', url: 'http://api.btstu.cn/sjbz/?lx=meizi'),
    (name: '搏天随机', url: 'http://api.btstu.cn/sjbz/?lx=suiji'),
    (name: 'catvod', url: 'https://pictures.catvod.eu.org/'),
  ];

  /// 无铭系接口需要 apiKey：带 `type=json` 时返回 JSON，里面的直链才是图片。
  static const Map<String, String> wumingApiKeys = <String, String>{
    '无铭必应每日壁纸': '0f57c17bca42966996d6a8bc28594858',
    '无铭随机美囡图片': '872080c8858c40e6a1eb2ba86694d4d8',
    '无铭随机黑絲图片': '0c0c7a39e084db0e9c7cf2e25318f42c',
    '无铭随机白絲图片': '7605369407c689e9b2804bfc56a82ac7',
    '无铭随机抖音美女图片': '7b6c5500e52878bc46264cd140196699',
    '无铭半次元cosplay': 'f5bce3b84b7409fbe8abb2246b46f4c8',
    '无铭动漫壁纸': '95e3a0e608a8b1bed6d513346f929202',
    '无铭随机唯美女生图片': '0a7c2239bc57624cac60967937da8a1b',
  };

  /// 需要先请求 JSON 再取直链的图源。
  static const Set<String> jsonApiNames = <String>{'官方壁纸', 'Wallhaven', 'Deepin'};

  /// 从 JSON 里挑直链时优先看这些字段名，再退化成全量递归扫描。
  static const List<String> _urlKeys = <String>[
    'url',
    'image_url',
    'imageUrl',
    'content',
    'path',
    'src',
    'link',
    'full',
  ];

  static List<String> get names => sources.map((e) => e.name).toList(growable: false);

  static int clampIndex(int index) => index.clamp(0, sources.length - 1);

  static int indexOfName(String name) {
    final index = sources.indexWhere((e) => e.name == name);
    return index < 0 ? 0 : index;
  }

  static ({String name, String url}) at(int index) => sources[clampIndex(index)];

  /// 从任意形态的 JSON 里挑出图片直链。
  ///
  /// 覆盖三种常见返回：`{"url": "..."}`、`{"data": {"path": "..."}}`、
  /// `{"data": [{"path": "..."}, ...]}`（Wallhaven / Deepin 这类）。
  /// 挑不到返回 null。
  static String? pickImageUrlFromJson(dynamic data) {
    if (data == null) return null;
    if (data is String) return data.startsWith('http') ? data : null;
    if (data is List) {
      for (final item in data) {
        final found = pickImageUrlFromJson(item);
        if (found != null) return found;
      }
      return null;
    }
    if (data is Map) {
      for (final key in _urlKeys) {
        final found = pickImageUrlFromJson(data[key]);
        if (found != null) return found;
      }
      for (final value in data.values) {
        final found = pickImageUrlFromJson(value);
        if (found != null) return found;
      }
    }
    return null;
  }
}

/// 背景图的填充模式（对应 `BackgroundConfigModel.boxFit`）。
class BackgroundFitOptions {
  BackgroundFitOptions._();

  static const List<BoxFit> values = <BoxFit>[
    BoxFit.cover,
    BoxFit.contain,
    BoxFit.fill,
    BoxFit.fitWidth,
    BoxFit.fitHeight,
    BoxFit.none,
    BoxFit.scaleDown,
  ];

  static const List<String> labels = <String>[
    '等比覆盖',
    '完整包含',
    '拉伸填充',
    '等宽自适应',
    '等高自适应',
    '原始大小',
    '等比缩放',
  ];

  static int indexOf(BoxFit fit) {
    final index = values.indexOf(fit);
    return index < 0 ? 0 : index;
  }
}
