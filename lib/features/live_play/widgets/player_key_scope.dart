import 'dart:async';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/states/live_play_state.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/app/router/app_router.dart';

/// Key handling for the whole player — **without d-pad**.
///
/// Modelled on the reference player
/// (`E:/project/pure_live_TV/lib/modules/live_play/widgets/video_player/controller/
/// video_key_handler.dart`): one handler owns every key and decides what to do
/// from what is currently on screen, instead of leaving focus traversal to the
/// d-pad layer. Keys reach it through one [Focus], so nothing can steal focus or
/// leave the player with a dead remote.
///
/// * nothing open: OK shows the controls, Up/Down switch channel, Left
///   double-presses to follow, Right opens the playlist
/// * a side panel open: keys belong to that panel (they are focus based)
/// * controls visible: the control layer's own [Focus] handles them first —
///   events bubble from the primary focus outwards, so this handler stays out of
///   the way by ignoring them
class PlayerKeyScope extends ConsumerStatefulWidget {
  const PlayerKeyScope({super.key, required this.args, required this.child});

  final LivePlayArgs args;
  final Widget child;

  @override
  ConsumerState<PlayerKeyScope> createState() => _PlayerKeyScopeState();
}

class _PlayerKeyScopeState extends ConsumerState<PlayerKeyScope> {
  /// Double-press window for the left key, as in the reference (500 ms).
  static const Duration _doubleClickWindow = Duration(milliseconds: 500);

  final FocusNode _focusNode = FocusNode(debugLabel: 'live_play/keys');
  int _lastLeftTapAt = 0;
  Timer? _leftTapTimer;

  @override
  void dispose() {
    _leftTapTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  static bool _isConfirm(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.controlLeft ||
      key == LogicalKeyboardKey.controlRight ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.gameButtonA;

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;

    final state = ref.read(livePlayControllerProvider(widget.args));
    final controller = ref.read(livePlayControllerProvider(widget.args).notifier);
    final key = event.logicalKey;

    // A panel with its own index handling consumes its keys first; what reaches
    // here while a panel is open is Left/Escape, which closes it (room info has no
    // keys of its own).
    if (state.showSidePanel) {
      if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.escape) {
        controller.toggleSidePanel();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    // 覆盖层（播放失败 / 未开播）自带可聚焦按钮，并按 index 自己处理 ←/→/OK。
    // 这里必须放行：否则页面会先把 OK 吃成"显示控制条"、把 ←/→ 吃成换台与关注，
    // 覆盖层上的按钮就永远点不动（它们的 autofocus 会被页面已持有的焦点压掉，
    // 只能靠落在自己节点上的按键生效）。↑/↓ 仍由这里处理——在离线房间里直接
    // 跳下一个直播间是最快的出路。
    if (state.hasBlockingOverlay) {
      if (key == LogicalKeyboardKey.arrowUp) {
        _switchChannel(-1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        _switchChannel(1);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // With the controls up, the control layer's own handler runs first; anything
    // it does not use has already bubbled to here.
    if (state.showControls) return KeyEventResult.ignored;

    if (_isConfirm(key)) {
      controller.showControls();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      _switchChannel(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _switchChannel(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _handleFollowDoublePress();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      controller.togglePanel(LivePlayPanel.playlist);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Switches channel by [delta] (-1 previous, 1 next).
  void _switchChannel(int delta) {
    final controller = ref.read(livePlayControllerProvider(widget.args).notifier);
    final rooms = controller.channelRooms;
    final target = controller.relativeChannel(delta);
    if (target == null) {
      ToastUtil.show(i18nOr('ui_no_switchable_channel', 'No channel available to switch to'));
      return;
    }
    // Channel switching uses a route replace, so the previous session is released.
    LivePlayRoute(
      LivePlayArgs.fromRoom(target, playlist: rooms, showChannelBanner: true),
    ).replace(context);
  }

  /// Left double-press follows or unfollows the room.
  void _handleFollowDoublePress() {
    final room = ref.read(livePlayControllerProvider(widget.args)).room;
    if (room == null) return;
    final fav = ref.read(favoriteRoomControllerProvider.notifier);
    final bool isFavorite = fav.isFavorite(room);

    final int now = DateTime.now().millisecondsSinceEpoch;
    final bool isDoubleClick = _lastLeftTapAt != 0 && now - _lastLeftTapAt < _doubleClickWindow.inMilliseconds;
    if (!isDoubleClick) {
      _lastLeftTapAt = now;
      ToastUtil.show(
        isFavorite
            ? i18nOr('ui_double_click_unfollow', 'Double click to unfollow')
            : i18nOr('ui_double_click_follow', 'Double click to follow'),
      );
      _leftTapTimer?.cancel();
      _leftTapTimer = Timer(const Duration(milliseconds: 600), () => _lastLeftTapAt = 0);
      return;
    }

    _lastLeftTapAt = 0;
    _leftTapTimer?.cancel();
    if (isFavorite) {
      fav.removeRoom(room);
      ToastUtil.show(i18nOr('ui_unfollowed', 'Unfollowed'));
    } else {
      fav.addRoom(room);
      ToastUtil.show(i18n('followed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back closes what is on screen before it leaves the player: an option
      // list, then the side panel, then the controls — and only then the page.
      // Leaving straight from a visible panel is what made the remote feel
      // unpredictable.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final state = ref.read(livePlayControllerProvider(widget.args));
        final controller = ref.read(livePlayControllerProvider(widget.args).notifier);
        if (state.showSidePanel) {
          controller.toggleSidePanel();
          return;
        }
        if (state.showControls) {
          controller.toggleControls();
          return;
        }
        if (mounted) Navigator.of(context).pop();
      },
      child: Focus(focusNode: _focusNode, autofocus: true, onKeyEvent: _onKeyEvent, child: widget.child),
    );
  }
}
