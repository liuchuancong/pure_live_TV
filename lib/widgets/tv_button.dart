import 'tv_focusable.dart';
import 'package:flutter/material.dart';

class TvButton extends StatelessWidget {
  final String title;

  final Widget? leading;
  final Widget? trailing;

  final VoidCallback? onTap;

  final bool autofocus;

  const TvButton({super.key, required this.title, this.leading, this.trailing, this.onTap, this.autofocus = false});

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      autofocus: autofocus,
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(28)),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],

            Expanded(child: Text(title)),

            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
  }
}
