import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'unified_player_interface.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pure_live/common/services/settings_service.dart';

class MediaKitPlayerAdapter implements UnifiedPlayer {
  late Player _player;
  late VideoController _controller;
  final SettingsService settings = Get.find<SettingsService>();
  bool _isPlaying = false;
  @override
  Future<void> init() async {
    _isPlaying = false;
    _player = Player();
    _controller = settings.playerCompatMode.value
        ? VideoController(
            _player,
            configuration: VideoControllerConfiguration(vo: 'mediacodec_embed', hwdec: 'mediacodec'),
          )
        : VideoController(
            _player,
            configuration: VideoControllerConfiguration(
              enableHardwareAcceleration: settings.enableCodec.value,
              androidAttachSurfaceAfterVideoParameters: false,
            ),
          );
    _player.stream.playing.listen((playing) {
      _isPlaying = playing;
    });
  }

  @override
  Future<void> setDataSource(String url, Map<String, String> headers) async {
    await _player.pause();
    await _player.open(Media(url, httpHeaders: headers));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Widget getVideoWidget(int index, Widget? controls) {
    return Video(
      controller: _controller,
      fit: SettingsService.videofitList[index],
      controls: NoVideoControls, // 不显示默认控制栏
    );
  }

  @override
  void dispose() {
    _player.dispose();
  }

  @override
  Stream<bool> get onPlaying => _player.stream.playing;
  @override
  Stream<String?> get onError => _player.stream.error.map((e) => e);
  @override
  Stream<bool> get onLoading => _player.stream.buffering;
  @override
  bool get isPlayingNow => _isPlaying;
}
