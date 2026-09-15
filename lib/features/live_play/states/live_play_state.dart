import 'package:pure_live/exports/common_export.dart';

/// UI-visible state of one playback session.
enum LivePlayStatus { idle, loadingDetail, preparing, buffering, playing, paused, error }

/// Which side panel is currently shown.
///
/// Only one panel is visible at a time, matching the legacy live_play app.
/// Switching is driven by [LivePlayState.panel] and
/// [LivePlayState.showSidePanel].
enum LivePlayPanel {
  /// Room info, quality and line pickers, and the danmaku list.
  info,

  /// Playlist, used for channel switching.
  playlist,

  /// Danmaku settings: size, speed, area, opacity and stroke.
  danmakuSettings,

  /// Danmaku filter, by blocked word.
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

  /// Whether the video control bar is visible. The remote toggles it with OK and
  /// it hides itself automatically.
  final bool showControls;

  /// Aspect ratio index, mirroring PlayerManager.videoFitIndex.
  final int fitIndex;

  /// Current volume, 0.0 to 1.0.
  final double volume;

  /// Whether the side info and danmaku panel is visible.
  final bool showSidePanel;

  /// Which side panel is currently shown.
  final LivePlayPanel panel;

  /// Channel name toast shown after an up/down switch; empty hides it.
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
