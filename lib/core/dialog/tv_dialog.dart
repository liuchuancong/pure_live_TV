import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/core/theme/tv_theme_x.dart';
import 'package:pure_live/core/widgets/tv_button.dart';
import 'package:pure_live/core/theme/tv_text_scale.dart';
import 'package:pure_live/core/dialog/tv_dialog_focus_guard.dart';
import 'package:pure_live/core/theme/typography/app_font_scale.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvDialog extends StatelessWidget {
  final String? title;
  final Widget child;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// The node the keyboard should open on — a select dialog passes the row
  /// holding the value in force. Without it the focus guard settles on the
  /// first focusable, which for a lazy list can transiently be the close button.
  final FocusNode? initialFocusNode;

  /// Frame width; the default fits a plain form, wide lists (the room
  /// switcher) pass more.
  final double? width;

  const TvDialog({
    super.key,
    this.title,
    required this.child,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.initialFocusNode,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final borderRadius = BorderRadius.circular(24.sp);

    // The frame is a plain container, not a DpadFocusable.
    //
    // It used to be wrapped in a focusable whose default `excludeChildFocus`
    // put an `ExcludeFocus` over the whole dialog body, so the confirm and
    // cancel buttons could never take focus (the confirm button's
    // `autofocus: true` silently did nothing) and the frame itself became a
    // dead focus stop that swallowed OK. The frame never varied with focus
    // state anyway, so nothing is lost by rendering it directly.
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: width ?? 800.ts(context),
        padding: EdgeInsets.all(32.ts(context)),
        decoration: BoxDecoration(
          color: tvTheme.cardColor,
          borderRadius: borderRadius,
          boxShadow: [
            // Crisp ring on light palettes; the blurred halo smears on white.
            BoxShadow(
              color: tvTheme.focusColor.withValues(alpha: .75),
              blurRadius: tvTheme.isLight ? 0 : 12.sp,
              spreadRadius: 1.sp,
            ),
          ],
          border: Border.all(color: tvTheme.focusColor, width: 1.sp),
        ),
        // Keeps the remote inside the modal: the page behind it must not react
        // to the d-pad while a dialog is open.
        child: DpadRegion(
          horizontalEdge: DpadEdgeBehavior.stop,
          verticalEdge: DpadEdgeBehavior.stop,
          // ...and keeps the keyboard here even when something behind the dialog
          // rebuilds and the d-pad layer restores focus to a node of that page.
          child: TvDialogFocusGuard(
            initialFocusNode: initialFocusNode,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 24.ts(context)),
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: tvTheme.primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: (32 * AppFontScale.user).sp,
                      ),
                    ),
                  ),
                child,
                if (confirmText != null || cancelText != null) ...[
                  SizedBox(height: 32.ts(context)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (cancelText != null)
                        Padding(
                          padding: EdgeInsets.only(right: 16.ts(context)),
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
        ),
      ),
    );
  }
}
