import 'package:pure_live/exports/common_export.dart';

/// UI-visible state of one playback session.
enum LivePlayStatus { idle, loadingDetail, preparing, buffering, playing, paused, error }

/// 右侧面板当前展示的内容。
///
/// 同一时刻只展示一个面板（与老项目 live_play 的面板互斥逻辑一致），
/// 切换面板通过 [LivePlayState.panel] + [LivePlayState.showSidePanel] 控制。
enum LivePlayPanel {
  /// 房间信息 + 清晰度 / 线路 + 弹幕列表
  info,

  /// 播放列表（换台）
  playlist,

  /// 弹幕设置（大小 / 速度 / 区域 / 透明度 / 描边）
  danmakuSettings,

  /// 弹幕过滤（屏蔽词）
  shield,
}

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
    this.panel = LivePlayPanel.info,
    this.channelBanner,
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

  /// 右侧面板当前展示的内容。
  final LivePlayPanel panel;

  /// 上下键切台时的频道名提示条文本；为空表示不展示。
  final String? channelBanner;

  bool get showChannelBanner => channelBanner != null && channelBanner!.isNotEmpty;

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
    LivePlayPanel? panel,
    String? channelBanner,
    bool clearChannelBanner = false,
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
      panel: panel ?? this.panel,
      channelBanner: clearChannelBanner ? null : (channelBanner ?? this.channelBanner),
    );
  }
}
