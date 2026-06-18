import 'dart:convert';
import 'dart:typed_data';
import 'package:rxdart/rxdart.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pure_live/common/index.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pure_live/services/background/back_ground_config.dart';
import 'package:pure_live/services/background/back_ground_source.dart';

class BackgroundController extends GetxController {
  static BackgroundController get to => Get.find<BackgroundController>();

  final RxString sourceStr = hiveString('bgSource', bgSourceToString(BackgroundSource.none));
  BackgroundSource get source => bgSourceFromString(sourceStr.value);
  set source(BackgroundSource val) => sourceStr.value = bgSourceToString(val);

  final RxString boxFitStr = hiveString('bgBoxFit', BoxFit.cover.name);
  BoxFit get boxFit => BoxFit.values.firstWhere((e) => e.name == boxFitStr.value, orElse: () => BoxFit.cover);
  set boxFit(BoxFit val) => boxFitStr.value = val.name;

  final RxDouble maskOpacity = hiveDouble('bgMaskOpacity', 0.35);

  final RxInt solidColorHex = hiveInt('bgSolidColor', 0xff141e30);
  Color get solidColor => Color(solidColorHex.value);
  set solidColor(Color c) => solidColorHex.value = c.value;

  final RxString gradientHexList = hiveString('bgGradientColors', "0xff141e30,0xff243b55,0xff141e30");
  List<Color> get gradientColors => gradientHexList.value.split(",").map((s) => Color(int.parse(s))).toList();
  set gradientColors(List<Color> list) =>
      gradientHexList.value = list.map((c) => "0xff${c.value.toRadixString(16)}").join(",");

  final RxString assetImagePath = hiveString('bgAssetImagePath', "");
  final RxString localImagePath = hiveString('bgLocalImagePath', "");
  final RxString networkImageUrl = hiveString('bgNetworkImageUrl', "");

  final RxString currentBoxImage = hiveString('bgCurrentBoxImageBase64', "");
  String? _cachedBase64;
  Uint8List? _cachedBytes;
  MemoryImage? get cachedBackgroundImage {
    if (currentBoxImage.isEmpty) return null;
    if (_cachedBase64 != currentBoxImage.value) {
      _cachedBase64 = currentBoxImage.value;
      _cachedBytes = base64Decode(currentBoxImage.value);
    }
    return _cachedBytes != null ? MemoryImage(_cachedBytes!) : null;
  }

  final RxString assetVideoPath = hiveString('bgAssetVideoPath', "");
  final RxString localVideoPath = hiveString('bgLocalVideoPath', "");
  final RxString networkVideoUrl = hiveString('bgNetworkVideoUrl', "");

  late final Player _videoPlayer;
  late final VideoController videoController;

  final _configStream = BehaviorSubject<BackgroundConfigModel>();
  Stream<BackgroundConfigModel> get configChanges => _configStream.stream;

  @override
  void onInit() {
    super.onInit();
    _videoPlayer = Player();
    videoController = VideoController(_videoPlayer);
    _videoPlayer.setVolume(0.0);
    _videoPlayer.setPlaylistMode(PlaylistMode.loop);

    everAll([
      sourceStr,
      boxFitStr,
      maskOpacity,
      solidColorHex,
      gradientHexList,
      assetImagePath,
      localImagePath,
      networkImageUrl,
      currentBoxImage,
      assetVideoPath,
      localVideoPath,
      networkVideoUrl,
    ], (_) => _emitConfig());
  }

  void _emitConfig() {
    final model = BackgroundConfigModel(
      source: source,
      boxFit: boxFit,
      maskOpacity: maskOpacity.value,
      solidColor: solidColor,
      gradientColors: gradientColors,
      assetImagePath: assetImagePath.value.isEmpty ? null : assetImagePath.value,
      localImagePath: localImagePath.value.isEmpty ? null : localImagePath.value,
      networkImageUrl: networkImageUrl.value.isEmpty ? null : networkImageUrl.value,
      currentBoxImageBase64: currentBoxImage.value,
      assetVideoPath: assetVideoPath.value.isEmpty ? null : assetVideoPath.value,
      localVideoPath: localVideoPath.value.isEmpty ? null : localVideoPath.value,
      networkVideoUrl: networkVideoUrl.value.isEmpty ? null : networkVideoUrl.value,
    );
    _configStream.add(model);
  }

