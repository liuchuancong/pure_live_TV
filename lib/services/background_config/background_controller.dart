import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path_util;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/widgets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/app/bootstrap/app_path_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/services/background_config/background_config_model.dart';
import 'package:pure_live/services/background_config/background_video_sources.dart';
import 'package:pure_live/services/background_config/background_image_sources.dart';
part 'background_controller.g.dart';

@riverpod
class BackgroundController extends _$BackgroundController {
  late final Player _videoPlayer;
  late final VideoController videoController;
  static BackgroundController get to => SettingsService.to.bg;
  final _configStream = BehaviorSubject<BackgroundConfigModel>();
  Stream<BackgroundConfigModel> get configChanges => _configStream.stream;

  String? _cachedBase64;
  Uint8List? _cachedBytes;

  @override
  BackgroundConfigModel build() {
    _videoPlayer = Player();
    videoController = VideoController(_videoPlayer);
    _videoPlayer.setVolume(0.0);
    _videoPlayer.setPlaylistMode(PlaylistMode.loop);

    ref.onDispose(() {
      _autoSwitchTimer?.cancel();
      _autoSwitchTimer = null;
      _videoPlayer.dispose();
      _configStream.close();
    });

    final model = BackgroundConfigModel(
      source: bgSourceFromString(HivePrefUtil.getString('bgSource') ?? 'none'),
      boxFit: BoxFit.values.firstWhere(
        (e) => e.name == (HivePrefUtil.getString('bgBoxFit') ?? 'cover'),
        orElse: () => BoxFit.cover,
      ),
      maskOpacity: HivePrefUtil.getDouble('bgMaskOpacity') ?? 0.35,
      blur: HivePrefUtil.getDouble('bgBlur') ?? 0.0,
      autoSwitch: HivePrefUtil.getBool('bgAutoSwitch') ?? false,
      autoSwitchIntervalHours: HivePrefUtil.getInt('bgAutoSwitchIntervalHours') ?? 6,
      solidColor: HexColor(HivePrefUtil.getString('bgSolidColorHex') ?? '141e30'),
      gradientColors: (HivePrefUtil.getString('bgGradientColors') ?? "141e30,243b55,141e30")
          .split(",")
          .map((s) => HexColor(s))
          .toList(),
      assetImagePath: HivePrefUtil.getString('bgAssetImagePath'),
      localImagePath: HivePrefUtil.getString('bgLocalImagePath'),
      networkImageUrl: HivePrefUtil.getString('bgNetworkImageUrl'),
      currentBoxImageBase64: HivePrefUtil.getString('bgCurrentBoxImageBase64') ?? "",
      assetVideoPath: HivePrefUtil.getString('bgAssetVideoPath'),
      localVideoPath: HivePrefUtil.getString('bgLocalVideoPath'),
      networkVideoUrl: HivePrefUtil.getString('bgNetworkVideoUrl'),
      currentImageUrl: HivePrefUtil.getString('bgCurrentImageUrl') ?? '',
      lastSwitchAt: _readLastSwitchAt(),
      recentImageUrls: HivePrefUtil.getStringList('bgRecentImageUrls') ?? const <String>[],
      customImageUrl: HivePrefUtil.getString('bgCustomImageUrl') ?? '',
      customVideoUrl: HivePrefUtil.getString('bgCustomVideoUrl') ?? '',
      networkVideoCover: HivePrefUtil.getString('bgNetworkVideoCover'),
      videoSourceIndex: BackgroundVideoSources.clampIndex(HivePrefUtil.getInt('bgVideoSourceIndex') ?? 0),
      videoTagIndex: BackgroundVideoSources.clampTagIndex(0, HivePrefUtil.getInt('bgVideoTagIndex') ?? 0),
      customVideoApiUrl: HivePrefUtil.getString('bgCustomVideoApiUrl') ?? '',
    );

    _configStream.add(model);
    _armAutoSwitch(model);
    return model;
  }

