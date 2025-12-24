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
    {"mtyqx": 'https://api.mtyqx.cn/tapi/random.php'},
    {'alcy': 'https://t.alcy.cc/'},
    {"picsum": 'https://picsum.photos/1280/720/?blur=10'},
    {"dmoe": 'https://www.dmoe.cc/random.php'},
    {'loliApi': 'https://www.loliapi.com/bg/'},
    {"btstu动漫": 'https://api.btstu.cn/sjbz/?lx=dongman'},
    {"btstu妹子": 'http://api.btstu.cn/sjbz/?lx=meizi'},
    {"btstu随机": 'http://api.btstu.cn/sjbz/?lx=suiji'},
    {"catvod": 'https://pictures.catvod.eu.org/'},
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
