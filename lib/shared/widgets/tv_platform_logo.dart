import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';

/// A platform's logo with a neutral fallback.
///
/// The artwork can be missing (a platform added before its asset lands, or the
/// synthetic "all" entry), and without the fallback the row renders an empty gap
/// and logs a failed asset load.
class TvPlatformLogo extends StatelessWidget {
  const TvPlatformLogo({super.key, required this.logo, this.size = 30});

  final String logo;

  /// Design pixels, both width and height.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      logo,
      width: size.sp,
      height: size.sp,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.live_tv_rounded, size: size.sp, color: context.tvTheme.secondaryTextColor),
    );
  }
}