  /// 上次换壁纸时间（持久化的毫秒时间戳，读到脏数据就当没存过）。
  static DateTime? _readLastSwitchAt() {
    final millis = HivePrefUtil.getInt('bgLastSwitchAt');
    if (millis == null || millis <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  BackgroundConfigModel _updateState(BackgroundConfigModel newModel) {
    state = newModel;
    _configStream.add(newModel); // 同步更新流

    HivePrefUtil.setString('bgSource', bgSourceToString(newModel.source));
    HivePrefUtil.setString('bgBoxFit', newModel.boxFit.name);
    HivePrefUtil.setDouble('bgMaskOpacity', newModel.maskOpacity);
    HivePrefUtil.setDouble('bgBlur', newModel.blur);
    HivePrefUtil.setBool('bgAutoSwitch', newModel.autoSwitch);
    HivePrefUtil.setInt('bgAutoSwitchIntervalHours', newModel.autoSwitchIntervalHours);
    HivePrefUtil.setString('bgSolidColorHex', newModel.solidColor.toHex());
    HivePrefUtil.setString('bgGradientColors', newModel.gradientColors.map((c) => c.toHex()).join(","));
    HivePrefUtil.setString('bgAssetImagePath', newModel.assetImagePath ?? "");
    HivePrefUtil.setString('bgLocalImagePath', newModel.localImagePath ?? "");
    HivePrefUtil.setString('bgNetworkImageUrl', newModel.networkImageUrl ?? "");
    HivePrefUtil.setString('bgCurrentBoxImageBase64', newModel.currentBoxImageBase64);
    HivePrefUtil.setString('bgAssetVideoPath', newModel.assetVideoPath ?? "");
    HivePrefUtil.setString('bgLocalVideoPath', newModel.localVideoPath ?? "");
    HivePrefUtil.setString('bgNetworkVideoUrl', newModel.networkVideoUrl ?? "");
    HivePrefUtil.setString('bgCurrentImageUrl', newModel.currentImageUrl);
    HivePrefUtil.setInt('bgLastSwitchAt', newModel.lastSwitchAt?.millisecondsSinceEpoch ?? 0);
    HivePrefUtil.setStringList('bgRecentImageUrls', newModel.recentImageUrls);
    HivePrefUtil.setString('bgCustomImageUrl', newModel.customImageUrl);
    HivePrefUtil.setString('bgCustomVideoUrl', newModel.customVideoUrl);
    HivePrefUtil.setString('bgNetworkVideoCover', newModel.networkVideoCover ?? '');
    HivePrefUtil.setInt('bgVideoSourceIndex', newModel.videoSourceIndex);
    HivePrefUtil.setInt('bgVideoTagIndex', newModel.videoTagIndex);
    HivePrefUtil.setString('bgCustomVideoApiUrl', newModel.customVideoApiUrl);
    _armAutoSwitch(newModel);
    return newModel;
  }

  MemoryImage? get cachedBackgroundImage {    final base64Str = state.currentBoxImageBase64;
    if (base64Str.isEmpty) return null;

    if (_cachedBase64 != base64Str) {
      _cachedBase64 = base64Str;
      _cachedBytes = base64Decode(_cachedBase64!);
    }
    return MemoryImage(_cachedBytes!);
  }

  Future<void> reloadBackgroundVideo() async {
    final src = switch (state.source) {
      BackgroundSource.assetVideo => state.assetVideoPath,
      BackgroundSource.localVideo => state.localVideoPath,
      BackgroundSource.networkVideo => state.networkVideoUrl,
      _ => null,
    };
    if (src != null && src.isNotEmpty) {
      await _videoPlayer.open(Media(src), play: true);
    } else {
      await _videoPlayer.stop();
    }
  }

  /// 当前配置快照。
  ///
  /// 对外暴露只读视图而不是直接用 `state`：`state` 是 Riverpod 的受保护成员，
  /// 非 Notifier 子类（设置界面）读它会触发 lint。
  BackgroundConfigModel get config => state;

  void setNone() => _updateState(state.copyWith(source: BackgroundSource.none));
  void setSolid(Color c) => _updateState(state.copyWith(source: BackgroundSource.color, solidColor: c));
  void setGradient(List<Color> colors) =>
      _updateState(state.copyWith(source: BackgroundSource.gradient, gradientColors: colors));
  void setBoxFit(BoxFit fit) => _updateState(state.copyWith(boxFit: fit));
  void setMaskOpacity(double opacity) => _updateState(state.copyWith(maskOpacity: opacity));
  void setAssetImage(String path) => _updateState(
    state.copyWith(source: BackgroundSource.assetImage, assetImagePath: path, localImagePath: "", networkImageUrl: ""),
  );
  void setLocalImage(String path) => _updateState(
    state.copyWith(source: BackgroundSource.localImage, localImagePath: path, assetImagePath: "", networkImageUrl: ""),
  );
  void setNetworkImage(String url) => _updateState(
    state.copyWith(source: BackgroundSource.networkImage, networkImageUrl: url, assetImagePath: "", localImagePath: ""),
  );
  void setCurrentBoxImage(String base64Str) => _updateState(state.copyWith(currentBoxImageBase64: base64Str));

  // ------------------------------------------------------------------
  // 随机壁纸
  // ------------------------------------------------------------------

  /// 随机壁纸图源下标。
  ///
  /// 单独存 pref 而不是加进 [BackgroundConfigModel]：那是个 freezed 模型，
  /// 加字段要跑 build_runner，而这里并不需要它进入备份/同步载荷。
  static const String _boxImageSourceKey = 'bgBoxImageSourceIndex';

  int get boxImageSourceIndex => BackgroundImageSources.clampIndex(HivePrefUtil.getInt(_boxImageSourceKey) ?? 0);

  Future<void> setBoxImageSourceIndex(int index) async {
    await HivePrefUtil.setInt(_boxImageSourceKey, BackgroundImageSources.clampIndex(index));
  }

  /// 拉取一张随机壁纸并写入背景，返回 false 表示这次没取到图。
  ///
  /// 移植自老项目 `SettingsService.getImage()`：
  /// - 无铭系接口要带 `type=json&apiKey=`，先拿 JSON 里的直链再下载图片；
  /// - 栗次元要随机拼一个分类路径；
  /// - 必应每日走官方接口，返回的相对路径由 [BackgroundImageSources.normalizeImageUrl] 补全；
  /// - 其余接口本身就是图片地址。
  ///
  /// 最后统一转 base64 存进 [BackgroundConfigModel.currentBoxImageBase64]，
  /// 因为 `TvScaffold` 的图片背景只消费这一个字段（asset/local/network 三个
  /// source 都走它）；同时记下直链和切换时间，供下载与「上一次换壁纸时间」使用。
  Future<bool> getRandomImage({int? sourceIndex}) async {
    final index = BackgroundImageSources.clampIndex(sourceIndex ?? boxImageSourceIndex);
    if (sourceIndex != null) await setBoxImageSourceIndex(index);

    final source = BackgroundImageSources.at(index);
    if (source.url == BackgroundImageSources.noneUrl) {
      setCurrentBoxImage('');
      return true;
    }

    final dio = Dio();
    try {
      final resolved = await _resolveImageUrl(dio, source);
      if (resolved == null || resolved.isEmpty) return false;
      final imageUrl = BackgroundImageSources.normalizeImageUrl(resolved);

      final imageResponse = await dio.get<List<int>>(
        imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: <String, String>{'User-Agent': _wallpaperUserAgent},
        ),
      );
      final bytes = imageResponse.data;
      if (bytes == null || bytes.length < 30) return false;

      // 先切到图片背景，再写入 base64，避免中途出现空白背景。
      setNetworkImage(imageUrl);
      setCurrentBoxImage(base64Encode(bytes));
      _rememberWallpaper(imageUrl);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 记下刚换上的在线壁纸：直链、切换时间、最近的几张。
  ///
  /// 与 base64 分两次写入是有意的：base64 决定画面，这三个字段决定
  /// 「自动换壁纸的下一次到期时间」和「能不能翻回上一张」，
  /// 即使写 base64 的过程被打断，时间戳也不会停在旧值上导致错过整轮。
  void _rememberWallpaper(String imageUrl) {
    final recent = <String>[imageUrl, ...state.recentImageUrls.where((url) => url != imageUrl)];
    final trimmed = recent.take(_maxRecentImages).toList(growable: false);
    _updateState(
      state.copyWith(
        currentImageUrl: imageUrl,
        lastSwitchAt: DateTime.now(),
        recentImageUrls: trimmed,
      ),
    );
  }

  /// 最多记住多少张历史壁纸（够「上一张」用，又不至于把偏好撑大）。
  static const int _maxRecentImages = 5;

  /// 把图源解析成图片直链。
  ///
  /// - 栗次元：随机拼一个分类路径；
  /// - 无铭系：要带 `type=json&apiKey=`，JSON 里才是直链；
  /// - 必应每日 / Wallhaven：JSON 接口，从响应里挑直链；
  /// - 其余：URL 本身就是图片地址。
  Future<String?> _resolveImageUrl(Dio dio, ({String name, String url}) source) async {
    if (source.url.contains(_alcyHost)) {
      final category = _alcyCategories[math.Random().nextInt(_alcyCategories.length)];
      return '${source.url}$category';
    }

    final isWuming = source.url.contains('://jkapi.com');
    if (!isWuming && !BackgroundImageSources.jsonApiNames.contains(source.name)) {
      return source.url;
    }

    var requestUrl = source.url;
    if (isWuming) {
      final apiKey = BackgroundImageSources.wumingApiKeys[source.name];
      if (apiKey == null) return null;
      final separator = source.url.contains('?') ? '&' : '?';
      requestUrl = '${source.url}${separator}type=json&apiKey=$apiKey';
    }

    final response = await dio.get<dynamic>(requestUrl);
    return BackgroundImageSources.pickImageUrlFromJson(response.data);
  }

  static const String _alcyHost = 'alcy.cc';
  static const List<String> _alcyCategories = <String>[
    'ycy', 'moez', 'ai', 'ysz', 'ys', 'mp', 'moemp', 'ysmp', 'aimp', 'tx', 'lai', 'xhl', 'bd',
  ];

  static const String _wallpaperUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/116.0.5845.97 Safari/537.36';

  // ------------------------------------------------------------------
  // 模糊度 / 自动换壁纸
  // ------------------------------------------------------------------

  Timer? _autoSwitchTimer;

  void setBlur(double value) => _updateState(state.copyWith(blur: value.clamp(0.0, 30.0)));

  void setAutoSwitch(bool value) => _updateState(state.copyWith(autoSwitch: value));

  void setAutoSwitchIntervalHours(int hours) =>
      _updateState(state.copyWith(autoSwitchIntervalHours: hours.clamp(1, 24)));

  /// 按「自动换壁纸」设置装/卸定时器。
  ///
  /// 只对「在线壁纸」生效：本机图片和视频是单份文件，没有可轮换的对象，
  /// 定时器空转没有意义，所以直接不装。
  ///
  /// ⚠️ 这是**页面内**的兜底：用户停在壁纸设置页时由它按时换图，界面立刻有反馈。
  /// 真正的长期轮换交给后台任务调度器（`BackgroundTaskKind.wallpaperRotate`），
  /// 因为 Riverpod provider 会随页面销毁而 dispose，定时器也跟着没了 —— 只靠这个
  /// 定时器，「自动换壁纸」其实只在设置页打开时生效。
  void _armAutoSwitch(BackgroundConfigModel model) {
    _autoSwitchTimer?.cancel();
    _autoSwitchTimer = null;
    if (!model.autoSwitch) return;
    if (model.source != BackgroundSource.networkImage) return;

    final hours = model.autoSwitchIntervalHours.clamp(1, 24);
    _autoSwitchTimer = Timer.periodic(Duration(hours: hours), (_) {
      unawaited(getRandomImage());
    });
  }

  // ------------------------------------------------------------------
  // 后台轮换（由 BackgroundTaskService 调用）
  // ------------------------------------------------------------------

  /// 是否还该换下一张：开关打开 + 在线 Image 源 + 已超过间隔。
  ///
  /// 时间基准是持久化的 [BackgroundConfigModel.lastSwitchAt]，所以应用重启、
  /// 长时间熄屏之后仍然算得对 —— 只靠 `Timer` 的话这段时间是被吞掉的。
  bool shouldRotateWallpaper({DateTime? now}) {
    if (!state.autoSwitch) return false;
    if (state.source != BackgroundSource.networkImage) return false;

    final last = state.lastSwitchAt;
    if (last == null) return true;

    final current = now ?? DateTime.now();
    if (current.isBefore(last)) return true; // 系统时间被往回调过，按到期处理。
    return current.difference(last) >= Duration(hours: state.autoSwitchIntervalHours.clamp(1, 24));
  }

  /// 到点则换一张，返回是否成功。
  ///
  /// 没到点直接返回 true（无事可做不算失败），避免后台任务把它记成失败并退避。
  Future<bool> rotateWallpaperIfNeeded({DateTime? now}) async {
    if (!shouldRotateWallpaper(now: now)) return true;
    return getRandomImage();
  }

  /// 当前壁纸的原始字节（在线壁纸直接读缓存字段，不重新下载）。
  Uint8List? get currentImageBytes {
    final base64Str = state.currentBoxImageBase64;
    if (base64Str.isEmpty) return null;
    if (_cachedBase64 != base64Str) {
      _cachedBase64 = base64Str;
      _cachedBytes = base64Decode(base64Str);
    }
    return _cachedBytes;
  }

  /// 把当前壁纸存到下载目录，返回落盘路径（失败返回 null）。
  ///
  /// 对应 iTab 的「下载壁纸」：在线壁纸本来就是一张网图，用户想留一份原图。
  /// 本机图片/视频也能导出，走的是同一份内存字节。
  Future<String?> saveCurrentWallpaper() async {
    final bytes = currentImageBytes;
    if (bytes == null || bytes.isEmpty) return null;

    try {
      final dir = await AppPathManager().downloadDir;
      final extension = _guessImageExtension(state.currentImageUrl);
      final name = 'wallpaper_${DateTime.now().millisecondsSinceEpoch}$extension';
      final file = File('${dir.path}${Platform.pathSeparator}$name');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  static String _guessImageExtension(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    final dot = path.lastIndexOf('.');
    if (dot < 0) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    const supported = <String>{'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'};
    return supported.contains(ext) ? ext : '.jpg';
  }

  /// 翻回上一张在线壁纸（历史里最新的那张换下来）。
  ///
  /// 只换 URL，不重新选图源；按 URL 重新下载，避免额外缓存一份字节。
  Future<bool> restorePreviousWallpaper() async {
    final current = state.currentImageUrl;
    final previous = state.recentImageUrls.where((url) => url != current).firstOrNull;
    if (previous == null || previous.isEmpty) return false;

    try {
      final response = await Dio().get<List<int>>(
        previous,
        options: Options(
          responseType: ResponseType.bytes,
          headers: <String, String>{'User-Agent': _wallpaperUserAgent},
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.length < 30) return false;

      setNetworkImage(previous);
      setCurrentBoxImage(base64Encode(bytes));
      _rememberWallpaper(previous);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------------
  // 自定义在线图片链接（iTab「使用在线图片链接」）
  // ------------------------------------------------------------------

  /// 下载并应用用户手填的图片直链。
  ///
  /// 与 [getRandomImage] 的区别：不经过图源表、不解析 JSON，用户给什么就拉什么。
  /// 拉取失败时保留用户输入（[BackgroundConfigModel.customImageUrl]），
  /// 输入框不用重敲。
  Future<bool> applyCustomImageUrl(String url) async {
    final target = url.trim();
    if (target.isEmpty) return false;

    setCustomImageUrl(target);
    final bytes = await _downloadBytes(target);
    if (bytes == null) return false;

    setNetworkImage(target);
    setCurrentBoxImage(base64Encode(bytes));
    _rememberWallpaper(target);
    return true;
  }

  void setCustomImageUrl(String url) => _updateState(state.copyWith(customImageUrl: url.trim()));

  /// 按地址下载图片字节；失败或内容过短返回 null（很多图床失败时返回 JSON/HTML）。
  Future<Uint8List?> _downloadBytes(String url) async {
    try {
      final response = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: <String, String>{'User-Agent': _wallpaperUserAgent},
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.length < 30) return null;
      return Uint8List.fromList(bytes);
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------------
  // 在线动态壁纸（iTab「视频」页签）
  // ------------------------------------------------------------------

  /// 从在线接口随机取一条动态壁纸并设为背景。
  ///
  /// 交互对齐 iTab 的视频页签：选图源 / 分类 → 取一条 → 立即播放 + 记下封面。
  /// 「自定义接口」走用户填的地址，其余走 [BackgroundVideoSources] 里的内置表。
  Future<bool> getRandomNetworkVideo({int? sourceIndex, int? tagIndex}) async {
    final index = BackgroundVideoSources.clampIndex(sourceIndex ?? state.videoSourceIndex);
    final tag = BackgroundVideoSources.clampTagIndex(index, tagIndex ?? state.videoTagIndex);
    final source = BackgroundVideoSources.at(index);

    // 「不使用」按清除处理：先记住用户的选择，再停掉当前视频。
    if (source.id == BackgroundVideoSources.noneId) {
      _updateState(state.copyWith(videoSourceIndex: index, videoTagIndex: tag));
      setNetworkVideo('');
      return true;
    }

    // 固定地址的图源（示例视频）直接播，不去请求接口。
    if (source.id == 'sample') {
      _updateState(
        state.copyWith(
          source: BackgroundSource.networkVideo,
          networkVideoUrl: source.url,
          networkVideoCover: null,
          videoSourceIndex: index,
          videoTagIndex: tag,
          assetVideoPath: '',
          localVideoPath: '',
          customVideoUrl: '',
          lastSwitchAt: DateTime.now(),
        ),
      );
      await reloadBackgroundVideo();
      return true;
    }

    // 后端会分页；同一次请求里带个随机页号，翻两条不同的是常态。
    final page = math.Random().nextInt(5) + 1;
    final requestUrl = source.id == BackgroundVideoSources.customId
        ? BackgroundVideoSources.buildCustomRequestUrl(
            state.customVideoApiUrl,
            page: page,
            tag: BackgroundVideoSources.tagId(index, tag),
            random: math.Random().nextInt(1 << 20),
          )
        : BackgroundVideoSources.buildRequestUrl(index, tag, page: page);
    if (requestUrl.isEmpty) return false;

    try {
      final body = await _requestVideoJson(requestUrl);
      if (body == null) return false;

      final videoUrl = BackgroundVideoSources.pickVideoUrl(body);
      if (videoUrl == null || videoUrl.isEmpty) return false;
      final cover = BackgroundVideoSources.pickCoverUrl(body);

      _updateState(
        state.copyWith(
          source: BackgroundSource.networkVideo,
          networkVideoUrl: videoUrl,
          networkVideoCover: cover ?? state.networkVideoCover,
          videoSourceIndex: index,
          videoTagIndex: tag,
          assetVideoPath: '',
          localVideoPath: '',
          // 从接口取到的地址不是「手填地址」，清掉以免界面误判来源。
          customVideoUrl: '',
          lastSwitchAt: DateTime.now(),
        ),
      );
      await reloadBackgroundVideo();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 请求并解析接口响应。
  ///
  /// 有的接口 Content-Type 是 `text/html` 但内容是 JSON（素颜就是），所以先按
  /// 文本取回来再自己 `jsonDecode`，并兼容「返回体被一层字符串包住」的情况。
  Future<dynamic> _requestVideoJson(String url) async {
    final response = await Dio().get<dynamic>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        headers: <String, String>{'User-Agent': _wallpaperUserAgent},
      ),
    );
    final data = response.data;
    if (data == null) return null;
    if (data is Map || data is List) return data;
    final text = data.toString().trim();
    if (text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  /// 探活用户填的自定义接口：能解析出视频地址才算可用，并把封面一起返回。
  ///
  /// 设置页的「测试接口」用它给即时反馈 —— 接口填错时用户不用等换壁纸失败才知道。
  Future<({bool ok, String message})> probeCustomVideoApi(String template) async {
    final url = BackgroundVideoSources.buildCustomRequestUrl(
      template,
      page: 1,
      tag: BackgroundVideoSources.tagId(state.videoSourceIndex, state.videoTagIndex),
      random: math.Random().nextInt(1 << 20),
    );
    if (url.isEmpty) return (ok: false, message: '请先填写接口地址');

    try {
      final body = await _requestVideoJson(url);
      if (body == null) return (ok: false, message: '响应不是有效的 JSON');
      final video = BackgroundVideoSources.pickVideoUrl(body);
      if (video == null) return (ok: false, message: '响应里没有找到 url / video 字段');
      final cover = BackgroundVideoSources.pickCoverUrl(body);
      return (ok: true, message: cover == null ? '可用（未检测到封面字段）' : '可用，已解析到视频与封面');
    } catch (error) {
      return (ok: false, message: '请求失败：$error');
    }
  }

  Future<void> setCustomVideoApiUrl(String url) async {
    _updateState(state.copyWith(customVideoApiUrl: url.trim()));
  }

  /// 应用用户手填的动态壁纸地址。
  Future<bool> applyCustomVideoUrl(String url) async {
    final target = url.trim();
    if (target.isEmpty) return false;

    _updateState(
      state.copyWith(
        source: BackgroundSource.networkVideo,
        networkVideoUrl: target,
        customVideoUrl: target,
        assetVideoPath: '',
        localVideoPath: '',
        networkVideoCover: null,
        lastSwitchAt: DateTime.now(),
      ),
    );
    await reloadBackgroundVideo();
    return true;
  }

  /// 选择在线动态壁纸图源；换源时清掉上一个源留下的封面。
  Future<void> setVideoSourceIndex(int index) async {
    final clamped = BackgroundVideoSources.clampIndex(index);
    _updateState(
      state.copyWith(
        videoSourceIndex: clamped,
        videoTagIndex: BackgroundVideoSources.clampTagIndex(clamped, state.videoTagIndex),
        networkVideoCover: null,
      ),
    );
  }

  Future<void> setVideoTagIndex(int index) async {
    _updateState(state.copyWith(videoTagIndex: BackgroundVideoSources.clampTagIndex(state.videoSourceIndex, index)));
  }

  // ------------------------------------------------------------------
  // 本机图片 / 视频（自定义壁纸）
  // ------------------------------------------------------------------

  /// 选一张本机图片作为壁纸。
  ///
  /// 会同时写两份：文件复制进应用私有目录（用户删掉原图也不失效），以及
  /// base64 —— 因为 `TvScaffold` 的图片背景只消费
  /// [BackgroundConfigModel.currentBoxImageBase64]。
  Future<bool> pickLocalImage() async {
    final picked = await FilePicker.pickFile(
      dialogTitle: '选择壁纸图片',
      type: FileType.custom,
      allowedExtensions: const <String>['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
    );
    final sourcePath = picked?.path;
    if (sourcePath == null || sourcePath.isEmpty) return false;

    try {
      final bytes = await File(sourcePath).readAsBytes();
      if (bytes.isEmpty) return false;
      final stored = await _importFile(sourcePath, 'bg_image');
      setLocalImage(stored ?? sourcePath);
      setCurrentBoxImage(base64Encode(bytes));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 选一个本机视频作为动态壁纸。
  Future<bool> pickLocalVideo() async {
    final picked = await FilePicker.pickFile(
      dialogTitle: '选择动态壁纸视频',
      type: FileType.custom,
      allowedExtensions: const <String>['mp4', 'mkv', 'webm', 'mov', 'm4v', 'ts'],
    );
    final sourcePath = picked?.path;
    if (sourcePath == null || sourcePath.isEmpty) return false;

    try {
      final stored = await _importFile(sourcePath, 'bg_video');
      setLocalVideo(stored ?? sourcePath);
      await reloadBackgroundVideo();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 复制进应用私有目录，避免用户之后删掉原文件导致背景失效。
  Future<String?> _importFile(String sourcePath, String baseName) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final target = Directory('${dir.path}/background');
      if (!target.existsSync()) await target.create(recursive: true);
      final file = File('${target.path}/$baseName${path_util.extension(sourcePath)}');
      await File(sourcePath).copy(file.path);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  void setAssetVideo(String path) => _updateState(
    state.copyWith(source: BackgroundSource.assetVideo, assetVideoPath: path, localVideoPath: "", networkVideoUrl: ""),
  );
  void setLocalVideo(String path) => _updateState(
    state.copyWith(source: BackgroundSource.localVideo, localVideoPath: path, assetVideoPath: "", networkVideoUrl: ""),
  );
  void setNetworkVideo(String url) => _updateState(
    state.copyWith(
      source: BackgroundSource.networkVideo,
      networkVideoUrl: url,
      assetVideoPath: "",
      localVideoPath: "",
      // 从图源表选的地址和手填地址是两条路，走这条就清掉手填记录。
      customVideoUrl: "",
      networkVideoCover: null,
    ),
  );

  void importFromJson(Map<String, dynamic> json) {
    final gradientHexStr = json["gradientHexList"] ?? "0xff141e30,0xff243b55,0xff141e30";
    final colors = gradientHexStr.toString().split(",").map((s) => HexColor(s)).toList();

    final model = BackgroundConfigModel(
      source: bgSourceFromString(json["source"] ?? 'none'),
      boxFit: BoxFit.values.firstWhere((e) => e.name == json["boxFit"], orElse: () => BoxFit.cover),
      maskOpacity: (json["maskOpacity"] ?? 0.35).toDouble(),
      blur: (json["blur"] is num) ? (json["blur"] as num).toDouble() : 0.0,
      autoSwitch: json["autoSwitch"] == true,
      autoSwitchIntervalHours: (json["autoSwitchIntervalHours"] is int)
          ? (json["autoSwitchIntervalHours"] as int).clamp(1, 24)
          : 6,
      solidColor: HexColor(json["solidColorHex"] ?? "141e30"),
      gradientColors: colors,
      assetImagePath: json["assetImagePath"],
      localImagePath: json["localImagePath"],
      networkImageUrl: json["networkImageUrl"],
      currentBoxImageBase64: json["currentBoxImage"] ?? "",
      assetVideoPath: json["assetVideoPath"],
      localVideoPath: json["localVideoPath"],
      networkVideoUrl: json["networkVideoUrl"],
      currentImageUrl: (json["currentImageUrl"] ?? '') as String,
      recentImageUrls: (json["recentImageUrls"] is List)
          ? (json["recentImageUrls"] as List).map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      customImageUrl: (json["customImageUrl"] ?? '') as String,
      customVideoUrl: (json["customVideoUrl"] ?? '') as String,
      networkVideoCover: json["networkVideoCover"] as String?,
      videoSourceIndex: BackgroundVideoSources.clampIndex(
        json["videoSourceIndex"] is int ? json["videoSourceIndex"] as int : 0,
      ),
      videoTagIndex: BackgroundVideoSources.clampTagIndex(
        0,
        json["videoTagIndex"] is int ? json["videoTagIndex"] as int : 0,
      ),
      customVideoApiUrl: (json["customVideoApiUrl"] ?? '') as String,
    );
    _updateState(model);
  }

  Map<String, dynamic> toJson() {
    return {
      "source": bgSourceToString(state.source),
      "boxFit": state.boxFit.name,
      "maskOpacity": state.maskOpacity,
      "blur": state.blur,
      "autoSwitch": state.autoSwitch,
      "autoSwitchIntervalHours": state.autoSwitchIntervalHours,
      "solidColorHex": state.solidColor.toHex(),
      "gradientHexList": state.gradientColors.map((c) => c.toHex()).join(","),
      "assetImagePath": state.assetImagePath ?? "",
      "localImagePath": state.localImagePath ?? "",
      "networkImageUrl": state.networkImageUrl ?? "",
      "currentBoxImage": state.currentBoxImageBase64,
      "assetVideoPath": state.assetVideoPath ?? "",
      "localVideoPath": state.localVideoPath ?? "",
      "networkVideoUrl": state.networkVideoUrl ?? "",
      // 只备份「当前是哪张」，不备份时间戳：换设备后不必等一整个间隔才换第一张。
      "currentImageUrl": state.currentImageUrl,
      "recentImageUrls": state.recentImageUrls,
      // 手填地址与动态壁纸选择要一起走，否则换设备后输入框是空的。
      "customImageUrl": state.customImageUrl,
      "customVideoUrl": state.customVideoUrl,
      "networkVideoCover": state.networkVideoCover,
      "videoSourceIndex": state.videoSourceIndex,
      "videoTagIndex": state.videoTagIndex,
      "customVideoApiUrl": state.customVideoApiUrl,
    };
  }
}
