import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/player/player_consts.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:pure_live/common/consts/app_consts.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:pure_live/common/utils/hive_pref_util.dart';
import 'package:pure_live/common/services/bilibili_account_service.dart';

class SettingsService extends GetxController {
  // ========== 实例变量 ==========
  // 主题相关
  final themeModeName = (HivePrefUtil.getString('themeMode') ?? "System").obs;
  final themeColorSwitch = (HivePrefUtil.getString('themeColorSwitch') ?? Colors.red.hex).obs;
  final enableDynamicTheme = (HivePrefUtil.getBool('enableDynamicTheme') ?? false).obs;
  final Map<ColorSwatch<Object>, String> colorsNameMap = AppConsts.themeColors.map(
    (key, value) => MapEntry(ColorTools.createPrimarySwatch(value), key),
  );

  // 语言相关
  final languageName = (HivePrefUtil.getString('language') ?? "简体中文").obs;

  // 定时器相关
  final StopWatchTimer _stopWatchTimer = StopWatchTimer(mode: StopWatchMode.countDown);
  final autoRefreshTime = (HivePrefUtil.getInt('autoRefreshTime') ?? 3).obs;
  final autoShutDownTime = (HivePrefUtil.getInt('autoShutDownTime') ?? 120).obs;
  final enableAutoShutDownTime = (HivePrefUtil.getBool('enableAutoShutDownTime') ?? false).obs;

  // 界面与交互相关
  final enableDenseFavorites = (HivePrefUtil.getBool('enableDenseFavorites') ?? false).obs;
  final enableBackgroundPlay = (HivePrefUtil.getBool('enableBackgroundPlay') ?? false).obs;
  final enableScreenKeepOn = (HivePrefUtil.getBool('enableScreenKeepOn') ?? true).obs;
  final enableAutoCheckUpdate = (HivePrefUtil.getBool('enableAutoCheckUpdate') ?? true).obs;
  final enableFullScreenDefault = (HivePrefUtil.getBool('enableFullScreenDefault') ?? false).obs;

  final isFirstInApp = (HivePrefUtil.getBool('isFirstInApp') ?? true).obs;

  // 播放器相关
  final videoFitIndex = (HivePrefUtil.getInt('videoFitIndex') ?? 0).obs;
  final videoPlayerIndex = (HivePrefUtil.getInt('videoPlayerIndex') ?? 0).obs;
  final enableCodec = (HivePrefUtil.getBool('enableCodec') ?? true).obs;
  final audioDelay = (HivePrefUtil.getDouble('audioDelay') ?? 0.0).obs;
  final playerCompatMode = (HivePrefUtil.getBool('playerCompatMode') ?? false).obs;
  final preferResolution = (HivePrefUtil.getString('preferResolution') ?? PlayerConsts.resolutions[0]).obs;
  final preferPlatform = (HivePrefUtil.getString('preferPlatform') ?? AppConsts.platforms[0]).obs;
  final volume = (HivePrefUtil.getDouble('volume') ?? 0.5).obs; // 补充原代码可能遗漏的变量
  final customPlayerOutput = (HivePrefUtil.getBool('customPlayerOutput') ?? false).obs; // 补充
  final videoOutputDriver = (HivePrefUtil.getString('videoOutputDriver') ?? "gpu").obs; // 补充
  final audioOutputDriver = (HivePrefUtil.getString('audioOutputDriver') ?? "auto").obs; // 补充
  final videoHardwareDecoder = (HivePrefUtil.getString('videoHardwareDecoder') ?? "auto").obs; // 补充

  // 弹幕相关
  final hideDanmaku = (HivePrefUtil.getBool('hideDanmaku') ?? false).obs;
  final danmakuArea = (HivePrefUtil.getDouble('danmakuArea') ?? 1.0).obs;
  final danmakuTopArea = (HivePrefUtil.getDouble('danmakuTopArea') ?? 0.0).obs;
  final danmakuBottomArea = (HivePrefUtil.getDouble('danmakuBottomArea') ?? 0.5).obs;
  final danmakuSpeed = (HivePrefUtil.getDouble('danmakuSpeed') ?? 8.0).obs;
  final danmakuFontSize = (HivePrefUtil.getDouble('danmakuFontSize') ?? 16.0).obs;
  final danmakuFontBorder = (HivePrefUtil.getDouble('danmakuFontBorder') ?? 4.0).obs;
  final danmakuOpacity = (HivePrefUtil.getDouble('danmakuOpacity') ?? 1.0).obs;

