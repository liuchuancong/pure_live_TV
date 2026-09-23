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
    this.hasStartedPlayback = false,
    this.switchingStream = false,
    this.isOffline = false,
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

  /// Whether this room has already painted a playing stream at least once.
  ///
  /// The full-screen spinner belongs to the *first* connection of a room. A
  /// quality or CDN-line switch reopens the source on the same native player, so
  /// it must not re-enter the "no picture yet" state: the reference client shows
  /// no overlay there at all, which is why its switch reads as a silent
  /// background update while the TV flashed its buffering spinner.
  final bool hasStartedPlayback;

  /// The room loaded successfully but is not broadcasting.
  ///
  /// Kept apart from [errorMessage]: nothing failed here — the stream simply
  /// does not exist yet, so asking the site for play URLs would be pointless
  /// and presenting a retry-an-error overlay would mislead. The page shows the
  /// "not living" placeholder with a channel switcher instead.
  final bool isOffline;

  /// Whether a quality/line change is currently being resolved and opened.
  ///
  /// Only a small indicator inside the selector uses this; the picture and the
  /// control bar stay exactly as they were.
  final bool switchingStream;

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
    bool? hasStartedPlayback,
    bool? switchingStream,
    bool? isOffline,
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
      hasStartedPlayback: hasStartedPlayback ?? this.hasStartedPlayback,
      switchingStream: switchingStream ?? this.switchingStream,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}
