import 'package:pure_live/common/index.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

enum HomeMenu {
  favorites('favorites'),
  popular('popular'),
  areas('areas'),
  record('record');

  final String id;
  const HomeMenu(this.id);

  static HomeMenu? fromId(String id) {
    return HomeMenu.values.firstWhereOrNull((e) => e.id == id);
  }
}

class AppConsts {
  static const String defaultLoadingStyleKey = 'default';
  static final List<String> supportSites = Sites.supportSites.map((e) => e.id).toList();

  // 主题模式映射
  static const Map<String, ThemeMode> themeModes = {
    "System": ThemeMode.system,
    "Dark": ThemeMode.dark,
    "Light": ThemeMode.light,
  };
  static const Map<String, String> themeModeI18n = {
    "System": "theme_mode_system",
    "Dark": "theme_mode_dark",
    "Light": "theme_mode_light",
  };

  // 语言映射
  static const Map<String, Locale> languages = {"English": Locale('en'), "简体中文": Locale('zh')};

  // 视频 Fit 模式
  List<BoxFit> videoFitList = [
    BoxFit.contain,
    BoxFit.cover,
    BoxFit.fill,
    BoxFit.fitHeight,
    BoxFit.fitWidth,
    BoxFit.scaleDown,
  ];

  /// desc 改成 key
  List<Map<String, dynamic>> videoFitType = [
    {'attr': BoxFit.contain, 'desc': 'video_fit_default'},
    {'attr': BoxFit.cover, 'desc': 'video_fit_crop_center'},
    {'attr': BoxFit.fill, 'desc': 'video_fit_fill_screen'},
    {'attr': BoxFit.fitHeight, 'desc': 'video_fit_fit_height'},
    {'attr': BoxFit.fitWidth, 'desc': 'video_fit_fit_width'},
    {'attr': BoxFit.scaleDown, 'desc': 'video_fit_scale_down'},
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
  static Map<ColorSwatch<Object>, String> colorsNameMap = AppConsts.themeColors.map(
    (key, value) => MapEntry(ColorTools.createPrimarySwatch(value), key),
  );

  static const List<Map<String, String>> allStyles = [
    {'key': 'default', 'nameEn': 'Default Ring', 'nameZh': '默认圆环'},
    {'key': 'rotatingPlain', 'nameEn': 'Rotating Plain', 'nameZh': '旋转方块'},
    {'key': 'doubleBounce', 'nameEn': 'Double Bounce', 'nameZh': '双重大圆'},
    {'key': 'wave', 'nameEn': 'Wave', 'nameZh': '波浪跳跃'},
    {'key': 'wanderingCubes', 'nameEn': 'Wandering Cubes', 'nameZh': '双块漫游'},
    {'key': 'fadingFour', 'nameEn': 'Fading Four', 'nameZh': '交替隐藏'},
    {'key': 'fadingCube', 'nameEn': 'Fading Cube', 'nameZh': '渐隐方块'},
    {'key': 'pulse', 'nameEn': 'Pulse', 'nameZh': '脉冲水波'},
    {'key': 'chasingDots', 'nameEn': 'Chasing Dots', 'nameZh': '追逐双圆'},
    {'key': 'threeBounce', 'nameEn': 'Three Bounce', 'nameZh': '三点弹跳'},
    {'key': 'circle', 'nameEn': 'Circle', 'nameZh': '时钟小点'},
    {'key': 'cubeGrid', 'nameEn': 'Cube Grid', 'nameZh': '九宫方格'},
    {'key': 'fadingCircle', 'nameEn': 'Fading Circle', 'nameZh': '渐隐圆圈'},
    {'key': 'rotatingCircle', 'nameEn': 'Rotating Circle', 'nameZh': '旋转大圆'},
    {'key': 'foldingCube', 'nameEn': 'Folding Cube', 'nameZh': '折叠魔方'},
    {'key': 'pumpingHeart', 'nameEn': 'Pumping Heart', 'nameZh': '心跳波动'},
    {'key': 'hourGlass', 'nameEn': 'Hour Glass', 'nameZh': '翻转沙漏'},
    {'key': 'pouringHourGlass', 'nameEn': 'Pouring Hour Glass', 'nameZh': '流动沙漏'},
    {'key': 'pouringHourGlassRefined', 'nameEn': 'Hour Glass Refined', 'nameZh': '质感沙漏'},
    {'key': 'fadingGrid', 'nameEn': 'Fading Grid', 'nameZh': '矩阵渐隐'},
    {'key': 'ring', 'nameEn': 'Ring', 'nameZh': '纯净圆环'},
    {'key': 'ripple', 'nameEn': 'Ripple', 'nameZh': '震荡涟漪'},
    {'key': 'spinningCircle', 'nameEn': 'Spinning Circle', 'nameZh': '半圆飞旋'},
    {'key': 'spinningLines', 'nameEn': 'Spinning Lines', 'nameZh': '流动线条'},
    {'key': 'squareCircle', 'nameEn': 'Square Circle', 'nameZh': '方变圆弧'},
    {'key': 'dualRing', 'nameEn': 'Dual Ring', 'nameZh': '双轨游环'},
    {'key': 'pianoWave', 'nameEn': 'Piano Wave', 'nameZh': '琴键节奏'},
    {'key': 'dancingSquare', 'nameEn': 'Dancing Square', 'nameZh': '律动方块'},
    {'key': 'threeInOut', 'nameEn': 'Three In Out', 'nameZh': '三点缩放'},
    {'key': 'waveSpinner', 'nameEn': 'Wave Spinner', 'nameZh': '声波雷达'},
    {'key': 'pulsingGrid', 'nameEn': 'Pulsing Grid', 'nameZh': '脉冲网格'},
    {'key': 'waveDots', 'nameEn': 'Wave Dots', 'nameZh': '律动圆点'},
    {'key': 'inkDrop', 'nameEn': 'Ink Drop', 'nameZh': '动态水滴'},
    {'key': 'twistingDots', 'nameEn': 'Twisting Dots', 'nameZh': '基因螺旋'},
    {'key': 'threeRotatingDots', 'nameEn': 'Three Rotating', 'nameZh': '三星环绕'},
    {'key': 'staggeredDotsWave', 'nameEn': 'Staggered Wave', 'nameZh': '错落波浪'},
    {'key': 'fourRotatingDots', 'nameEn': 'Four Rotating', 'nameZh': '四星环绕'},
    {'key': 'fallingDot', 'nameEn': 'Falling Dot', 'nameZh': '重力落点'},
    {'key': 'progressiveDots', 'nameEn': 'Progressive Dots', 'nameZh': '线性生长'},
    {'key': 'discreteCircular', 'nameEn': 'Discrete Circle', 'nameZh': '分离圆环'},
    {'key': 'threeArchedCircle', 'nameEn': 'Three Arched', 'nameZh': '三重连环'},
    {'key': 'bouncingBall', 'nameEn': 'Bouncing Ball', 'nameZh': '地面弹球'},
    {'key': 'flickr', 'nameEn': 'Flickr', 'nameZh': '环绕互换'},
    {'key': 'hexagonDots', 'nameEn': 'Hexagon Dots', 'nameZh': '六角矩阵'},
    {'key': 'beat', 'nameEn': 'Beat', 'nameZh': '心率电波'},
    {'key': 'twoRotatingArc', 'nameEn': 'Two Rotating Arc', 'nameZh': '双轴弧旋'},
    {'key': 'horizontalRotatingDots', 'nameEn': 'Horizontal Dots', 'nameZh': '水平环绕'},
    {'key': 'newtonCradle', 'nameEn': 'Newton Cradle', 'nameZh': '牛顿摆球'},
    {'key': 'stretchedDots', 'nameEn': 'Stretched Dots', 'nameZh': '拉伸光点'},
    {'key': 'halfTriangleDot', 'nameEn': 'Half Triangle', 'nameZh': '三角错落'},
    {'key': 'dotsTriangle', 'nameEn': 'Dots Triangle', 'nameZh': '动态三角'},
    {'key': 'ballPulse', 'nameEn': 'Ball Pulse', 'nameZh': '三点渐变'},
    {'key': 'ballGridPulse', 'nameEn': 'Ball Grid Pulse', 'nameZh': '九宫格闪烁'},
    {'key': 'ballClipRotate', 'nameEn': 'Ball Clip Rotate', 'nameZh': '裁剪圆环旋转'},
    {'key': 'ballClipRotatePulse', 'nameEn': 'Ball Clip Rotate Pulse', 'nameZh': '双层环球旋转'},
    {'key': 'squareSpin', 'nameEn': 'Square Spin', 'nameZh': '方块翻转'},
    {'key': 'ballClipRotateMultiple', 'nameEn': 'Ball Clip Rotate Multiple', 'nameZh': '多重碎片圆环'},
    {'key': 'ballPulseRise', 'nameEn': 'Ball Pulse Rise', 'nameZh': '交错交替上升'},
    {'key': 'ballRotate', 'nameEn': 'Ball Rotate', 'nameZh': '三球围绕旋转'},
    {'key': 'cubeTransition', 'nameEn': 'Cube Transition', 'nameZh': '双对角方块位移'},
    {'key': 'ballZigZag', 'nameEn': 'Ball ZigZag', 'nameZh': '双球Z字错位'},
    {'key': 'ballZigZagDeflect', 'nameEn': 'Ball ZigZag Deflect', 'nameZh': '双球曲线反弹'},
    {'key': 'ballTrianglePath', 'nameEn': 'Ball Triangle Path', 'nameZh': '三角轨迹循环'},
    {'key': 'ballTrianglePathColored', 'nameEn': 'Ball Triangle Path Colored', 'nameZh': '三角彩轨循环'}, // 补齐
    {'key': 'ballTrianglePathColoredFilled', 'nameEn': 'Ball Triangle Filled', 'nameZh': '三角实心循环'}, // 补齐
    {'key': 'ballScale', 'nameEn': 'Ball Scale', 'nameZh': '单圆水波脉冲'},
    {'key': 'lineScale', 'nameEn': 'Line Scale', 'nameZh': '五线谱律动'},
    {'key': 'lineScaleParty', 'nameEn': 'Line Scale Party', 'nameZh': '律动线条'},
    {'key': 'ballScaleMultiple', 'nameEn': 'Ball Scale Multiple', 'nameZh': '多重水波涟漪'},
    {'key': 'ballPulseSync', 'nameEn': 'Ball Pulse Sync', 'nameZh': '三点波浪同步'},
    {'key': 'ballBeat', 'nameEn': 'Ball Beat', 'nameZh': '三点心跳缩放'},
    {'key': 'lineScalePulseOut', 'nameEn': 'Line Scale Pulse Out', 'nameZh': '线条由内向外扩散'},
    {'key': 'lineScalePulseOutRapid', 'nameEn': 'Line Scale Pulse Out Rapid', 'nameZh': '线条高频向外扩散'},
    {'key': 'ballScaleRipple', 'nameEn': 'Ball Scale Ripple', 'nameZh': '空心圆环震荡'},
    {'key': 'ballScaleRippleMultiple', 'nameEn': 'Ball Scale Ripple Multiple', 'nameZh': '多重空心涟漪'},
    {'key': 'ballSpinFadeLoader', 'nameEn': 'Ball Spin Fade Loader', 'nameZh': '经典菊花圆点'},
    {'key': 'lineSpinFadeLoader', 'nameEn': 'Line Spin Fade Loader', 'nameZh': '经典时钟线条'},
    {'key': 'triangleSkewSpin', 'nameEn': 'Triangle Skew Spin', 'nameZh': '三角倾斜翻转'},
    {'key': 'pacman', 'nameEn': 'Pacman', 'nameZh': '吃豆人游戏'},
    {'key': 'ballGridBeat', 'nameEn': 'Ball Grid Beat', 'nameZh': '九宫格心跳闪烁'},
    {'key': 'semiCircleSpin', 'nameEn': 'Semi Circle Spin', 'nameZh': '半圆飞速旋转'},
    {'key': 'ballRotateChase', 'nameEn': 'Ball Rotate Chase', 'nameZh': '圆点接力追逐'},
    {'key': 'orbit', 'nameEn': 'Orbit', 'nameZh': '行星轨道公转'},
    {'key': 'audioEqualizer', 'nameEn': 'Audio Equalizer', 'nameZh': '音频均衡器'}, // 替代旧版 audioWave
    {'key': 'circleStrokeSpin', 'nameEn': 'Circle Stroke Spin', 'nameZh': '纯净描边圆环'},
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
  static const List<String> players = ['Mpv播放器', 'IJK播放器', 'Exo播放器'];

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
}
