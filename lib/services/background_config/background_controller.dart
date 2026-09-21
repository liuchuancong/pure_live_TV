import 'dart:async';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/widgets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/services/background_config/local/wallpaper_video.dart';
import 'package:pure_live/services/background_config/background_config_model.dart';
part 'background_controller.g.dart';

/// Background configuration and the player behind a video background.
///
/// keepAlive: the video player and its [VideoController] are created here, and
/// the background layer only *reads* this provider. As auto-dispose it was
/// disposed between reads and rebuilt on the next one, so every rebuild created
/// a new `Player`/`VideoController` and disposed the previous one — the
/// `VideoOutputManager.create` → `dispose` → `Resize 0x0` →
/// `Surface.release()` NPE in logcat, plus a reloading wallpaper.
@Riverpod(keepAlive: true)
class BackgroundController extends _$BackgroundController {
  /// 背景视频播放器：**按需创建**。
  ///
  /// 以前它在 build 里就 new 出来，且只在 provider 销毁时才释放——即使用户
  /// 选的是纯色/图片壁纸，也常驻一个原生播放器。现在只在真的需要播视频时创建，
  /// 并在“播放器强制销毁”开启时于切走视频后彻底释放解码器。
  Player? _videoPlayer;
  VideoController? _videoController;

  /// 背景层读取的渲染控制器；未创建时为 null（背景层据此画空白）。
  VideoController? get videoController => _videoController;

  static BackgroundController get to => SettingsService.to.bg;
  final _configStream = BehaviorSubject<BackgroundConfigModel>();
  Stream<BackgroundConfigModel> get configChanges => _configStream.stream;

  String? _cachedBase64;
  Uint8List? _cachedBytes;

  @override
  BackgroundConfigModel build() {
    // 关闭应用时才释放（keepAlive 期间由 reloadBackgroundVideo 按需创建/释放）。
    ref.onDispose(() {
      _disposeVideoPlayer();
      _configStream.close();
    });

    final model = BackgroundConfigModel(
      source: bgSourceFromString(HivePrefUtil.getString('bgSource') ?? 'none'),
      boxFit: BoxFit.values.firstWhere(
        (e) => e.name == (HivePrefUtil.getString('bgBoxFit') ?? 'cover'),
        orElse: () => BoxFit.cover,
      ),
      maskOpacity: HivePrefUtil.getDouble('bgMaskOpacity') ?? 0.35,
      blurSigma: HivePrefUtil.getDouble('bgBlurSigma') ?? 0,
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
    );

    _configStream.add(model);
    // A video background survives a restart, so the player has to pick it up on
    // startup too. `state` is only readable once `build` has returned, hence the
    // microtask.
    unawaited(Future.microtask(reloadBackgroundVideo));
    return model;
  }

  void _updateState(BackgroundConfigModel newModel) {
    final BackgroundConfigModel previous = state;
    final bool videoChanged =
        newModel.source != previous.source ||
        newModel.localVideoPath != previous.localVideoPath ||
        newModel.networkVideoUrl != previous.networkVideoUrl ||
        newModel.assetVideoPath != previous.assetVideoPath;

    state = newModel;
    _configStream.add(newModel); // keep the stream in sync

    // Write only keys whose value changed: the base64 image slot can hold a
    // whole wallpaper, and rewriting it (plus everything else) on every mask
    // or box-fit cycle was a visible hitch on TV boxes.
    _writeIfChanged('bgSource', bgSourceToString(newModel.source));
    _writeIfChanged('bgBoxFit', newModel.boxFit.name);
    _writeIfChanged('bgMaskOpacity', newModel.maskOpacity);
    _writeIfChanged('bgBlurSigma', newModel.blurSigma);
    _writeIfChanged('bgSolidColorHex', newModel.solidColor.toHex());
    _writeIfChanged('bgGradientColors', newModel.gradientColors.map((c) => c.toHex()).join(","));
    _writeIfChanged('bgAssetImagePath', newModel.assetImagePath ?? "");
    _writeIfChanged('bgLocalImagePath', newModel.localImagePath ?? "");
    _writeIfChanged('bgNetworkImageUrl', newModel.networkImageUrl ?? "");
    _writeIfChanged('bgCurrentBoxImageBase64', newModel.currentBoxImageBase64);
    _writeIfChanged('bgAssetVideoPath', newModel.assetVideoPath ?? "");
    _writeIfChanged('bgLocalVideoPath', newModel.localVideoPath ?? "");
    _writeIfChanged('bgNetworkVideoUrl', newModel.networkVideoUrl ?? "");

    // Nothing used to open the media: the background layer only renders the
    // controller, so a freshly chosen video stayed a black rectangle until the
    // app was restarted. Switching away from a video also lands here and stops
    // the player.
    if (videoChanged) unawaited(reloadBackgroundVideo());
  }

