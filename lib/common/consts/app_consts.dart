import 'package:flutter/material.dart';
import 'package:pure_live/core/sites.dart';

class AppConsts {
  static const List<String> supportSites = [
    Sites.bilibiliSite,
    Sites.douyuSite,
    Sites.huyaSite,
    Sites.douyinSite,
    Sites.kuaishouSite,
    Sites.ccSite,
    Sites.iptvSite,
  ];

  static final List<Map<dynamic, String>> currentBoxImageSources = [
    {"不使用": 'default'},
    {"必应随机": 'https://bing.img.run/rand.php'},
    {'小晓API': 'https://v2.xxapi.cn/api/wallpaper'},
    {'无铭必应每日壁纸': 'https://jkapi.com/api/bing_img'},
    {'无铭随机美囡图片': 'https://jkapi.com/api/meinv_img'},
    {'无铭随机黑絲图片': 'https://jkapi.com/api/heisi_img'},
    {'无铭随机白絲图片': 'https://jkapi.com/api/baisi_img'},
    {'无铭随机抖音美女图片': 'https://jkapi.com/api/dymm_img'},
    {'无铭半次元cosplay': 'https://jkapi.com/api/bcy_cos'},
    {'无铭动漫壁纸': 'https://jkapi.com/api/dm_wallpaper'},
    {'无铭随机唯美女生图片': 'https://jkapi.com/api/wm_girl'},
    {"mtyqx": 'https://api.mtyqx.cn/tapi/random.php'},
    {'栗次元': 'https://t.alcy.cc/'},
    {"picsum": 'https://picsum.photos/1280/720/?blur=10'},
    {"dmoe": 'https://www.dmoe.cc/random.php'},
    {'loliApi': 'https://www.loliapi.com/bg/'},
    {"搏天动漫": 'https://api.btstu.cn/sjbz/?lx=dongman'},
    {"搏天妹子": 'http://api.btstu.cn/sjbz/?lx=meizi'},
    {"搏天随机": 'http://api.btstu.cn/sjbz/?lx=suiji'},
    {"catvod": 'https://pictures.catvod.eu.org/'},
  ];

  static const List<Map<dynamic, String>> wumingApiKeys = [
    {'无铭必应每日壁纸': '0f57c17bca42966996d6a8bc28594858'},
    {'无铭随机美囡图片': '872080c8858c40e6a1eb2ba86694d4d8'},
    {'无铭随机黑絲图片': '0c0c7a39e084db0e9c7cf2e25318f42c'},
    {'无铭随机白絲图片': '7605369407c689e9b2804bfc56a82ac7'},
    {'无铭随机抖音美女图片': '7b6c5500e52878bc46264cd140196699'},
    {'无铭半次元cosplay': 'f5bce3b84b7409fbe8abb2246b46f4c8'},
    {'无铭动漫壁纸': '95e3a0e608a8b1bed6d513346f929202'},
    {'无铭随机唯美女生图片': '0a7c2239bc57624cac60967937da8a1b'},
  ];

  // 平台列表
  static const List<String> platforms = ['bilibili', 'douyu', 'huya', 'douyin', 'kuaishow', 'cc', '网络'];

  // 播放器类型
  static const List<String> players = ['Mpv播放器', 'IJK播放器'];

  // 音频延时
  static const Map<String, String> audioDelayMap = {
    "0.0": "同步 (0ms)",
    "-0.025": "-25 ms",
    "-0.05": "-50 ms",
    "-0.075": "-75 ms",
    "-0.1": "-100 ms",
    "-0.125": "-125 ms",
    "-0.15": "-150 ms",
    "-0.175": "-175 ms",
    "-0.2": "-200 ms (推荐)",
    "-0.225": "-225 ms",
    "-0.25": "-250 ms",
    "-0.275": "-275 ms",
    "-0.3": "-300 ms",
    "-0.35": "-350 ms",
    "-0.4": "-400 ms",
    "-0.5": "-500 ms",
    "-1.0": "-1000 ms",
    "0.05": "+50 ms",
    "0.1": "+100 ms",
    "0.2": "+200 ms",
  };

  // 主题模式映射
  static const Map<String, ThemeMode> themeModes = {
    "System": ThemeMode.system,
    "Dark": ThemeMode.dark,
    "Light": ThemeMode.light,
  };

  // 语言映射
  static const Map<String, Locale> languages = {"English": Locale('en'), "简体中文": Locale('zh', 'CN')};

  // 视频 Fit 模式
  static const List<BoxFit> videoFitList = [
    BoxFit.contain,
    BoxFit.fill,
    BoxFit.cover,
    BoxFit.fitWidth,
    BoxFit.fitHeight,
    BoxFit.scaleDown,
  ];

  Map<dynamic, String> getFitItems() {
    return {0: "拉伸填充", 1: "完整包含", 2: "等比覆盖", 3: "等宽自适应", 4: "等高自适应 ", 5: "原始大小", 6: "等比缩放"};
  }

  static const List<String> videoFitChineseTranslation = [
    "等比适配", // 对应 BoxFit.contain
    "拉伸填充", // 对应 BoxFit.fill
    "等比覆盖", // 对应 BoxFit.cover
    "适配宽度", // 对应 BoxFit.fitWidth
    "适配高度", // 对应 BoxFit.fitHeight
    "等比缩小", // 对应 BoxFit.scaleDown
  ];

  static Map<String, Color> themeColors = {
    "Crimson": const Color.fromARGB(255, 220, 20, 60),
    "Orange": Colors.orange,
    "Chrome": const Color.fromARGB(255, 230, 184, 0),
    "Grass": Colors.lightGreen,
    "Teal": Colors.teal,
    "SeaFoam": const Color.fromARGB(255, 112, 193, 207),
    "Ice": const Color.fromARGB(255, 115, 155, 208),
    "Blue": Colors.blue,
    "Indigo": Colors.indigo,
    "Violet": Colors.deepPurple,
    "Primary": const Color(0xFF6200EE),
    "Orchid": const Color.fromARGB(255, 218, 112, 214),
    "Variant": const Color(0xFF3700B3),
    "Secondary": const Color(0xFF03DAC6),
  };
}
