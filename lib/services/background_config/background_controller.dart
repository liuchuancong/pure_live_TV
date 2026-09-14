import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/widgets.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/services/background_config/background_config_model.dart';
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
    return model;
  }

  void _updateState(BackgroundConfigModel newModel) {
    state = newModel;
    _configStream.add(newModel); // 同步更新流

    HivePrefUtil.setString('bgSource', bgSourceToString(newModel.source));
    HivePrefUtil.setString('bgBoxFit', newModel.boxFit.name);
    HivePrefUtil.setDouble('bgMaskOpacity', newModel.maskOpacity);
    HivePrefUtil.setString('bgSolidColorHex', newModel.solidColor.toHex());
    HivePrefUtil.setString('bgGradientColors', newModel.gradientColors.map((c) => c.toHex()).join(","));
    HivePrefUtil.setString('bgAssetImagePath', newModel.assetImagePath ?? "");
    HivePrefUtil.setString('bgLocalImagePath', newModel.localImagePath ?? "");
    HivePrefUtil.setString('bgNetworkImageUrl', newModel.networkImageUrl ?? "");
    HivePrefUtil.setString('bgCurrentBoxImageBase64', newModel.currentBoxImageBase64);
    HivePrefUtil.setString('bgAssetVideoPath', newModel.assetVideoPath ?? "");
    HivePrefUtil.setString('bgLocalVideoPath', newModel.localVideoPath ?? "");
    HivePrefUtil.setString('bgNetworkVideoUrl', newModel.networkVideoUrl ?? "");
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
  /// - 其余接口本身就是图片地址。
  ///
  /// 最后统一转 base64 存进 [BackgroundConfigModel.currentBoxImageBase64]，
  /// 因为 `TvScaffold` 的图片背景只消费这一个字段（asset/local/network 三个
  /// source 都走它）。
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
      String? imageUrl;
      if (source.url.contains('://jkapi.com')) {
        final apiKey = BackgroundImageSources.wumingApiKeys[source.name];
        if (apiKey == null) return false;
        final separator = source.url.contains('?') ? '&' : '?';
        final response = await dio.get<dynamic>('${source.url}${separator}type=json&apiKey=$apiKey');
        final data = response.data;
        if (data is Map) imageUrl = (data['image_url'] ?? data['content'])?.toString();
      } else if (source.url == 'https://alcy.cc') {
        const categories = <String>[
          'ycy', 'moez', 'ai', 'ysz', 'ys', 'mp', 'moemp', 'ysmp', 'aimp', 'tx', 'lai', 'xhl', 'bd',
        ];
        imageUrl = '${source.url}${categories[math.Random().nextInt(categories.length)]}';
      } else {
        imageUrl = source.url;
      }

      if (imageUrl == null || imageUrl.isEmpty) return false;

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
      return true;
    } catch (_) {
      return false;
    }
  }

  static const String _wallpaperUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/116.0.5845.97 Safari/537.36';

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
