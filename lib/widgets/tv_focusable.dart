import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

typedef TvFocusableBuilder = Widget Function(BuildContext context, bool isFocused, Widget? child);

class TvFocusable extends StatelessWidget {
  final Widget? child;
  final TvFocusableBuilder? builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool autofocus;

  const TvFocusable({super.key, this.child, this.builder, this.onTap, this.onLongPress, this.autofocus = false});

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.tvTheme;

    return DpadFocusable(
      autofocus: autofocus,
      onSelect: onTap,
      onLongSelect: onLongPress,
      onFocusChange: (focused) {
        if (!focused) return;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: 0.2,
        );
      },
      builder: (context, state, _) {
        final isFocused = state.focused;
        final content = builder != null ? builder!(context, isFocused, child) : (child ?? const SizedBox.shrink());
        return content
            .animate(target: isFocused ? 1 : 0, onPlay: (controller) => controller.stop())
            .scale(begin: const Offset(1, 1), end: const Offset(1, 1.05), duration: 120.ms, curve: Curves.easeOutCubic)
            .boxShadow(
              begin: const BoxShadow(color: Colors.transparent),
              end: BoxShadow(blurRadius: 24, spreadRadius: 1, color: activeTheme.focusColor.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(20.sp),
            );
      },
      child: const SizedBox.shrink(),
    );
  }
}
