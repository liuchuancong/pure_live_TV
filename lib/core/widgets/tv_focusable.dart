import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/core/theme/tv_theme_x.dart';
import 'package:pure_live/core/utils/dpad_long_press_gate.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

typedef TvFocusableBuilder = Widget Function(BuildContext context, bool isFocused, Widget? child);

class TvFocusable extends StatefulWidget {
  final Widget? child;
  final TvFocusableBuilder? builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool autofocus;

  /// External node, for callers that steer focus programmatically (a list that
  /// puts the focus back on the playing row). Null keeps DpadFocusable's own.
  final FocusNode? focusNode;

  /// Directional keys while focused. Return `true` to consume the press
  /// (a row that opens its context menu on Right, for example); `false` lets
  /// the dpad layer move the focus. Null keeps plain traversal.
  final DpadDirectionCallback? onDirection;

  const TvFocusable({
    super.key,
    this.child,
    this.builder,
    this.onTap,
    this.onLongPress,
    this.autofocus = false,
    this.focusNode,
    this.onDirection,
  });

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  /// TvRoomCard's long-press semantics, shared by every focusable: the card
  /// marks its long-press action and drops the next select if it is that
  /// press's release — a disturbed hold then never fires the tap on its way
  /// out (the card opened the menu and also navigated, the classic bug).
  final DpadLongPressGate _longPressGate = DpadLongPressGate();

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.tvTheme;

    return DpadFocusable(
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      onDirection: widget.onDirection,
      onSelect: () {
        if (_longPressGate.swallowSelect()) return;
        widget.onTap?.call();
      },
      onLongSelect: widget.onLongPress == null
          ? null
          : () {
              _longPressGate.markLongPress();
              widget.onLongPress!.call();
            },
      // No manual `Scrollable.ensureVisible` here: `DpadFocusable` already
      // reveals the focused item through `DpadScroll.ensureVisible`, which
      // walks every scrollable ancestor and keeps `scrollPadding` around the
      // item for its focus glow. Calling `Scrollable.ensureVisible` as well
      // animated to a second, slightly different offset.
      builder: (context, state, _) {
        final isFocused = state.focused;
        final content = widget.builder != null
            ? widget.builder!(context, isFocused, widget.child)
            : (widget.child ?? const SizedBox.shrink());
        return content
            .animate(target: isFocused ? 1 : 0, onPlay: (controller) => controller.stop())
            .scale(begin: const Offset(1, 1), end: const Offset(1, 1.05), duration: 120.ms, curve: Curves.easeOutCubic)
            .boxShadow(
              begin: const BoxShadow(color: Colors.transparent),
              // Same rule as [TvFocusStyle]: a 24-blur halo smears on a light
              // palette, so focus there is a crisp accent edge instead.
              end: BoxShadow(
                blurRadius: activeTheme.isLight ? 0 : 24,
                spreadRadius: 1,
                color: activeTheme.focusColor.withValues(alpha: activeTheme.isLight ? 1.0 : 0.4),
              ),
              borderRadius: BorderRadius.circular(20.sp),
            );
      },
      child: const SizedBox.shrink(),
    );
  }
}