  // 账号与Cookie相关
  final bilibiliCookie = (HivePrefUtil.getString('bilibiliCookie') ?? '').obs;
  final huyaCookie = (HivePrefUtil.getString('huyaCookie') ?? '').obs;
  final douyinCookie = (HivePrefUtil.getString('douyinCookie') ?? '').obs;
  final dontAskExit = (HivePrefUtil.getBool('dontAskExit') ?? false).obs; // 补充
  final exitChoose = (HivePrefUtil.getString('exitChoose') ?? '').obs; // 补充

  // 过滤与区域相关
  final shieldList = ((HivePrefUtil.getStringList('shieldList') ?? [])).obs;
  final hotAreasList = ((HivePrefUtil.getStringList('hotAreasList') ?? AppConsts.supportSites)).obs;

  // 收藏与历史相关
  final favoriteRooms =
      ((HivePrefUtil.getStringList('favoriteRooms') ?? []).map((e) => LiveRoom.fromJson(jsonDecode(e))).toList()).obs;
  final historyRooms =
      ((HivePrefUtil.getStringList('historyRooms') ?? []).map((e) => LiveRoom.fromJson(jsonDecode(e))).toList()).obs;
  final favoriteAreas =
      ((HivePrefUtil.getStringList('favoriteAreas') ?? []).map((e) => LiveArea.fromJson(jsonDecode(e))).toList()).obs;

  // 播放列表相关
  final currentPlayList = [].obs;
  final currentPlayListNodeIndex = 0.obs;

  // 图片与界面定制相关
  final currentBoxImage = (HivePrefUtil.getString('currentBoxImage') ?? "").obs;
  final currentBoxImageIndex = (HivePrefUtil.getInt('currentBoxImageIndex') ?? 0).obs;
  Uint8List? _cachedBytes;
  String? _cachedBase64;

  // Web与网络相关
  final webPort = (HivePrefUtil.getString('webPort') ?? "9527").obs;
  final webPortEnable = false.obs;
  final httpErrorMsg = ''.obs;

  // 焦点节点相关
  final AppFocusNode preferResolutionNode = AppFocusNode();
  final AppFocusNode videoPlayerNode = AppFocusNode();
  final AppFocusNode enableCodecNode = AppFocusNode();
  final AppFocusNode audioDelayNode = AppFocusNode();
  final AppFocusNode playerCompatModeNode = AppFocusNode();
  final AppFocusNode preferPlatformNode = AppFocusNode();
  final AppFocusNode dataSyncNode = AppFocusNode();
  final AppFocusNode accountNode = AppFocusNode();
  final AppFocusNode platformNode = AppFocusNode();
  final AppFocusNode currentImageNode = AppFocusNode();
  final AppFocusNode currentImageIndexNode = AppFocusNode();

  // 路由相关
  final routeChangeType = RouteChangeType.push.obs;
  final currentRouteName = ''.obs;

  // 备份与存储相关
  final backupDirectory = (HivePrefUtil.getString('backupDirectory') ?? '').obs;
  final m3uDirectory = (HivePrefUtil.getString('m3uDirectory') ?? 'm3uDirectory').obs;

  // ========== Getter 方法 ==========
  ThemeMode get themeMode => AppConsts.themeModes[themeModeName.value]!;
  Locale get language => AppConsts.languages[languageName.value]!;
  StopWatchTimer get stopWatchTimer => _stopWatchTimer;
  List<String> get resolutionsList => PlayerConsts.resolutions;
  List<BoxFit> get videofitArrary => PlayerConsts.videofitList;
  List<String> get playerlist => PlayerConsts.players;
  MemoryImage? get cachedBackgroundImage {
    if (currentBoxImage.isEmpty) return null;
    if (_cachedBase64 != currentBoxImage.value) {
      _cachedBase64 = currentBoxImage.value;
      _cachedBytes = base64Decode(currentBoxImage.value);
    }
    return _cachedBytes != null ? MemoryImage(_cachedBytes!) : null;
  }

