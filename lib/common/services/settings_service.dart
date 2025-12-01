import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:pure_live/common/services/bilibili_account_service.dart';

class SettingsService extends GetxController {
  SettingsService() {
    enableDynamicTheme.listen((bool value) {
      PrefUtil.setBool('enableDynamicTheme', value);
      update(['myapp']);
    });
    themeColorSwitch.listen((value) {
      themeColorSwitch.value = value;
      PrefUtil.setString('themeColorSwitch', value);
    });
    enableDenseFavorites.listen((value) {
      PrefUtil.setBool('enableDenseFavorites', value);
    });

    shieldList.listen((value) {
      PrefUtil.setStringList('shieldList', value);
    });

    hotAreasList.listen((value) {
      PrefUtil.setStringList('hotAreasList', value);
    });
    favoriteRooms.listen((rooms) {
      PrefUtil.setStringList('favoriteRooms', favoriteRooms.map<String>((e) => jsonEncode(e.toJson())).toList());
    });
    favoriteAreas.listen((rooms) {
      PrefUtil.setStringList('favoriteAreas', favoriteAreas.map<String>((e) => jsonEncode(e.toJson())).toList());
    });

    historyRooms.listen((rooms) {
      PrefUtil.setStringList('historyRooms', historyRooms.map<String>((e) => jsonEncode(e.toJson())).toList());
    });

    videoFitIndex.listen((value) {
      PrefUtil.setInt('videoFitIndex', value);
    });
    hideDanmaku.listen((value) {
      PrefUtil.setBool('hideDanmaku', value);
    });

    danmakuArea.listen((value) {
      PrefUtil.setDouble('danmakuArea', value);
    });

    danmakuTopArea.listen((value) {
      PrefUtil.setDouble('danmakuTopArea', value);
    });

    danmakuBottomArea.listen((value) {
      PrefUtil.setDouble('danmakuBottomArea', value);
    });

    danmakuSpeed.listen((value) {
      PrefUtil.setDouble('danmakuSpeed', value);
    });

    danmakuSpeed.listen((value) {
      PrefUtil.setDouble('danmakuSpeed', value);
    });

    danmakuFontSize.listen((value) {
      PrefUtil.setDouble('danmakuFontSize', value);
    });

    danmakuFontBorder.listen((value) {
      PrefUtil.setDouble('danmakuFontBorder', value);
    });

    danmakuOpacity.listen((value) {
      PrefUtil.setDouble('danmakuOpacity', value);
    });

    doubleExit.listen((value) {
      PrefUtil.setBool('doubleExit', value);
    });

    enableCodec.listen((value) {
      PrefUtil.setBool('enableCodec', value);
    });

    videoPlayerIndex.listen((value) {
      PrefUtil.setInt('videoPlayerIndex', value);
    });

    bilibiliCookie.listen((value) {
      PrefUtil.setString('bilibiliCookie', value);
    });

    huyaCookie.listen((value) {
      PrefUtil.setString('huyaCookie', value);
    });

    douyinCookie.listen((value) {
      PrefUtil.setString('douyinCookie', value);
    });

    webPort.listen((value) {
      PrefUtil.setString('webPort', value);
    });

    isFirstInApp.listen((value) {
      PrefUtil.setBool('isFirstInApp', false);
    });

    currentBoxImage.listen((value) {
      PrefUtil.setString('currentBoxImage', value);
    });

    currentBoxImageIndex.listen((value) {
      PrefUtil.setInt('currentBoxImageIndex', value);
    });

    playerCompatMode.listen((value) {
      PrefUtil.setBool('playerCompatMode', value);
    });

    preferResolution.listen((value) {
      PrefUtil.setString('preferResolution', value);
    });

    preferPlatform.listen((value) {
      PrefUtil.setString('preferPlatform', value);
    });
  }
  // Theme settings
  static Map<String, ThemeMode> themeModes = {
    "System": ThemeMode.system,
    "Dark": ThemeMode.dark,
    "Light": ThemeMode.light,
  };
  final themeModeName = (PrefUtil.getString('themeMode') ?? "System").obs;

  ThemeMode get themeMode => SettingsService.themeModes[themeModeName.value]!;

  void changeThemeMode(String mode) {
    themeModeName.value = mode;
    PrefUtil.setString('themeMode', mode);
    Get.changeThemeMode(themeMode);
  }

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

  // Make a custom ColorSwatch to name map from the above custom colors.
  final Map<ColorSwatch<Object>, String> colorsNameMap = themeColors.map(
    (key, value) => MapEntry(ColorTools.createPrimarySwatch(value), key),
  );

