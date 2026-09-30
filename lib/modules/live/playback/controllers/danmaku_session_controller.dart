import 'dart:async';
import 'package:flutter/painting.dart';
import 'package:flame_barrage/flame_barrage.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/modules/live/playback/controllers/danmaku_filters.dart';
import 'package:pure_live/modules/live/playback/models/live_play_args.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/modules/live/playback/services/live_play_repository.dart';
part 'danmaku_session_controller.g.dart';

// The danmaku session: connection, gating, filtering and the list view
// state, extracted from the live play controller's god file.



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
