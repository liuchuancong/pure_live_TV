import 'package:pure_live/exports/common_export.dart';

/// UI-visible state of one playback session.
enum LivePlayStatus { idle, loadingDetail, preparing, buffering, playing, paused, error }

class LivePlayState {
  const LivePlayState({
    this.room,
    this.detailError,
    this.qualities = const <LivePlayQuality>[],
    this.qualityIndex = 0,
    this.playUrls = const <String>[],
    this.lineIndex = 0,
    this.status = LivePlayStatus.idle,
    this.errorMessage,
    this.showControls = false,
    this.fitIndex = 0,
    this.volume = 1.0,
    this.showSidePanel = true,
  });

  final LiveRoom? room;
  final String? detailError;
  final List<LivePlayQuality> qualities;
  final int qualityIndex;
  final List<String> playUrls;
  final int lineIndex;
  final LivePlayStatus status;
  final String? errorMessage;

  /// 视频区控制面板是否可见（TV 遥控器 OK 键呼出/隐藏，自动隐藏）。
  final bool showControls;

  /// 画面比例索引（PlayerManager.videoFitIndex 的镜像）。
  final int fitIndex;

  /// 当前音量 0.0 - 1.0。
  final double volume;

  /// 右侧信息/弹幕面板是否可见。
  final bool showSidePanel;

  LivePlayState copyWith({
    LiveRoom? room,
    bool clearRoom = false,
    String? detailError,
    bool clearDetailError = false,
    List<LivePlayQuality>? qualities,
    int? qualityIndex,
    List<String>? playUrls,
    int? lineIndex,
    LivePlayStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? showControls,
    int? fitIndex,
    double? volume,
    bool? showSidePanel,
  }) {
    return LivePlayState(
      room: clearRoom ? null : (room ?? this.room),
      detailError: clearDetailError ? null : (detailError ?? this.detailError),
      qualities: qualities ?? this.qualities,
      qualityIndex: qualityIndex ?? this.qualityIndex,
      playUrls: playUrls ?? this.playUrls,
      lineIndex: lineIndex ?? this.lineIndex,
      status: status ?? this.status,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      showControls: showControls ?? this.showControls,
      fitIndex: fitIndex ?? this.fitIndex,
      volume: volume ?? this.volume,
      showSidePanel: showSidePanel ?? this.showSidePanel,
    );
  }
}