  // ========== 数据迁移方法 ==========
  Future<void> migrateOldPrefsData() async {
    if (HivePrefUtil.getBool('_migrated_from_sp') == true) {
      return;
    }
    try {
      final allKeys = PrefUtil.prefs.getKeys();
      for (final key in allKeys) {
        final value = PrefUtil.prefs.get(key);
        if (value == null) continue;
        if (value is String) {
          await HivePrefUtil.setString(key, value);
        } else if (value is int) {
          await HivePrefUtil.setInt(key, value);
        } else if (value is bool) {
          await HivePrefUtil.setBool(key, value);
        } else if (value is double) {
          await HivePrefUtil.setDouble(key, value);
        } else if (value is List<String>) {
          await HivePrefUtil.setStringList(key, value);
        }
      }

      await HivePrefUtil.setBool('_migrated_from_sp', true);
      log('旧 SharedPreferences 数据迁移到 Hive 完成！', name: 'SettingsService');
    } catch (e) {
      log('数据迁移失败: $e', name: 'SettingsService');
    }
  }

  // ========== 初始化生命周期方法 ==========
  @override
  void onInit() {
    super.onInit();

    // 执行旧数据迁移
    migrateOldPrefsData().then((_) {
      update(['migrate_complete']);
    });

    // 初始化变量监听
    _initVariableListeners();
  }

  /// 初始化变量监听（异步写入 Hive）
  void _initVariableListeners() {
    enableDynamicTheme.listen((bool value) async {
      await HivePrefUtil.setBool('enableDynamicTheme', value);
      update(['myapp']);
    });

    themeColorSwitch.listen((value) async {
      await HivePrefUtil.setString('themeColorSwitch', value);
    });

    enableDenseFavorites.listen((value) async {
      await HivePrefUtil.setBool('enableDenseFavorites', value);
    });

    shieldList.listen((value) async {
      await HivePrefUtil.setStringList('shieldList', value);
    });

    hotAreasList.listen((value) async {
      await HivePrefUtil.setStringList('hotAreasList', value);
    });

    favoriteRooms.listen((rooms) async {
      await HivePrefUtil.setStringList(
        'favoriteRooms',
        favoriteRooms.map<String>((e) => jsonEncode(e.toJson())).toList(),
      );
    });

    favoriteAreas.listen((rooms) async {
      await HivePrefUtil.setStringList(
        'favoriteAreas',
        favoriteAreas.map<String>((e) => jsonEncode(e.toJson())).toList(),
      );
    });

    historyRooms.listen((rooms) async {
      await HivePrefUtil.setStringList(
        'historyRooms',
        historyRooms.map<String>((e) => jsonEncode(e.toJson())).toList(),
      );
    });

    videoFitIndex.listen((value) async {
      await HivePrefUtil.setInt('videoFitIndex', value);
    });

    hideDanmaku.listen((value) async {
      await HivePrefUtil.setBool('hideDanmaku', value);
    });

    danmakuArea.listen((value) async {
      await HivePrefUtil.setDouble('danmakuArea', value);
    });

    danmakuTopArea.listen((value) async {
      await HivePrefUtil.setDouble('danmakuTopArea', value);
    });

    danmakuBottomArea.listen((value) async {
      await HivePrefUtil.setDouble('danmakuBottomArea', value);
    });

    danmakuSpeed.listen((value) async {
      await HivePrefUtil.setDouble('danmakuSpeed', value);
    });

    danmakuFontSize.listen((value) async {
      await HivePrefUtil.setDouble('danmakuFontSize', value);
    });

    danmakuFontBorder.listen((value) async {
      await HivePrefUtil.setDouble('danmakuFontBorder', value);
    });

    danmakuOpacity.listen((value) async {
      await HivePrefUtil.setDouble('danmakuOpacity', value);
    });

    enableCodec.listen((value) async {
      await HivePrefUtil.setBool('enableCodec', value);
    });

    audioDelay.listen((value) async {
      await HivePrefUtil.setDouble('audioDelay', value);
    });

    videoPlayerIndex.listen((value) async {
      await HivePrefUtil.setInt('videoPlayerIndex', value);
    });

    bilibiliCookie.listen((value) async {
      await HivePrefUtil.setString('bilibiliCookie', value);
    });

    huyaCookie.listen((value) async {
      await HivePrefUtil.setString('huyaCookie', value);
    });

    douyinCookie.listen((value) async {
      await HivePrefUtil.setString('douyinCookie', value);
    });

    webPort.listen((value) async {
      await HivePrefUtil.setString('webPort', value);
    });

    isFirstInApp.listen((value) async {
      await HivePrefUtil.setBool('isFirstInApp', false);
    });

    currentBoxImage.listen((value) async {
      await HivePrefUtil.setString('currentBoxImage', value);
    });

    currentBoxImageIndex.listen((value) async {
      await HivePrefUtil.setInt('currentBoxImageIndex', value);
    });

    playerCompatMode.listen((value) async {
      await HivePrefUtil.setBool('playerCompatMode', value);
    });

    preferResolution.listen((value) async {
      await HivePrefUtil.setString('preferResolution', value);
    });

    preferPlatform.listen((value) async {
      await HivePrefUtil.setString('preferPlatform', value);
    });
  }

