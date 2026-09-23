import 'dart:async';
import 'dart:developer';
import 'package:flutter/painting.dart';
import 'package:pure_live/player/index.dart';
import 'package:flame_barrage/flame_barrage.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:media_core/core/player_state.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:media_core/error/player_failure.dart';
import 'package:media_core/error/error_formatter.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/states/live_play_state.dart';
import 'package:pure_live/features/live_play/controllers/danmaku_filters.dart';
import 'package:pure_live/features/live_play/services/live_play_repository.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';

part 'live_play_controller.g.dart';

/// Aspect ratio options, aligned with the index semantics of
/// PlayerManager.changeVideoFit and the stored settings index.
List<BoxFit> get kLivePlayFitList => AppThemeConsts.videoFitList;

/// Localized labels of [kLivePlayFitList] in the same order as the stored index.
List<String> get kLivePlayFitLabels => AppThemeConsts.videoFitType.map((e) => i18n(e['desc'] as String)).toList();

/// Drives one live room: detail/quality/URL fetching, playback state
/// projection, quality and line switching. Danmaku sessions live in
/// [DanmakuSessionController].
@riverpod
class LivePlayController extends _$LivePlayController {
  static const LivePlayRepository _repository = LivePlayRepository();

  LivePlayerFacade? _playerManager;

  final List<StreamSubscription<dynamic>> _subscriptions = <StreamSubscription<dynamic>>[];

  /// Async bootstrap generation: stale callbacks are dropped after a retry or
  /// rebuild.
  int _generation = 0;

  /// How long a loading state may last before the UI calls it a failure.
  ///
  /// Recovery runs inside media_core, and a stream that offers more than one
  /// line keeps it cycling between them: every pass re-opens a line and re-enters
  /// buffering without spending an attempt, so the terminal error that would
  /// reach the UI is never produced. The watchdogs do not cover it either - they
  /// only watch a playback that already started. Without this deadline the
  /// spinner is the last word on screen and the remote has nothing left to press.
  static const Duration _stallReportTimeout = Duration(seconds: 30);

  Timer? _stallReportTimer;

  @override
  LivePlayState build(LivePlayArgs args) {
    ref.onDispose(_teardown);

    ref.listen(playerSettingsControllerProvider, (prev, next) {
      if (prev?.videoPlayerKey != next.videoPlayerKey) {
        _bootstrap();
      }
    });

    // Register the current-room lookup with the site layer, which needs it for
    // viewer counts and error recovery.
    Sites.currentRoomLookup = (platform, roomId) {
      final room = state.room;

      return room != null && room.platform == platform && room.roomId == roomId ? room : null;
    };

    // Microtask-deferred: build has no state yet while it runs, and reading
    // it now throws "uninitialized provider".
    Future<void>.microtask(_bootstrap);

    return LivePlayState(playerState: PlayerState());
  }

  // =========================
  // bootstrap / teardown
  // =========================

