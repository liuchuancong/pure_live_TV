import 'package:flutter/material.dart';
import 'package:marquee_list/marquee_list.dart';

class TvMarqueerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool isFocused;

  const TvMarqueerText({super.key, required this.text, required this.style, required this.isFocused});

  @override
  State<TvMarqueerText> createState() => _TvMarqueerTextState();
}

class _TvMarqueerTextState extends State<TvMarqueerText> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.style.fontSize! * 1.3,
      child: widget.isFocused
          ? MarqueeList(
              scrollDirection: Axis.horizontal,
              scrollDuration: const Duration(seconds: 2),
              children: [Text(widget.text, style: widget.style, maxLines: 1)],
            )
          : Text(widget.text, style: widget.style, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