  final StopWatchTimer _stopWatchTimer = StopWatchTimer(mode: StopWatchMode.countDown); // Create instance.

  final themeColorSwitch = (PrefUtil.getString('themeColorSwitch') ?? Colors.red.hex).obs;

  final AppFocusNode preferResolutionNode = AppFocusNode();

  final AppFocusNode videoPlayerNode = AppFocusNode();

  final AppFocusNode enableCodecNode = AppFocusNode();

  final AppFocusNode playerCompatModeNode = AppFocusNode();

  final AppFocusNode preferPlatformNode = AppFocusNode();

  final AppFocusNode dataSyncNode = AppFocusNode();

  final AppFocusNode accountNode = AppFocusNode();

  final AppFocusNode platformNode = AppFocusNode();

  final AppFocusNode currentImageNode = AppFocusNode();

  final AppFocusNode currentImageIndexNode = AppFocusNode();

  StopWatchTimer get stopWatchTimer => _stopWatchTimer;

  static Map<String, Locale> languages = {
    "English": const Locale.fromSubtags(languageCode: 'en'),
    "简体中文": const Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
  };
  final languageName = (PrefUtil.getString('language') ?? "简体中文").obs;

  final webPort = (PrefUtil.getString('webPort') ?? "9527").obs;

  final webPortEnable = false.obs;

  final httpErrorMsg = ''.obs;

  final isFirstInApp = (PrefUtil.getBool('isFirstInApp') ?? true).obs;

  final playerCompatMode = (PrefUtil.getBool('playerCompatMode') ?? false).obs;
  // Route change type 0: push, 1: pop, 2: replace
  final routeChangeType = RouteChangeType.push.obs;

  final currentRouteName = ''.obs;

  Locale get language => SettingsService.languages[languageName.value]!;

  void changeLanguage(String value) {
    languageName.value = value;
    PrefUtil.setString('language', value);
    Get.updateLocale(language);
  }

  void changePlayer(int value) {
    videoPlayerIndex.value = value;
    PrefUtil.setInt('videoPlayerIndex', value);
  }

  final enableDynamicTheme = (PrefUtil.getBool('enableDynamicTheme') ?? false).obs;

  // Custom settings
  final autoRefreshTime = (PrefUtil.getInt('autoRefreshTime') ?? 3).obs;

  final autoShutDownTime = (PrefUtil.getInt('autoShutDownTime') ?? 120).obs;

  final enableDenseFavorites = (PrefUtil.getBool('enableDenseFavorites') ?? false).obs;

  final enableBackgroundPlay = (PrefUtil.getBool('enableBackgroundPlay') ?? false).obs;

  final enableScreenKeepOn = (PrefUtil.getBool('enableScreenKeepOn') ?? true).obs;

  final enableAutoCheckUpdate = (PrefUtil.getBool('enableAutoCheckUpdate') ?? true).obs;
  final videoFitIndex = (PrefUtil.getInt('videoFitIndex') ?? 0).obs;
  final hideDanmaku = (PrefUtil.getBool('hideDanmaku') ?? false).obs;
  final danmakuArea = (PrefUtil.getDouble('danmakuArea') ?? 1.0).obs;
  final danmakuTopArea = (PrefUtil.getDouble('danmakuTopArea') ?? 0.0).obs;
  final danmakuBottomArea = (PrefUtil.getDouble('danmakuBottomArea') ?? 0.5).obs;
  final danmakuSpeed = (PrefUtil.getDouble('danmakuSpeed') ?? 8.0).obs;
  final danmakuFontSize = (PrefUtil.getDouble('danmakuFontSize') ?? 16.0).obs;
  final danmakuFontBorder = (PrefUtil.getDouble('danmakuFontBorder') ?? 4.0).obs;

  final danmakuOpacity = (PrefUtil.getDouble('danmakuOpacity') ?? 1.0).obs;

  final videoPlayerIndex = (PrefUtil.getInt('videoPlayerIndex') ?? 0).obs;

  final enableFullScreenDefault = (PrefUtil.getBool('enableFullScreenDefault') ?? false).obs;

  final enableCodec = (PrefUtil.getBool('enableCodec') ?? true).obs;

  final enableAutoShutDownTime = (PrefUtil.getBool('enableAutoShutDownTime') ?? false).obs;
  final doubleExit = (PrefUtil.getBool('doubleExit') ?? true).obs;
  static const List<String> resolutions = ['原画', '蓝光8M', '蓝光4M', '超清', '流畅'];

