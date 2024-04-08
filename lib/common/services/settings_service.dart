import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/plugins/local_http.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
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
    autoRefreshTime.listen((value) {
      PrefUtil.setInt('autoRefreshTime', value);
    });
    debounce(autoShutDownTime, (callback) {
      PrefUtil.setInt('autoShutDownTime', autoShutDownTime.value);
      if (enableAutoShutDownTime.isTrue) {
        _stopWatchTimer.onStopTimer();
        _stopWatchTimer.setPresetMinuteTime(autoShutDownTime.value, add: false);
        _stopWatchTimer.onStartTimer();
      } else {
        _stopWatchTimer.onStopTimer();
      }
    }, time: 1.seconds);
    enableBackgroundPlay.listen((value) {
      PrefUtil.setBool('enableBackgroundPlay', value);
    });
    enableScreenKeepOn.listen((value) {
      PrefUtil.setBool('enableScreenKeepOn', value);
    });
    debounce(enableAutoShutDownTime, (callback) {
      PrefUtil.setBool('enableAutoShutDownTime', enableAutoShutDownTime.value);
      if (enableAutoShutDownTime.value == true) {
        _stopWatchTimer.onStopTimer();
        _stopWatchTimer.setPresetMinuteTime(autoShutDownTime.value, add: false);
        _stopWatchTimer.onStartTimer();
      } else {
        _stopWatchTimer.onStopTimer();
      }
    }, time: 1.seconds);
    enableAutoCheckUpdate.listen((value) {
      PrefUtil.setBool('enableAutoCheckUpdate', value);
    });
    enableFullScreenDefault.listen((value) {
      PrefUtil.setBool('enableFullScreenDefault', value);
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

    backupDirectory.listen((String value) {
      PrefUtil.setString('backupDirectory', value);
    });
    onInitShutDown();
    _stopWatchTimer.fetchEnded.listen((value) {
      _stopWatchTimer.onStopTimer();
      FlutterExitApp.exitApp();
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

    mergeDanmuRating.listen((value) {
      PrefUtil.setDouble('mergeDanmuRating', value);
    });

    webPort.listen((value) {
      PrefUtil.setString('webPort', value);
    });

    webPortEnable.listen((value) {
      changeWebListen(webPort.value, value);
      PrefUtil.setBool('webPortEnable', value);
    });
  }

  // Theme settings
  static Map<String, ThemeMode> themeModes = {
    "System": ThemeMode.system,
    "Dark": ThemeMode.dark,
    "Light": ThemeMode.light,
  };
  final themeModeName = (PrefUtil.getString('themeMode') ?? "System").obs;

  get themeMode => SettingsService.themeModes[themeModeName.value]!;

  void changeThemeMode(String mode) {
    themeModeName.value = mode;
    PrefUtil.setString('themeMode', mode);
    Get.changeThemeMode(themeMode);
  }

  void changeThemeColorSwitch(String hexColor) {
    var themeColor = HexColor(hexColor);
    var lightTheme = MyTheme(primaryColor: themeColor).lightThemeData;
    var darkTheme = MyTheme(primaryColor: themeColor).darkThemeData;
    Get.changeTheme(lightTheme);
    Get.changeTheme(darkTheme);
  }

  void onInitShutDown() {
    if (enableAutoShutDownTime.isTrue) {
      _stopWatchTimer.setPresetMinuteTime(autoShutDownTime.value, add: false);
      _stopWatchTimer.onStartTimer();
    }
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
  final Map<ColorSwatch<Object>, String> colorsNameMap =
      themeColors.map((key, value) => MapEntry(ColorTools.createPrimarySwatch(value), key));

  final StopWatchTimer _stopWatchTimer = StopWatchTimer(mode: StopWatchMode.countDown); // Create instance.

  final themeColorSwitch = (PrefUtil.getString('themeColorSwitch') ?? Colors.blue.hex).obs;

  StopWatchTimer get stopWatchTimer => _stopWatchTimer;

  static Map<String, Locale> languages = {
    "English": const Locale.fromSubtags(languageCode: 'en'),
    "简体中文": const Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
  };
  final languageName = (PrefUtil.getString('language') ?? "简体中文").obs;

  final webPort = (PrefUtil.getString('webPort') ?? "8008").obs;

  final webPortEnable = (PrefUtil.getBool('webPortEnable') ?? false).obs;

  get language => SettingsService.languages[languageName.value]!;

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
  final danmakuSpeed = (PrefUtil.getDouble('danmakuSpeed') ?? 8.0).obs;
  final danmakuFontSize = (PrefUtil.getDouble('danmakuFontSize') ?? 16.0).obs;
  final danmakuFontBorder = (PrefUtil.getDouble('danmakuFontBorder') ?? 0.5).obs;

  final danmakuOpacity = (PrefUtil.getDouble('danmakuOpacity') ?? 1.0).obs;

  final enableFullScreenDefault = (PrefUtil.getBool('enableFullScreenDefault') ?? false).obs;

  final videoPlayerIndex = (PrefUtil.getInt('videoPlayerIndex') ?? 0).obs;

  final enableCodec = (PrefUtil.getBool('enableCodec') ?? true).obs;

  final mergeDanmuRating = (PrefUtil.getDouble('mergeDanmuRating') ?? 0.0).obs;

  final enableAutoShutDownTime = (PrefUtil.getBool('enableAutoShutDownTime') ?? false).obs;
  final doubleExit = (PrefUtil.getBool('doubleExit') ?? true).obs;
  static const List<String> resolutions = ['原画', '蓝光8M', '蓝光4M', '超清', '流畅'];

  // cookie

  final bilibiliCookie = (PrefUtil.getString('bilibiliCookie') ?? '').obs;
  static const List<BoxFit> videofitList = [
    BoxFit.contain,
    BoxFit.fill,
    BoxFit.cover,
    BoxFit.fitWidth,
    BoxFit.fitHeight
  ];

  final preferResolution = (PrefUtil.getString('preferResolution') ?? resolutions[0]).obs;

  void changePreferResolution(String name) {
    if (resolutions.indexWhere((e) => e == name) != -1) {
      preferResolution.value = name;
      PrefUtil.setString('preferResolution', name);
    }
  }

  void changeWebListen(port, enable) {
    try {
      if (enable) {
        LocalHttpServer().startServer(port);
      } else {
        LocalHttpServer().closeServer();
      }
    } catch (e) {
      SmartDialog.showToast('打开故障,请稍后重试');
    }
  }

  List<String> get resolutionsList => resolutions;

  List<BoxFit> get videofitArrary => videofitList;

  void changeShutDownConfig(int minutes, bool isAutoShutDown) {
    autoShutDownTime.value = minutes;
    enableAutoShutDownTime.value = isAutoShutDown;
    PrefUtil.setInt('autoShutDownTime', minutes);
    PrefUtil.setBool('enableAutoShutDownTime', isAutoShutDown);
    onInitShutDown();
  }

  void changeAutoRefreshConfig(int minutes) {
    autoRefreshTime.value = minutes;
    PrefUtil.setInt('autoRefreshTime', minutes);
  }

  static const List<String> platforms = ['bilibili', 'douyu', 'huya', 'douyin', 'kuaishow', 'cc', '网络'];

  static const List<String> players = ['ExoPlayer', 'IjkPlayer', 'MpvPlayer'];
  final preferPlatform = (PrefUtil.getString('preferPlatform') ?? platforms[0]).obs;

  List<String> get playerlist => players;
  void changePreferPlatform(String name) {
    if (platforms.indexWhere((e) => e == name) != -1) {
      preferPlatform.value = name;
      update(['myapp']);
      PrefUtil.setString('preferPlatform', name);
    }
  }

  static const List<String> supportSites = ['bilibili', 'douyu', 'huya', 'douyin', 'kuaishou', 'cc', 'iptv'];

  final shieldList = ((PrefUtil.getStringList('shieldList') ?? [])).obs;

  final hotAreasList = ((PrefUtil.getStringList('hotAreasList') ?? supportSites)).obs;

  // Favorite rooms storage
  final favoriteRooms =
      ((PrefUtil.getStringList('favoriteRooms') ?? []).map((e) => LiveRoom.fromJson(jsonDecode(e))).toList()).obs;

  final historyRooms =
      ((PrefUtil.getStringList('historyRooms') ?? []).map((e) => LiveRoom.fromJson(jsonDecode(e))).toList()).obs;

  bool isFavorite(LiveRoom room) {
    return favoriteRooms.any((element) => element.roomId == room.roomId);
  }

  LiveRoom getLiveRoomByRoomId(roomId, {String platform = ''}) {
    if (platform.isNotEmpty) {
      return favoriteRooms.firstWhere((element) => element.roomId == roomId && element.platform == platform);
    }
    return favoriteRooms.firstWhere((element) => element.roomId == roomId);
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

  bool updateRoom(LiveRoom room) {
    int idx = favoriteRooms.indexWhere((element) => element.roomId == room.roomId);
    if (idx == -1) return false;
    favoriteRooms[idx] = room;
    return true;
  }

  updateRooms(List<LiveRoom> rooms) {
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
    //默认只记录20条，够用了
    if (historyRooms.length > 19) {
      historyRooms.removeRange(0, historyRooms.length - 19);
    }
    historyRooms.add(room);
  }

  // Favorite areas storage
  final favoriteAreas =
      ((PrefUtil.getStringList('favoriteAreas') ?? []).map((e) => LiveArea.fromJson(jsonDecode(e))).toList()).obs;

  bool isFavoriteArea(LiveArea area) {
    return favoriteAreas.contains(area);
  }

  bool addArea(LiveArea area) {
    if (favoriteAreas.any((element) => element.areaId == area.areaId && element.platform == area.platform)) {
      return false;
    }
    favoriteAreas.add(area);
    return true;
  }

  bool removeArea(LiveArea area) {
    if (!favoriteAreas.any((element) => element.areaId == area.areaId && element.platform == area.platform)) {
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

  setBilibiliCookit(cookie) {
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
    hotAreasList.value =
        json['hotAreasList'] != null ? (json['hotAreasList'] as List).map((e) => e.toString()).toList() : [];
    autoShutDownTime.value = json['autoShutDownTime'] ?? 120;
    autoRefreshTime.value = json['autoRefreshTime'] ?? 3;
    themeModeName.value = json['themeMode'] ?? "System";
    enableAutoShutDownTime.value = json['enableAutoShutDownTime'] ?? false;
    enableDynamicTheme.value = json['enableDynamicTheme'] ?? false;
    enableDenseFavorites.value = json['enableDenseFavorites'] ?? false;
    enableBackgroundPlay.value = json['enableBackgroundPlay'] ?? false;
    enableScreenKeepOn.value = json['enableScreenKeepOn'] ?? true;
    enableAutoCheckUpdate.value = json['enableAutoCheckUpdate'] ?? true;
    enableFullScreenDefault.value = json['enableFullScreenDefault'] ?? false;
    languageName.value = json['languageName'] ?? "简体中文";
    preferResolution.value = json['preferResolution'] ?? resolutions[0];
    preferPlatform.value = json['preferPlatform'] ?? platforms[0];
    videoFitIndex.value = json['videoFitIndex'] ?? 0;
    hideDanmaku.value = json['hideDanmaku'] ?? false;
    danmakuArea.value = json['danmakuArea'] != null ? double.parse(json['danmakuArea'].toString()) : 1.0;
    danmakuSpeed.value = json['danmakuSpeed'] != null ? double.parse(json['danmakuSpeed'].toString()) : 8.0;
    danmakuFontSize.value = json['danmakuFontSize'] != null ? double.parse(json['danmakuFontSize'].toString()) : 16.0;
    danmakuFontBorder.value =
        json['danmakuFontBorder'] != null ? double.parse(json['danmakuFontBorder'].toString()) : 0.5;
    danmakuOpacity.value = json['danmakuOpacity'] != null ? double.parse(json['danmakuOpacity'].toString()) : 1.0;
    doubleExit.value = json['doubleExit'] ?? true;
    videoPlayerIndex.value = json['videoPlayerIndex'] ?? 0;
    enableCodec.value = json['enableCodec'] ?? true;
    mergeDanmuRating.value = json['mergeDanmuRating'] != null ? double.parse(json['mergeDanmuRating'].toString()) : 0.0;
    bilibiliCookie.value = json['bilibiliCookie'] ?? '';
    themeColorSwitch.value = json['themeColorSwitch'] ?? Colors.blue.hex;
    webPort.value = json['webPort'] ?? '8008';
    webPortEnable.value = json['webPortEnable'] ?? false;
    changeThemeMode(themeModeName.value);
    changeThemeColorSwitch(themeColorSwitch.value);
    setBilibiliCookit(bilibiliCookie.value);
    changeLanguage(languageName.value);
    changePreferResolution(preferResolution.value);
    changePreferPlatform(preferPlatform.value);
    changeShutDownConfig(autoShutDownTime.value, enableAutoShutDownTime.value);
    changeAutoRefreshConfig(autoRefreshTime.value);
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
    json['danmakuSpeed'] = danmakuSpeed.value;
    json['danmakuFontSize'] = danmakuFontSize.value;
    json['danmakuFontBorder'] = danmakuFontBorder.value;
    json['danmakuOpacity'] = danmakuOpacity.value;
    json['doubleExit'] = doubleExit.value;
    json['videoPlayerIndex'] = videoPlayerIndex.value;
    json['enableCodec'] = enableCodec.value;
    json['bilibiliCookie'] = bilibiliCookie.value;
    json['shieldList'] = shieldList.map<String>((e) => e.toString()).toList();
    json['hotAreasList'] = hotAreasList.map<String>((e) => e.toString()).toList();

    json['mergeDanmuRating'] = mergeDanmuRating.value;
    json['themeColorSwitch'] = themeColorSwitch.value;
    json['webPort '] = webPort.value;
    json['webPortEnable'] = webPortEnable.value;
    return json;
  }

  defaultConfig() {
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
      "danmakuFontBorder": 0.5,
      "danmakuOpacity": 1.0,
      'doubleExit': true,
      "videoPlayerIndex": 0,
      'enableCodec': true,
      'bilibiliCookie': '',
      'shieldList': [],
      'mergeDanmuRating': 0.0,
      "hotAreasList": [],
      "webPortEnable": false,
      "webPort": "8008",
    };
    return json;
  }
}
