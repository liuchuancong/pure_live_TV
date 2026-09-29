import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_core/media_core.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';


/// The subtitle line stack, driven by a timer against the handle position.
class SubtitleLines extends StatefulWidget {
  const SubtitleLines({super.key, required this.cues, required this.handle});

  final List<SubtitleCue> cues;
  final PlayerHandle handle;

  @override
  State<SubtitleLines> createState() => _SubtitleLinesState();
}

class _SubtitleLinesState extends State<SubtitleLines> {
  Timer? _timer;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    if (widget.cues.isEmpty) return;
    final now = widget.handle.position.inMilliseconds / 1000.0;
    String active = '';
    for (final cue in widget.cues) {
      if (now >= cue.from && now <= cue.to) {
        active = cue.text;
        break;
      }
    }
    if (active != _text) setState(() => _text = active);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_text.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in _text.split('\n').take(2))
          Container(
            margin: EdgeInsets.only(top: 4.sp),
            padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 6.sp),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(8.sp),
            ),
            child: Text(
              line,
              textAlign: TextAlign.center,
              style: AppTextStyles.t20.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
      ],
    );
  }
}
