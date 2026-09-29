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
    this.showRoomInfo = false,
    this.fitIndex = 0,
    this.volume = 1.0,
    this.showSidePanel = false,
    this.panel,
    this.channelBanner,
    this.hasStartedPlayback = false,
    this.switchingStream = false,
    this.isOffline = false,
    this.fetchingDetail = false,
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
  /// Separate from [playerState], because errors such
  /// as room-detail or stream-url requests are not player playback states.
  final String? errorMessage;

  /// The bottom control bar: quality, lines, fit, audio mode.
  final bool showControls;

  /// The room card at the top: title, platform, streamer, audience, clock.
  ///
  /// Separate from [showControls] so that entering a room can show what is
  /// playing without the control bar covering the bottom of the picture.
  final bool showRoomInfo;
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

  /// The site's room-detail request is in flight.
  ///
  /// The player seeds [room] from the playlist entry it was opened with, so the
  /// info card renders immediately; this flag tells the page that the seeded
  /// data is a hint and the site response is still pending.
  final bool fetchingDetail;

  /// Whether a quality/line change is currently being resolved and opened.
  ///
  /// Only a small indicator inside the selector uses this; the picture and the
  /// control bar stay exactly as they were.
  final bool switchingStream;

  bool get showChannelBanner => channelBanner != null && channelBanner!.isNotEmpty;

  /// Whether the failure overlay owns the picture.
  ///
  /// Both blocking overlays (this one and the "not living" placeholder) are
  /// full-screen, carry their own focusable buttons, and therefore have to be
  /// known to the page-level key handler: while one is up it must let ←/→/OK
  /// through to those buttons instead of eating OK as "show the controls".
  bool get showFailureOverlay =>
      !isOffline && (errorMessage != null || detailError != null || playerState.hasError);

  /// Whether a blocking overlay (failure or offline) is covering the picture.
  bool get hasBlockingOverlay => isOffline || showFailureOverlay;

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
    bool? showRoomInfo,
    int? fitIndex,
    double? volume,
    bool? showSidePanel,
    LivePlayPanel? panel,
    String? channelBanner,
    bool clearChannelBanner = false,
    bool? hasStartedPlayback,
    bool? switchingStream,
    bool? isOffline,
    bool? fetchingDetail,
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
      showRoomInfo: showRoomInfo ?? this.showRoomInfo,
      fitIndex: fitIndex ?? this.fitIndex,
      volume: volume ?? this.volume,
      showSidePanel: showSidePanel ?? this.showSidePanel,
      panel: panel ?? this.panel,
      channelBanner: clearChannelBanner ? null : (channelBanner ?? this.channelBanner),
      hasStartedPlayback: hasStartedPlayback ?? this.hasStartedPlayback,
      switchingStream: switchingStream ?? this.switchingStream,
      isOffline: isOffline ?? this.isOffline,
      fetchingDetail: fetchingDetail ?? this.fetchingDetail,
    );
  }
}