  Future<void> _bootstrap() async {
    final generation = ++_generation;

    _armStallReport(restart: true);

    // A fresh session (first room, or a new kernel) starts without a picture, so
    // the loading overlay is armed again. Switching quality or line never comes
    // through here, which is why the picture survives those.
    state = state.copyWith(
      clearDetailError: true,
      clearErrorMessage: true,
      hasStartedPlayback: false,
      switchingStream: false,
    );

    try {
      // Bring the service up on the stored kernel, not a hardcoded default.
      await GlobalPlayerService.instance.initialize(
        defaultEngine: PlayerConsts.engines[SettingsService.to.playerState.videoPlayerKey] ?? PlayerEngine.mediaKit,
      );
    } catch (e, s) {
      log('GlobalPlayerService initialize failed: $e', name: 'LivePlayController', error: e, stackTrace: s);
    }

    if (!_isCurrent(generation)) return;

    _playerManager = GlobalPlayerService.instance.livePlayer;
    _bindPlayerStreams();
    _applyStoredVideoFit();

    // Room details: the LiveRoom carried by the route only hints at platform and
    // room id; the site response is authoritative.
    LiveRoom detail;

    try {
      detail = await _repository.fetchRoomDetail(hintRoom: args.room ?? _hintRoom());
    } catch (e) {
      if (!_isCurrent(generation)) return;

      state = state.copyWith(
        detailError: i18n('get_room_info_failed_retry'),
        errorMessage: i18n('get_room_info_failed_retry'),
      );

      return;
    }

    if (!_isCurrent(generation)) return;

    state = state.copyWith(room: detail, clearDetailError: true);

    // Align the displayed volume with the volume remembered for the room; the
    // player restores the same value on start.
    state = state.copyWith(volume: detail.getSavedVolume().clamp(0.0, 1.0).toDouble());

    // Entering a room writes to watch history, which doubles as the channel list
    // when the route carried no playlist.
    try {
      SettingsService.to.history.addRoomToHistory(detail);
    } catch (e) {
      log('addRoomToHistory failed: $e', name: 'LivePlayController');
    }

    // When the entry came from a channel switch, show the channel name first.
    if (args.showChannelBanner) {
      showChannelBanner(detail.nick.isNotEmpty ? detail.nick : detail.title);
    }

    // A TV room is always fullscreen, so the controls are never pinned: they
    // appear for a few seconds on entry (quality and line switching are then one
    // press away) and hide themselves again.
    showControls();
    _holdScreenAwake();

    unawaited(ref.read(danmakuSessionControllerProvider(args).notifier).connectRoom(detail));

    await loadQualitiesAndPlay(detail, generation);
  }

  LiveRoom _hintRoom() => LiveRoom(roomId: args.roomId, platform: args.platform);

  bool _isCurrent(int generation) => ref.mounted && generation == _generation;

  /// Starts the loading deadline. An already running one is kept unless
  /// [restart] is set, so media_core cycling through lines cannot push the
  /// deadline forward forever.
  void _armStallReport({bool restart = false}) {
    if (_stallReportTimer != null && !restart) return;

    _stallReportTimer?.cancel();

    _stallReportTimer = Timer(_stallReportTimeout, _reportStalledLoad);
  }

  void _cancelStallReport() {
    _stallReportTimer?.cancel();
    _stallReportTimer = null;
  }

  /// Turns a load that never resolved into a failure the user can act on.
  ///
  /// The actual playback state comes from media_core. Room-detail loading is
  /// represented by [state.room] still being null.
  void _reportStalledLoad() {
    _stallReportTimer = null;

    if (!ref.mounted) return;

    final playerState = state.playerState;

    final loading = state.room == null || playerState.opening || playerState.buffering;

    if (!loading) return;

    state = state.copyWith(errorMessage: i18n('multiview_play_failed'));
  }

  void _bindPlayerStreams() {
    final manager = _playerManager;

    if (manager == null) return;

    _cancelSubscriptions();

    _subscriptions.addAll(<StreamSubscription<dynamic>>[
      manager.onStateChanged.listen(_onPlayerStateChanged),
      manager.onError.listen(_onPlayerError),
      manager.videoFitIndex.stream.listen((index) {
        if (index != state.fitIndex) {
          state = state.copyWith(fitIndex: index);
        }
      }),
    ]);
  }

  /// media_core is the single source of truth for playback state.
  ///
  /// No local LivePlayStatus is maintained here.
  void _onPlayerStateChanged(PlayerState playerState) {
    if (!ref.mounted) return;

    // Once a room has played, the loading overlay stays down for the rest of the
    // session: quality/line switches and ordinary live re-buffering reopen on the
    // same player and must not blank the picture with a spinner. Only a new
    // session (another room, another kernel) arms it again.
    final bool started = state.hasStartedPlayback || playerState.playing || playerState.ready;

    state = state.copyWith(playerState: playerState, hasStartedPlayback: started);

    if (playerState.playing || playerState.ready) {
      _cancelStallReport();
    } else if (playerState.opening || playerState.buffering) {
      // Deliberately not restarted: media_core may re-enter buffering once per
      // line, and each pass would otherwise push back the deadline.
      _armStallReport();
    } else if (playerState.hasError) {
      _cancelStallReport();
    }
  }

