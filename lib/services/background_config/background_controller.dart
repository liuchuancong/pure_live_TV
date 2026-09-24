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
  /// Lazily created: only a real video background needs a native player.
  /// Creating it in `build` kept an mpv instance alive even for solid/image
  /// wallpapers.
  Player? _videoPlayer;
  VideoController? _videoController;

  /// The controller the background layer renders; null until the player exists.
  VideoController? get videoController => _videoController;

  static BackgroundController get to => SettingsService.to.bg;
  final _configStream = BehaviorSubject<BackgroundConfigModel>();
  Stream<BackgroundConfigModel> get configChanges => _configStream.stream;

  String? _cachedBase64;
  Uint8List? _cachedBytes;

  BackgroundConfigModel? _lastModel;

  /// Snapshot of the latest config, safe to read from any context (including
  /// lifecycle callbacks where `state` is off-limits).
  ///
  /// Nullable + lazily seeded: a lifecycle read can race the first `build()`
  /// when the controller is reached through `SettingsService.to.bg` outside the
  /// normal provider graph — a `late` field would throw `LateInitializationError`
  /// in that window.
  BackgroundConfigModel get _model {
    final cached = _lastModel;
    if (cached != null) return cached;
    final fresh = _readModelFromPrefs();
    _lastModel = fresh;
    return fresh;
  }

  BackgroundConfigModel _readModelFromPrefs() {
    return BackgroundConfigModel(
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
  }

  @override
  BackgroundConfigModel build() {
    // Released only when the app closes; keepAlive keeps it alive between
    // reloadBackgroundVideo calls.
    ref.onDispose(() {
      _disposeVideoPlayer();
      _configStream.close();
    });

    final model = _readModelFromPrefs();

    // Seed the snapshot before anything can read it.
    _lastModel = model;
    _configStream.add(model);
    // A video background survives a restart, so the player has to pick it up on
    // startup too. `state` is only readable once `build` has returned, hence the
    // microtask.
    unawaited(Future.microtask(reloadBackgroundVideo));
    return model;
  }

  void _updateState(BackgroundConfigModel newModel) {
    // Compare against the cached snapshot, not `state` — see [_model].
    final BackgroundConfigModel previous = _model;
    final bool videoChanged =
        newModel.source != previous.source ||
        newModel.localVideoPath != previous.localVideoPath ||
        newModel.networkVideoUrl != previous.networkVideoUrl ||
        newModel.assetVideoPath != previous.assetVideoPath;

    state = newModel;
    _lastModel = newModel;
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

  /// Creates the background player on first real video use.
  ///
  /// Uses the live player's platform configuration on purpose: media_kit's
  /// default attaches an Android Surface before video parameters are known,
  /// which is what made video wallpapers render black (or a single pixel).
  void _ensureVideoPlayer() {
    if (_videoPlayer != null) return;
    final player = Player();
    _videoPlayer = player;
    _videoController = VideoController(player, configuration: wallpaperVideoControllerConfiguration());
    player.setVolume(0.0);
    player.setPlaylistMode(PlaylistMode.loop);
  }

  /// While the live/VOD player is active, the background shows a static poster.
  ///
  /// Two video layers decoding at once fight for Android TV Surface / hwdec
  /// resources (visible even on emulators: wallpaper and live frame flash
  /// together). So on playback start we don't just pause — we capture the
  /// current frame as a poster and fully release the wallpaper decoder; only
  /// the static image is drawn. If capture fails, fall back to pausing on the
  /// last frame.
  bool _playbackSuspended = false;

  /// Poster shown while playback is active; null means "no poster", in which
  /// case the player is paused instead.
  Uint8List? _posterFrame;
  Uint8List? get posterFrame => _posterFrame;

  bool get isPlaybackSuspended => _playbackSuspended;

  /// Called when the player page enters or leaves the navigation stack
  /// (via [WallpaperRouteObserver]; a buffer-level play/pause flip is not a
  /// real user action and must not reach here).
  ///
  /// Every read below goes through [_model] instead of `state` to stay out of
  /// the Riverpod lifecycle assertion.
  Future<void> setPlaybackActive(bool active) async {
    if (_playbackSuspended == active) return;
    _playbackSuspended = active;

    if (active) {
      // Nothing to release when the background is not a video.
      if (!_isVideoSource) return;
      final player = _videoPlayer;
      if (player == null) return;
      Uint8List? frame;
      try {
        frame = await player.screenshot(format: 'image/jpeg');
      } catch (_) {
        frame = null;
      }
      // The capture is asynchronous, and playback can have ended while it was
      // in flight. That branch already rebuilt (and resumed) the background
      // player, so acting on the stale frame here would dispose the fresh
      // player and leave the wallpaper black until the next rebuild.
      if (!_playbackSuspended) return;
      if (frame != null && frame.isNotEmpty) {
        _posterFrame = frame;
        _disposeVideoPlayer();
        // The player is gone; tell the background layer to draw the poster,
        // otherwise it would render a black fill.
        _configStream.add(_model);
      } else {
        // Capture unsupported by some hwdec combos: fall back to pausing on
        // the last frame, which still avoids two decoders running at once.
        await player.pause();
      }
      return;
    }

    // Playback ended: drop the poster first — the background may have been
    // switched to another image/video meanwhile, and keeping the stale frame
    // would show the wrong one on the next switch back.
    if (_posterFrame != null) {
      _posterFrame = null;
      _configStream.add(_model);
    }
    if (_isVideoSource) await reloadBackgroundVideo();
  }

  /// Reads the snapshot, never `state` — this getter is called from the
  /// lifecycle path described on [setPlaybackActive].
  bool get _isVideoSource {
    final source = _model.source;
    return source == BackgroundSource.assetVideo ||
        source == BackgroundSource.localVideo ||
        source == BackgroundSource.networkVideo;
  }

  /// Fully releases the background player (forced-destroy path).
  void _disposeVideoPlayer() {
    final player = _videoPlayer;
    _videoPlayer = null;
    _videoController = null;
    unawaited(player?.dispose());
  }

  /// Also driven from the route-observer path, so it reads [_model] only.
  Future<void> reloadBackgroundVideo() async {
    final src = switch (_model.source) {
      BackgroundSource.assetVideo => _model.assetVideoPath,
      BackgroundSource.localVideo => _model.localVideoPath,
      BackgroundSource.networkVideo => _model.networkVideoUrl,
      _ => null,
    };
    if (src != null && src.isNotEmpty) {
      // Don't allocate a decoder while playback is active: the background
      // shows the poster right now and the video resumes on playback end
      // (see setPlaybackActive).
      if (_playbackSuspended) return;
      final bool created = _videoPlayer == null;
      _ensureVideoPlayer();
      // The player is lazy, and the background layer reads the controller on
      // configChanges rebuild: on the frame it was just created, it still sees
      // null, so notify once more so it can pick up the controller.
      if (created) _configStream.add(_model);
      await _videoPlayer?.open(Media(src), play: !_playbackSuspended);
      return;
    }

    // No longer a video wallpaper: release the decoder entirely, never keep
    // an idle instance.
    _disposeVideoPlayer();
    // The controller is gone; notify the background layer to stop rendering it.
    _configStream.add(_model);
  }

  void setNone() => _updateState(state.copyWith(source: BackgroundSource.none));
  void setSolid(Color c) => _updateState(state.copyWith(source: BackgroundSource.color, solidColor: c));
  void setGradient(List<Color> colors) =>
      _updateState(state.copyWith(source: BackgroundSource.gradient, gradientColors: colors));
  void setBoxFit(BoxFit fit) => _updateState(state.copyWith(boxFit: fit));
  void setMaskOpacity(double opacity) => _updateState(state.copyWith(maskOpacity: opacity));

  /// Gaussian blur strength (sigma, 0 disables).
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
