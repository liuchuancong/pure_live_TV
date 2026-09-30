import 'package:flutter/material.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/services/cookie_manager/bilibili/bilibili_account_controller.dart';

/// Gates music/video mode content behind a bilibili login, the bmsc way: a
/// centered lock placeholder replaces the content until the account cookie
/// exists; tapping it opens the QR login page, and watching the account
/// controller swaps the content in the moment the login lands.
class BilibiliLoginGate extends ConsumerWidget {
  const BilibiliLoginGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(bilibiliAccountControllerProvider);
    if (account.isLogined) return child;

    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return Center(
      child: TvFocusable(
        autofocus: true,
        onTap: () => const AccountBilibiliRoute().push(context),
        builder: (context, focused, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: 48.ts(context), vertical: 36.ts(context)),
            decoration: BoxDecoration(
              color: tvTheme.cardColor,
              borderRadius: BorderRadius.circular(24.sp),
              border: Border.all(
                color: focused ? accent : accent.withValues(alpha: 0.4),
                width: focused ? 2.5.sp : 1.5.sp,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: focused ? 0.4 : 0),
                  blurRadius: focused ? 20.sp : 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 72.sp, color: accent),
                SizedBox(height: 18.sp),
                Text(
                  i18n('bili_login_required'),
                  style: AppTextStyles.t22.copyWith(fontWeight: FontWeight.w700, color: tvTheme.primaryTextColor),
                ),
                SizedBox(height: 8.sp),
                Text(
                  i18n('bili_login_hint'),
                  style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                ),
                SizedBox(height: 20.sp),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 32.ts(context), vertical: 12.ts(context)),
                  decoration: BoxDecoration(
                    color: focused ? accent : accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(28.sp),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, size: 26.sp, color: focused ? Colors.white : accent),
                      SizedBox(width: 10.sp),
                      Text(
                        i18n('bili_login_action'),
                        style: AppTextStyles.t18.copyWith(
                          fontWeight: FontWeight.w600,
                          color: focused ? Colors.white : accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