  /// Keeps the screen awake for as long as the player route is open.
  ///
  /// This is not a setting on a TV: the screen must never dim or start its
  /// screen saver in the middle of a stream, and while this controller is alive
  /// the player route is the only thing on screen. The lock is released in
  /// [_teardown].
  void _holdScreenAwake() {
    unawaited(WakelockPlus.enable().catchError((Object _) {}));
  }

  /// Terminal playback failure from media_core.
  ///
  /// The facade hands over the structured [PlayerFailure]; we render it into a
  /// user-facing sentence through [ErrorFormatter]. The failure's code and
  /// category stay available on the object if a future UI needs to branch on
  /// them (network / decode / backend), but [LivePlayState] only carries the
  /// final string.
  void _onPlayerError(PlayerFailure failure) {
    if (!ref.mounted) return;
    _cancelStallReport();
    Log.d(ErrorFormatter.format(failure));
    state = state.copyWith(errorMessage: ErrorFormatter.format(failure));
  }

  void _teardown() {
    _generation++;

    _cancelStallReport();
    _cancelSubscriptions();

    _channelBannerTimer?.cancel();
    _channelBannerTimer = null;

    // Leaving the room releases the wake lock even when a new room follows.
    unawaited(WakelockPlus.disable().catchError((Object _) {}));

    final manager = _playerManager;
    _playerManager = null;

    if (manager != null) {
      // PlayerManager is a global singleton, so leaving a room stops this session.
      unawaited(manager.close().catchError((Object e, StackTrace s) {}));
    }
  }

  void _cancelSubscriptions() {
    if (_subscriptions.isEmpty) return;

    final list = List<StreamSubscription<dynamic>>.of(_subscriptions);

    _subscriptions.clear();

    for (final sub in list) {
      unawaited(sub.cancel().catchError((Object e, StackTrace s) {}));
    }
  }

  // =========================
  // stream loading
  // =========================

  Future<void> loadQualitiesAndPlay(LiveRoom detail, int generation) async {
    final qualities = await _repository.fetchPlayQualities(detail);

    if (!_isCurrent(generation)) return;

    if (qualities.isEmpty) {
      state = state.copyWith(
        qualities: const <LivePlayQuality>[],
        qualityIndex: 0,
        errorMessage: i18n('stream_no_available_quality'),
      );

      return;
    }

    final preferredIndex = _resolvePreferredQualityIndex(qualities);

    state = state.copyWith(qualities: qualities, qualityIndex: preferredIndex);

    await _openStream(qualities[preferredIndex], generation);
  }

  int _resolvePreferredQualityIndex(List<LivePlayQuality> qualities) {
    // Pick the quality that best matches the preferred resolution; otherwise
    // fall back to the highest bitrate.
    final prefer = SettingsService.to.playerState.preferResolution;

    if (prefer.isNotEmpty) {
      var bestScore = 0;
      var bestIndex = -1;

      for (var i = 0; i < qualities.length; i++) {
        final score = PlayerConsts.resolutionMatchScore(prefer, qualities[i].quality);

        if (score > bestScore) {
          bestScore = score;
          bestIndex = i;
        }
      }

      if (bestIndex != -1) return bestIndex;
    }

    var best = 0;

    for (var i = 1; i < qualities.length; i++) {
      if (qualities[i].sort > qualities[best].sort) {
        best = i;
      }
    }

    return best;
  }

