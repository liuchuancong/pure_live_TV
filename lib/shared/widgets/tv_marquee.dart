import 'package:flutter/material.dart';
import 'package:marquee_list/marquee_list.dart';

class TvMarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool isFocused;

  const TvMarqueeText({super.key, required this.text, required this.style, required this.isFocused});

  @override
  State<TvMarqueeText> createState() => _TvMarqueerTextState();
}

class _TvMarqueerTextState extends State<TvMarqueeText> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.style.fontSize! * 1.3,
      child: widget.isFocused
          ? MarqueeList(
              scrollDirection: Axis.horizontal,
              scrollDuration: const Duration(seconds: 2),
              // Trailing spacer: one gap per loop, so the end of the text and
              // its next repetition do not butt together.
              children: [
                Text(widget.text, style: widget.style, maxLines: 1),
                SizedBox(width: widget.style.fontSize! * 3),
              ],
            )
          : Text(widget.text, style: widget.style, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
