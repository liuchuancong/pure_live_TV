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

/// Colours offered by the picker.
///
/// The mobile app opens a full colour wheel plus the named palette
/// (`AppConsts.colorsNameMap`); a remote cannot drive a wheel, so the same
/// freedom is offered as a dense grid: the named colours first, then three
/// shades of every Material hue, which covers what a wheel is actually used for
/// — finding a nearby tone.
final List<TvColorOption> kTvColorOptions = <TvColorOption>[
  for (final MapEntry<String, Color> entry in PlayerConsts.themeColors.entries)
    TvColorOption(entry.key, entry.value),
  const TvColorOption('White', Color(0xFFFFFFFF)),
  const TvColorOption('Black', Color(0xFF000000)),
  const TvColorOption('Grey', Color(0xFF9E9E9E)),
  for (final MapEntry<String, MaterialColor> hue in _tvHueShades.entries)
    for (final int shade in _tvShadeSteps) TvColorOption('${hue.key} $shade', hue.value[shade]!),
];

/// Material hues the palette is built from.
const Map<String, MaterialColor> _tvHueShades = <String, MaterialColor>{
  'Red': Colors.red,
  'Pink': Colors.pink,
  'Purple': Colors.purple,
  'Deep Purple': Colors.deepPurple,
  'Indigo': Colors.indigo,
  'Blue': Colors.blue,
  'Light Blue': Colors.lightBlue,
  'Cyan': Colors.cyan,
  'Teal': Colors.teal,
  'Green': Colors.green,
  'Light Green': Colors.lightGreen,
  'Lime': Colors.lime,
  'Yellow': Colors.yellow,
  'Amber': Colors.amber,
  'Orange': Colors.orange,
  'Deep Orange': Colors.deepOrange,
  'Brown': Colors.brown,
  'Blue Grey': Colors.blueGrey,
};

/// One dark, one mid and one light tone per hue.
const List<int> _tvShadeSteps = <int>[200, 400, 700];

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
        padding: EdgeInsets.all(16.w),
        // Extent-based, not a fixed column count: the swatches stay small on any
        // panel size instead of ballooning on a 4K screen.
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150.w,
          mainAxisSpacing: 10.w,
          crossAxisSpacing: 10.w,
          childAspectRatio: 1.0,
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