  Future<void> _openStream(LivePlayQuality quality, int generation) async {
    final detail = state.room;
    final manager = _playerManager;

    if (detail == null || manager == null) return;

    state = state.copyWith(clearErrorMessage: true);

    List<String> urls;

    try {
      urls = await _repository.fetchPlayUrls(detail, quality);
    } catch (e) {
      if (!_isCurrent(generation)) return;

      state = state.copyWith(errorMessage: i18n('stream_fetch_url_failed'));

      return;
    }

    if (!_isCurrent(generation)) return;

    urls = urls.where((u) => u.trim().isNotEmpty).toList(growable: false);

    if (urls.isEmpty) {
      state = state.copyWith(errorMessage: i18n('stream_no_available_line'));

      return;
    }

    // A quality change may return a different number of CDN lines, so the line
    // the viewer is on is re-clamped rather than reset: the reference client
    // keeps the same line across a quality switch instead of jumping back to the
    // first one.
    final int line = state.lineIndex.clamp(0, urls.length - 1);

    state = state.copyWith(playUrls: urls, lineIndex: line);

    try {
      await manager.play(urls[line], urls, const <String, String>{}, room: detail);
    } on ArgumentError catch (e) {
      if (!_isCurrent(generation)) return;

      state = state.copyWith(errorMessage: e.message ?? i18n('stream_start_invalid_params'));
    } catch (e) {
      if (!_isCurrent(generation)) return;

      state = state.copyWith(errorMessage: i18n('stream_start_failed'));
    }
  }

  // =========================
  // user commands
  // =========================

  Future<void> changeQuality(int index) async {
    if (index < 0 || index >= state.qualities.length || index == state.qualityIndex) {
      return;
    }

    final generation = ++_generation;

    _armStallReport(restart: true);

    // The picture keeps running while the new URLs are resolved: the switch is
    // announced only inside the selector, never over the video.
    state = state.copyWith(qualityIndex: index, switchingStream: true);

    try {
      await _openStream(state.qualities[index], generation);
    } finally {
      if (_isCurrent(generation)) {
        state = state.copyWith(switchingStream: false);
      }
    }
  }

  Future<void> changeLine(int index) async {
    if (index < 0 || index >= state.playUrls.length || index == state.lineIndex) {
      return;
    }

    final manager = _playerManager;

    if (manager == null) return;

    final urls = state.playUrls;

    _armStallReport(restart: true);

    state = state.copyWith(lineIndex: index, clearErrorMessage: true, switchingStream: true);

    try {
      await manager.play(urls[index], urls, const <String, String>{}, room: state.room);
    } catch (e) {
      if (!ref.mounted) return;

      state = state.copyWith(errorMessage: i18n('stream_switch_line_failed'));
    } finally {
      if (ref.mounted) {
        state = state.copyWith(switchingStream: false);
      }
    }
  }

  Future<void> togglePlayPause() async {
    final manager = _playerManager;

    if (manager == null) return;

    await manager.togglePlayPause();
  }

  Future<void> retry() async {
    final manager = _playerManager;

    if (manager == null || !manager.initialized) {
      await _bootstrap();
      return;
    }

    _armStallReport(restart: true);

    state = state.copyWith(clearErrorMessage: true);

    try {
      await manager.retry();
    } catch (e) {
      if (!ref.mounted) return;

      state = state.copyWith(errorMessage: i18n('play_video_failed'));
    }
  }

  /// Refetches room details and lines, then starts playback. Used for a full
  /// refresh after a long offline period.
  Future<void> refreshRoom() async {
    _generation++;
    _cancelSubscriptions();

    await _bootstrap();
  }

  /// Applies and persists the aspect ratio at [index]; called from the
  /// fullscreen control bar's aspect ratio dialog.
  void setFit(int index) {
    final options = kLivePlayFitList;

    if (index < 0 || index >= options.length || index == state.fitIndex) {
      return;
    }

    ref
        .read(playerSettingsControllerProvider.notifier)
        .updateSettings(ref.read(playerSettingsControllerProvider).copyWith(videoFitIndex: index));

    state = state.copyWith(fitIndex: index);

    _playerManager?.changeVideoFit(index);
  }