  Future<void> reloadBackgroundVideo() async {
    String? src;
    switch (source) {
      case BackgroundSource.assetVideo:
        src = assetVideoPath.value;
        break;
      case BackgroundSource.localVideo:
        src = localVideoPath.value;
        break;
      case BackgroundSource.networkVideo:
        src = networkVideoUrl.value;
        break;
      default:
        await _videoPlayer.stop();
        return;
    }
    if (src.isNotEmpty) {
      await _videoPlayer.open(Media(src), play: true);
    }
  }

  void setNone() => source = BackgroundSource.none;
  void setSolid(Color c) {
    source = BackgroundSource.color;
    solidColor = c;
  }

  void setGradient(List<Color> colors) {
    source = BackgroundSource.gradient;
    gradientColors = colors;
  }

  void setAssetImage(String path) {
    source = BackgroundSource.assetImage;
    assetImagePath.value = path;
    localImagePath.value = "";
    networkImageUrl.value = "";
  }

  void setLocalImage(String path) {
    source = BackgroundSource.localImage;
    localImagePath.value = path;
    assetImagePath.value = "";
    networkImageUrl.value = "";
  }

  void setNetworkImage(String url) {
    source = BackgroundSource.networkImage;
    networkImageUrl.value = url;
    assetImagePath.value = "";
    localImagePath.value = "";
  }

  void setAssetVideo(String path) {
    source = BackgroundSource.assetVideo;
    assetVideoPath.value = path;
    localVideoPath.value = "";
    networkVideoUrl.value = "";
  }

  void setLocalVideo(String path) {
    source = BackgroundSource.localVideo;
    localVideoPath.value = path;
    assetVideoPath.value = "";
    networkVideoUrl.value = "";
  }

  void setNetworkVideo(String url) {
    source = BackgroundSource.networkVideo;
    networkVideoUrl.value = url;
    assetVideoPath.value = "";
    localVideoPath.value = "";
  }

  Map<String, dynamic> toJson() {
    return {
      "source": sourceStr.value,
      "boxFit": boxFitStr.value,
      "maskOpacity": maskOpacity.value,
      "solidColorHex": solidColorHex.value,
      "gradientHexList": gradientHexList.value,
      "assetImagePath": assetImagePath.value,
      "localImagePath": localImagePath.value,
      "networkImageUrl": networkImageUrl.value,
      "currentBoxImage": currentBoxImage.value,
      "assetVideoPath": assetVideoPath.value,
      "localVideoPath": localVideoPath.value,
      "networkVideoUrl": networkVideoUrl.value,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    sourceStr.value = json["source"] ?? bgSourceToString(BackgroundSource.none);
    boxFitStr.value = json["boxFit"] ?? BoxFit.cover.name;
    maskOpacity.value = (json["maskOpacity"] ?? 0.35).toDouble();
    solidColorHex.value = json["solidColorHex"] ?? 0xff141e30;
    gradientHexList.value = json["gradientHexList"] ?? "0xff141e30,0xff243b55,0xff141e30";
    assetImagePath.value = json["assetImagePath"] ?? "";
    localImagePath.value = json["localImagePath"] ?? "";
    networkImageUrl.value = json["networkImageUrl"] ?? "";
    currentBoxImage.value = json["currentBoxImage"] ?? "";
    assetVideoPath.value = json["assetVideoPath"] ?? "";
    localVideoPath.value = json["localVideoPath"] ?? "";
    networkVideoUrl.value = json["networkVideoUrl"] ?? "";
  }

  static Map<String, dynamic> extractConfig(Map<String, dynamic>? rootConfig) {
    final bg = rootConfig?["background"] as Map<String, dynamic>? ?? {};
    return bg;
  }

  static Map<String, dynamic> mergeConfig(Map<String, dynamic> rootConfig, Map<String, dynamic> updateFields) {
    rootConfig["background"] = updateFields;
    return rootConfig;
  }

  @override
  void onClose() {
    _configStream.close();
    _videoPlayer.dispose();
    super.onClose();
  }
}
