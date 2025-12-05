import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'unified_player_interface.dart';
import 'package:flv_lzc/fijkplayer.dart';
import 'package:pure_live/player/fijk_helper.dart';
import 'package:pure_live/common/services/settings_service.dart';

class FijkPlayerAdapter implements UnifiedPlayer {
  final FijkPlayer _player = FijkPlayer();
  // 用于广播 playing 状态
  final BehaviorSubject<bool> _playingSubject = BehaviorSubject.seeded(false);
  // 用于广播错误
  final BehaviorSubject<String?> _errorSubject = BehaviorSubject.seeded(null);

  final BehaviorSubject<bool> _loadingSubject = BehaviorSubject.seeded(false);

  final BehaviorSubject<int?> _heightSubject = BehaviorSubject.seeded(null);
  final BehaviorSubject<int?> _widthSubject = BehaviorSubject.seeded(null);
  bool _isPlaying = false;

  @override
  Future<void> init() async {
    _player.addListener(_playerListener);
  }

  void _playerListener() {
    bool isPlaying = _player.state == FijkState.started;
    if (_isPlaying != isPlaying) {
      _isPlaying = isPlaying;
    }
    if (_playingSubject.value != isPlaying) {
      _playingSubject.add(isPlaying);
    }
    if (_player.state == FijkState.error) {
      _errorSubject.add("FijkPlayer error: ${_player.value.exception.message}");
    }
    if (_player.state == FijkState.prepared ||
        _player.state == FijkState.started ||
        _player.state == FijkState.paused) {
      _loadingSubject.add(false);
      int actualWidth = _player.value.size!.width.toInt();
      int actualHeight = _player.value.size!.height.toInt();
      _heightSubject.add(actualHeight);
      _widthSubject.add(actualWidth);
    } else if (_player.state == FijkState.asyncPreparing || _player.state == FijkState.initialized) {
      _loadingSubject.add(true);
    }
  }

  @override
  Future<void> setDataSource(String url, Map<String, String> headers) async {
    final SettingsService settings = Get.find<SettingsService>();
    await _player.reset();
    await FijkHelper.setFijkOption(_player, enableCodec: settings.enableCodec.value, headers: headers);
    await _player.setDataSource(url, autoPlay: true);
  }

  @override
  Future<void> play() => _player.start();

  @override
  Future<void> pause() => _player.pause();

  @override
  Widget getVideoWidget(int index, Widget? controls) {
    return FijkView(
      player: _player,
      fit: FijkHelper.getIjkBoxFit(SettingsService.videofitList[index]),
      fs: false,
      color: Colors.black,
      panelBuilder: (FijkPlayer fijkPlayer, FijkData fijkData, BuildContext context, Size viewSize, Rect texturePos) =>
          Container(),
    );
  }

  @override
  void dispose() {
    _player.release();
    _playingSubject.close();
    _errorSubject.close();
  }

  @override
  Stream<bool> get onPlaying => _playingSubject.stream;

  @override
  Stream<String?> get onError => _errorSubject.stream;

  @override
  Stream<bool> get onLoading => _loadingSubject.stream;

  @override
  bool get isPlayingNow => _isPlaying;

  @override
  Stream<int?> get width => _widthSubject.stream;
  @override
  Stream<int?> get height => _heightSubject.stream;

  @override
  Stream<double?> get volume => throw UnimplementedError();

  @override
  void setVolume(double value) {
    throw UnimplementedError();
  }

  @override
  void stop() {
    _player.stop();
  }
}
