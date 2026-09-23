import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

/// Playback failure overlay with two actions: retry and refresh room.
///
/// Focus model: this overlay **owns a focus node and handles its own keys**,
/// exactly like the control bar does. The player page is key-handled by one
/// handler that would otherwise eat OK as "show the controls" and ←/→ as
/// "switch channel / follow", leaving these buttons unreachable. An
/// `autofocus` inside the buttons cannot win here either: Flutter honours one
/// autofocus per scope and the page's handler node already holds it.
///
/// Steering is by selected index (0 = retry, 1 = refresh room): ←/→ move,
/// OK activates. ↑/↓ are deliberately left to the page — switching channels is
/// the quickest way out of a room that will not play.
class PlaybackFailureOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onRefreshRoom;

  const PlaybackFailureOverlay({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onRefreshRoom,
  });

  @override
  State<PlaybackFailureOverlay> createState() => _PlaybackFailureOverlayState();
}

class _PlaybackFailureOverlayState extends State<PlaybackFailureOverlay> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'live_play/failure');
  int _index = 0;

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
    if (_index == 0) {
      widget.onRetry();
    } else {
      widget.onRefreshRoom();
    }
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
      setState(() => _index = _index == 0 ? 1 : 0);
      return KeyEventResult.handled;
    }
    // ↑/↓ stay with the page: switching channels is the quickest exit from a
    // room that will not play.
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: tvTheme.secondaryTextColor),
            SizedBox(height: 12.sp),
            SizedBox(
              width: 560.sp,
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.t18W500.copyWith(color: tvTheme.primaryTextColor),
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
                  index: 0,
                  background: tvTheme.focusColor,
                  label: i18n('ui_retry_playback'),
                  icon: Icons.refresh,
                  onTap: widget.onRetry,
                ),
                SizedBox(width: 16.sp),
                _pill(
                  tvTheme,
                  index: 1,
                  background: Colors.white.withValues(alpha: 0.12),
                  label: i18n('ui_refresh_room'),
                  icon: Icons.travel_explore,
                  onTap: widget.onRefreshRoom,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// One action pill. [index] is the index-driven highlight; tapping moves the
  /// highlight too, so mouse and remote cannot disagree.
  Widget _pill(
    TvThemeData tvTheme, {
    required int index,
    required Color background,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool selected = _index == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _index = index);
        onTap();
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