  // ========== 配置修改方法 ==========
  void changeThemeMode(String mode) async {
    themeModeName.value = mode;
    await HivePrefUtil.setString('themeMode', mode);
    Get.changeThemeMode(themeMode);
  }

  void changeLanguage(String value) async {
    languageName.value = value;
    await HivePrefUtil.setString('language', value);
    Get.updateLocale(language);
  }

  void changePlayer(int value) async {
    videoPlayerIndex.value = value;
    await HivePrefUtil.setInt('videoPlayerIndex', value);
  }

  void changePreferResolution(String name) async {
    if (PlayerConsts.resolutions.indexWhere((e) => e == name) != -1) {
      preferResolution.value = name;
      await HivePrefUtil.setString('preferResolution', name);
    }
  }

  void changeAutoRefreshConfig(int minutes) async {
    autoRefreshTime.value = minutes;
    await HivePrefUtil.setInt('autoRefreshTime', minutes);
  }

  void changePreferPlatform(String name) async {
    if (AppConsts.platforms.indexWhere((e) => e == name) != -1) {
      preferPlatform.value = name;
      update(['myapp']);
      await HivePrefUtil.setString('preferPlatform', name);
    }
  }

  // ========== 图片相关方法 ==========
  Future<void> getImage() async {
    var url = AppConsts.currentBoxImageSources.map((e) => e.values.first).toList()[currentBoxImageIndex.value];
    if (url == "default") {
      currentBoxImage.value = "";
    } else if (url == "https://t.alcy.cc/") {
      var category = ['ycy', 'moez', 'ai', 'ysz', 'ys', 'mp', 'moemp', 'ysmp', 'aimp', 'tx', 'lai', 'xhl', 'bd'];
      var index = math.Random().nextInt(category.length);
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
    var keys = AppConsts.currentBoxImageSources.map((e) => e.keys.first).toList();
    Map<dynamic, String> map = {};
    for (var i = 0; i < keys.length; i++) {
      map[keys[i]] = keys[i];
    }
    return map;
  }

  // ========== 收藏与历史相关业务方法 ==========
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
    if (historyRooms.length > 50) {
      historyRooms.removeRange(0, historyRooms.length - 50);
    }
    historyRooms.insert(0, room);
  }

  // ========== 分区收藏相关业务方法 ==========
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