  void _writeIfChanged(String key, Object value) {
    final current = HivePrefUtil.getAnyPref(key);
    if (current == value) return;
    if (value is String) {
      HivePrefUtil.setString(key, value);
    } else if (value is double) {
      HivePrefUtil.setDouble(key, value);
    }
  }

  MemoryImage? get cachedBackgroundImage {
    final base64Str = state.currentBoxImageBase64;
    if (base64Str.isEmpty) return null;

    if (_cachedBase64 != base64Str) {
      _cachedBase64 = base64Str;
      _cachedBytes = base64Decode(_cachedBase64!);
    }
    return MemoryImage(_cachedBytes!);
  }

  /// 创建背景播放器（首次需要播视频时）。
  ///
  /// 沿用直播播放器的平台适配：media_kit 默认配置会在视频参数未知时就挂载
  /// Android Surface，这正是背景视频变黑（或只有一个像素）的原因。
  void _ensureVideoPlayer() {
    if (_videoPlayer != null) return;
    final player = Player();
    _videoPlayer = player;
    _videoController = VideoController(player, configuration: wallpaperVideoControllerConfiguration());
    player.setVolume(0.0);
    player.setPlaylistMode(PlaylistMode.loop);
  }

  /// 播放器（直播/点播）正在播放时，背景层改用一张静态海报帧。
  ///
  /// 两个视频层同时解码时，Android TV（模拟器上更明显）的 Surface / 硬解
  /// 资源会互相抢占，表现就是壁纸和直播画面一起闪。所以播放开始时不只暂停：
  /// 先截下当前帧当海报，再彻底释放壁纸播放器的解码器——播放期间背景层只画
  /// 这张静态图，截帧失败才退回"暂停保留最后一帧"。
  bool _playbackSuspended = false;

  /// 播放期间展示的静态帧；为空表示没有海报可用（此时播放器是暂停状态）。
  Uint8List? _posterFrame;
  Uint8List? get posterFrame => _posterFrame;

  bool get isPlaybackSuspended => _playbackSuspended;

  /// 由播放端在 播放/停止 时调用。
  Future<void> setPlaybackActive(bool active) async {
    if (_playbackSuspended == active) return;
    _playbackSuspended = active;

    if (active) {
      // 背景不是视频时没有解码器要释放。
      if (!_isVideoSource) return;
      final player = _videoPlayer;
      if (player == null) return;
      Uint8List? frame;
      try {
        frame = await player.screenshot(format: 'image/jpeg');
      } catch (_) {
        frame = null;
      }
      if (frame != null && frame.isNotEmpty) {
        _posterFrame = frame;
        _disposeVideoPlayer();
        // 播放器没了，通知背景层改画静态帧（否则它拿到 null 会画黑底）。
        _configStream.add(state);
      } else {
        // 截不到帧（部分硬解组合不支持）：退回暂停保留最后一帧，同样不会
        // 两路同时解码。
        await player.pause();
      }
      return;
    }

    // 播放结束：先丢掉海报帧——期间背景可能已经被换成图片或其他视频，
    // 留着旧帧会让下一次切回视频壁纸时显示错的那一张。
    if (_posterFrame != null) {
      _posterFrame = null;
      _configStream.add(state);
    }
    if (_isVideoSource) await reloadBackgroundVideo();
  }

  bool get _isVideoSource =>
      state.source == BackgroundSource.assetVideo ||
      state.source == BackgroundSource.localVideo ||
      state.source == BackgroundSource.networkVideo;

  /// 彻底释放背景播放器（强制销毁路径）。
  void _disposeVideoPlayer() {
    final player = _videoPlayer;
    _videoPlayer = null;
    _videoController = null;
    unawaited(player?.dispose());
  }

  Future<void> reloadBackgroundVideo() async {
    final src = switch (state.source) {
      BackgroundSource.assetVideo => state.assetVideoPath,
      BackgroundSource.localVideo => state.localVideoPath,
      BackgroundSource.networkVideo => state.networkVideoUrl,
      _ => null,
    };
    if (src != null && src.isNotEmpty) {
      // 播放期间不分配解码器：背景层此刻画的是海报帧，等播放结束再起播
      // （见 setPlaybackActive）。
      if (_playbackSuspended) return;
      final bool created = _videoPlayer == null;
      _ensureVideoPlayer();
      // 播放器是懒创建的，而背景层是在 configChanges 重建时读到控制器：
      // 刚创建出来的这一帧它拿到的还是 null，必须再发一次通知让它取到。
      if (created) _configStream.add(state);
      // 播放期间挂起的壁纸保持暂停：起播后由播放端在结束时恢复。
      await _videoPlayer?.open(Media(src), play: !_playbackSuspended);
      return;
    }

    // 不再是视频壁纸：一律释放解码器，不留常驻实例。
    _disposeVideoPlayer();
    // 控制器已释放，通知背景层别再拿它渲染。
    _configStream.add(state);
  }

