import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/widgets/tv_button.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvDialog extends StatelessWidget {
  final String? title;
  final Widget child;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const TvDialog({
    super.key,
    this.title,
    required this.child,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final borderRadius = BorderRadius.circular(24.sp);

    final List<DpadEffect> effects = [
      DpadScaleEffect(
        scale: 1.01,
        pressedScale: 0.97,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
      ),
      DpadGlowEffect(color: tvTheme.focusColor, opacity: 0.8, blurRadius: 3.0, spreadRadius: 1.0),
      DpadCustomEffect((ctx, state, _) {
        return Container(
          width: 800.sp,
          padding: EdgeInsets.all(32.sp),
          decoration: BoxDecoration(
            color: tvTheme.cardColor,
            borderRadius: borderRadius,
            border: Border.all(color: tvTheme.secondaryTextColor.withAlpha(50), width: 2.sp),
          ),
          child: DpadRegion(
            horizontalEdge: DpadEdgeBehavior.stop,
            verticalEdge: DpadEdgeBehavior.stop,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 24.sp),
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: tvTheme.primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 32.sp,
                      ),
                    ),
                  ),
                child,
                if (confirmText != null || cancelText != null) ...[
                  SizedBox(height: 32.sp),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (cancelText != null)
                        Padding(
                          padding: EdgeInsets.only(right: 16.sp),
                          child: TvButton(
                            title: cancelText!,
                            size: TvButtonSize.mini,
                            isSecondary: true,
                            onTap: onCancel ?? () => Navigator.of(context).pop(),
                          ),
                        ),
                      if (confirmText != null)
                        TvButton(title: confirmText!, size: TvButtonSize.mini, autofocus: true, onTap: onConfirm),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: DpadFocusable(autofocus: false, effects: effects, child: const SizedBox.shrink()),
    );
  }
}
