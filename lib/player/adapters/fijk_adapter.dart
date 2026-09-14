import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../models/player_state.dart';
import '../models/player_exception.dart';
import '../models/player_error_type.dart';

import 'package:flutter/material.dart';

import '../interface/unified_player_interface.dart';

import 'package:pure_live/player/utils/fijk_helper.dart';
import 'package:pure_live/player/models/player_engine.dart';
import 'package:pure_live/player/interface/fijk_player_accessor.dart';
import 'package:pure_live/player/core/playback_proxy_policy.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:flv_lzc/fijkplayer.dart';

class FijkAdapter
    implements
        UnifiedPlayer,
        FijkPlayerAccessor,
        VideoFitAwarePlayer,
        SourceTransitionAwarePlayer,
        PrivateInputAwarePlayer,
        AudioOutputSuppressionAwarePlayer {
  bool _privateInput = false;
  bool _audioOutputSuppressed = false;
  @override
  void setPrivateInput(bool value, {String? sourceIdentity}) => _privateInput = value;
  @override
  void setAudioOutputSuppressed(bool suppressed) => _audioOutputSuppressed = suppressed;
  late final FijkPlayer _player;

  bool _initialized = false;
  bool _disposed = false;
  bool _isAudioOnly = false;
  bool _sourceTransitionPrepared = false;
  bool _acceptSourceEvents = false;
  bool _sourceOpening = false;
  bool _sourceBuffering = false;
  PlayerException? _deferredSourceError;
  BoxFit _videoFit = BoxFit.contain;
  VoidCallback? _playerListener;

  final _stateSubject = BehaviorSubject<PlayerState>.seeded(PlayerState.idle);
  final _playingSubject = BehaviorSubject<bool>.seeded(false);
  final _loadingSubject = BehaviorSubject<bool>.seeded(false);

  final _errorSubject = PublishSubject<PlayerException>();

  final _completeSubject = BehaviorSubject<bool>.seeded(false);
  final _widthSubject = BehaviorSubject<int?>.seeded(null);
  final _heightSubject = BehaviorSubject<int?>.seeded(null);

  final List<StreamSubscription> _subscriptions = [];

  @override
  Future<void> init({bool audioOnly = false}) async {
    if (_initialized) return;

    _isAudioOnly = audioOnly;

    try {
      _stateSubject.add(PlayerState.initializing);
      _player = FijkPlayer();
      if (audioOnly) {
        await applyAudioOnlySettings();
      }
      _bindListeners();
      _initialized = true;
      _stateSubject.add(PlayerState.initialized);
    } catch (e, s) {
      final exception = PlayerException(
        message: 'Fijk init failed',
        type: PlayerErrorType.initialization,
        error: e,
        stackTrace: s,
      );
      _safeAddError(exception);
      throw exception;
    }
  }

  void _bindListeners() {
    // 先移除旧监听
    _removePlayerListener();

    // Fijk sends freeze=start/end on a separate stream; its native state can
    // remain started throughout buffering. Track it inside this source scope,
    // since FijkPlayer.isBuffering itself survives reset into the next source.
    _subscriptions.add(
      _player.onBufferStateUpdate.listen((buffering) {
        if (!_acceptSourceEvents || _disposed) return;
        final state = _player.state;
        if (state == FijkState.idle ||
            state == FijkState.stopped ||
            state == FijkState.completed ||
            state == FijkState.end ||
            state == FijkState.error) {
          return;
        }
        _sourceBuffering = buffering;
        if (state == FijkState.started) _publishStartedState();
      }),
    );

    _playerListener = () {
      if (!_acceptSourceEvents || _disposed) return;
      final value = _player.value;
      final state = value.state;

      if (value.size != null) {
        final w = value.size!.width.toInt();
        final h = value.size!.height.toInt();
        if (_widthSubject.value != w || _heightSubject.value != h) {
          _widthSubject.add(w);
          _heightSubject.add(h);
        }
      }

      switch (state) {
        case FijkState.asyncPreparing:
        case FijkState.prepared:
          _loadingSubject.add(true);
          _stateSubject.add(PlayerState.buffering);
          break;
        case FijkState.started:
          _publishStartedState();
          break;
        case FijkState.paused:
          _playingSubject.add(false);
          _loadingSubject.add(false);
          _stateSubject.add(PlayerState.paused);
          break;
        case FijkState.completed:
          _playingSubject.add(false);
          _loadingSubject.add(false);
          _completeSubject.add(true);
          _stateSubject.add(PlayerState.completed);
          break;
        case FijkState.error:
          _loadingSubject.add(false);
          _playingSubject.add(false);
          final nativeException = value.exception;
          final exception = PlayerException(
            message: 'Fijk error ${nativeException.code}: ${nativeException.message ?? 'native playback failure'}',
            type: _classifyFijkError(nativeException),
            code: 'fijk_${nativeException.code}',
            error: nativeException,
          );
          if (_sourceOpening) {
            _deferredSourceError = exception;
          } else {
            _safeAddError(exception);
          }
          // The manager owns line/engine replacement. Resetting here launched
          // an unawaited native teardown concurrently with that replacement,
          // producing intermittent Surface and decoder races.
          break;
        default:
          break;
      }
    };

    _player.addListener(_playerListener!);
  }

  void _publishStartedState() {
    if (_loadingSubject.value != _sourceBuffering) _loadingSubject.add(_sourceBuffering);
    if (!_playingSubject.value) _playingSubject.add(true);
    final state = _sourceBuffering ? PlayerState.buffering : PlayerState.playing;
    if (_stateSubject.value != state) _stateSubject.add(state);
  }

  Future<void> _cancelAllSubscriptions() async {
    _removePlayerListener();

    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
  }

  void _removePlayerListener() {
    if (_playerListener != null) {
      _player.removeListener(_playerListener!);
      _playerListener = null;
    }
  }

  void _safeAddError(PlayerException exception) {
    if (_disposed || _errorSubject.isClosed) return;
    _errorSubject.add(exception);
  }

  static PlayerErrorType _classifyFijkError(FijkException exception) {
    switch (exception.code) {
      case FijkException.noDecoder:
        return PlayerErrorType.codec;
      case FijkException.localIOe:
      case FijkException.http5xx:
        return PlayerErrorType.network;
      case FijkException.local404:
      case FijkException.noDemuxer:
      case FijkException.badData:
      case FijkException.noProtocol:
      case FijkException.noStream:
      case FijkException.http400:
      case FijkException.http401:
      case FijkException.http403:
      case FijkException.http404:
      case FijkException.http4xx:
        return PlayerErrorType.source;
      default:
        return PlayerErrorType.native;
    }
  }

  Future<void> _setupProxy({required bool privateInput}) async {
    await _player.setOption(
      FijkOption.formatCategory,
      "http_proxy",
      PlaybackProxyPolicy.currentNativeUrl(privateInput: privateInput),
    );
  }

  @override
  void beginSourceTransition() {
    if (_disposed) return;
    _acceptSourceEvents = false;
    _sourceTransitionPrepared = true;
    _sourceOpening = false;
    _sourceBuffering = false;
    _deferredSourceError = null;
    _playingSubject.add(false);
    _loadingSubject.add(true);
    _completeSubject.add(false);
    _widthSubject.add(null);
    _heightSubject.add(null);
  }

  void _consumeSourceTransition() {
    if (!_sourceTransitionPrepared) beginSourceTransition();
    _sourceTransitionPrepared = false;
  }

  void _publishCurrentSourceState() {
    if (!_acceptSourceEvents || _disposed) return;
    final value = _player.value;
    final size = value.size;
    if (size != null && size.width > 0 && size.height > 0) {
      _widthSubject.add(size.width.toInt());
      _heightSubject.add(size.height.toInt());
    }
    if (value.state == FijkState.started) {
      _publishStartedState();
    }
  }

  @override
  Future<void> setDataSource(
    String url,
    List<String> playUrls,
    Map<String, String> headers, {
    LiveRoom? room,
    bool audioOnly = false,
  }) async {
    final privateInput = _privateInput;
    _privateInput = false;
    _consumeSourceTransition();
    try {
      _isAudioOnly = audioOnly;
      if (_player.state != FijkState.idle) {
        await _player.reset();
      }
      await _setupProxy(privateInput: privateInput);
      await FijkHelper.setFijkOption(
        _player,
        enableCodec: SettingsService.to.playerState.enableCodec,
        disableAudioOutput: _audioOutputSuppressed,
        headers: headers,
      );

      // Native prepare can enter FijkState.error before the Future completes.
      // Enabling the source listener afterwards lost that sole callback and
      // left the fallback orchestrator waiting forever.
      _sourceOpening = true;
      _acceptSourceEvents = true;
      await _player.setDataSource(url, autoPlay: true);
      _sourceOpening = false;
      final deferredError = _deferredSourceError;
      _deferredSourceError = null;
      if (deferredError != null && _player.value.state == FijkState.error) {
        throw deferredError;
      }
      _publishCurrentSourceState();
      if (!_playingSubject.value && _stateSubject.value != PlayerState.buffering) {
        _stateSubject.add(PlayerState.ready);
      }
      await setVolume(_audioOutputSuppressed ? 0.0 : 1.0);
    } catch (e, s) {
      _sourceOpening = false;
      _acceptSourceEvents = false;
      final exception = e is PlayerException
          ? e
          : PlayerException(
              message: 'Fijk setDataSource failed',
              type: PlayerErrorType.source,
              error: e,
              stackTrace: s,
            );
      _safeAddError(exception);
      throw exception;
    }
  }

  @override
  Widget getVideoWidget({BoxFit? fit}) {
    if (_isAudioOnly) {
      return const SizedBox.shrink();
    }
    final effectiveFit = fit ?? _videoFit;
    _videoFit = effectiveFit;
    return FijkView(
      player: _player,
      fit: FijkHelper.getIjkBoxFit(effectiveFit),
      fs: false,
      color: Colors.black,
      panelBuilder: (FijkPlayer fijkPlayer, FijkData fijkData, BuildContext context, Size viewSize, Rect texturePos) {
        return const SizedBox();
      },
    );
  }

  @override
  void setVideoFit(BoxFit fit) {
    _videoFit = fit;
  }

  @override
  Future<void> play() => _player.start();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> softStop() async {
    if (!_initialized) return;
    _acceptSourceEvents = false;
    _sourceBuffering = false;
    await _player.reset();
    _playingSubject.add(false);
    _loadingSubject.add(false);
    _stateSubject.add(PlayerState.idle);
  }

  @override
  Future<void> setAudioOnly(bool audioOnly) async {
    if (_disposed || _isAudioOnly == audioOnly) return;
    await _player.setOption(FijkOption.playerCategory, "disable-vid", audioOnly ? "1" : "0");
    _isAudioOnly = audioOnly;
  }

  Future<void> applyAudioOnlySettings() async {
    await _player.setOption(FijkOption.playerCategory, "disable-vid", "1");
  }

  @override
  Future<void> hardDispose() async {
    if (_disposed) return;
    _disposed = true;

    //  取消所有监听
    await _cancelAllSubscriptions();

    try {
      await _player.release();
    } catch (_) {}

    _initialized = false;

    // 关闭所有流
    await _stateSubject.close();
    await _playingSubject.close();
    await _loadingSubject.close();
    await _errorSubject.close();
    await _completeSubject.close();
    await _widthSubject.close();
    await _heightSubject.close();
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  // =========================
  // GETTER
  // =========================
  @override
  bool get isInitialized => _initialized;
  @override
  bool get isPlayingNow => _playingSubject.value;
  @override
  bool get isReusable => true;

  @override
  Stream<PlayerState> get onStateChanged => _stateSubject.stream;
  @override
  Stream<bool> get onPlaying => _playingSubject.stream;
  @override
  Stream<PlayerException> get onError => _errorSubject.stream;
  @override
  Stream<bool> get onLoading => _loadingSubject.stream;
  @override
  Stream<bool> get onComplete => _completeSubject.stream;
  @override
  Stream<int?> get width => _widthSubject.stream;
  @override
  Stream<int?> get height => _heightSubject.stream;

  @override
  PlayerEngine get engine => PlayerEngine.fijk;

  @override
  FijkPlayer get fijkPlayer => _player;
}