  /// Applies the fit mode saved in settings to the current playback session.
  ///
  /// Without this the room always started with the first option even though the
  /// settings page showed the user's choice.
  void _applyStoredVideoFit() {
    final manager = _playerManager;

    if (manager == null) return;

    final stored = PlayerSettingsController.normalizeVideoFitIndex(
      ref.read(playerSettingsControllerProvider).videoFitIndex,
    );

    state = state.copyWith(fitIndex: stored);

    manager.changeVideoFit(stored);
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0).toDouble();

    state = state.copyWith(volume: clamped);

    await _playerManager?.setVolume(clamped);

    final room = state.room;

    if (room != null) {
      unawaited(room.saveCurrentVolume(clamped).catchError((Object e, StackTrace s) {}));
    }
  }

  Future<void> volumeUp() => setVolume(state.volume + 0.1);

  Future<void> volumeDown() => setVolume(state.volume - 0.1);

  // =========================
  // Channel switching and the playlist.
  // =========================

  /// Channel list: prefer the list carried by the route (the current page of
  /// favourites, popular, areas or search results),
  /// otherwise fall back to the rooms in watch history that are still live.
  List<LiveRoom> get channelRooms {
    if (args.playlist.length > 1) {
      return args.playlist;
    }

    final history = SettingsService.to.historyState.historyRooms
        .where((room) => room.platform != Sites.iptvSite && room.liveStatus == LiveStatus.live)
        .toList(growable: false);

    return history.length > 1 ? history : args.playlist;
  }

  /// Index of the current room in the channel list, or 0 when it is missing.
  int get channelIndex {
    final rooms = channelRooms;
    final current = state.room;

    if (current == null || rooms.isEmpty) return 0;

    final index = rooms.indexWhere((room) => room.hasSameIdentity(current));

    return index < 0 ? 0 : index;
  }

  /// Resolves the target channel for [delta] (-1 previous, 1 next), wrapping
  /// around at the ends.
  ///
  /// A null result means there is nothing to switch to and the caller should
  /// tell the user.
  LiveRoom? relativeChannel(int delta) {
    final rooms = channelRooms;

    if (rooms.length < 2) return null;

    final current = channelIndex;
    final raw = current + delta;

    final next = raw < 0 ? rooms.length - 1 : (raw >= rooms.length ? 0 : raw);

    final target = rooms[next];

    // Switching is pointless when only one playable room exists.
    return state.room != null && target.hasSameIdentity(state.room!) ? null : target;
  }

  // =========================
  // Side panels. Only one is visible at a time.
  // =========================

  /// Switches the side panel; pressing again on the active panel collapses it.
  void togglePanel(LivePlayPanel panel) {
    if (state.showSidePanel && state.panel == panel) {
      state = state.copyWith(showSidePanel: false);
    } else {
      state = state.copyWith(panel: panel, showSidePanel: true);
    }
  }

  /// Opens a panel directly, without the press-again-to-collapse behaviour.
  void openPanel(LivePlayPanel panel) {
    state = state.copyWith(panel: panel, showSidePanel: true);
  }

  // =========================
  // Channel switch toast.
  // =========================

  Timer? _channelBannerTimer;

  /// Shows the channel name for two seconds after an up/down switch.
  void showChannelBanner(String text) {
    _channelBannerTimer?.cancel();

    state = state.copyWith(channelBanner: text);

    _channelBannerTimer = Timer(const Duration(seconds: 2), () {
      if (ref.mounted) {
        state = state.copyWith(clearChannelBanner: true);
      }
    });
  }

  void dismissChannelBanner() {
    _channelBannerTimer?.cancel();
    _channelBannerTimer = null;

    if (state.showChannelBanner) {
      state = state.copyWith(clearChannelBanner: true);
    }
  }

  // =========================
  // controls visibility (TV auto-hide)
  // =========================

  Timer? _controlsHideTimer;

  void showControls() {
    state = state.copyWith(showControls: true);

    _armControlsHide();
  }

  void toggleControls() {
    if (state.showControls) {
      _dismissControls();
    } else {
      showControls();
    }
  }

  void keepControlsAlive() => _armControlsHide();

  void toggleSidePanel() {
    state = state.copyWith(showSidePanel: !state.showSidePanel);
  }

  void _armControlsHide() {
    _controlsHideTimer?.cancel();

    _controlsHideTimer = Timer(const Duration(seconds: 5), _dismissControls);
  }

  void _dismissControls() {
    _controlsHideTimer?.cancel();
    _controlsHideTimer = null;

    if (ref.mounted) {
      state = state.copyWith(showControls: false);
    }
  }
}

