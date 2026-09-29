import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/core/theme/index.dart';

/// A platform's logo with a neutral fallback.
///
/// The artwork can be missing (a platform added before its asset lands, or the
/// synthetic "all" entry), and without the fallback the row renders an empty gap
/// and logs a failed asset load.
class TvPlatformLogo extends StatelessWidget {
  const TvPlatformLogo({super.key, required this.logo, this.size = 30});

  final String logo;

  /// Design pixels, both width and height, before the font-scale factor.
  final double size;

  @override
  Widget build(BuildContext context) {
    // The rows this leads grow their labels with the app font setting; the
    // logo grows with them so the row keeps one visual rhythm.
    final double scaled = size.sp * TvTextScale.factorOf(context);
    return Image.asset(
      logo,
      width: scaled,
      height: scaled,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.live_tv_rounded, size: scaled, color: context.tvTheme.secondaryTextColor),
    );
  }
}