  final bilibiliCookie = (PrefUtil.getString('bilibiliCookie') ?? '').obs;

  final huyaCookie = (PrefUtil.getString('huyaCookie') ?? '').obs;

  final douyinCookie = (PrefUtil.getString('douyinCookie') ?? '').obs;

  static const List<BoxFit> videofitList = [
    BoxFit.contain,
    BoxFit.fill,
    BoxFit.cover,
    BoxFit.fitWidth,
    BoxFit.fitHeight,
  ];

  final preferResolution = (PrefUtil.getString('preferResolution') ?? resolutions[0]).obs;

  void changePreferResolution(String name) {
    if (resolutions.indexWhere((e) => e == name) != -1) {
      preferResolution.value = name;
      PrefUtil.setString('preferResolution', name);
    }
  }

  List<String> get resolutionsList => resolutions;

  List<BoxFit> get videofitArrary => videofitList;

  void changeAutoRefreshConfig(int minutes) {
    autoRefreshTime.value = minutes;
    PrefUtil.setInt('autoRefreshTime', minutes);
  }

  static const List<String> platforms = ['bilibili', 'douyu', 'huya', 'douyin', 'kuaishow', 'cc', '网络'];

  final preferPlatform = (PrefUtil.getString('preferPlatform') ?? platforms[0]).obs;

  void changePreferPlatform(String name) {
    if (platforms.indexWhere((e) => e == name) != -1) {
      preferPlatform.value = name;
      update(['myapp']);
      PrefUtil.setString('preferPlatform', name);
    }
  }

  static const List<String> players = ['MpvPlayer', 'ExoPlayer'];

  List<String> get playerlist => players;

  static const List<String> supportSites = ['bilibili', 'douyu', 'huya', 'douyin', 'kuaishou', 'cc', 'iptv'];

  final shieldList = ((PrefUtil.getStringList('shieldList') ?? [])).obs;

  final hotAreasList = ((PrefUtil.getStringList('hotAreasList') ?? supportSites)).obs;

  // Favorite rooms storage
  final favoriteRooms =
      ((PrefUtil.getStringList('favoriteRooms') ?? []).map((e) => LiveRoom.fromJson(jsonDecode(e))).toList()).obs;

  final historyRooms =
      ((PrefUtil.getStringList('historyRooms') ?? []).map((e) => LiveRoom.fromJson(jsonDecode(e))).toList()).obs;

  final currentPlayList = [].obs;

  final currentPlayListNodeIndex = 0.obs;

  final currentBoxImage = (PrefUtil.getString('currentBoxImage') ?? "").obs;

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

  final currentBoxImageIndex = (PrefUtil.getInt('currentBoxImageIndex') ?? 0).obs;

