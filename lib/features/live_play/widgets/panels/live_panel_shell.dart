import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/theme/index.dart';

/// 右侧面板的统一外壳：标题栏 + 操作提示 + 内容区。
///
/// 播放页的四个面板（房间信息 / 播放列表 / 弹幕设置 / 弹幕过滤）共用它，
/// 保证焦点进入面板后的视觉与导航手感一致。
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

/// 一行「左右键调值」的选项。
///
/// 上下键不拦截，交给 D-pad 焦点遍历在行之间移动；左右键被本行消费用于调值，
/// 这样在电视上不需要进入子弹窗就能改参数（与老项目弹幕设置面板手感一致）。
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

  /// 确认键行为（例如切换开关）；为空时确认键不做任何事。
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

/// 一行「确认键执行」的操作项（删除屏蔽词、切台等）。
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

  /// 是否是「当前项」（例如正在播放的频道）。
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
