import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/theme/index.dart';

/// A compact translucent chip for cover overlays (platform, followed, replay,
/// audience, type, counts, duration) — the one cover-badge language every
/// card shares. Near-opaque black, fixed-size text on purpose: cover meta is
/// an overlay, exempt from the font-scale resolver like the avatar initial,
/// because an enlarged label inside a pill swallowed the artwork.
class TvCoverChip extends StatelessWidget {
  const TvCoverChip({super.key, required this.label, this.icon, this.iconColor});

  final String label;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 5.sp),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(20.sp),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13.sp, color: iconColor ?? Colors.white),
            SizedBox(width: 4.sp),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.t14.copyWith(fontSize: 12.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