  void setNone() => _updateState(state.copyWith(source: BackgroundSource.none));
  void setSolid(Color c) => _updateState(state.copyWith(source: BackgroundSource.color, solidColor: c));
  void setGradient(List<Color> colors) =>
      _updateState(state.copyWith(source: BackgroundSource.gradient, gradientColors: colors));
  void setBoxFit(BoxFit fit) => _updateState(state.copyWith(boxFit: fit));
  void setMaskOpacity(double opacity) => _updateState(state.copyWith(maskOpacity: opacity));

  /// 设置高斯模糊强度（sigma，0 关闭）。
  void setBlurSigma(double sigma) => _updateState(state.copyWith(blurSigma: sigma.clamp(0, 60)));
  void setAssetImage(String path) => _updateState(
    state.copyWith(source: BackgroundSource.assetImage, assetImagePath: path, localImagePath: "", networkImageUrl: ""),
  );
  void setLocalImage(String path) => _updateState(
    state.copyWith(source: BackgroundSource.localImage, localImagePath: path, assetImagePath: "", networkImageUrl: ""),
  );
  // networkImageUrl and currentBoxImageBase64 are exclusive: whichever setter
  // runs clears the other, so the background layer can trust either field.
  void setNetworkImage(String url) => _updateState(
    state.copyWith(
      source: BackgroundSource.networkImage,
      networkImageUrl: url,
      assetImagePath: "",
      localImagePath: "",
      currentBoxImageBase64: "",
    ),
  );

  /// Applies a downloaded picture (a random API returns a different image per
  /// request, so only the bytes are stable) as the network background.
  void setNetworkImageBytes(Uint8List bytes) => _updateState(
    state.copyWith(
      source: BackgroundSource.networkImage,
      currentBoxImageBase64: base64Encode(bytes),
      networkImageUrl: "",
      assetImagePath: "",
      localImagePath: "",
    ),
  );
  void setCurrentBoxImage(String base64Str) => _updateState(state.copyWith(currentBoxImageBase64: base64Str));
  void setAssetVideo(String path) => _updateState(
    state.copyWith(source: BackgroundSource.assetVideo, assetVideoPath: path, localVideoPath: "", networkVideoUrl: ""),
  );
  void setLocalVideo(String path) => _updateState(
    state.copyWith(source: BackgroundSource.localVideo, localVideoPath: path, assetVideoPath: "", networkVideoUrl: ""),
  );
  void setNetworkVideo(String url) => _updateState(
    state.copyWith(source: BackgroundSource.networkVideo, networkVideoUrl: url, assetVideoPath: "", localVideoPath: ""),
  );

  void importFromJson(Map<String, dynamic> json) {
    final gradientHexStr = json["gradientHexList"] ?? "0xff141e30,0xff243b55,0xff141e30";
    final colors = gradientHexStr.toString().split(",").map((s) => HexColor(s)).toList();

    final model = BackgroundConfigModel(
      source: bgSourceFromString(json["source"] ?? 'none'),
      boxFit: BoxFit.values.firstWhere((e) => e.name == json["boxFit"], orElse: () => BoxFit.cover),
      maskOpacity: (json["maskOpacity"] ?? 0.35).toDouble(),
      blurSigma: (json["blurSigma"] ?? 0).toDouble(),
      solidColor: HexColor(json["solidColorHex"] ?? "141e30"),
      gradientColors: colors,
      assetImagePath: json["assetImagePath"],
      localImagePath: json["localImagePath"],
      networkImageUrl: json["networkImageUrl"],
      currentBoxImageBase64: json["currentBoxImage"] ?? "",
      assetVideoPath: json["assetVideoPath"],
      localVideoPath: json["localVideoPath"],
      networkVideoUrl: json["networkVideoUrl"],
    );
    _updateState(model);
  }

  Map<String, dynamic> toJson() {
    return {
      "source": bgSourceToString(state.source),
      "boxFit": state.boxFit.name,
      "maskOpacity": state.maskOpacity,
      "blurSigma": state.blurSigma,
      "solidColorHex": state.solidColor.toHex(),
      "gradientHexList": state.gradientColors.map((c) => c.toHex()).join(","),
      "assetImagePath": state.assetImagePath ?? "",
      "localImagePath": state.localImagePath ?? "",
      "networkImageUrl": state.networkImageUrl ?? "",
      "currentBoxImage": state.currentBoxImageBase64,
      "assetVideoPath": state.assetVideoPath ?? "",
      "localVideoPath": state.localVideoPath ?? "",
      "networkVideoUrl": state.networkVideoUrl ?? "",
    };
  }
}
