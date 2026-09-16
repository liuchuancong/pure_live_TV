import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// What the colour picker returns.
///
/// A null [color] is the "follow the theme colour" choice; a null result means
/// the picker was dismissed.
class ColorPickResult {
  const ColorPickResult(this.color);

  final Color? color;
}

/// One colour of the picker grid.
class TvColorOption {
  const TvColorOption(this.label, this.color);

  final String label;
  final Color color;
}

/// Colours offered by the picker: the desktop app's named palette first, then
/// a wider set so a TV without a colour picker still has a real choice.
final List<TvColorOption> kTvColorOptions = <TvColorOption>[
  for (final MapEntry<String, Color> entry in PlayerConsts.themeColors.entries)
    TvColorOption(entry.key, entry.value),
  const TvColorOption('#FFFFFF', Color(0xFFFFFFFF)),
  const TvColorOption('#F5F5F5', Color(0xFFF5F5F5)),
  const TvColorOption('#9E9E9E', Color(0xFF9E9E9E)),
  const TvColorOption('#616161', Color(0xFF616161)),
  const TvColorOption('#212121', Color(0xFF212121)),
  const TvColorOption('#F44336', Color(0xFFF44336)),
  const TvColorOption('#E91E63', Color(0xFFE91E63)),
  const TvColorOption('#FF5722', Color(0xFFFF5722)),
  const TvColorOption('#FF9800', Color(0xFFFF9800)),
  const TvColorOption('#FFC107', Color(0xFFFFC107)),
  const TvColorOption('#FFEB3B', Color(0xFFFFEB3B)),
  const TvColorOption('#CDDC39', Color(0xFFCDDC39)),
  const TvColorOption('#8BC34A', Color(0xFF8BC34A)),
  const TvColorOption('#4CAF50', Color(0xFF4CAF50)),
  const TvColorOption('#009688', Color(0xFF009688)),
  const TvColorOption('#00BCD4', Color(0xFF00BCD4)),
  const TvColorOption('#03A9F4', Color(0xFF03A9F4)),
  const TvColorOption('#2196F3', Color(0xFF2196F3)),
  const TvColorOption('#3F51B5', Color(0xFF3F51B5)),
  const TvColorOption('#673AB7', Color(0xFF673AB7)),
  const TvColorOption('#9C27B0', Color(0xFF9C27B0)),
  const TvColorOption('#E040FB', Color(0xFFE040FB)),
  const TvColorOption('#FF80AB', Color(0xFFFF80AB)),
  const TvColorOption('#80D8FF', Color(0xFF80D8FF)),
  const TvColorOption('#A7FFEB', Color(0xFFA7FFEB)),
  const TvColorOption('#CCFF90', Color(0xFFCCFF90)),
  const TvColorOption('#FFD180', Color(0xFFFFD180)),
];

/// Colour picker page: a grid of colours, since a TV has no colour picker.
class ColorPickerSectionPage extends StatelessWidget {
  const ColorPickerSectionPage({super.key, this.current});

  /// The colour the caller currently uses, marked in the grid.
  final Color? current;

  @override
  Widget build(BuildContext context) {
    return TvScaffold(
      title: i18n('ui_choose_color'),
      child: GridView.builder(
        padding: EdgeInsets.all(16.sp),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 12.sp,
          crossAxisSpacing: 12.sp,
          childAspectRatio: 1.25,
        ),
        itemCount: kTvColorOptions.length + 1,
        itemBuilder: (context, index) {
          // First tile: keep the theme colour.
          if (index == 0) {
            return _ColorTile(
              label: i18n('follow_theme_color'),
              color: context.tvTheme.focusColor,
              active: current == null,
              onTap: () => context.pop(const ColorPickResult(null)),
            );
          }
          final TvColorOption option = kTvColorOptions[index - 1];
          return _ColorTile(
            label: option.label,
            color: option.color,
            active: current != null && current!.toARGB32() == option.color.toARGB32(),
            onTap: () => context.pop(ColorPickResult(option.color)),
          );
        },
      ),
    );
  }
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({required this.label, required this.color, required this.active, required this.onTap});

  final String label;
  final Color color;
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
            border: Border.all(
              color: focused || active ? tvTheme.focusColor : tvTheme.secondaryTextColor.withValues(alpha: 0.3),
              width: focused || active ? 3.sp : 1.sp,
            ),
          ),
          padding: EdgeInsets.all(6.sp),
          child: Column(
            children: [
              Expanded(child: SizedBox(width: double.infinity, child: ColoredBox(color: color))),
              SizedBox(height: 4.sp),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.t14W500.copyWith(
                  color: focused ? tvTheme.focusColor : tvTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
