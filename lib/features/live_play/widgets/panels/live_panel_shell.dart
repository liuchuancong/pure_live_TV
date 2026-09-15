import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/theme/index.dart';

/// Shared shell for the side panels: title bar, key hints and content.
///
/// The four player panels (room info, playlist, danmaku settings, danmaku
/// filter) share it so focus visuals and navigation feel identical.
class LivePanelShell extends StatelessWidget {
  const LivePanelShell({super.key, required this.title, required this.child, this.hint, this.trailing});

  final String title;
  final String? hint;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t18W600.copyWith(color: tvTheme.primaryTextColor),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        if (hint != null)
          Padding(
            padding: EdgeInsets.only(left: 16.sp, right: 16.sp, bottom: 8.sp),
            child: Text(
              hint!,
              maxLines: 2,
              style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
            ),
          ),
        Divider(height: 1, color: tvTheme.secondaryTextColor.withValues(alpha: 0.2)),
        Expanded(child: child),
      ],
    );
  }
}

/// A row whose value is changed with Left/Right.
///
/// Up/Down is left to D-pad traversal so focus moves between rows, while
/// Left/Right is consumed here to change the value, so parameters can be
/// edited on TV without opening a sub-dialog.
class LiveOptionRow extends StatelessWidget {
  const LiveOptionRow({
    super.key,
    required this.label,
    required this.value,
    required this.onPrev,
    required this.onNext,
    this.icon,
    this.autofocus = false,
    this.onSelect,
  });

  final String label;
  final String value;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final IconData? icon;
  final bool autofocus;

  /// Action for the OK key, such as toggling a switch. Null means OK does
  /// nothing.
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 4.sp),
      child: DpadFocusable(
        autofocus: autofocus,
        onSelect: onSelect,
        onDirection: (direction) {
          switch (direction) {
            case TraversalDirection.left:
              onPrev();
              return true;
            case TraversalDirection.right:
              onNext();
              return true;
            case TraversalDirection.up:
            case TraversalDirection.down:
              return false;
          }
        },
        child: const SizedBox.shrink(),
        builder: (context, state, _) {
          final focused = state.focused;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 12.sp),
            decoration: BoxDecoration(
              color: focused ? tvTheme.focusColor.withValues(alpha: 0.22) : tvTheme.cardColor,
              borderRadius: BorderRadius.circular(10.sp),
              border: Border.all(
                color: focused ? tvTheme.focusColor : tvTheme.secondaryTextColor.withValues(alpha: 0.15),
                width: focused ? 2.sp : 1.sp,
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20.sp, color: focused ? tvTheme.focusColor : tvTheme.secondaryTextColor),
                  SizedBox(width: 10.sp),
                ],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t16W500.copyWith(
                      color: focused ? tvTheme.primaryTextColor : tvTheme.secondaryTextColor,
                    ),
                  ),
                ),
                if (focused) Icon(Icons.chevron_left, size: 22.sp, color: tvTheme.focusColor),
                SizedBox(width: 6.sp),
                Text(
                  value,
                  style: AppTextStyles.t16W600.copyWith(
                    color: focused ? tvTheme.focusColor : tvTheme.primaryTextColor,
                  ),
                ),
                SizedBox(width: 6.sp),
                if (focused) Icon(Icons.chevron_right, size: 22.sp, color: tvTheme.focusColor),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A row whose action runs on the OK key, such as deleting a blocked word or
/// switching channel.
class LiveActionRow extends StatelessWidget {
  const LiveActionRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    required this.onSelect,
    this.autofocus = false,
    this.highlighted = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback onSelect;
  final bool autofocus;

  /// Whether this is the current entry, for example the channel being played.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 4.sp),
      child: DpadFocusable(
        autofocus: autofocus,
        onSelect: onSelect,
        child: const SizedBox.shrink(),
        builder: (context, state, _) {
          final focused = state.focused;
          final accent = highlighted || focused;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 10.sp),
            decoration: BoxDecoration(
              color: focused
                  ? tvTheme.focusColor.withValues(alpha: 0.22)
                  : (highlighted ? tvTheme.cardColor : Colors.transparent),
              borderRadius: BorderRadius.circular(10.sp),
              border: Border.all(
                color: focused
                    ? tvTheme.focusColor
                    : (highlighted ? tvTheme.focusColor.withValues(alpha: 0.5) : Colors.transparent),
                width: focused ? 2.sp : 1.sp,
              ),
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  SizedBox(width: 12.sp),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t16W500.copyWith(
                          color: focused ? tvTheme.primaryTextColor : (accent ? tvTheme.primaryTextColor : tvTheme.secondaryTextColor),
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 8.sp),
                ?trailing,
              ],
            ),
          );
        },
      ),
    );
  }
}