  Future<void> getImage() async {
    var url = currentBoxImageSources.map((e) => e.values.first).toList()[currentBoxImageIndex.value];
    if (url == "default") {
      currentBoxImage.value = "";
    } else if (url == "https://t.alcy.cc/") {
      var category = ['ycy', 'moez', 'ai', 'ysz', 'ys', 'mp', 'moemp', 'ysmp', 'aimp', 'tx', 'lai', 'xhl', 'bd'];
      var index = Random().nextInt(category.length);
      var requestUrl = url + category[index];
      Dio dio = Dio();
      var response = await dio.get(requestUrl, options: Options(responseType: ResponseType.bytes));
      String base64String = base64Encode(response.data);
      if (base64String.length > 30) {
        currentBoxImage.value = base64String;
      } else {
        SmartDialog.showToast("图片加载失败,请重新获取");
      }
    } else {
      Dio dio = Dio();
      var response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36',
          },
        ),
      );
      String base64String = base64Encode(response.data);
      if (base64String.length > 30) {
        currentBoxImage.value = base64String;
      } else {
        SmartDialog.showToast("图片加载失败,请重新获取");
      }
    }
  }

  Map<dynamic, String> getBoxImageItems() {
    var keys = currentBoxImageSources.map((e) => e.keys.first).toList();
    Map<dynamic, String> map = {};
    for (var i = 0; i < keys.length; i++) {
      map[keys[i]] = keys[i];
    }
    return map;
  }

  bool isFavorite(LiveRoom room) {
    return favoriteRooms.any((element) => element.roomId == room.roomId);
  }

  LiveRoom getLiveRoomByRoomId(String roomId, String platform) {
    if (!favoriteRooms.any((element) => element.roomId == roomId && element.platform == platform) &&
        !historyRooms.any((element) => element.roomId == roomId && element.platform == platform)) {
      return LiveRoom(roomId: roomId, platform: platform, liveStatus: LiveStatus.unknown);
    }
    return favoriteRooms.firstWhere(
      (element) => element.roomId == roomId && element.platform == platform,
      orElse: () => historyRooms.firstWhere((element) => element.roomId == roomId && element.platform == platform),
    );
  }

  bool addRoom(LiveRoom room) {
    if (favoriteRooms.any((element) => element.roomId == room.roomId)) {
      return false;
    }
    favoriteRooms.add(room);
    return true;
  }

  void addShieldList(String value) {
    shieldList.add(value);
  }

  void removeShieldList(int value) {
    shieldList.removeAt(value);
  }

  bool removeRoom(LiveRoom room) {
    if (!favoriteRooms.any((element) => element.roomId == room.roomId)) {
      return false;
    }
    favoriteRooms.remove(room);
    return true;
  }

  bool removeHistoryRoom(LiveRoom room) {
    if (!historyRooms.any((element) => element.roomId == room.roomId)) {
      return false;
    }
    historyRooms.remove(room);
    return true;
  }

  bool updateRoom(LiveRoom room) {
    updateRoomInHistory(room);
    int idx = favoriteRooms.indexWhere((element) => element.roomId == room.roomId);
    if (idx == -1) return false;
    favoriteRooms[idx] = room;
    return true;
  }

  void updateRooms(List<LiveRoom> rooms) {
    favoriteRooms.value = rooms;
  }

  bool updateRoomInHistory(LiveRoom room) {
    int idx = historyRooms.indexWhere((element) => element.roomId == room.roomId);
    if (idx == -1) return false;
    historyRooms[idx] = room;
    return true;
  }

  void addRoomToHistory(LiveRoom room) {
    if (historyRooms.any((element) => element.roomId == room.roomId)) {
      historyRooms.remove(room);
    }
    updateRoom(room);
    //默认只记录50条，够用了
    // 防止数据量大页面卡顿
    if (historyRooms.length > 50) {
      historyRooms.removeRange(0, historyRooms.length - 50);
    }
    historyRooms.insert(0, room);
  }

  // Favorite areas storage
  final favoriteAreas =
      ((PrefUtil.getStringList('favoriteAreas') ?? []).map((e) => LiveArea.fromJson(jsonDecode(e))).toList()).obs;

  bool isFavoriteArea(LiveArea area) {
    return favoriteAreas.any(
      (element) =>
          element.areaId == area.areaId && element.platform == area.platform && element.areaType == area.areaType,
    );
  }

  bool addArea(LiveArea area) {
    if (favoriteAreas.any(
      (element) =>
          element.areaId == area.areaId && element.platform == area.platform && element.areaType == area.areaType,
    )) {
      return false;
    }
    favoriteAreas.add(area);
    return true;
  }

  bool removeArea(LiveArea area) {
    if (!favoriteAreas.any(
      (element) =>
          element.areaId == area.areaId && element.platform == area.platform && element.areaType == area.areaType,
    )) {
      return false;
    }
    favoriteAreas.remove(area);
    return true;
  }

  // Backup & recover storage
  final backupDirectory = (PrefUtil.getString('backupDirectory') ?? '').obs;

  final m3uDirectory = (PrefUtil.getString('m3uDirectory') ?? 'm3uDirectory').obs;

  bool backup(File file) {
    try {
      final json = toJson();
      file.writeAsStringSync(jsonEncode(json));
    } catch (e) {
      return false;
    }
    return true;
  }

  bool recover(File file) {
    try {
      final json = file.readAsStringSync();
      fromJson(jsonDecode(json));
    } catch (e) {
      return false;
    }
    return true;
  }

  void setBilibiliCookit(String cookie) {
    final BiliBiliAccountService biliAccountService = Get.find<BiliBiliAccountService>();
    if (biliAccountService.cookie.isEmpty || biliAccountService.uid == 0) {
      biliAccountService.resetCookie(cookie);
      biliAccountService.loadUserInfo();
    }
  }

  void fromJson(Map<String, dynamic> json) {
    favoriteRooms.value = json['favoriteRooms'] != null
        ? (json['favoriteRooms'] as List).map<LiveRoom>((e) => LiveRoom.fromJson(jsonDecode(e))).toList()
        : [];
    favoriteAreas.value = json['favoriteAreas'] != null
        ? (json['favoriteAreas'] as List).map<LiveArea>((e) => LiveArea.fromJson(jsonDecode(e))).toList()
        : [];
    shieldList.value = json['shieldList'] != null ? (json['shieldList'] as List).map((e) => e.toString()).toList() : [];
    hotAreasList.value = json['hotAreasList'] != null
        ? (json['hotAreasList'] as List).map((e) => e.toString()).toList()
        : [];
    themeModeName.value = json['themeMode'] ?? "System";
    enableDynamicTheme.value = json['enableDynamicTheme'] ?? false;
    enableDenseFavorites.value = json['enableDenseFavorites'] ?? false;
    languageName.value = json['languageName'] ?? "简体中文";
    preferResolution.value = json['preferResolution'] ?? resolutions[0];
    preferPlatform.value = json['preferPlatform'] ?? platforms[0];
    bilibiliCookie.value = json['bilibiliCookie'] ?? '';
    huyaCookie.value = json['huyaCookie'] ?? '';
    douyinCookie.value = json['douyinCookie'] ?? '';
    themeColorSwitch.value = json['themeColorSwitch'] ?? Colors.blue.hex;
    webPort.value = json['webPort'] ?? '9527';
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['favoriteRooms'] = favoriteRooms.map<String>((e) => jsonEncode(e.toJson())).toList();
    json['favoriteAreas'] = favoriteAreas.map<String>((e) => jsonEncode(e.toJson())).toList();
    json['themeMode'] = themeModeName.value;

    json['autoRefreshTime'] = autoRefreshTime.value;
    json['autoShutDownTime'] = autoShutDownTime.value;
    json['enableAutoShutDownTime'] = enableAutoShutDownTime.value;

    json['enableDynamicTheme'] = enableDynamicTheme.value;
    json['enableDenseFavorites'] = enableDenseFavorites.value;
    json['enableBackgroundPlay'] = enableBackgroundPlay.value;
    json['enableScreenKeepOn'] = enableScreenKeepOn.value;
    json['enableAutoCheckUpdate'] = enableAutoCheckUpdate.value;
    json['enableFullScreenDefault'] = enableFullScreenDefault.value;
    json['preferResolution'] = preferResolution.value;
    json['preferPlatform'] = preferPlatform.value;
    json['languageName'] = languageName.value;

    json['videoFitIndex'] = videoFitIndex.value;
    json['hideDanmaku'] = hideDanmaku.value;
    json['danmakuArea'] = danmakuArea.value;
    json['danmakuTopArea'] = danmakuTopArea.value;
    json['danmakuBottomArea'] = danmakuBottomArea.value;
    json['danmakuSpeed'] = danmakuSpeed.value;
    json['danmakuFontSize'] = danmakuFontSize.value;
    json['danmakuFontBorder'] = danmakuFontBorder.value;
    json['danmakuOpacity'] = danmakuOpacity.value;
    json['doubleExit'] = doubleExit.value;
    json['videoPlayerIndex'] = videoPlayerIndex.value;
    json['enableCodec'] = enableCodec.value;
    json['bilibiliCookie'] = bilibiliCookie.value;
    json['huyaCookie'] = huyaCookie.value;
    json['douyinCookie'] = douyinCookie.value;
    json['shieldList'] = shieldList.map<String>((e) => e.toString()).toList();
    json['hotAreasList'] = hotAreasList.map<String>((e) => e.toString()).toList();

    json['themeColorSwitch'] = themeColorSwitch.value;
    json['webPort'] = webPort.value;
    json['webPortEnable'] = false;
    return json;
  }

  Map<String, dynamic> defaultConfig() {
    Map<String, dynamic> json = {
      "favoriteRooms": [],
      "favoriteAreas": [],
      "themeMode": "Light",
      "themeColor": "Chrome",
      "enableDynamicTheme": false,
      "autoShutDownTime": 120,
      "autoRefreshTime": 3,
      "languageName": languageName.value,
      "enableAutoShutDownTime": false,
      "enableDenseFavorites": false,
      "enableBackgroundPlay": false,
      "enableScreenKeepOn": true,
      "enableAutoCheckUpdate": false,
      "enableFullScreenDefault": false,
      "preferResolution": "原画",
      "preferPlatform": "bilibili",
      "hideDanmaku": false,
      "danmakuArea": 1.0,
      "danmakuSpeed": 8.0,
      "danmakuFontSize": 16.0,
      "danmakuFontBorder": 4.0,
      "videoPlayerIndex": 0,
      "danmakuOpacity": 1.0,
      'doubleExit': true,
      'enableCodec': true,
      'bilibiliCookie': '',
      'huyaCookie': '',
      'douyinCookie': '',
      'shieldList': [],
      "hotAreasList": [],
      "webPortEnable": false,
      "webPort": "9527",
    };
    return json;
  }
}