/// Danmaku session for one room: owns the transport connection, message
/// gating and duplicate filtering, and fans messages out to the overlay and
/// the list view. Filter thresholds come from the global danmaku settings.
@riverpod
class DanmakuSessionController extends _$DanmakuSessionController {
  final DanmakuMessageGate _messageGate = DanmakuMessageGate();
  final RepeatedDanmakuFilter _repeatedFilter = RepeatedDanmakuFilter();
  final DanmakuSimilarityFilter _similarityFilter = DanmakuSimilarityFilter();

  LiveDanmaku? _engine;
  int _sessionToken = 0;

  @override
  DanmakuSessionState build(LivePlayArgs args) {
    ref.onDispose(_teardown);

    return DanmakuSessionState(barrageController: BarrageController());
  }

  Future<void> connectRoom(LiveRoom room) async {
    final token = ++_sessionToken;
    final controller = state.barrageController;

    // Tear down the old session and clear the render layer so packets from the
    // previous room cannot leak in.
    final oldEngine = _engine;
    _engine = null;

    if (oldEngine != null) {
      oldEngine.onMessage = null;
      oldEngine.onClose = null;

      unawaited(oldEngine.stop().catchError((Object e, StackTrace s) {}));
    }

    _messageGate.clear();
    _repeatedFilter.clear();
    _similarityFilter.clear();
    controller.clear();

    state = state.copyWith(
      messages: const <LiveMessage>[],
      connected: false,
      statusText: i18n('connecting_danmaku_server'),
    );

    LiveDanmaku engine;

    try {
      engine = _repository.createDanmaku(room);
    } catch (e) {
      if (token == _sessionToken && ref.mounted) {
        state = state.copyWith(statusText: i18n('danmaku_unavailable'));
      }

      return;
    }

    _engine = engine;

    engine.onMessage = (msg) => _acceptMessage(msg, token);

    engine.onClose = (msg) {
      if (token == _sessionToken && ref.mounted) {
        state = state.copyWith(connected: false, statusText: i18n('danmaku_disconnected'));
      }
    };

    try {
      await engine.start(room.danmakuData).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      if (token == _sessionToken && ref.mounted) {
        state = state.copyWith(connected: false, statusText: i18n('danmaku_connect_timeout'));
      }

      return;
    } catch (e) {
      if (token == _sessionToken && ref.mounted) {
        state = state.copyWith(connected: false, statusText: i18n('danmaku_connect_failed'));
      }

      return;
    }

    if (token == _sessionToken && ref.mounted) {
      state = state.copyWith(connected: engine.isConnected, statusText: null);
    }
  }

  static const LivePlayRepository _repository = LivePlayRepository();

