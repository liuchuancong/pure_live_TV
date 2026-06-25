import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/routes/extensions.dart';
import 'package:pure_live/widgets/tv_button.dart';
import 'package:pure_live/theme/styles/styles.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvAppBar extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final Future<bool> Function()? beforeBack;

  const TvAppBar({super.key, this.title, this.titleWidget, this.actions, this.showBackButton = true, this.beforeBack});

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final bool canPop = Navigator.of(context).canPop();
    final bool hasBackButton = showBackButton && canPop;
    final bool hasTitle = (title != null && title!.isNotEmpty) || titleWidget != null;
    final bool hasActions = actions != null && actions!.isNotEmpty;

    if (!hasBackButton && !hasTitle && !hasActions) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 66.sp,
      padding: EdgeInsets.symmetric(horizontal: 16.sp),
      alignment: Alignment.centerLeft,
      color: Colors.transparent,
      child: Row(
        children: [
          if (hasBackButton) ...[
            TvButton(
              title: '返回',
              size: TvButtonSize.mini,
              autofocus: true,
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 24.sp),
              onTap: () async {
                if (beforeBack != null) {
                  final shouldPop = await beforeBack!();
                  if (!shouldPop) return;
                }
                if (context.mounted) {
                  context.back();
                }
              },
            ),
            SizedBox(width: 16.sp),
          ],
          Expanded(
            child:
                titleWidget ??
                Text(
                  title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t24W700.copyWith(color: tvTheme.primaryTextColor),
                ),
          ),
          if (actions != null) ...[SizedBox(width: 16.sp), Row(mainAxisSize: MainAxisSize.min, children: actions!)],
        ],
      ),
    );
  }
}
