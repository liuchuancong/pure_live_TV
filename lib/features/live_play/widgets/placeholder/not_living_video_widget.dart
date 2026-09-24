import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/states/live_play_state.dart';
import 'package:pure_live/features/live_play/dialogs/room_switch_dialog.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';

/// "This room is not broadcasting" placeholder.
///
/// Ported from the reference client's `NotLivingVideoWidget`: the room loaded
/// fine, so this is not an error screen — nothing failed, there is simply no
/// stream yet. It therefore offers the two things that actually help:
///
/// - **Switch room**: the same switch dialog the control bar opens, so the viewer
///   can move on without backing out to the list first.
/// - **Re-check**: re-runs the room bootstrap (site response included), which is
///   what clears the placeholder once the streamer is back.
///
/// Focus model: this placeholder **owns a focus node and handles its own keys**,
/// the same way the control bar and the failure overlay do. The player page is
/// key-handled by one handler which would otherwise eat OK as "show the
/// controls" and ←/→ as "switch channel / follow" — and an `autofocus` on the
/// buttons cannot win either, because Flutter honours one autofocus per scope
/// and the page's handler node already holds it.
///
/// Steering is by selected index (0 = switch room, 1 = re-check): ←/→ move, OK
/// activates. ↑/↓ stay with the page — channel switching skips past a dead room
/// in one press.
class NotLivingVideoWidget extends ConsumerStatefulWidget {
  const NotLivingVideoWidget({super.key, required this.args});

  final LivePlayArgs args;

  @override
  ConsumerState<NotLivingVideoWidget> createState() => _NotLivingVideoWidgetState();
}

class _NotLivingVideoWidgetState extends ConsumerState<NotLivingVideoWidget> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'live_play/offline');
  int _index = 0;

  static const int _actionSwitchRoom = 0;
  static const int _actionRefresh = 1;

  @override
  void initState() {
    super.initState();
    // Explicit request: the page's own handler node already holds this scope's
    // focus, so `autofocus` alone would be ignored and every key would be
    // routed to the page instead of here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  static bool _isConfirm(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.gameButtonA;

  void _activate() {
    if (_index == _actionSwitchRoom) {
      final LiveRoom? room = ref.read(livePlayControllerProvider(widget.args)).room;
      unawaited(pickAndSwitchRoom(context, ref: ref, args: widget.args, current: room ?? _fallbackRoom()));
      return;
    }
    unawaited(ref.read(livePlayControllerProvider(widget.args).notifier).refreshRoom());
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (!mounted) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (_isConfirm(key)) {
      _activate();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      setState(() => _index = _index == _actionSwitchRoom ? _actionRefresh : _actionSwitchRoom);
      return KeyEventResult.handled;
    }
    // ↑/↓ stay with the page: switching channels is the quickest exit from a
    // room that is not on air.
    return KeyEventResult.ignored;
  }

  /// Room the switch dialog removes from its lists. When the detail request
  /// never produced a room, the route's hint is all we have — an empty room
  /// still opens the dialog with every other channel available.
  LiveRoom _fallbackRoom() =>
      widget.args.room ?? LiveRoom(roomId: widget.args.roomId, platform: widget.args.platform);

  @override
  Widget build(BuildContext context) {
    final LivePlayState state = ref.watch(livePlayControllerProvider(widget.args));
    final TvThemeData tvTheme = context.tvTheme;
    final LiveRoom? room = state.room;
    final String title = _roomTitle(room);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.86),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // An offline marker on the avatar reads faster than a line of text.
            _OfflineBadge(room: room, title: title),
            SizedBox(height: 18.sp),
            Text(
              i18n('room_offline'),
              textAlign: TextAlign.center,
              style: AppTextStyles.t24W600.copyWith(color: tvTheme.primaryTextColor),
            ),
            SizedBox(height: 8.sp),
            SizedBox(
              width: 640.sp,
              child: Text(
                i18n('switch_other_room_hint'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.t18W300.copyWith(color: tvTheme.secondaryTextColor),
              ),
            ),
            SizedBox(height: 10.sp),
            Text(
              i18nOr('ui_panel_keys_adjust', '←→ 选择 · OK 确认'),
              style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
            ),
            SizedBox(height: 20.sp),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _pill(
                  tvTheme,
                  index: _actionSwitchRoom,
                  background: tvTheme.focusColor,
                  label: i18n('switch_live_room'),
                  icon: Icons.swap_horiz_rounded,
                ),
                SizedBox(width: 16.sp),
                _pill(
                  tvTheme,
                  index: _actionRefresh,
                  background: Colors.white.withValues(alpha: 0.12),
                  label: i18n('ui_refresh_room'),
                  icon: Icons.refresh_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Title line: room title, else streamer, else room id — never blank.
  static String _roomTitle(LiveRoom? room) {
    for (final String candidate in <String>[room?.title ?? '', room?.nick ?? '', room?.roomId ?? '']) {
      final String value = candidate.trim();
      if (value.isNotEmpty) return value;
    }
    return i18n('untitled_room');
  }

  /// One action pill. [index] is the index-driven highlight; tapping moves the
  /// highlight too, so mouse and remote cannot disagree.
  Widget _pill(
    TvThemeData tvTheme, {
    required int index,
    required Color background,
    required String label,
    required IconData icon,
  }) {
    final bool selected = _index == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _index = index);
        _activate();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 22.sp, vertical: 12.sp),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12.sp),
          border: Border.all(color: selected ? Colors.white.withValues(alpha: 0.85) : Colors.transparent),
          boxShadow: selected
              ? [BoxShadow(color: tvTheme.focusColor.withValues(alpha: 0.55), blurRadius: 14.sp, spreadRadius: 1.sp)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20.sp, color: Colors.white),
            SizedBox(width: 8.sp),
            Text(label, style: AppTextStyles.t16W600.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// Avatar (or a neutral disc) with an offline marker, plus the room title.
class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge({required this.room, required this.title});

  final LiveRoom? room;
  final String title;

  @override
  Widget build(BuildContext context) {
    final TvThemeData tvTheme = context.tvTheme;
    final String avatar = (room?.avatar ?? '').trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: SizedBox(
                width: 72.sp,
                height: 72.sp,
                child: avatar.isEmpty
                    ? ColoredBox(
                        color: tvTheme.cardColor,
                        child: Icon(Icons.person_outline_rounded, size: 36.sp, color: tvTheme.secondaryTextColor),
                      )
                    : CachedNetworkImage(
                        imageUrl: avatar,
                        fit: BoxFit.cover,
                        errorWidget: (context, _, _) => ColoredBox(
                          color: tvTheme.cardColor,
                          child: Icon(Icons.person_outline_rounded, size: 36.sp, color: tvTheme.secondaryTextColor),
                        ),
                      ),
              ),
            ),
            // Bottom-right marker: reads as "streamer not live", not as a network fault.
            Positioned(
              right: -2.sp,
              bottom: -2.sp,
              child: Container(
                padding: EdgeInsets.all(4.sp),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3F),
                  shape: BoxShape.circle,
                  border: Border.all(color: tvTheme.backgroundColor, width: 2.sp),
                ),
                child: Icon(Icons.videocam_off_rounded, size: 16.sp, color: Colors.white70),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.sp),
        SizedBox(
          width: 560.sp,
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.t18W500.copyWith(color: tvTheme.secondaryTextColor),
          ),
        ),
      ],
    );
  }
}
