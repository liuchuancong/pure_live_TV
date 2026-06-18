import 'package:flutter/material.dart';

class TvFocusAnimation extends StatelessWidget {
  final bool focused;

  final Widget child;

  const TvFocusAnimation({super.key, required this.focused, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: focused ? 1.08 : 1,

      duration: const Duration(milliseconds: 180),

      curve: Curves.easeOut,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),

          boxShadow: focused
              ? [
                  BoxShadow(
                    blurRadius: 24,
                    spreadRadius: 2,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: .6),
                  ),
                ]
              : null,
        ),

        child: child,
      ),
    );
  }
}
