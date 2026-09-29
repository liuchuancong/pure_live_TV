import 'package:flutter/material.dart';
import 'package:marquee_list/marquee_list.dart';
import 'package:pure_live/core/theme/tv_text_scale.dart';

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
    // No fixed line box: the height of one line is whatever the font needs at
    // the scale it is drawn at. `style.fontSize * 1.3` was a design-pixel box
    // while the inherited scaler multiplies the font, so it was already short of
    // a line by the font's own leading, and clipped the title outright once the
    // app font was enlarged. The focused marquee and the plain label lay out the
    // same single line, so the card's height does not change when focus moves.
    if (widget.isFocused) {
      return MarqueeList(
        scrollDirection: Axis.horizontal,
        scrollDuration: const Duration(seconds: 2),
        // Trailing spacer: one gap per loop, so the end of the text and its next
        // repetition do not butt together. It follows the text it separates.
        children: [
          Text(widget.text, style: widget.style, maxLines: 1),
          SizedBox(width: widget.style.fontSize! * 3 * TvTextScale.factorOf(context)),
        ],
      );
    }
    return Text(widget.text, style: widget.style, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}