  // ========== 备份与恢复相关方法 ==========
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
      log(e.toString(), name: 'recover');
      return false;
    }
    return true;
  }

  // ========== Bilibili账号相关方法 ==========
  void setBilibiliCookit(String cookie) {
    final BiliBiliAccountService biliAccountService = Get.find<BiliBiliAccountService>();
    if (biliAccountService.cookie.isEmpty || biliAccountService.uid == 0) {
      biliAccountService.resetCookie(cookie);
      biliAccountService.loadUserInfo();
    }
  }

  // ========== JSON序列化/反序列化 ==========
  void fromJson(Map<String, dynamic> json) async {
    // 1. 定義內部輔助解析函數，處理兼容性邏輯
    List<T> safeParseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJsonFactory) {
      if (data == null || data is! List) return [];
      return data.map<T>((e) {
        if (e is Map<String, dynamic>) {
          return fromJsonFactory(e);
        } else if (e is String) {
          try {
            return fromJsonFactory(jsonDecode(e));
          } catch (err) {
            debugPrint("解析單項數據失敗: $err");
          }
        }
        return fromJsonFactory({}); // 備選方案
      }).toList();
    }

    // 2. 解析列表數據 (自動處理 String/Map 兼容)
    favoriteRooms.value = safeParseList<LiveRoom>(json['favoriteRooms'], (m) => LiveRoom.fromJson(m));
    favoriteAreas.value = safeParseList<LiveArea>(json['favoriteAreas'], (m) => LiveArea.fromJson(m));
    // 3. 解析普通列表與基本類型
    shieldList.value = (json['shieldList'] as List?)?.map((e) => e.toString()).toList() ?? [];
    hotAreasList.value = (json['hotAreasList'] as List?)?.map((e) => e.toString()).toList() ?? [];
    themeModeName.value = AppConsts.themeModes.keys.firstWhere((e) => e == json['themeMode'], orElse: () => "System");
    enableDynamicTheme.value = json['enableDynamicTheme'] ?? false;
    enableDenseFavorites.value = json['enableDenseFavorites'] ?? false;
    languageName.value = AppConsts.languages.keys.firstWhere((e) => e == json['languageName'], orElse: () => "简体中文");
    preferResolution.value = PlayerConsts.resolutions.firstWhere(
      (e) => e == json['preferResolution'],
      orElse: () => PlayerConsts.resolutions[0],
    );
    preferPlatform.value = AppConsts.platforms.firstWhere(
      (e) => e == json['preferPlatform'],
      orElse: () => AppConsts.platforms[0],
    );
    bilibiliCookie.value = json['bilibiliCookie'] ?? '';
    huyaCookie.value = json['huyaCookie'] ?? '';
    douyinCookie.value = json['douyinCookie'] ?? '';
    themeColorSwitch.value = json['themeColorSwitch'] ?? Colors.blue.hex;
    webPort.value = json['webPort'] ?? '9527';

    // 4. 恢復備份時同步到 Hive
    // 使用 Future.wait 並行執行所有異步操作，效率更高
    await Future.wait([
      HivePrefUtil.setString('themeMode', themeModeName.value),
      HivePrefUtil.setBool('enableDynamicTheme', enableDynamicTheme.value),
      HivePrefUtil.setBool('enableDenseFavorites', enableDenseFavorites.value),
      HivePrefUtil.setString('language', languageName.value),
      HivePrefUtil.setString('preferResolution', preferResolution.value),
      HivePrefUtil.setString('preferPlatform', preferPlatform.value),
      HivePrefUtil.setString('bilibiliCookie', bilibiliCookie.value),
      HivePrefUtil.setString('huyaCookie', huyaCookie.value),
      HivePrefUtil.setString('douyinCookie', douyinCookie.value),
      HivePrefUtil.setString('themeColorSwitch', themeColorSwitch.value),
      HivePrefUtil.setString('webPort', webPort.value),
      // 注意：確保傳入的是 List<String> 類型
      HivePrefUtil.setStringList('shieldList', shieldList.value),
      HivePrefUtil.setStringList('hotAreasList', hotAreasList.value),
      // 保存至 Hive 時，維持 StringList 格式以確保底層兼容性
      HivePrefUtil.setStringList('favoriteRooms', favoriteRooms.value.map((e) => jsonEncode(e.toJson())).toList()),
      HivePrefUtil.setStringList('favoriteAreas', favoriteAreas.value.map((e) => jsonEncode(e.toJson())).toList()),
    ]);
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
    json['danmakuArea'] = 1.0;
    json['danmakuTopArea'] = danmakuTopArea.value;
    json['danmakuBottomArea'] = danmakuBottomArea.value;
    json['danmakuSpeed'] = danmakuSpeed.value;
    json['danmakuFontSize'] = danmakuFontSize.value;
    json['danmakuFontBorder'] = danmakuFontBorder.value;
    json['danmakuOpacity'] = danmakuOpacity.value;
    json['videoPlayerIndex'] = videoPlayerIndex.value;
    json['enableCodec'] = enableCodec.value;
    json['audioDelay'] = audioDelay.value;
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

  // ========== 生命周期结束方法 ==========
  @override
  void onClose() {
    _stopWatchTimer.dispose();
    super.onClose();
  }
}
