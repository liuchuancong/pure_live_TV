import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class TvFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  final bool autofocus;

  const TvFocusable({super.key, required this.child, this.onTap, this.autofocus = false});

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      autofocus: widget.autofocus,

      onSelect: widget.onTap,

      onFocusChange: (value) {
        setState(() {
          focused = value;
        });
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        transform: Matrix4.identity()..scale(focused ? 1.06 : 1.0),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),

          boxShadow: focused
              ? [
                  BoxShadow(
                    blurRadius: 20,
                    spreadRadius: 2,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: .5),
                  ),
                ]
              : null,
        ),

        child: widget.child,
      ),
    );
  }
}
