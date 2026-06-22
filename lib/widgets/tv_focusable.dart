import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TvFocusable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool autofocus;

  const TvFocusable({super.key, required this.child, this.onTap, this.autofocus = false});

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.tvTheme;

    return DpadFocusable(
      autofocus: autofocus,
      onSelect: onTap,

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

        return child
            .animate(target: isFocused ? 1 : 0, onPlay: (controller) => controller.stop())
            .scale(begin: const Offset(1, 1), end: const Offset(1, 1.06), duration: 150.ms)
            .boxShadow(
              begin: const BoxShadow(color: Colors.transparent),
              end: BoxShadow(blurRadius: 20, spreadRadius: 2, color: activeTheme.focusColor.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(16),
            );
      },

      child: const SizedBox.shrink(),
    );
  }
}
