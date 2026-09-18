import 'package:dpad/dpad.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/consts/icon_catalog.dart';

/// What the icon picker returns.
///
/// A result carrying a null [option] is the picker's "restore default" action;
/// a null result (the user went back) means "leave it alone".
class IconPickResult {
  const IconPickResult(this.option);

  final IconOption? option;
}

/// Pick an icon for a menu entry.
///
/// Its own full-screen route rather than a section page: the grid owns the
/// scroll axis, and the picker returns the chosen icon to the row that opened
/// it.
class IconPickerSectionPage extends StatelessWidget {
  const IconPickerSectionPage({super.key, this.currentLabel});

  /// Label of the icon the caller currently shows, marked in the grid.
  final String? currentLabel;

  @override
  Widget build(BuildContext context) {
    return TvPageScaffold(
      appBar: TvAppBar(
        title: i18n('ui_choose_icon'),
        actions: [
          TvButton(
            title: i18n('reset'),
            size: TvButtonSize.mini,
            icon: Icon(Remix.restart_line, size: 22.sp),
            onTap: () => context.pop(const IconPickResult(null)),
          ),
        ],
      ),
      child: GridView.builder(
        padding: EdgeInsets.all(16.sp),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 12,
          mainAxisSpacing: 12.sp,
          crossAxisSpacing: 12.sp,
          childAspectRatio: 1.15,
        ),
        itemCount: kIconCatalog.length,
        itemBuilder: (context, index) {
          final IconOption option = kIconCatalog[index];
          return _IconTile(
            option: option,
            active: currentLabel != null && currentLabel == option.label,
            onTap: () => context.pop(IconPickResult(option)),
          );
        },
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.option, required this.active, required this.onTap});

  final IconOption option;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return DpadFocusable(
      onSelect: onTap,
      builder: (context, state, child) {
        final bool focused = state.focused;
        return Container(
          decoration: BoxDecoration(
            color: focused ? tvTheme.focusColor.withValues(alpha: 0.22) : Colors.transparent,
            // Marked with a border rather than a rounded corner, like the rest
            // of the TV settings surfaces.
            border: Border.all(
              color: focused || active ? tvTheme.focusColor : tvTheme.secondaryTextColor.withValues(alpha: 0.25),
              width: focused || active ? 2.sp : 1.sp,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 8.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(option.icon, size: 34.sp, color: focused || active ? tvTheme.focusColor : tvTheme.primaryTextColor),
              SizedBox(height: 6.sp),
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.t14W500.copyWith(color: focused ? tvTheme.focusColor : tvTheme.secondaryTextColor),
              ),
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