  void _acceptMessage(LiveMessage message, int token) {
    if (token != _sessionToken || !ref.mounted) return;

    // The danmaku layer only handles chat messages; gifts and entrances go to the
    // list view alone.
    if (message.type != LiveMessageType.chat) return;

    if (!_messageGate.accepts(message)) return;

    // Blocked words and users configured in the filter panel are dropped on
    // match.
    if (!_passesShield(message)) return;

    final danmakuSettings = SettingsService.to.danmakuState;

    if (!_repeatedFilter.accepts(
      message,
      enabled: danmakuSettings.collapseRepeatedDanmaku,
      window: Duration(seconds: danmakuSettings.repeatedDanmakuWindowSeconds.clamp(1, 30)),
    )) {
      return;
    }

    if (danmakuSettings.enableDanmakuSimilarityFilter) {
      // The three sliders on the danmaku settings page (similarity threshold /
      // cache duration / max cache size) were stored and never applied: the
      // filter kept its constructor defaults, so changing them did nothing.
      _similarityFilter.updateConfig(
        similarityThreshold: danmakuSettings.danmakuSimilarityThreshold,
        cacheDuration: Duration(seconds: danmakuSettings.danmakuSimilarityCacheDuration.clamp(1, 60)),
        maxCacheSize: danmakuSettings.danmakuSimilarityMaxCacheSize,
      );

      if (!_similarityFilter.shouldDisplay(message.message)) {
        return;
      }
    }

    // flame_barrage rendering, only fed to the picture layer while danmaku are on.
    if (danmakuSettings.enableDanmakuDisplay && !danmakuSettings.hideDanmaku) {
      state.barrageController.send(_toBarrageItem(message));
    }

    // Keep the list view bounded in a single pass (no copy-then-trim).
    const maxListedMessages = 200;

    final messages = state.messages.length >= maxListedMessages
        ? <LiveMessage>[...state.messages.sublist(state.messages.length - maxListedMessages + 1), message]
        : <LiveMessage>[...state.messages, message];

    state = state.copyWith(messages: messages);
  }

  /// Keyword shielding.
  ///
  /// The list is shared with the danmaku filter panel and the phone scan page
  /// through one [FavoriteRoomController], so all three stay in step. Filtering
  /// by author was removed: keywords are the only rule the player applies.
  bool _passesShield(LiveMessage message) {
    final shieldList = SettingsService.to.favState.shieldList;

    if (shieldList.isEmpty) return true;

    final text = message.message;

    for (final word in shieldList) {
      if (word.isNotEmpty && text.contains(word)) {
        return false;
      }
    }

    return true;
  }

  BarrageItem _toBarrageItem(LiveMessage msg) {
    final style = msg.style;

    final color = Color.fromARGB(255, msg.color.r, msg.color.g, msg.color.b);

    return BarrageItem(
      content: msg.message,
      type: switch (style?.placement) {
        LiveMessagePlacement.top => BarrageType.topFixed,
        LiveMessagePlacement.bottom => BarrageType.bottomFixed,
        _ => BarrageType.scroll,
      },
      userId: msg.userId,
      userName: msg.userName,
      textColor: color,
      fontSize: style?.fontSize,
      fontWeight: style == null ? null : FontWeight(style.fontWeight),
      fontFamily: style?.fontFamily,
      showStroke: style?.showStroke,
      strokeColor: style == null ? null : Color(style.strokeColor),
      strokeWidth: style?.strokeWidth,
      baseSpeed: style?.baseSpeed,
    );
  }

  void clearMessages() {
    _messageGate.clear();
    _repeatedFilter.clear();
    _similarityFilter.clear();

    state.barrageController.clear();

    state = state.copyWith(messages: const <LiveMessage>[]);
  }

  void _teardown() {
    _sessionToken++;

    final engine = _engine;
    _engine = null;

    engine?.onMessage = null;
    engine?.onClose = null;

    if (engine != null) {
      unawaited(engine.stop().catchError((Object e, StackTrace s) {}));
    }
  }
}

class DanmakuSessionState {
  const DanmakuSessionState({
    required this.barrageController,
    this.messages = const <LiveMessage>[],
    this.connected = false,
    this.statusText,
  });

  final BarrageController barrageController;
  final List<LiveMessage> messages;
  final bool connected;
  final String? statusText;

  DanmakuSessionState copyWith({
    List<LiveMessage>? messages,
    bool? connected,
    String? statusText,
    bool clearStatusText = false,
  }) {
    return DanmakuSessionState(
      barrageController: barrageController,
      messages: messages ?? this.messages,
      connected: connected ?? this.connected,
      statusText: clearStatusText ? null : (statusText ?? this.statusText),
    );
  }
}
