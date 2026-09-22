import 'package:media_core/core/player_state.dart';
import 'package:pure_live/exports/common_export.dart';

/// Which side panel is currently shown.
///
/// Only one panel is visible at a time, matching the legacy live_play app.
enum LivePlayPanel { danmakuSettings, playlist, shield }

class LivePlayState {
  const LivePlayState({
    this.room,
    this.detailError,
    this.qualities = const <LivePlayQuality>[],
    this.qualityIndex = 0,
    this.playUrls = const <String>[],
    this.lineIndex = 0,
    required this.playerState,
    this.errorMessage,
    this.showControls = false,
    this.fitIndex = 0,
    this.volume = 1.0,
    this.showSidePanel = false,
    this.panel,
    this.channelBanner,
  });

  final LiveRoom? room;
  final String? detailError;
  final List<LivePlayQuality> qualities;
  final int qualityIndex;
  final List<String> playUrls;
  final int lineIndex;

  /// Playback state owned by media_core.
  ///
  /// The page should use this directly instead of maintaining another
  /// LivePlayStatus enum.
  final PlayerState playerState;

  /// Business/UI error message.
  ///
  /// This is intentionally separate from [playerState], because errors such
  /// as room-detail or stream-url requests are not player playback states.
  final String? errorMessage;

  final bool showControls;
  final int fitIndex;
  final double volume;
  final bool showSidePanel;
  final LivePlayPanel? panel;
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
    PlayerState? playerState,
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
      playerState: playerState ?? this.playerState,
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
