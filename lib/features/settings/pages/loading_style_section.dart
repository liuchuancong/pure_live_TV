import 'package:dpad/dpad.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/pages/color_picker_section.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/services/index.dart';

/// Loading animation picker.
///
/// Mirrors the mobile page: the animation colour sits on top of the list, then
/// the styles follow in a grid. Two differences are TV-driven. The colour is
/// chosen from a page of swatches instead of a colour wheel, because a remote
/// cannot drive an HSV picker, and *every* tile runs its real animation — a
/// list of names tells the user nothing about what they are picking.
class LoadingStyleSectionPage extends ConsumerWidget {
  const LoadingStyleSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeSettingsControllerProvider);
    final theme = ref.read(themeSettingsControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final Color color = themeState.loadingStyleColor ?? tvTheme.focusColor;

    return TvScaffold(
      appBar: TvAppBar(
        title: i18n('change_loading_style'),
        actions: [
          TvButton(
            title: i18n('restore_default'),
            size: TvButtonSize.mini,
            icon: Icon(Remix.restart_line, size: 22.w),
            onTap: () => theme.updateSettings(
              themeState.copyWith(
                loadingStyle: AppConsts.defaultLoadingStyleKey,
                loadingStyleColor: null,
              ),
            ),
          ),
        ],
      ),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 12.w, 16.w, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TvSettingsGroupTitle(title: i18n('change_loading_color')),
                  TvSettingsCard(
                    children: [
                      TvSettingsRow(
                        title: i18n('change_loading_color'),
                        subtitle: i18n('change_loading_color_subtitle'),
                        icon: Remix.palette_line,
                        trailingBuilder: (context, focused) => _LoadingColorSwatch(color: color, focused: focused),
                        onSelect: () => _pickColor(context, ref),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.w),
                  TvSettingsGroupTitle(title: i18n('change_loading_style')),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.w),
            // Sized by extent rather than a fixed column count: the same table
            // stays sane on a 1080p box and on a 4K panel, and the tiles keep
            // the density of the mobile grid instead of becoming huge blocks.
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190.w,
                mainAxisSpacing: 10.w,
                crossAxisSpacing: 10.w,
                childAspectRatio: 1.15,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final Map<String, String> style = AppConsts.allStyles[index];
                final String key = style['key'] ?? AppConsts.defaultLoadingStyleKey;
                return _LoadingStyleTile(
                  styleKey: key,
                  name: loadingStyleName(style),
                  color: color,
                  active: themeState.loadingStyle == key,
                  onTap: () => theme.updateSettings(themeState.copyWith(loadingStyle: key)),
                );
              }, childCount: AppConsts.allStyles.length),
            ),
          ),
        ],
      ),
    );
  }

  /// Colour choice for the animation, on the swatch page the TV app uses
  /// everywhere. A null colour means "keep the theme colour".
  Future<void> _pickColor(BuildContext context, WidgetRef ref) async {
    final ColorPickResult? result = await context.push<ColorPickResult>(
      AppRoutes.kSettingsColorPicker,
      extra: ref.read(themeSettingsControllerProvider).loadingStyleColor,
    );
    if (result == null) return;
    final ThemeSettingsModel state = ref.read(themeSettingsControllerProvider);
    ref.read(themeSettingsControllerProvider.notifier).updateSettings(state.copyWith(loadingStyleColor: result.color));
  }
}

/// Localized name of a style entry, falling back to its English name.
String loadingStyleName(Map<String, String> style) {
  final String localized = style['nameZh'] ?? '';
  final String english = style['nameEn'] ?? '';
  if (localized.isEmpty) return english;
  return i18nExists(localized) ? i18n(localized) : (english.isNotEmpty ? english : localized);
}

/// Square swatch of the colour the animations currently use.
class _LoadingColorSwatch extends StatelessWidget {
  const _LoadingColorSwatch({required this.color, required this.focused});

  final Color color;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return Container(
      width: 34.w,
      height: 34.w,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: focused ? tvTheme.focusColor : tvTheme.secondaryTextColor.withValues(alpha: 0.5),
          width: 2.w,
        ),
      ),
    );
  }
}

class _LoadingStyleTile extends StatelessWidget {
  const _LoadingStyleTile({
    required this.styleKey,
    required this.name,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String styleKey;
  final String name;
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
        final Color accent = tvTheme.focusColor;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: focused ? accent.withValues(alpha: 0.22) : Colors.transparent,
            border: Border.all(
              color: focused || active ? accent : tvTheme.secondaryTextColor.withValues(alpha: 0.25),
              width: focused || active ? 2.w : 1.w,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.w),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: TvLoadingStylePreview(style: styleKey, color: color, size: 44.w, theme: tvTheme),
                    ),
                  ),
                  SizedBox(height: 6.w),
                  Text(
                    name,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t14W500.copyWith(
                      color: focused || active ? accent : tvTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
              if (active)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(Icons.check_circle_rounded, size: 18.w, color: accent),
                ),
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
