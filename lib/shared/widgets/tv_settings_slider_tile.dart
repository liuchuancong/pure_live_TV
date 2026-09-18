import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/tv_settings_row.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvSettingsSliderTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final ValueChanged<double> onChanged;
  final double step;

  const TvSettingsSliderTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.onChanged,
    this.step = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final double progress = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return TvSettingsRow(
      title: title,
      subtitle: subtitle,
      icon: icon,
      onDirection: (direction) {
        if (direction != TraversalDirection.left && direction != TraversalDirection.right) {
          return false;
        }
        final double delta = direction == TraversalDirection.left ? -step : step;
        final double newValue = (value + delta).clamp(min, max);
        // At the minimum/maximum the value no longer changes: release the key
        // so focus can leave the slider instead of being trapped on it.
        if (newValue == value) return false;
        onChanged(newValue);
        return true;
      },
      trailingBuilder: (context, focused) => Text(
        displayValue,
        maxLines: 1,
        // The focused row fills with the palette's focus surface; its ink, not
        // the accent, reads on it.
        style: AppTextStyles.t20W600.copyWith(
          color: focused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor,
        ),
      ),
      footer: _SliderTrack(progress: progress, accent: tvTheme.focusColor, track: tvTheme.secondaryTextColor),
    );
  }
}

/// Track drawn with the palette colours instead of the Material progress
/// indicator, so it matches the row borders on every theme.
class _SliderTrack extends StatelessWidget {
  const _SliderTrack({required this.progress, required this.accent, required this.track});

  final double progress;
  final Color accent;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8.sp,
      decoration: BoxDecoration(
        color: track.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(4.sp),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress,
          child: DecoratedBox(
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4.sp)),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
