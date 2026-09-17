import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// Group container for [TvSettingsRow]s.
///
/// Uses the TV palette (like the rows themselves) rather than the Material
/// card theme, so the whole settings page shares one set of colours.
class TvSettingsCard extends StatelessWidget {
  final List<Widget> children;

  const TvSettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    // A spacer — `const SizedBox(height: …)` with nothing in it — is not a row. A box that
    // *wraps* content is one: dropping every `SizedBox` silently hid whole sections (the
    // update page's status view disappeared this way), so only empty boxes are skipped.
    final validChildren = children.where((w) => w is! SizedBox || w.child != null).toList();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tvTheme.cardColor,
        borderRadius: BorderRadius.circular(20.sp),
        border: Border.all(color: tvTheme.secondaryTextColor.withValues(alpha: 0.12), width: 1.sp),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.sp, horizontal: 4.sp),
        child: Column(
          children: List.generate(validChildren.length, (index) {
            return Column(
              children: [
                validChildren[index],
                if (index != validChildren.length - 1)
                  Divider(
                    height: 1.sp,
                    thickness: 1.sp,
                    indent: 16.sp,
                    endIndent: 16.sp,
                    color: tvTheme.secondaryTextColor.withValues(alpha: 0.12),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
